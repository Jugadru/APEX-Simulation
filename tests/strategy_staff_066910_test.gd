extends SceneTree
## APEX v0.6.6.9.10 — bounded strategist decisions and replay compatibility.
const Staff = preload("res://scripts/core/race_strategy_staff_intelligence_066910.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("STRATEGY_STAFF_066910_FAIL " + label)

func _run() -> void:
	var team: Dictionary = {"staff_levels":{"Estrategista":2},
		"staff_roster":{"Estrategista":{"id":"est_c","name":"Elisa Nogueira",
			"skill":90,"energy":80,"trust":80,"morale":75,
			"specialty":"Estratégia em clima variável"}},
		"staff_soul":{"relations":{"Engenheiro|Estrategista":70}}}
	var team_bytes: PackedByteArray = var_to_bytes(team)
	var staff: Dictionary = Staff.profile(team)
	check(bool(staff["active"]) and int(staff["skill"]) == 90
		and str(staff["name"]) == "Elisa Nogueira"
		and int(staff["engineer_bond"]) == 70,
		"strategist profile uses real contract, Soul Staff and training")
	check(var_to_bytes(team) == team_bytes, "profile must not mutate garage state")
	var car: Dictionary = {"id":1,"name":"Piloto A","team":"Ferrari",
		"laps_done":12,"progress":12.4,"stint_laps":7,"stops":0,"position":5,
		"tire":"Médio","wear":35.0,"last_lap":102.0,"pit_scheduled_lap":0,
		"pit_request":false,"pit_left":0.0,"finished":false}
	var other: Dictionary = {"id":2,"name":"Rival","team":"McLaren",
		"progress":12.21,"last_lap":100.0,"finished":false}
	var weather: Dictionary = {"wetness_factor":0.0}
	var advice: Dictionary = {"pit_now":true,"compound":"Duro","life_laps":4.5,
		"forecast_3":0.0,"forecast_6":0.0,"critical":false}
	var car_bytes: PackedByteArray = var_to_bytes(car)
	var grid: Array = [car, other]
	var result: Dictionary = Staff.assess(car, {}, grid, advice, weather, staff,
		["Médio","Duro"], 20.0, 100.0, 53, 13)
	check(bool(result["proposed_hold_one_lap"]) and bool(result["now_traffic"])
		and bool(result["later_clear_air"]),
		"experienced rested strategist identifies actual +1V clear-air alternative")
	check(result == Staff.assess(car, {}, grid, advice, weather, staff,
		["Médio","Duro"], 20.0, 100.0, 53, 13),
		"identical observations always produce identical staff assessment")
	check(var_to_bytes(car) == car_bytes and bool(advice["pit_now"]),
		"advisory module never mutates car or plan")
	var beginner: Dictionary = staff.duplicate(true)
	beginner["skill"] = 60
	check(not bool(Staff.assess(car, {}, grid, advice, weather, beginner,
		["Médio","Duro"], 20.0, 100.0, 53, 13)["proposed_hold_one_lap"]),
		"low-competence staff does not force optional tactical adjustment")
	var tired: Dictionary = staff.duplicate(true)
	tired["energy"] = 20
	check(not bool(Staff.assess(car, {}, grid, advice, weather, tired,
		["Médio","Duro"], 20.0, 100.0, 53, 13)["proposed_hold_one_lap"]),
		"fatigued strategist cannot trigger optional hold")
	var booked: Dictionary = car.duplicate(true)
	booked["pit_scheduled_lap"] = 21
	var protected: Dictionary = Staff.assess(booked, {}, [booked, other],
		advice, weather, staff, ["Médio","Duro"], 20.0, 100.0, 53, 13)
	check(not bool(protected["proposed_hold_one_lap"])
		and str(protected["recommendation"]) == "ORDEM MANUAL PROTEGIDA",
		"manual box V21 remains immutable")
	var wet: Dictionary = {"wetness_factor":0.55}
	check(not bool(Staff.assess(car, {}, grid, advice, wet, staff,
		["Médio","Duro"], 20.0, 100.0, 53, 13)["proposed_hold_one_lap"]),
		"unsafe wet slicks are never deferred")
	var critical: Dictionary = advice.duplicate(true)
	critical["critical"] = true
	check(not bool(Staff.assess(car, {}, grid, critical, weather, staff,
		["Médio","Duro"], 20.0, 100.0, 53, 13)["proposed_hold_one_lap"]),
		"critical pit may not be delayed")
	var claimed: Dictionary = car.duplicate(true)
	claimed["staff_strategy_hold_stint_066910"] = 0
	check(not bool(Staff.assess(claimed, {}, [claimed, other], advice, weather,
		staff, ["Médio","Duro"], 20.0, 100.0, 53, 13)["proposed_hold_one_lap"]),
		"one automatic hold maximum per stint")
	var teammate: Dictionary = {"id":3,"team":"Ferrari","pit_request":true}
	check(not bool(Staff.assess(car, teammate, grid, advice, weather, staff,
		["Médio","Duro"], 20.0, 100.0, 53, 13)["proposed_hold_one_lap"]),
		"shared garage conflict blocks optional staff delay")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = season["tracks"][0]
	var one = Race.new(season["teams"], "Ferrari", 6610, {}, track, {})
	var two = Race.new(season["teams"], "Ferrari", 6610, {}, track, {})
	one.strategy_staff_profile = staff.duplicate(true)
	two.strategy_staff_profile = staff.duplicate(true)

	var integrated_staff_report: Dictionary = one.get_engineer_advice(int(one.player_cars()[0]["id"])).get("staff_strategy_066910", {})
	check(str(integrated_staff_report.get("staff_name", "")) == "Elisa Nogueira"
		and str(integrated_staff_report.get("source", "")) == "observacoes_e_previsoes_imperfeitas",
		"real RaceEngine engineer advice exposes signed strategist without issuing an order")
	var protective = Race.new(season["teams"], "Ferrari", 6612, {}, track, {})
	protective.strategy_staff_profile = staff.duplicate(true)
	var protected_driver: Dictionary = protective.player_cars()[0]
	var protected_id: int = int(protected_driver["id"])
	check(protective.schedule_pit(protected_id, str(protective.available_pit_compounds()[1]), 21),
		"real RaceEngine accepts explicit BOX V21 with active strategist")
	var protected_staff_report: Dictionary = protective.get_engineer_advice(protected_id).get("staff_strategy_066910", {})
	check(str(protected_staff_report.get("recommendation", "")) == "ORDEM MANUAL PROTEGIDA",
		"real staff advice defers to confirmed player order")
	protective.configure_weather("Chuva intensa")
	protected_driver["progress"] = 3.94
	protective.running = true
	for tick in range(36):
		protective.step(0.2)
	check(int(protected_driver["pit_scheduled_lap"]) == 21
		and not bool(protected_driver["pit_request"])
		and int(protected_driver["stops"]) == 0,
		"real V21 stays V21 even with live 83 percent rain and active strategist")
	var initial_state: Dictionary = Codec.capture(one)
	check(not initial_state["engine"].has("strategy_staff_intelligence_enabled")
		and not initial_state["engine"].has("strategy_staff_profile")
		and Codec.restore(initial_state) != null,
		"staff session profile is outside fixed sporting checkpoint schema")
	var session = Replay.new()
	session.attach(one, {}, {"Estrategista":2})
	check(str(session.recorded_simulation_revision) == Replay.SIMULATION_REVISION
		and session.policy.has("strategy_staff")
		and str(session.policy["strategy_staff"].get("name", "")) == "Elisa Nogueira",
		"021 replay captures the profile independently of Garage")
	var reference = Replay.new()
	reference.attach(two, {}, {"Estrategista":2})
	for i in range(60):
		check(session.step_tick() and reference.step_tick(),
			"new race executes a deterministic tick")
	check(Codec.sporting_hash(session.race, session.policy)
		== Codec.sporting_hash(reference.race, reference.policy),
		"two identical 021 races keep the same sporting hash")
	var archive: Dictionary = session.export_data()
	var playback = Replay.new()
	check(playback.load_data(archive) and not bool(playback.legacy_staff_strategy)
		and playback.seek(60) and playback.first_divergence < 0,
		"021 replay imports and seeks with staff policy intact")
	var legacy = Replay.new()
	legacy.attach(Race.new(season["teams"], "Ferrari", 6611, {}, track, {}))
	legacy.recorded_simulation_revision = Replay.PRE_STAFF_SIMULATION_REVISION
	legacy.legacy_staff_strategy = true
	legacy.race.strategy_staff_intelligence_enabled = false
	legacy.policy.erase("strategy_staff")
	legacy.checkpoints = [legacy.checkpoint()]
	for i in range(30):
		check(legacy.step_tick(), "020 archive tick")
	var old_playback = Replay.new()
	check(old_playback.load_data(legacy.export_data())
		and bool(old_playback.legacy_staff_strategy)
		and not bool(old_playback.race.strategy_staff_intelligence_enabled)
		and old_playback.seek(30) and old_playback.first_divergence < 0,
		"020 legacy archive keeps pre-staff sporting decisions and hash")
	if failures.is_empty():
		print("STRATEGY_STAFF_066910_PASS checks=%d" % checks)
	else:
		for message in failures:
			printerr("FAIL: " + message)
	quit(0 if failures.is_empty() else 1)
