extends RefCounted
## 9.22 presentation-only communication. No writes to RaceEngine or RNG.
const Thermal = preload("res://scripts/core/race_tyre_thermal.gd")
const Portuguese0922 = preload("res://scripts/presentation/race_radio_pt_0922.gd")
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
# PT-BR subtitle catalogue for the new original English radio vocabulary.
const SUBTITLES := {
	"Lock-up noted. Build the pace back gradually.":"Travamento registrado. Recupere o ritmo aos poucos.",
	"Copy. Reset for the next corner.":"Entendido. Concentre-se na próxima curva.",
	"Copy. Smooth on the throttle as you recover.":"Entendido. Acelere suavemente durante a recuperação.",
	"Understood. Give yourself room to settle the car.":"Entendido. Dê espaço para estabilizar o carro.",
	"Copy. Regroup and focus on the next corner.":"Entendido. Recupere a concentração para a próxima curva.",
	"Take your time. Bring the pace back when you can.":"Sem pressa. Recupere o ritmo quando puder.",
	"Copy. Build the pace back gradually.":"Entendido. Recupere o ritmo aos poucos.",
	"No clear cause yet. We'll keep watching the sectors.":"Ainda não há uma causa clara. Vamos acompanhar os setores.",
	"Grip may be dropping on these tyres. We are checking the pit window.":"A aderência pode estar diminuindo. Estamos avaliando a janela de box.",
	"Tyre wear is high. We need to compare the pace with the cost of stopping.":"Desgaste elevado. Precisamos comparar o ritmo com o custo da parada.",
	"Tyre temperature is outside the target window. Watch the grip.":"Temperatura fora da faixa ideal. Observe a aderência.",
	"We're seeing an aerodynamic wake effect. Let's watch the gap.":"Estamos observando efeito de ar sujo. Vamos acompanhar a diferença.",
	"Traffic may be costing us time. Let's look for clean air.":"O tráfego pode estar custando tempo. Vamos buscar ar limpo.",
	"That's one off the list. Don't send me the bill.":"Mais um fora da lista. Não me mande a conta.",
	"One less car to worry about. Very considerate.":"Um carro a menos para preocupar. Muito gentil.",
	"Pass confirmed. Build the gap now.":"Ultrapassagem confirmada. Agora abra vantagem.",
	"Nice work. Keep it tidy and look ahead.":"Bom trabalho. Mantenha a precisão e olhe à frente.",
	"That's one done.":"Mais um resolvido.",
	"Good pass. Keep the pace under control.":"Boa ultrapassagem. Mantenha o ritmo sob controle.",
	"Pace recovery noted. Keep building from here.":"Recuperação registrada. Continue evoluindo o ritmo.",
	"That indicator has settled. We'll keep monitoring.":"Esse indicador estabilizou. Continuaremos monitorando.",
	"Copy. Settle the car and build the pace back.":"Entendido. Estabilize o carro e recupere o ritmo.",
	"Pace is back now.":"Recuperei o ritmo.",
	"No active recovery indicated.":"Nenhuma recuperação ativa indicada.",
	"No data available.":"Dados indisponíveis.",
	"No stop booked. We are reviewing the pit window.":"Sem parada agendada. Estamos avaliando a janela de box."
}

static func subtitle(words: String, evidence: Dictionary = {}) -> String:
	if SUBTITLES.has(words):
		return str(SUBTITLES[words])
	if evidence.has("rival_name") and evidence.has("position"):
		return "%s avançou para P%d. Fique atento." % [str(evidence.rival_name), int(evidence.position)]
	if words.begins_with("Box lap ") and words.ends_with(" is booked. We will review the window."):
		var lap: String = words.substr(8).split(" ")[0]
		if lap.is_valid_int():
			return "A parada da volta %d está marcada. Vamos rever a janela." % int(lap)
	if words.begins_with("Track wetness indicator: ") and words.ends_with(". Future conditions remain uncertain."):
		return "Indicador de umidade da pista: " + words.trim_prefix("Track wetness indicator: ").trim_suffix(". Future conditions remain uncertain.") + ". As condições futuras permanecem incertas."
	if words.begins_with("KERS: ") and words.contains(". DRS: "):
		return words.replace("not confirmed active", "atividade não confirmada").replace("active", "ativo").replace("unknown", "desconhecido")
	return Portuguese0922.translate(words)

static func language(words: String) -> String:
	if SUBTITLES.has(words):
		return "en"
	var lower: String = words.to_lower()
	for token in ["rádio", "engenheiro:", "para ", "pneus", "volta", "piloto", "ção", "não", "está", "ordem", "aderência"]:
		if lower.contains(token):
			return "pt"
	return "en"

var history: Dictionary = {}
var pending: Array[Dictionary] = []
var last_at: Dictionary = {}
var active: Dictionary = {}
var relationships: Dictionary = {}
var observed_candidates: Dictionary = {}
var last_banter: Dictionary = {}
var staff_context: Dictionary = {}
var career_bonds: Dictionary = {}
var serial: int = 0
var last_clock: float = -1.0

static func is_system(text: String, kind: String = "") -> bool:
	var s: String = text.to_lower()
	if kind in ["system", "configuration", "driver_control"]:
		return true
	for token in ["controle individual:", "controle de box ", "modo auto ativado", "modo auto habilitado", "modo automatico ligado", "automatic mode enabled", "auto mode on", "modo automático ativado", "modo automatico ativado", "modo manual ativado", "automatic mode activated", "auto mode activated", "manual mode activated", "modo automático habilitado", "modo ia ativado", "modo automatico habilitado", "modo assistido ativado", "auto mode enabled", "ia de estratégia habilitada", "staff | controle"]:
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

static func profile(car: Dictionary, staff: Dictionary = {}) -> Dictionary:
	# Fictional session voice, not a claim about a real engineer.
	var style: String = str(staff.get("engineer_radio_style", ""))
	var styles: Array[String] = ["CALM", "DEADPAN", "TECHNICAL"]
	if not style in styles:
		style = styles[posmod(int(car.get("id", 0)), styles.size())]
	var competence: int = clampi(int(staff.get("Engenheiro", 1)), 0, 3)
	var contract_id: String = str(staff.get("engineer_contract_id", ""))
	var voice: String = "apex_original_" + (contract_id if not contract_id.is_empty() else style.to_lower())
	return {"style": style, "competence": competence, "voice_profile_id": voice, "locale": "en", "name": str(staff.get("engineer_name", "Race Engineer"))}

static func pass_words(car: Dictionary, event_id: int, staff: Dictionary = {}) -> String:
	# Only for an actual confirmed on-track pass.
	match str(profile(car, staff).style):
		"DEADPAN":
			return "That's one off the list. Don't send me the bill." if event_id % 2 == 0 else "One less car to worry about. Very considerate."
		"TECHNICAL":
			return "Pass confirmed. Build the gap now."
		_:
			return "Nice work. Keep it tidy and look ahead."

static func confirmed_position(source: String) -> int:
	# Event text carries the confirmed position, not the identity of the car passed.
	var index: int = source.rfind("P")
	if index < 0:
		return -1
	var value: String = source.substr(index + 1).strip_edges().trim_suffix(".")
	return int(value) if value.is_valid_int() and int(value) > 0 else -1

func on_pass(car: Dictionary, event: Dictionary, staff: Dictionary = {}) -> void:
	if str(event.get("type", "")) != "pass" or car.is_empty():
		return
	var id: int = int(car.get("id", -1))
	var event_id: int = int(event.get("event_id", -1))
	var now: float = float(event.get("time", 0.0))
	var p: Dictionary = profile(car, staff)
	var soul: Dictionary = car.get("driver_soul", {})
	var e: Dictionary = car.get("driver_error_0921", {})
	var facts: Dictionary = {"position": confirmed_position(str(event.get("message", ""))), "style": p.style, "voice_profile_id": p.voice_profile_id, "source": "confirmed_pass"}
	var cid: String = "%d:pass:%d" % [id, event_id]
	var pair: String = "%s|%d" % [str(staff.get("engineer_contract_id", "")), id]
	var bond: int = clampi(int(career_bonds.get(pair, 50)), 0, 100)
	var relaxed: bool = float(soul.get("pressure", 0.0)) < .4 and float(soul.get("confidence", .55)) > .5 and str(e.get("mode", "NORMAL")) in ["NORMAL", "REBUILD"]
	if relaxed and str(p.style) == "DEADPAN" and now - float(last_banter.get(id, -9999.0)) >= float(130 - bond * 4 / 5):
		if offer(id, "PASS_PILOT", "That's one done.", 3, now, event_id, facts, "PILOTO", cid):
			last_banter[id] = now
			offer(id, "CONFIRMED_PASS", pass_words(car, event_id, staff), 3, now, event_id, facts, "ENGENHEIRO", cid)
	else:
		offer(id, "CONFIRMED_PASS", "Good pass. Keep the pace under control." if not relaxed else pass_words(car, event_id, staff), 3, now, event_id, facts, "ENGENHEIRO", cid)

func on_rival_pass(player: Dictionary, rival: Dictionary, event: Dictionary, now: float, staff: Dictionary = {}) -> void:
	if str(event.get("type", "")) != "pass" or rival.is_empty() or now - float(event.get("time", 0.0)) > 2.0:
		return
	var pos: int = confirmed_position(str(event.get("message", "")))
	var ours: int = int(player.get("position", -1))
	if pos < 1 or ours < 1 or absi(pos - ours) > 2 or pos == ours:
		return
	if str(rival.get("team", "")) == str(player.get("team", "")):
		return
	var id: int = int(player.get("id", -1))
	var name: String = str(rival.get("name", ""))
	if name.is_empty():
		return
	var p: Dictionary = profile(player, staff)
	var words: String = "%s is through to P%d. Keep an eye on that." % [name, pos]
	if str(p.style) == "DEADPAN" and float((player.get("driver_soul", {}) as Dictionary).get("pressure", 0.0)) < .4:
		words = "%s has found a way through. P%d now. No time for sightseeing." % [name, pos]
	offer(id, "RIVAL_PASS", words, 2, float(event.get("time", 0.0)), int(event.get("event_id", -1)), {"rival_id": int(rival.get("id", -1)), "rival_name": name, "position": pos, "style": p.style, "voice_profile_id": p.voice_profile_id})


func reset() -> void:
	history.clear()
	pending.clear()
	last_at.clear()
	active.clear()
	relationships.clear()
	observed_candidates.clear()
	last_banter.clear()
	staff_context.clear()
	career_bonds.clear()
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
	pending.append({"message_id": serial, "conversation_id": cid, "car_id": car_id, "intent": intent, "sender": sender, "priority": priority, "created": now, "expires": now + (35.0 if priority <= 1 else 20.0), "source_event_id": event_id, "evidence": evidence.duplicate(true), "text": words, "command_authorized": false, "voice_profile_id": ("apex_original_driver_%d" % car_id) if sender == "PILOTO" else str(evidence.get("voice_profile_id", "apex_original_engineer_%d" % posmod(car_id, 3))), "subtitle": words, "subtitle_pt": subtitle(words, evidence), "locale": "en", "audio_channel": "TEAM_RADIO", "interruptible": priority > 1})
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
		remember_delivery(packet)
	return ready

func remember_delivery(packet: Dictionary) -> void:
	var id: int = int(packet.get("car_id", -1))
	if id < 0:
		return
	var entries: Array = history.get(id, [])
	entries.append(packet.duplicate(true))
	while entries.size() > MAX_HISTORY:
		entries.pop_front()
	history[id] = entries
	var relationship: Dictionary = relationships.get(id, {"acknowledged": 0, "followups": 0, "exchanges": 0})
	relationship["acknowledged"] = int(relationship.get("acknowledged", 0)) + 1
	var intent: String = str(packet.get("intent", ""))
	if intent.ends_with("FOLLOWUP"):
		relationship["followups"] = int(relationship.get("followups", 0)) + 1
	if intent in ["interactive_reply", "stint_analysis", "engineer_comparison", "soul_engineer"]:
		relationship["exchanges"] = int(relationship.get("exchanges", 0)) + 1
	relationships[id] = relationship

func legacy_packet(at: float, role: String, text: String, kind: String, car_id: int, metadata: Dictionary = {}) -> Dictionary:
	if text.is_empty() or is_system(text, kind):
		return {}
	serial += 1
	var p: Dictionary = profile({"id": car_id}, staff_context)
	var words: String = text
	if words.begins_with("Para ") or words.begins_with("RÁDIO FICTÍCIO |") or words.begins_with("RADIO FICTICIO |") or words.begins_with("ENGENHEIRO |"):
		var separator: int = words.find(": ")
		if separator >= 0:
			words = words.substr(separator + 2)
	var raw: Dictionary = metadata.get("radio3", {})
	if not raw.is_empty():
		words = str(raw.get("text", words))
	var priority: int = int(metadata.get("priority", 2 if kind == "engineer_reply" else 3))
	var cid: String = str(metadata.get("conversation_id", "%d:legacy:%.3f" % [car_id, at]))
	if cid.is_empty():
		cid = "%d:legacy:%.3f" % [car_id, at]
	return {"message_id": serial, "conversation_id": cid, "car_id": car_id, "intent": kind, "sender": role, "priority": priority, "created": at, "expires": at + (35.0 if priority <= 1 else 20.0), "source_event_id": int(metadata.get("source_event_id", -1)), "evidence": {}, "text": text, "command_authorized": false, "voice_profile_id": "apex_original_driver_%d" % car_id if role == "PILOTO" else str(p.voice_profile_id), "subtitle": text, "subtitle_pt": str(raw.get("subtitle_pt", subtitle(words))), "locale": str(raw.get("locale", language(words))), "speech_text": words, "audio_channel": "TEAM_RADIO", "interruptible": priority > 1, "legacy_kind": kind, "radio3": raw.duplicate(true)}

func record_legacy(at: float, role: String, text: String, kind: String, car_id: int) -> Dictionary:
	# Explicit player consultations stay synchronous; all use the shared packet.
	var packet: Dictionary = legacy_packet(at, role, text, kind, car_id)
	if not packet.is_empty():
		remember_delivery(packet)
	return packet

func enqueue_legacy(at: float, role: String, text: String, kind: String, car_id: int, metadata: Dictionary = {}) -> bool:
	var packet: Dictionary = legacy_packet(at, role, text, kind, car_id, metadata)
	if packet.is_empty():
		return false
	# Critical messages may displace obsolete chatter. Prefer the oldest
	# low-priority pending item, without reordering messages of equal priority.
	if pending.size() >= MAX_PENDING:
		var worst: int = 0
		for i in range(1, pending.size()):
			if int(pending[i].priority) > int(pending[worst].priority):
				worst = i
		if int(pending[worst].priority) <= int(packet.priority):
			return false
		pending.remove_at(worst)
	pending.append(packet)
	return true

func observe(car: Dictionary, weather: Dictionary, now: float, staff: Dictionary = {}) -> void:
	if car.is_empty() or bool(car.get("finished", false)) or float(car.get("pit_left", 0.0)) > 0.0:
		return
	var id: int = int(car.get("id", -1))
	var d: Dictionary = diagnose(car, weather)
	var p: Dictionary = profile(car, staff)
	d["style"] = p.style
	d["voice_profile_id"] = p.voice_profile_id
	d["competence"] = p.competence
	var current: Dictionary = active.get(id, {})
	var cause: String = str(d.cause)
	var previous: String = str(current.get("cause", "UNKNOWN"))
	if cause == previous:
		observed_candidates.erase(id)
		return
	# Require sustained evidence for ordinary alerts; urgent recovery and wet
	# mismatch are observed immediately. Staff competence affects interpretation
	# latency only, never the simulation or what gets commanded.
	if cause not in ["RECOVERY", "WET_MISMATCH"] and cause != "UNKNOWN" and previous != "RECOVERY":
		var candidate: Dictionary = observed_candidates.get(id, {})
		if str(candidate.get("cause", "")) != cause:
			observed_candidates[id] = {"cause": cause, "since": now}
			return
		if now - float(candidate.get("since", now)) < float(8 - int(p.competence) * 2):
			return
	observed_candidates.erase(id)
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
