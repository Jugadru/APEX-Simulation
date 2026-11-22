extends RefCounted
## APEX v0.6.6.9.5 - Race Radio 3.0.
## PRESENTATION ONLY. Consumes already-confirmed incidents/requests and a read-only
## snapshot of the driver's Soul. Never writes to RaceEngine, RNG, pace or pit.
## The short fictional text is original; no historical recordings or voice clones.
const VERSION := "3.0"
const LOCALE := "en"
const STYLE_NAMES := ["TERSE", "FIERY", "TECHNICAL", "CAUTIOUS", "COMPETITIVE"]
const MAX_MEMORY := 8

# Five distinct voices per *verified* intention, not random sentences.
# Do not mention an axle, a corner, a precise power unit fault, etc. unless
# a validated event actually supplies that specific observation.
const PILOT_LINES := {
	"revisar_plano": [
		"Conditions changed. What about our lap %d stop?",
		"Track's changed! Are we still stopping on lap %d?",
		"Check the plan. We still have lap %d booked.",
		"Can we check the lap %d stop? It feels different out here.",
		"Lap %d is the plan, right? I need an update."
	],
	"avaliar_box": [
		"Grip's going. Check the window.",
		"I can't keep this going! Check the pit window!",
		"Grip is dropping. Review our stop window.",
		"Not happy on these tyres. Can we look at the window?",
		"We're losing time here. Look at the stop."
	],
	"troca_equipe": [
		"I'm quicker. Check with the pit wall.",
		"I'm faster! Can we sort this out?",
		"My last laps are quicker. Compare the gaps.",
		"I'm catching our car. Can we discuss the order?",
		"He's holding me up. I have more pace."
	],
	"perda_ritmo": [
		"No pace. Check the tyres.",
		"Where's the pace gone?!",
		"My lap times are dropping. Check the data.",
		"I'm struggling for pace. Is it the tyres?",
		"We're losing time. Need an answer."
	],
	"estender_stint": [
		"Tyres feel good. I'd stay out.",
		"I've still got grip! Keep me out if we can!",
		"Tyres still respond. Check if we can extend.",
		"I think there's another lap in these tyres.",
		"I can keep going. Let's not give up track position."
	],
	"grip_molhado": [
		"Too slippery on these slicks.",
		"No grip! It's too wet for these tyres!",
		"Water's up. These slicks aren't working.",
		"It's getting slippery. Can we look at tyres?",
		"I'm losing grip on the slicks. Need a plan."
	],
	"chuva_secando": [
		"Track's drying. Check the tyres.",
		"It's drying! These wets aren't working now!",
		"Surface is drying. Reassess the full wets.",
		"Feels much drier. Can we review the tyres?",
		"We're giving away time on these wets."
	],
	"inter_secando": [
		"Almost dry. Check the inters.",
		"It's dry out here! The inters are done!",
		"Track is almost dry. Review the inters.",
		"I think it's time to consider slicks.",
		"We need to look at slicks. It's drying fast."
	],
	"aderencia": [
		"Grip's gone away. Check the stop.",
		"No grip anymore! What about the stop?!",
		"Tyre wear is hurting traction. Check the window.",
		"I'm struggling on these tyres. Can we review?",
		"These tyres are costing us. Look at the pit window."
	],
	"temperatura": [
		"Tyres are running hot.",
		"Tyres are too hot! I'm struggling!",
		"Tyre temperatures are up. I'm managing them.",
		"Having trouble keeping these tyres cool.",
		"Temperatures are hurting us. Need to manage this."
	],
	"trafego": [
		"Stuck behind him. Dirty air.",
		"I can't get close! Too much dirty air!",
		"Close to the car ahead. Losing grip in traffic.",
		"Hard to follow in these corners.",
		"I've got pace, but the traffic's killing it."
	],
	"incidente": [
		"Had a moment. Checking the car.",
		"That was close! Need to check the car!",
		"Had an incident. I'll monitor the handling.",
		"Something happened there. Car feels different.",
		"Lost time in that incident. We need to recover."
	],
	"box": [
		"Lost time in the stop. What's the gap?",
		"What happened in the box?! We lost time!",
		"Pit service delay. Update the gaps.",
		"That stop cost us time. Any update?",
		"We lost time in the pits. Need the gaps."
	],
	"disputa": [
		"Clear now. Back to pace.",
		"Yes! Good move! Keep pushing!",
		"Move complete. Checking the next gap.",
		"Got through. I'll settle the tyres.",
		"Got him. Who's next?"
	],
	"desgaste": [
		"Tyres are starting to go.",
		"I'm losing grip on these tyres!",
		"Degradation is building. Keep an eye on it.",
		"These tyres are fading a bit.",
		"Grip is dropping. Need to watch the pace."
	],
	"chuva": [
		"It's getting wet. Slicks are struggling.",
		"There's more water! These slicks won't work!",
		"Track's getting wetter. Slick grip is falling.",
		"Less grip now. The rain is affecting us.",
		"Too wet for slicks. Let's reassess."
	],
	"ritmo": [
		"Lap times are off. Check why.",
		"Why are we so slow now?!",
		"Last laps are slower. Compare the data.",
		"I'm losing pace. Need to understand it.",
		"We're dropping time. What's happening?"
	]
}

const ENGINEER_LINES := {
	"revisar_plano": "Copy. We're checking the conditions.",
	"avaliar_box": "Copy. Reviewing the window. No call yet.",
	"troca_equipe": "Copy. Comparing lap times. No team order issued.",
	"perda_ritmo": "Understood. Checking tyres and traffic.",
	"estender_stint": "Copy. We'll compare your feeling with the data.",
	"grip_molhado": "Copy. We're reviewing conditions and compounds.",
	"chuva_secando": "Copy. Watching the crossover.",
	"inter_secando": "Understood. Checking the dry-tyre window.",
	"aderencia": "Copy. Looking at wear and pit loss.",
	"temperatura": "Copy. Monitor the grip; we'll check the data.",
	"trafego": "Copy. We'll monitor the gap.",
	"incidente": "Copy. Report any handling change.",
	"box": "Copy. Checking the gaps after the stop.",
	"disputa": "Copy. Focus on the next car.",
	"desgaste": "Copy. We're watching the wear.",
	"chuva": "Copy. Reviewing tyre suitability.",
	"ritmo": "Copy. Comparing the recent laps."
}

# Strictly recognise existing APEX 9.4 event templates. Unknown text is
# displayed unchanged, never guessed into a fabricated sporting fact.
static func classify_source(source: String) -> String:
	if source.contains("Temos a parada V") and source.contains("marcada"):
		return "revisar_plano"
	if source.contains("A aderência está piorando. Peço"):
		return "avaliar_box"
	if source.contains("Estou mais rápido que o companheiro"):
		return "troca_equipe"
	if source.contains("Não estou encontrando o ritmo"):
		return "perda_ritmo"
	if source.contains("Ainda sinto boa aderência"):
		return "estender_stint"
	if source.contains("A pista está escorregadia com estes pneus"):
		return "grip_molhado"
	if source.contains("A pista está secando. Os pneus de chuva"):
		return "chuva_secando"
	if source.contains("Está praticamente seco aqui"):
		return "inter_secando"
	if source.contains("Estou perdendo aderência. Podem"):
		return "aderencia"
	if source.contains("Os pneus estão aquecendo demais"):
		return "temperatura"
	if source.contains("Estou muito perto do carro da frente"):
		return "trafego"
	return ""

# Read only a lap actually contained in an event message. Historic replay
# events may be ingested after the car has already completed that stint.
static func booked_lap_from_source(source: String) -> int:
	var marker: String = "Temos a parada V"
	var at: int = source.find(marker)
	if at < 0:
		marker = "BOX V"
		at = source.find(marker)
	if at < 0:
		return 0
	var digits: String = ""
	for i in range(at + marker.length(), source.length()):
		var ch: String = source.substr(i, 1)
		if not ch.is_valid_int():
			break
		digits += ch
	return digits.to_int() if not digits.is_empty() else 0

static func profile(car: Dictionary) -> Dictionary:
	var id: int = int(car.get("id", 0))
	var soul: Dictionary = car.get("driver_soul", {})
	var temperament: String = str(soul.get("temperament", "EQUILIBRADO"))
	var offset: int = 2 if temperament == "ASSERTIVO" else (1 if temperament == "CAUTELOSO" else 0)
	var voice_index: int = posmod(id + offset, STYLE_NAMES.size())
	var pressure: float = clampf(float(soul.get("pressure", 0.0)), 0.0, 1.0)
	var confidence: float = clampf(float(soul.get("confidence", 0.55)), 0.0, 1.0)
	return {"style": STYLE_NAMES[voice_index], "index": voice_index,
		"emotion": "FRUSTRATED" if pressure > 0.65 else ("CONFIDENT" if confidence > 0.74 else "FOCUSED"),
		"intensity": 2 if pressure > 0.72 else (1 if pressure > 0.40 else 0)}

static func _packet(car: Dictionary, kind: String, context: Dictionary, role: String,
		message: String, variant: int) -> Dictionary:
	var p: Dictionary = profile(car)
	var id: int = int(car.get("id", -1))
	var lap: int = int(context.get("lap", car.get("laps_done", 0)))
	var event_id: int = int(context.get("event_id", -1))
	var conversation: String = str(context.get("conversation_id", "%d:%d:%s" % [id, lap, kind]))
	return {"version": VERSION, "speaker_id": id, "speaker_role": role,
		"intent": kind, "emotion": str(p["emotion"]),
		"intensity": int(p["intensity"]), "text_key": "radio3.%s.%s.%d" % [kind, role.to_lower(), variant],
		"locale": LOCALE, "text": message, "subtitle_pt": "",
		"voice_profile_id": "", "simulation_tick": int(context.get("simulation_tick", -1)),
		"event_id": event_id, "lap": lap, "sim_time": float(context.get("sim_time", -1.0)),
		"conversation_id": conversation,
		"priority": int(context.get("priority", 60)), "style": str(p["style"])}

static func driver(car: Dictionary, kind: String, context: Dictionary = {}, previous: Dictionary = {}) -> Dictionary:
	if car.is_empty() or not PILOT_LINES.has(kind):
		return {}
	var booked: int = int(context.get("booked_lap", car.get("pit_scheduled_lap", 0)))
	if kind == "revisar_plano" and booked <= 0:
		return {}  # Never mention a pit reservation that does not exist.
	var p: Dictionary = profile(car)
	var index: int = int(p["index"])
	var lines: Array = PILOT_LINES[kind]
	var words: String = str(lines[index])
	if kind == "revisar_plano":
		words = words % booked
	var repeated: bool = str(previous.get("last_pilot_kind", "")) == kind 			and int(context.get("lap", car.get("laps_done", 0))) > int(previous.get("last_pilot_lap", -1))
	if repeated and kind in ["desgaste", "trafego", "perda_ritmo", "avaliar_box"]:
		words = "Same issue. " + words
	return _packet(car, kind, context, "PILOTO", words, index)

static func engineer(car: Dictionary, kind: String, context: Dictionary = {}) -> Dictionary:
	if car.is_empty() or not ENGINEER_LINES.has(kind):
		return {}
	var words: String = str(ENGINEER_LINES[kind])
	var booked: int = int(context.get("booked_lap", car.get("pit_scheduled_lap", 0)))
	var lap: int = int(context.get("lap", car.get("laps_done", 0)))
	if kind in ["revisar_plano", "avaliar_box", "aderencia", "desgaste", "chuva", "grip_molhado", "perda_ritmo", "estender_stint"]:
		if booked > lap:
			words += " Lap %d remains booked; no change made." % booked
		elif booked > 0:
			words += " No new stop has been scheduled."
	return _packet(car, kind, context, "ENGENHEIRO", words, 0)

# Ring of presentation-only conversation context. Never serialize into cars,
# RaceStateCodec or gameplay hashes. Replay ingestion can rebuild it in order.
static func remember(previous: Dictionary, packet: Dictionary) -> Dictionary:
	var next: Dictionary = previous.duplicate(true)
	if packet.is_empty():
		return next
	var history: Array = next.get("history", []).duplicate(true)
	var event_id: int = int(packet.get("event_id", -1))
	var role: String = str(packet.get("speaker_role", ""))
	var kind: String = str(packet.get("intent", ""))
	if event_id >= 0:
		for entry in history:
			if int(entry.get("event_id", -2)) == event_id and str(entry.get("role", "")) == role:
				return next
	history.append({"event_id": event_id, "role": role, "kind": kind,
		"lap": int(packet.get("lap", 0)), "text_key": str(packet.get("text_key", "")),
		"conversation_id": str(packet.get("conversation_id", ""))})
	while history.size() > MAX_MEMORY:
		history.pop_front()
	next["history"] = history
	if role == "PILOTO":
		next["last_pilot_kind"] = kind
		next["last_pilot_lap"] = int(packet.get("lap", 0))
		next["last_pilot_time"] = float(packet.get("sim_time", -1.0))
	next["last_conversation_id"] = str(packet.get("conversation_id", ""))
	return next

# Clear, original radio responses to explicit *communication* choices only.
# Soul2.respond / SoulDriver.choose remain the authority for any Soul effects.
static func choice_response(car: Dictionary, choice: String) -> Dictionary:
	if choice not in ["ouvir", "explicar", "piloto", "engenheiro"]:
		return {}
	var kind: String = "acknowledge" if choice in ["ouvir", "piloto"] else "accept_data"
	var p: Dictionary = profile(car)
	var lines: Array = ["Copy.", "Alright. Keep me updated.", "Understood. I'll report back.",
		"Okay, I'll keep an eye on it.", "Copy. I'll focus on the next lap."]
	if kind == "acknowledge":
		lines = ["Thanks. I'll keep you posted.", "Good. Just keep me informed.",
			"Copy. I'll report any change.", "Okay. I'll let you know.",
			"Alright. I'll keep pushing."]
	return _packet(car, kind, {"lap": int(car.get("laps_done", 0))}, "PILOTO",
		str(lines[int(p["index"])]), int(p["index"]))

# Consultation lines are generated only after DriverMemory or StintDialogue
# has confirmed a current observation. These are not free-form prompts.
static func consultation(car: Dictionary, subject: String, context: Dictionary = {}) -> Dictionary:
	if car.is_empty() or subject not in ["perception", "stint"]:
		return {}
	var p: Dictionary = profile(car)
	var style: int = int(p["index"])
	var lines: Array = []
	if subject == "perception":
		var feeling: float = clampf(float((car.get("driver_soul", {}) as Dictionary).get(
			"perceived_wear", car.get("wear", 0.0))), 0.0, 100.0)
		if feeling >= 77.0:
			lines = ["Tyres are fading.", "I'm running out of grip!",
				"Grip loss is increasing.", "I'm struggling with the tyres.",
				"These tyres are costing us."]
		elif feeling >= 48.0:
			lines = ["Some wear, still manageable.", "Grip's dropping a bit!",
				"Tyre response is getting weaker.", "Not as much grip now.",
				"I can manage, but it's getting harder."]
		else:
			lines = ["Tyres feel okay.", "Grip's fine for now!",
				"Tyres are responding normally.", "Feels reasonably stable.",
				"Good grip. Let's keep it going."]
	elif bool(context.get("pit_active", false)):
		lines = ["Pit call received.", "Copy! Coming in!",
			"Pit procedure confirmed.", "Understood. Heading to the pits.",
			"Copy. I'm coming in."]
	elif bool(context.get("wants_extend", false)):
		lines = ["I think we can stay out.", "I can do another lap!",
			"Tyres still have some life. Consider extending.",
			"Feels possible to stay out a little longer.",
			"I can keep going. Let's check the window."]
	else:
		lines = ["We should check these tyres.", "This isn't working! Check the plan!",
			"Current tyre behaviour needs reviewing.",
			"Not comfortable on these tyres. Can we review?",
			"These tyres aren't helping. Need a plan."]
	return _packet(car, "consult_" + subject, context, "PILOTO", str(lines[style]), style)

# Low-priority repetition can be silent. Safety and active requests are never
# filtered here. SoulReactive already gates repeated raw events; this is a
# second presentation-only guard for chatter around the same completed lap.
static func should_transmit(packet: Dictionary, previous: Dictionary) -> bool:
	if packet.is_empty():
		return false
	if int(packet.get("priority", 60)) >= 90:
		return true
	var kind: String = str(packet.get("intent", ""))
	if kind not in ["desgaste", "tráfego", "ritmo", "disputa", "temperatura"]:
		return true
	return not (str(previous.get("last_pilot_kind", "")) == kind 		and int(packet.get("lap", 0)) - int(previous.get("last_pilot_lap", -100)) < 3)
