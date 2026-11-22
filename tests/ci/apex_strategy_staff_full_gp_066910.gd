extends SceneTree
## v0.6.6.9.10: real full-distance GP with one protected manual V21
## and one automatic driver using the currently hired Strategy Staff.
## Runs two identical seeded races and compares final sporting state.
const Race = preload("res://scripts/race_engine.gd")
const Staff = preload("res://scripts/core/race_strategy_staff_intelligence_066910.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const STEP_SECONDS: float = 4.0
const MAX_STEPS: int = 5500

func _initialize() -> void:
	call_deferred("_run")

func _race_once(season: Dictionary, track: Dictionary, seed: int, mode: String) -> Dictionary:
	var team: Dictionary = {"staff_roster":{"Estrategista":{
		"id":"est_c", "name":"Elisa Nogueira", "skill":90,
		"energy":80, "morale":75, "trust":80,
		"specialty":"Estratégia em clima variável"}},
		"staff_levels":{"Estrategista":3},
		"staff_soul":{"relations":{"Engenheiro|Estrategista":70}}}
	var race = Race.new(season["teams"], "Ferrari", seed, {}, track, {})
	race.strategy_staff_profile = Staff.profile(team)
	race.configure_weather(mode)
	var players: Array = race.player_cars()
	if players.size() != 2 or race.cars.size() != 24:
		return {"error":"grid incompleto"}
	var first_id: int = int(players[0].get("id", -1))
	var second_id: int = int(players[1].get("id", -1))
	var tires: Array = race.available_pit_compounds()
	if tires.size() < 2:
		return {"error":"compostos indisponiveis"}
	if not race.schedule_pit(first_id, str(tires[1]), 21):
		return {"error":"agendamento V21 recusado"}
	if not race.set_pit_control_mode(second_id, "IA"):
		return {"error":"piloto automatico recusado"}
	if not bool(race.strategy_staff_profile.get("active", false)):
		return {"error":"staff nao ativo"}
	var staff_report: Dictionary = race.get_engineer_advice(first_id).get("staff_strategy_066910", {})
	if str(staff_report.get("recommendation", "")) != "ORDEM MANUAL PROTEGIDA":
		return {"error":"consultoria nao respeitou V21"}
	race.running = true
	var manual_early_pit: bool = false
	var staff_events: int = 0
	var last_event: int = 0
	var steps: int = 0
	for _i in range(MAX_STEPS):
		if race.finished:
			break
		race.step(STEP_SECONDS)
		steps += 1
		if int(players[0].get("stops", 0)) > 0 and int(players[0].get("laps_done", 0)) < 20:
			manual_early_pit = true
		for idx in range(last_event, race.events.size()):
			if str(race.events[idx].get("type", "")) == "strategy_staff":
				staff_events += 1
		last_event = race.events.size()
	var finished_cars: int = 0
	for car in race.cars:
		if bool(car.get("finished", false)):
			finished_cars += 1
	var history: Array = race.get_pit_history()
	var manual_stops: int = 0
	var auto_stops: int = 0
	for item in history:
		if int(item.get("car_id", -1)) == first_id:
			manual_stops += 1
		if int(item.get("car_id", -1)) == second_id:
			auto_stops += 1
	return {
		"finished":bool(race.finished), "finished_cars":finished_cars,
		"race_laps":race.lap_count, "steps":steps,
		"manual_early_pit":manual_early_pit,
		"manual_stops":manual_stops, "auto_stops":auto_stops,
		"staff_events":staff_events, "sporting_hash":Codec.sporting_hash(race, {}),
		"final_player_stops":[int(players[0].get("stops", 0)), int(players[1].get("stops", 0))]
	}

func _run() -> void:
	var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not (season is Dictionary):
		printerr("APEX_STAFF_FULL_GP_FAIL season")
		quit(1)
		return
	var code: String = OS.get_environment("APEX_TRACK")
	if code.is_empty():
		code = "GBR"
	var mode: String = OS.get_environment("APEX_WEATHER")
	if mode.is_empty():
		mode = "Seco"
	var seed: int = int(OS.get_environment("APEX_SEED"))
	if seed <= 0:
		seed = 6610
	var track: Dictionary = {}
	for item in season["tracks"]:
		if str(item.get("code", "")) == code:
			track = item
			break
	if track.is_empty():
		printerr("APEX_STAFF_FULL_GP_FAIL unknown track " + code)
		quit(1)
		return
	var one: Dictionary = _race_once(season, track, seed, mode)
	var two: Dictionary = _race_once(season, track, seed, mode)
	var valid: bool = (
		not one.has("error") and not two.has("error")
		and bool(one.get("finished", false)) and bool(two.get("finished", false))
		and int(one.get("finished_cars", 0)) == 24 and int(two.get("finished_cars", 0)) == 24
		and not bool(one.get("manual_early_pit", true))
		and int(one.get("manual_stops", 0)) >= 1 and int(one.get("auto_stops", 0)) >= 1
		and str(one.get("sporting_hash", "")) == str(two.get("sporting_hash", ""))
		and one.get("final_player_stops", []) == two.get("final_player_stops", [])
	)
	var report: Dictionary = {"track":code,"mode":mode,"seed":seed,"passed":valid,"a":one,"b":two}
	print("APEX_STAFF_FULL_GP_%s %s" % ["PASS" if valid else "FAIL", JSON.stringify(report)])
	quit(0 if valid else 1)
