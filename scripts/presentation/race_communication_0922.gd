extends RefCounted
## 9.22 presentation-only communication. No writes to RaceEngine or RNG.
const Thermal = preload("res://scripts/core/race_tyre_thermal.gd")
const MAX_HISTORY := 32
const MAX_PENDING := 16
const ERROR_WORDS := {
	"LOCK_UP": "Lock-up noted. Build the pace back gradually.",
	"MISSED_APEX": "Copy. Reset for the next corner.",
	"POOR_TRACTION": "Copy. Smooth on the throttle as you recover.",
	"OVERSTEER": "Understood. Give yourself room to settle the car.",
	"RUNNING_WIDE": "Copy. Regroup and focus on the next corner.",
	"SPIN": "Take your time. Bring the pace back when you can."
}
var history: Dictionary = {}
var pending: Array[Dictionary] = []
var last_at: Dictionary = {}
var active: Dictionary = {}
var relationships: Dictionary = {}
var serial: int = 0
var last_clock: float = -1.0

static func is_system(text: String, kind: String = "") -> bool:
	var s: String = text.to_lower()
	if kind in ["system", "configuration", "driver_control"]:
		return true
	for token in ["controle individual:", "controle de box ", "modo automático ativado", "modo automatico ativado", "modo manual ativado", "automatic mode activated", "auto mode activated", "manual mode activated", "modo automático habilitado", "modo ia ativado", "modo automatico habilitado", "modo assistido ativado", "auto mode enabled", "ia de estratégia habilitada", "staff | controle"]:
		if s.contains(token):
			return true
	return false

static func diagnose(car: Dictionary, weather: Dictionary) -> Dictionary:
	var e: Dictionary = car.get("driver_error_0921", {})
	var mode: String = str(e.get("mode", "NORMAL"))
	var wear: float = float(car.get("wear", 0.0))
	var wet: float = float(weather.get("wetness_factor", 0.0))
	var tire: String = str(car.get("tire", ""))
	var traffic: Dictionary = car.get("traffic_pack_09201", {})
	var booked: int = int(car.get("pit_scheduled_lap", 0))
	var aero: Dictionary = car.get("aero_wake_032", {})
	var band: Array = Thermal.band(tire)
	var temperature: float = float(car.get("tyre_surface_c", -1.0))
	var causes: Array[String] = []
	if mode in ["ERROR", "CONTROL", "RECOVERY"]:
		causes.append("RECOVERY")
	if wet >= 0.25 and tire != "" and tire not in ["Intermediário", "Chuva"]:
		causes.append("WET_MISMATCH")
	if wear >= 78.0:
		causes.append("TYRE_WEAR")
	if temperature >= 0.0 and band.size() >= 2 and (temperature > float(band[1]) or temperature < float(band[0])):
		causes.append("TYRE_TEMPERATURE")
	if float(aero.get("dirty_fraction", 0.0)) > 0.005:
		causes.append("DIRTY_AIR")
	if str(traffic.get("mode", "")) in ["FOLLOWING", "TRAIN", "WAIT"]:
		causes.append("TRAFFIC")
	var cause: String = "UNKNOWN" if causes.is_empty() else causes[0]
	var priority: int = 3
	var advice: String = "No clear cause yet. We'll keep watching the sectors."
	match cause:
		"RECOVERY":
			advice = str(ERROR_WORDS.get(str(e.get("kind", "")), "Copy. Build the pace back gradually."))
			priority = 2
		"WET_MISMATCH":
			advice = "Grip may be dropping on these tyres. We are checking the pit window."
			priority = 1
		"TYRE_WEAR":
			advice = "Tyre wear is high. We need to compare the pace with the cost of stopping."
			priority = 1
		"TYRE_TEMPERATURE":
			advice = "Tyre temperature is outside the target window. Watch the grip."
			priority = 2
		"DIRTY_AIR":
			advice = "We're seeing an aerodynamic wake effect. Let's watch the gap."
			priority = 2
		"TRAFFIC":
			advice = "Traffic may be costing us time. Let's look for clean air."
			priority = 2
	return {"cause": cause, "causes": causes, "priority": priority, "confidence": "LIMITED" if cause == "UNKNOWN" or causes.size() > 1 else "SUPPORTED", "advice": advice, "booked_lap": booked, "recovery_mode": mode, "wear": wear, "wetness": wet, "tire": tire, "temperature": temperature, "dirty_fraction": float(aero.get("dirty_fraction", 0.0))}

static func answer(topic: String, car: Dictionary, weather: Dictionary) -> String:
	if car.is_empty():
		return "No data available."
	var d: Dictionary = diagnose(car, weather)
	match topic:
		"recuperacao":
			return str(d.advice) if str(d.cause) == "RECOVERY" else "No active recovery indicated."
		"diagnostico":
			return str(d.advice)
		"clima":
			return "Track wetness indicator: %.0f%%. Future conditions remain uncertain." % (float(d.wetness) * 100.0)
		"kers_drs":
			return "KERS: %s. DRS: %s." % [str(car.get("kers_mode", "unknown")), "active" if bool(car.get("drs_active", false)) else "not confirmed active"]
		"estrategia":
			return "Box lap %d is booked. We will review the window." % int(d.booked_lap) if int(d.booked_lap) > 0 else "No stop booked. We are reviewing the pit window."
	return str(d.advice)

static func pass_words(car: Dictionary, event_id: int) -> String:
	# Original dry humour, only on a confirmed pass. No claims about rivals' thoughts.
	var style: int = posmod(int(car.get("id", 0)), 3)
	var options: Array[String] = ["Nice work. One less car to worry about.", "That's done. Next one, please.", "Good pass. Now let's make it stick."]
	return options[posmod(style + event_id, options.size())]

func reset() -> void:
	history.clear()
	pending.clear()
	last_at.clear()
	active.clear()
	relationships.clear()
	serial = 0
	last_clock = -1.0

func offer(car_id: int, intent: String, words: String, priority: int, now: float, event_id: int = -1, evidence: Dictionary = {}, sender: String = "ENGENHEIRO", conversation_id: String = "") -> bool:
	if words.is_empty() or is_system(words):
		return false
	var key: String = "%d|%s|%s" % [car_id, intent, sender]
	if now - float(last_at.get(key, -9999.0)) < (4.0 if priority <= 1 else 15.0):
		return false
	if pending.size() >= MAX_PENDING:
		var worst: int = 0
		for i in range(1, pending.size()):
			if int(pending[i].priority) > int(pending[worst].priority):
				worst = i
		if int(pending[worst].priority) <= priority:
			return false
		pending.remove_at(worst)
	serial += 1
	var cid: String = conversation_id if not conversation_id.is_empty() else "%d:%d" % [car_id, serial]
	pending.append({"message_id": serial, "conversation_id": cid, "car_id": car_id, "intent": intent, "sender": sender, "priority": priority, "created": now, "expires": now + (35.0 if priority <= 1 else 20.0), "source_event_id": event_id, "evidence": evidence.duplicate(true), "text": words, "command_authorized": false, "voice_profile_id": "apex_original_engineer_%d" % posmod(car_id, 3), "subtitle": words, "audio_channel": "TEAM_RADIO", "interruptible": priority > 1})
	last_at[key] = now
	return true

func drain(now: float) -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	for packet in pending:
		if float(packet.expires) >= now:
			ready.append(packet)
	pending.clear()
	ready.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.priority) < int(b.priority) if int(a.priority) != int(b.priority) else int(a.message_id) < int(b.message_id))
	for packet in ready:
		var id: int = int(packet.car_id)
		var entries: Array = history.get(id, [])
		entries.append(packet.duplicate(true))
		while entries.size() > MAX_HISTORY:
			entries.pop_front()
		history[id] = entries
		var relationship: Dictionary = relationships.get(id, {"acknowledged": 0, "followups": 0})
		relationship["acknowledged"] = int(relationship.acknowledged) + 1
		if str(packet.intent).ends_with("FOLLOWUP"):
			relationship["followups"] = int(relationship.followups) + 1
		relationships[id] = relationship
	return ready

func observe(car: Dictionary, weather: Dictionary, now: float) -> void:
	if car.is_empty() or bool(car.get("finished", false)):
		return
	var id: int = int(car.get("id", -1))
	var d: Dictionary = diagnose(car, weather)
	var current: Dictionary = active.get(id, {})
	var cause: String = str(d.cause)
	var previous: String = str(current.get("cause", "UNKNOWN"))
	if cause == previous:
		return
	if previous == "RECOVERY" and str(d.recovery_mode) in ["REBUILD", "NORMAL"] and float(car.get("pit_left", 0.0)) <= 0.0:
		offer(id, "RECOVERY_FOLLOWUP", "Pace recovery noted. Keep building from here.", 2, now, -1, d, "ENGENHEIRO", str(current.get("conversation_id", "")))
	if previous != "UNKNOWN" and previous != "RECOVERY" and cause == "UNKNOWN":
		offer(id, previous + "_FOLLOWUP", "That indicator has settled. We'll keep monitoring.", 3, now, -1, d, "ENGENHEIRO", str(current.get("conversation_id", "")))
	if cause == "UNKNOWN":
		active.erase(id)
		return
	if cause == "RECOVERY":
		# Engine 040 already reports the initial error and recovery. Do not invent a second incident.
		active[id] = {"cause": cause, "conversation_id": "%d:recovery:%d" % [id, int((car.get("driver_error_0921", {}) as Dictionary).get("count", 0))]}
		return
	if offer(id, cause, str(d.advice), int(d.priority), now, -1, d):
		active[id] = {"cause": cause, "conversation_id": "%d:%d" % [id, serial]}
