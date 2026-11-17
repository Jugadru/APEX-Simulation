extends SceneTree
const RaceScript = preload("res://scripts/race_engine.gd")
const Soul = preload("res://scripts/core/race_soul_driver_0636.gd")
const Reactive = preload("res://scripts/core/race_soul_reactive_0637.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> bool:
	if not condition:
		printerr("FAIL 0637: " + message)
	return condition

func _run() -> void:
	var good: bool = true
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for item in season["tracks"]:
		if str(item.get("code", "")) == "BEL":
			track = item
			break
	var race = RaceScript.new(season["teams"], "Red Bull Racing Renault", 637, {}, track, {})
	var pilot: int = int(race.player_cars()[0]["id"])
	good = check(race.schedule_pit(pilot, "Médio", 21), "Pit V21 scheduled") and good
	var baseline: String = JSON.stringify(race.get_state_snapshot())
	var snapshot: Dictionary = race.get_state_snapshot()
	var profile: Dictionary = Soul.initial_profile(pilot)
	var memory: Dictionary = Reactive.initial_memory()
	# No manufactured message from a static grid.
	var empty: Dictionary = Reactive.observe(pilot, snapshot, profile, memory)
	good = check(not bool(empty.get("emitted", true)), "No grid spam") and good
	# Genuine incident event triggers private radio but no simulation mutation.
	var accident: Array = [{"event_id": 2, "type": "incident", "driver_id": pilot, "time": 30.0}]
	var active: Dictionary = snapshot.duplicate(true)
	active["time"] = 30.0
	var incident: Dictionary = Reactive.observe(pilot, active, profile, memory, accident)
	good = check(bool(incident.get("emitted", false)) and str(incident.get("kind", "")) == "incidente", "Incident generates radio") and good
	var muted: Dictionary = Reactive.observe(pilot, active, profile, incident["memory"], accident)
	good = check(not bool(muted.get("emitted", true)), "No repeated incident in cooldown") and good
	var second: Dictionary = active.duplicate(true)
	second["time"] = 56.0
	var high: Dictionary = Reactive.observe(pilot, second, profile, incident["memory"], [{"event_id": 3, "type": "pit_failure", "driver_id": pilot}])
	good = check(bool(high.get("emitted", false)) and str(high.get("kind", "")) == "box", "Urgent pit error passes short cooldown") and good
	# Thresholds come from telemetry; a duplicate crossing is not repeated.
	var tyres: Dictionary = snapshot.duplicate(true)
	tyres["time"] = 150.0
	for car in tyres["cars"]:
		if int(car.get("id", -1)) == pilot:
			car["laps_done"] = 4
			car["wear"] = 77.0
	var wear: Dictionary = Reactive.observe(pilot, tyres, profile, Reactive.initial_memory())
	good = check(bool(wear.get("emitted", false)) and str(wear.get("kind", "")) == "desgaste", "Tyre threshold generated") and good
	var later: Dictionary = tyres.duplicate(true)
	later["time"] = 260.0
	var repeated_wear: Dictionary = Reactive.observe(pilot, later, profile, wear["memory"])
	good = check(not bool(repeated_wear.get("emitted", true)), "Tyre threshold not farmed") and good
	# Wetter track on dry tyre results in advice only.
	var wet: Dictionary = snapshot.duplicate(true)
	wet["time"] = 200.0
	wet["weather"] = {"wetness_factor": 0.67}
	for car in wet["cars"]:
		if int(car.get("id", -1)) == pilot:
			car["laps_done"] = 4
			car["tire"] = "Médio"
	var warning: Dictionary = Reactive.observe(pilot, wet, profile, Reactive.initial_memory())
	good = check(bool(warning.get("emitted", false)) and str(warning.get("kind", "")) == "chuva", "Wet track dry tyre warning") and good
	# Overtakes don't create fabricated race order, they only report engine events.
	var overtake: Dictionary = snapshot.duplicate(true)
	overtake["time"] = 300.0
	for car in overtake["cars"]:
		if int(car.get("id", -1)) == pilot:
			car["laps_done"] = 3
	var reaction: Dictionary = Reactive.observe(pilot, overtake, profile, Reactive.initial_memory(), [{"type": "pass", "driver_id": pilot, "event_id": 9}])
	good = check(bool(reaction.get("emitted", false)) and str(reaction.get("kind", "")) == "disputa", "Overtake event sourced") and good
	# Traffic feedback requires two completed laps with a measured small interval.
	var near: Dictionary = snapshot.duplicate(true)
	near["time"] = 125.0
	var traffic_car: Dictionary = {}
	for car in near["cars"]:
		if int(car.get("id", -1)) == pilot:
			car["laps_done"] = 3
			car["position"] = 3
			car["interval"] = 0.78
			traffic_car = car
	var near_a: Dictionary = Reactive.observe(pilot, near, profile, Reactive.initial_memory())
	good = check(not bool(near_a.get("emitted", false)), "No traffic alert on a single sample") and good
	near["time"] = 235.0
	traffic_car["laps_done"] = 4
	var near_b: Dictionary = Reactive.observe(pilot, near, profile, near_a["memory"])
	good = check(bool(near_b.get("emitted", false)) and str(near_b.get("kind", "")) == "tráfego", "Traffic alert after sustained measured proximity") and good
	# Pace feedback compares recorded completed laps, never a speculative cause.
	var slow: Dictionary = snapshot.duplicate(true)
	slow["time"] = 180.0
	var slow_car: Dictionary = {}
	for car in slow["cars"]:
		if int(car.get("id", -1)) == pilot:
			car["laps_done"] = 4
			car["position"] = 1
			car["best_lap"] = 107.5
			car["last_lap"] = 110.9
			slow_car = car
	var slow_a: Dictionary = Reactive.observe(pilot, slow, profile, Reactive.initial_memory())
	good = check(not bool(slow_a.get("emitted", false)), "Slow lap must be sustained") and good
	slow["time"] = 290.0
	slow_car["laps_done"] = 5
	var slow_b: Dictionary = Reactive.observe(pilot, slow, profile, slow_a["memory"])
	good = check(bool(slow_b.get("emitted", false)) and str(slow_b.get("kind", "")) == "ritmo", "Two slow laps generate pace consultation") and good
	# Cooling tire state after replacement resets a warning threshold for a new stint.
	var new_tire: Dictionary = later.duplicate(true)
	new_tire["time"] = 320.0
	for car in new_tire["cars"]:
		if int(car.get("id", -1)) == pilot:
			car["wear"] = 8.0
	var new_stint: Dictionary = Reactive.observe(pilot, new_tire, profile, repeated_wear["memory"])
	good = check(int(new_stint["memory"].get("wear_stage", -1)) == 0, "Tyre threshold resets on new set") and good
	# Commentary private: no reporter fabricating radio of rivals.
	var cast = Commentary.new()
	cast.reset(637)
	cast.add_soul_spontaneous(150.0, "Piloto de teste", str(wear["message"]), str(wear["engineer"]), pilot)
	good = check(cast.formatted(2, pilot).contains("RÁDIO FICTÍCIO"), "Team filter contains own spontaneous radio") and good
	good = check(cast.formatted(3, pilot).contains("RÁDIO FICTÍCIO") and not cast.formatted(3, pilot).contains("ENGENHEIRO"), "Pilot filter excludes engineer") and good
	good = check(not cast.formatted(1).contains("RÁDIO FICTÍCIO"), "TV never leaks private radio") and good
	good = check(JSON.stringify(race.get_state_snapshot()) == baseline, "Engine snapshot identical after Soul reactions") and good
	# Native HUD smoke and reset: proactivity stays separate from pit controller.
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	good = check(hud != null and hud.visible, "HUD present") and good
	if hud != null:
		var baseline_game: String = JSON.stringify(game.race.get_state_snapshot())
		hud._open_window("radio")
		good = check(hud.radio_reactive_label != null and hud.radio_reactive_label.text.contains("RÁDIO ESPONTÂNEO"), "Radio widget present") and good
		hud._update_reactive_radio()
		good = check(JSON.stringify(game.race.get_state_snapshot()) == baseline_game, "HUD radio tick read-only") and good
		hud.begin_race()
		good = check(hud.radio_reactive_memories.is_empty() and hud.radio_reactive_event_id == 0, "Per-GP reset") and good
	if good:
		print("APEX 0637 PASS: event, incident, wear, rain, duel, cooldown, privacy, reset, immutable race, HUD")
	quit(0 if good else 1)
