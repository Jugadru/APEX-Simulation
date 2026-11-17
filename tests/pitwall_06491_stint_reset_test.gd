extends SceneTree
## Regressão 0.6.4.9.1: no more than one auto-hold per stint;
## reset strictly after completed tyre service (never on pit request/entry).
const Race = preload("res://scripts/race_engine.gd")
const Planner = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func verify(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		printerr("PITWALL_06491_FAIL ", label)

func proposal(car: Dictionary, teammate: Dictionary) -> Dictionary:
	# Repeated independent simulations of a safe strategy case.
	var next_entry: int = int(car.get("laps_done", 0)) + 1
	var advice: Dictionary = {"pit_now":true, "compound":"Médio", "life_laps":6.0,
		"forecast_3":0.02, "forecast_6":0.02, "planned_pit_lap":next_entry, "critical":false}
	var analysis: Dictionary = Planner.assess(car, teammate, [car, teammate], advice,
		{"wetness_factor":0.02}, ["Macio", "Médio"], 52, 20.0, 95.0, next_entry)
	return Planner.auto_coordinate(car, teammate, analysis, advice)

func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var gbr: Dictionary = {}
	for track in season["tracks"]:
		if str(track.get("code", "")) == "GBR":
			gbr = track
			break
	verify(not gbr.is_empty() and int(gbr.get("laps", -1)) == 52, "Silverstone 52 laps")
	if gbr.is_empty():
		quit(2)
		return
	var race = Race.new(season["teams"], "Ferrari", 6403, {}, gbr, {})
	var team: Array = race.player_cars()
	verify(team.size() == 2 and race.cars.size() == 24, "24-car Silverstone simulation")
	if team.size() != 2:
		quit(2)
		return
	var car: Dictionary = team[0]
	var mate: Dictionary = team[1]
	car["progress"] = 5.0
	car["laps_done"] = 5
	car["stint_laps"] = 5
	car["wear"] = 35.0
	car["tire"] = "Macio"
	car["last_lap"] = 95.0
	mate["progress"] = 4.90
	mate["laps_done"] = 4
	mate["pit_request"] = true
	mate["pit_scheduled_lap"] = 0
	verify(bool(proposal(car,mate).get("pitwall49_hold", false)), "initial auto deferral allowed")
	car["pitwall49_held"] = true # Real _request_ai_pit sets this after deferral.
	verify(not bool(proposal(car,mate).get("pitwall49_hold", false)), "repeat blocked in same stint")
	verify(bool(proposal(car,mate).get("pit_now", false)), "repeat cannot force further delay")

	# A simple order or entering pit lane must NOT rearm the hold. Only service may.
	car["pit_target"] = "Médio"
	car["progress"] = 5.95
	race._begin_pit(car, 5.95)
	verify(bool(car.get("pitwall49_held", false)), "pit entry does not rearm prematurely")
	verify(not bool(car.get("pit_service_complete", false)), "service not yet completed")
	mate["pit_request"] = false # Release garage to allow actual service.
	for i in range(450):
		if float(car.get("pit_left", 0.0)) <= 0.0:
			break
		race.clock += 0.20
		race._advance_pit(car, 0.20)
	verify(bool(car.get("pit_service_complete", false)), "actual tyre service completed")
	verify(float(car.get("pit_left", 1.0)) <= 0.0, "car completes pit exit")
	verify(not bool(car.get("pitwall49_held", true)), "hold cleared after tyre service")
	verify(str(car.get("tire", "")) == "Médio", "tyres actually replaced")
	verify(int(car.get("stops", 0)) == 1, "one actual stop")

	# Separate next stint. Safe conditions now permit exactly one new deferral.
	car["progress"] = 12.0
	car["laps_done"] = 12
	car["stint_laps"] = 5
	car["wear"] = 35.0
	car["last_lap"] = 95.0
	mate["progress"] = 11.90
	mate["pit_request"] = true
	verify(bool(proposal(car,mate).get("pitwall49_hold", false)), "new stint permits a fresh hold")
	car["pitwall49_held"] = true
	verify(not bool(proposal(car,mate).get("pitwall49_hold", false)), "new stint allows only one deferral")

	# Explicit future bookings remain protected through the rain/urgency safeguards.
	mate["pit_request"] = false
	var car_id: int = int(car["id"])
	car["pit_scheduled_lap"] = 0
	car["pit_request"] = false
	verify(race.schedule_pit(car_id, "Macio", 21), "player can schedule V21")
	var snapshot: int = int(car["pit_scheduled_lap"])
	var advice: Dictionary = {"pit_now":true, "compound":"Chuva", "life_laps":1.0,
		"forecast_3":0.75,"forecast_6":0.9,"planned_pit_lap":13,"critical":true}
	var rain: Dictionary = Planner.assess(car,mate,[car,mate],advice,
		{"wetness_factor":0.83}, ["Macio", "Médio", "Chuva"], 52, 20.0, 95.0, 13)
	verify(not bool(rain.get("auto_hold_safe", true)), "wet critical conditions never defer")
	verify(int(car["pit_scheduled_lap"]) == snapshot and not bool(car["pit_request"]), "V21 remains intact")
	if failures.is_empty():
		print("PITWALL_06491_PASS Silverstone, one hold per stint, real tyre service reset, V21")
	quit(0 if failures.is_empty() else 1)
