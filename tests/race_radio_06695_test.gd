extends SceneTree
## Race Radio 3.0: deterministic presentation, original dialogue, no hidden orders.
const Radio3 = preload("res://scripts/presentation/race_radio_06695.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")
const Race = preload("res://scripts/race_engine.gd")
var errors: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		printerr("RACE_RADIO_06695_FAIL: " + label)

func sample(id: int, pressure: float = 0.25) -> Dictionary:
	return {"id": id, "name": "Pilot %d" % id, "laps_done": 9,
		"wear": 61.0, "pit_scheduled_lap": 0, "pit_request": false,
		"pace": "Normal", "driver_soul": {"version": "3.0",
			"temperament": "EQUILIBRADO", "pressure": pressure,
			"confidence": 0.60, "focus": 0.83, "initiative": 0.55}}

func _run() -> void:
	var car: Dictionary = sample(10)
	var previous_bytes: PackedByteArray = var_to_bytes(car)
	var ctx: Dictionary = {"lap": 9, "event_id": 55, "simulation_tick": 620, "priority": 73}
	var first: Dictionary = Radio3.driver(car, "desgaste", ctx)
	var duplicate: Dictionary = Radio3.driver(car, "desgaste", ctx)
	check(first == duplicate, "Same facts produce the same voice and packet")
	check(str(first.get("locale", "")) == "en" and str(first.get("voice_profile_id", "")) == "", "Text first, future voice slot")
	check(int(first.get("simulation_tick", -1)) == 620 and int(first.get("event_id", -1)) == 55, "Stable event and tick metadata")
	check(str(first.get("speaker_role", "")) == "PILOTO" and str(first.get("intent", "")) == "desgaste", "Typed intent and speaker")
	check(var_to_bytes(car) == previous_bytes, "Formatter never mutates a sporting car")
	check(Radio3.driver(car, "unverified_engine_damage", ctx).is_empty(), "No invented unsupported intent")
	check(Radio3.classify_source("Completely unrelated event") == "", "Unknown legacy message is preserved")
	check(Radio3.classify_source("RÁDIO FICTÍCIO | Pilot: Temos a parada V21 marcada. As condições mudaram; podemos conversar sobre o plano?") == "revisar_plano",
		"Legacy Soul3 request recognised without changing sporting event")
	check(Radio3.classify_source("RÁDIO FICTÍCIO | Pilot: Os pneus estão aquecendo demais nas curvas.") == "temperatura",
		"Legacy telemetry feedback recognised")
	var variants: Dictionary = {}
	for id in range(5):
		var voice: Dictionary = Radio3.driver(sample(id), "desgaste", ctx)
		variants[str(voice.get("text", ""))] = true
	check(variants.size() == 5, "Five distinguishable consistent personalities")
	check(str(Radio3.profile(sample(3, 0.90)).get("emotion", "")) == "FRUSTRATED",
		"Soul3 pressure changes emotional description")
	for kind in Radio3.PILOT_LINES.keys():
		var fixture: Dictionary = sample(5)
		fixture["pit_scheduled_lap"] = 21
		var packet: Dictionary = Radio3.driver(fixture, str(kind), ctx)
		check(not packet.is_empty() and str(packet.get("text", "")).length() < 125,
			"Concise original line for %s" % str(kind))
		check(not str(packet.get("text", "")).contains("Talvez seja interessante") and not str(packet.get("text", "")).contains("Podemos conversar"),
			"No verbose chatbot language for %s" % str(kind))
	var booked: Dictionary = sample(3)
	booked["pit_scheduled_lap"] = 21
	var planned: Dictionary = Radio3.driver(booked, "revisar_plano", ctx)
	check(str(planned.get("text", "")).contains("21"), "Scheduled lap is factual in driver line")
	check(Radio3.driver(car, "revisar_plano", ctx).is_empty(), "Cannot invent a scheduled stop")
	var answer: Dictionary = Radio3.engineer(booked, "revisar_plano", ctx)
	check(str(answer.get("text", "")).contains("21") and str(answer.get("text", "")).contains("no change"),
		"Engineer clarifies that V21 has not changed")
	check(int(booked["pit_scheduled_lap"]) == 21 and not bool(booked["pit_request"]),
		"Radio cannot execute or reschedule V21")
	var response: Dictionary = Radio3.choice_response(booked, "explicar")
	check(not response.is_empty() and str(response.get("speaker_role", "")) == "PILOTO",
		"Explicit response reuses individual pilot voice")
	check(Radio3.choice_response(booked, "pit_now").is_empty(), "Radio cannot introduce hidden pit orders")
	var memory: Dictionary = {}
	for idx in range(15):
		var item: Dictionary = Radio3.driver(booked, "desgaste", {"event_id": idx, "lap": 9 + idx}, memory)
		memory = Radio3.remember(memory, item)
	check((memory.get("history", []) as Array).size() == Radio3.MAX_MEMORY, "Conversation memory bounded to eight")
	var once: Dictionary = Radio3.remember(memory, item_for_duplicate(booked))
	check((once.get("history", []) as Array).size() <= Radio3.MAX_MEMORY, "Replay ingestion cannot grow history")
	var repeated: Dictionary = Radio3.driver(booked, "desgaste", {"event_id": 93, "lap": 30}, memory)
	check(str(repeated.get("text", "")).begins_with("Same issue."), "Later complaints acknowledge earlier discussion")
	# Real engine emits 9.4 source events; Radio3 acts ONLY in Commentary.
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = Race.new(season.teams, "Ferrari", 6695, {}, season.tracks[0], {})
	var driver: Dictionary = race.player_cars()[0]
	driver["pit_scheduled_lap"] = 21
	var car_id: int = int(driver["id"])
	race._event("driver_radio", car_id,
		"RÁDIO FICTÍCIO | %s: Temos a parada V21 marcada. As condições mudaram; podemos conversar sobre o plano?" % str(driver["name"]), 75)
	var sporting_before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
	var commentary = Commentary.new()
	commentary.reset(6695)
	check(commentary.ingest(race, "Ferrari"), "Actual engine event ingested through presentation")
	var team_text: String = commentary.formatted(2, car_id)
	check(team_text.contains("lap 21") or team_text.contains("Lap 21"),
		"Real radio shows natural concise voice with factual V21")
	check(team_text.contains("ENGENHEIRO") and team_text.contains("no change made"),
		"Contextual reply registered without issuing commands")
	check(not commentary.formatted(1).contains("lap 21"), "Team radio is not leaked into TV")
	check(var_to_bytes(race.get_state_snapshot()) == sporting_before,
		"Commentary, dialogue memory and engineer response do not alter race snapshot")
	check(str((commentary.lines[-1] as Dictionary).get("radio3", {}).get("voice_profile_id", "missing")) == "",
		"Structured packet stored for later voice support")
	if errors.is_empty():
		print("RACE_RADIO_06695_PASS ", {"checks": checks, "sporting_unchanged": true,
			"original_text": true, "bounded_memory": true, "voice_ready": true})
		quit(0)
	else:
		quit(1)

func item_for_duplicate(car: Dictionary) -> Dictionary:
	return Radio3.driver(car, "desgaste", {"event_id": 14, "lap": 23})
