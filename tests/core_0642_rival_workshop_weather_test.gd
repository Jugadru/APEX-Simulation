extends SceneTree
## Real Godot assertions for v0.6.4.2; uses isolated XDG_DATA_HOME in CI.
const Rivals = preload("res://scripts/core/rival_development_0642.gd")
const Championship = preload("res://scripts/championship_2012.gd")
const Garage = preload("res://scripts/garage.gd")
const RainGate = preload("res://scripts/core/race_rain_hysteresis_0642.gd")
const PaceModel = preload("res://scripts/core/race_performance.gd")
const Race = preload("res://scripts/race_engine.gd")
const PATH := "user://apex_test_0642_season.json"
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func expect(ok: bool, context: String) -> void:
	if not ok:
		failures.append(context)
		printerr("APEX 0642 ERROR: ", context)
func make_grid(teams: Array) -> Array:
	var grid: Array = []
	for team in teams:
		for driver in team["drivers"]:
			grid.append({"name": driver["name"], "team": team["name"], "best_lap": 90.0, "stops": 2})
	return grid
func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var career = Championship.new(PATH)
	expect(career.start_new("Ferrari", 321, fixture["tracks"], fixture["teams"]), "season saved")
	var initial: Dictionary = career.get_rival_development()
	expect(initial.size() == 11, "11 rival teams initialized")
	expect(not initial.has("Ferrari"), "player not included as rival")
	var garage = Garage.new()
	var balance_before: int = int(garage.get_team("Ferrari")["budget"])
	var normal_price: int = garage.next_cost("Ferrari", "Asa")
	var discounted: int = garage.research_next_cost("Ferrari", "Asa")
	expect(discounted == int(round(float(normal_price) * 0.85)), "P&D discount is 15 percent")
	var serial: int = int(career.state["serial"])
	var contract: String = garage.start_research("Ferrari", "Asa", serial, 0, 20)
	expect(contract.contains("iniciado"), "project started")
	expect(int(garage.get_team("Ferrari")["budget"]) == balance_before - discounted, "reserved cost debited")
	expect(garage.next_cost("Ferrari", "Asa") < 0, "instant buy cannot bypass queued upgrade")
	expect(not garage.deliver_research("Ferrari", serial, 1), "project not delivered at GP1")
	var ordering: Array = make_grid(fixture["teams"])
	var start_round: Dictionary = career.record_result(fixture["tracks"][0], ordering, 6000.0)
	expect(bool(start_round.get("ok", false)), "GP1 recorded")
	expect(not bool(career.record_result(fixture["tracks"][0], ordering, 6000.0).get("ok", false)), "duplicate GP blocked")
	var rivals_gp1: Dictionary = career.get_rival_development()
	var invested: int = 0
	for name in rivals_gp1.keys():
		var team: Dictionary = rivals_gp1[name]
		invested += int(team.get("invested", 0))
		expect(int(team["budget"]) >= 0, "no negative rival money " + str(name))
	expect(invested > 0, "rival upgrade purchased after GP1")
	var restored = Championship.new(PATH)
	expect(int(restored.state["round_index"]) == 1, "season recovered after first round")
	var restored_accounts: Dictionary = restored.get_rival_development()
	for name in rivals_gp1.keys():
		var previous: Dictionary = rivals_gp1[name]
		var loaded: Dictionary = restored_accounts.get(name, {})
		expect(int(loaded.get("budget", -1)) == int(previous.get("budget", -2)), "budget persists: " + str(name))
		for part in Rivals.PARTS:
			expect(int(loaded.get("levels", {}).get(part, -1)) == int(previous.get("levels", {}).get(part, -2)), "rival part persists: " + str(name) + "/" + part)
	expect(bool(restored.record_result(fixture["tracks"][1], ordering, 6000.0).get("ok", false)), "GP2 recorded")
	expect(not garage.deliver_research("Ferrari", serial + 1, 2), "cannot deliver wrong-season project")
	expect(garage.deliver_research("Ferrari", serial, 2), "correct project delivers after second completed GP")
	expect(int(garage.get_team("Ferrari")["levels"]["Asa"]) == 1, "garage upgrade becomes available")
	expect(not garage.deliver_research("Ferrari", serial, 2), "cannot double-deliver")
	expect(garage.get_team("Ferrari")["development_project"].is_empty(), "completed project clears queue")
	expect(garage.start_research("Ferrari", "Motor", serial, 2, 20).contains("iniciado"), "second P&D project started")
	var second_cost: int = int(garage.get_team("Ferrari")["development_project"]["cost"])
	var balance_after_second: int = int(garage.get_team("Ferrari")["budget"])
	expect(garage.cancel_research("Ferrari").to_lower().contains("reembolso"), "P&D cancellation works")
	expect(int(garage.get_team("Ferrari")["budget"]) == balance_after_second + int(round(float(second_cost) * 0.75)), "75 percent cancel refund exact")
	var latest: Dictionary = restored.get_rival_levels()
	var rv_name: String = "Red Bull Racing Renault"
	expect(latest.has(rv_name), "Red Bull upgrades exposed for real race")
	var rival_car: Dictionary = {}
	var race = Race.new(fixture["teams"], "Ferrari", 42, {}, fixture["tracks"][0], {})
	for car in race.cars:
		if str(car["team"]) == rv_name:
			rival_car = car
			break
	expect(not rival_car.is_empty(), "Red Bull car found")
	if not rival_car.is_empty():
		var weather: Dictionary = race.weather_snapshot()
		var ctx: Dictionary = {"gap": 999.0, "lap": 1, "race_laps": 58, "base_lap": race.base_lap,
			"upgrades": {}, "player_car": false, "track": race.track,
			"tyre_specs": race.tyre_specs, "tyre_track_severity": race.tyre_severity(),
			"rival_development_bonus": 0.0, "rival_upgrades": {}, "weather": weather}
		var baseline: float = float(PaceModel.evaluate(rival_car, ctx)["target"])
		ctx["rival_upgrades"] = {rv_name: {"Motor":3, "Asa":2, "Chassi":1}}
		var developed: float = float(PaceModel.evaluate(rival_car, ctx)["target"])
		expect(developed < baseline - 0.50, "rival car development affects simulated lap time")
		race.set_rival_development(latest)
		expect(race.rival_upgrades == latest, "race engine receives exact rival levels")
	var dry_to_inter: Dictionary = RainGate.validate("Médio", "Intermediário", 40.0, false, 0.21, 0.12, 0.25)
	expect(not bool(dry_to_inter["allowed"]), "do not pit for passing light drizzle")
	var storm: Dictionary = RainGate.validate("Médio", "Intermediário", 40.0, false, 0.22, 0.72, 0.70)
	expect(bool(storm["allowed"]), "incoming strong rain allowed")
	expect(bool(RainGate.validate("Médio", "Intermediário", 95.0, true, 0.08, 0.0, 0.08)["allowed"]), "critical wear always allowed")
	expect(not bool(RainGate.validate("Chuva", "Intermediário", 20.0, false, 0.86, 0.0, 0.75)["allowed"]), "no unsafe full-wet crossover")
	expect(not bool(RainGate.validate("Intermediário", "Médio", 25.0, false, 0.19, 0.0, 0.08)["allowed"]), "no premature return to slick")
	# Real workshop GUI creates research buttons and displays 11 rivals.
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._new_championship()
	game._open_garage()
	await process_frame
	expect(game.garage_project_buttons.size() == 3, "real workshop P&D buttons wired")
	expect(game.garage_development_summary != null, "workshop performance estimate visible")
	expect(game.garage_rivals_summary.text.contains("Red Bull"), "rival upgrade tracker visible")
	game._start_garage_research("Asa")
	expect(not game.garage.get_team("Ferrari")["development_project"].is_empty(), "workshop button really starts R&D")
	game._cancel_garage_research()
	expect(game.garage.get_team("Ferrari")["development_project"].is_empty(), "workshop cancel really refunds")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	if failures.is_empty():
		print("APEX 0642 PASS: rival investment, speed, save/load, no duplicates, P&D budgets, delivery, cancel, UI, weather safety")
		quit(0)
	else:
		print("APEX 0642 FAIL: ", failures)
		quit(1)
