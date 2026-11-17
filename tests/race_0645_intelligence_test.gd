extends SceneTree
const Intel = preload("res://scripts/core/race_intelligence_0645.gd")
const Soul = preload("res://scripts/core/race_driver_soul_0645.gd")
const Engineer = preload("res://scripts/core/race_engineer_0645.gd")
const Race = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var car: Dictionary = {"id": 1, "progress": 10.0, "laps_done": 10, "position": 2, "interval": 1.0, "wear": 50.0}
	var other: Dictionary = {"id": 2, "progress": 9.79}
	var base: Dictionary = {"pit_now": true, "planned_pit_lap": 11, "life_laps": 4.0, "forecast_3": 0.0, "forecast_6": 0.0}
	var before: String = JSON.stringify([car, base])
	var result: Dictionary = Intel.refine(car, [car, other], base, {}, 20.0, 90.0, 50)
	check(JSON.stringify([car, base]) == before, "assessment must be pure")
	check(bool(result.get("traffic_deferred", false)) and not result["pit_now"], "safe traffic deferral")
	check(result["planned_pit_lap"] == 12, "one lap delay")
	car["ai_plan"] = result
	result = Intel.refine(car, [car, other], base, {}, 20.0, 90.0, 50)
	check(result["pit_now"], "no consecutive traffic deferral")
	car.erase("ai_plan")
	for field in ["critical", "wet", "manual", "late", "wear"]:
		var c: Dictionary = car.duplicate(true)
		var b: Dictionary = base.duplicate(true)
		var w: Dictionary = {}
		if field == "critical": b["critical"] = true
		if field == "wet": w["wetness_factor"] = 0.4
		if field == "manual": c["pit_scheduled_lap"] = 21
		if field == "late": c["laps_done"] = 48
		if field == "wear": c["wear"] = 85.0
		var guarded: Dictionary = Intel.refine(c, [c, other], b, w, 20.0, 90.0, 50)
		check(guarded["pit_now"] and not guarded.get("traffic_deferred", false), "guard " + field)
	var clear: Dictionary = Intel.refine(car, [car], base, {}, 20.0, 90.0, 50)
	check(clear["tactic"] == "UNDERCUT NA JANELA", "undercut only on viable plan")
	car["driver_soul"] = Soul.initial(car)
	car["laps_done"] = 11
	Soul.update(car, {"wetness_factor": 0.8})
	var once: String = JSON.stringify(car)
	Soul.update(car, {"wetness_factor": 0.8})
	check(JSON.stringify(car) == once, "soul once per lap")
	for lap in range(12, 200):
		car["laps_done"] = lap
		Soul.update(car, {"wetness_factor": 1.0})
	check(car["driver_soul"]["history"].size() <= 8, "bounded soul memory")
	check(car["driver_soul"]["pressure"] <= 1.0, "bounded emotion")
	check(car["wear"] == 50.0 and car["progress"] == 10.0, "emotion never changes physics")
	car["finished"] = true
	var report: Dictionary = Engineer.enrich(car, {"can_call_pit": true}, clear)
	check(not report["can_call_pit"], "stale advice cannot pit a finished car")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var sim = Race.new(season["teams"], "Ferrari", 645, {}, season["tracks"][0], {})
	sim.running = true
	var player: Dictionary = sim.player_cars()[0]
	var id: int = int(player["id"])
	check(sim.schedule_pit(id, sim.available_pit_compounds()[1], 21), "schedule manual V21")
	var rng_state: int = sim.rng.state
	var advice: Dictionary = sim.get_engineer_advice(id)
	check(advice.get("intelligence_version", "") == "2.0", "engine uses strategic IA 2.0")
	check(sim.rng.state == rng_state, "assessment does not consume race RNG")
	for n in range(40): sim.step(4.0)
	check(int(player["pit_scheduled_lap"]) == 21 and not player["pit_request"], "manual reservation survives native ticks")
	check(player["driver_soul"]["last_lap"] > 0, "soul active without HUD")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	hud._update_engineer_reports()
	hud._open_window("engineer")
	await process_frame
	check(hud.overlay_title.text.contains("UI03"), "HUD UI03 visible")
	check(hud.engineer_cards.size() == 2, "two driver cards")
	for ui in hud.engineer_cards:
		check(ui["text"].text.contains("SOUL"), "soul shown in actual HUD")
		check(ui["tradeoff"].text.contains("Parar:"), "alternatives shown in actual HUD")
	game.queue_free()
	await process_frame
	if failures.is_empty(): print("APEX_0645_PASS strategy, guards, soul, RNG, native ticks, manual V21, HUD UI03")
	quit(0 if failures.is_empty() else 1)
