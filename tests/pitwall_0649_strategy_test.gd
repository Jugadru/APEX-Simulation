extends SceneTree
## Pure analysis, double-stack, auto deferral, native scheduling, UI safety.
const Planner = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const Race = preload("res://scripts/race_engine.gd")
var fail: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(cond: bool, text: String) -> void:
	if not cond:
		fail.append(text)
		printerr("PITWALL_0649_FAIL ", text)
func _run() -> void:
	var car: Dictionary = {"id":1, "name":"Primeiro", "team":"A", "position":5,
		"progress":4.0,"laps_done":4,"wear":35.0,"tire":"Macio", "last_lap":95.0,
		"pit_scheduled_lap":0,"pit_request":false,"pit_left":0.0}
	var mate: Dictionary = {"id":2,"team":"A", "position":6,"progress":3.80,
		"last_lap":95.0,"pit_scheduled_lap":0,"pit_request":false,"pit_left":0.0}
	var rival: Dictionary = {"id":3,"team":"B","name":"Rival","progress":3.80,"last_lap":95.0}
	var advice: Dictionary = {"pit_now":true,"compound":"Médio","life_laps":6.0,
		"forecast_3":0.02,"forecast_6":0.02,"planned_pit_lap":5,"critical":false}
	var grid: Array = [car, mate, rival]
	var before: String = JSON.stringify([car,mate,grid,advice])
	var r: Dictionary = Planner.assess(car,mate,grid,advice,{"wetness_factor":0.02},["Macio","Médio","Intermediário"],71,20.0,95.0,5)
	check(r.get("version", "") == "3.0", "module version")
	check(r["cases"].size() == 3 and r["can_schedule"] and r["can_extend"], "three hypothetical plans")
	check(r["now"]["traffic"] and str(r["plan"]).contains("OVERCUT"), "traffic leads to safe overcut proposal")
	check(Planner.can_manual_schedule(r,car,mate,"Manual",5,71), "manual can schedule")
	check(Planner.can_manual_schedule(r,car,mate,"Assistido",6,71), "assisted can schedule one lap extension")
	check(not Planner.can_manual_schedule(r,car,mate,"Automático",5,71), "automatic cannot schedule")
	check(JSON.stringify([car,mate,grid,advice]) == before, "pure analysis does not mutate race")
	mate["pit_scheduled_lap"] = 5
	var booked: Dictionary = Planner.assess(car,mate,grid,advice,{"wetness_factor":0.02},["Macio","Médio"],71,20.0,95.0,5)
	check(booked["team_overlap"] and not Planner.can_manual_schedule(booked,car,mate,"Manual",5,71), "double stack blocks same-lap convenience booking")
	check(Planner.can_manual_schedule(booked,car,mate,"Manual",6,71), "staggered manual booking allowed")
	check(bool(booked.get("auto_hold_safe", false)), "confirmed teammate booking qualifies for bounded auto stagger")
	var staggered_auto: Dictionary = Planner.auto_coordinate(car,mate,booked,advice)
	check(not bool(staggered_auto.get("pit_now", true)) and bool(staggered_auto.get("pitwall49_hold", false)), "auto respects teammate confirmed next entry")
	mate["pit_scheduled_lap"] = 0
	mate["pit_request"] = true
	var busy: Dictionary = Planner.assess(car,mate,grid,advice,{"wetness_factor":0.02},["Macio","Médio"],71,20.0,95.0,5)
	check(busy["auto_hold_safe"], "safe candidate for auto double-stack avoidance")
	check(not Planner.can_manual_schedule(busy,car,mate,"Manual",5,71), "manual convenience booking blocked while garage occupied")
	var auto: Dictionary = Planner.auto_coordinate(car,mate,busy,advice)
	check(not auto["pit_now"] and auto["pitwall49_hold"], "defer one safe auto stop")
	car["pitwall49_held"] = true
	check(Planner.auto_coordinate(car,mate,busy,advice)["pit_now"], "never defer twice")
	car["pitwall49_held"] = false
	var rain: Dictionary = Planner.assess(car,mate,grid,advice,{"wetness_factor":0.83},["Macio","Médio"],71,20.0,95.0,5)
	check(rain["critical"] and not rain["auto_hold_safe"], "wet mismatch bypasses auto stagger")
	check(Planner.auto_coordinate(car,mate,rain,advice)["pit_now"], "rain urgent stop not deferred")
	car["pit_scheduled_lap"] = 21
	var scheduled: Dictionary = Planner.assess(car,mate,grid,advice,{"wetness_factor":0.83},["Macio","Médio"],71,20.0,95.0,5)
	check(scheduled["booked"] == 21 and not scheduled["can_schedule"] and not scheduled["auto_hold_safe"], "V21 remains protected even under rain")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = season["tracks"][0]
	var race = Race.new(season["teams"],"Ferrari",649,{},track,{})
	race.running = true
	var people: Array = race.player_cars()
	var id: int = int(people[0]["id"])
	var compound: String = str(race.available_pit_compounds()[0])
	check(race.schedule_pit(id,compound,21), "real motor accepted manual V21")
	var snap: String = JSON.stringify(race.get_state_snapshot())
	var checked: Dictionary = Planner.assess(people[0],people[1],race.get_sorted(),race.get_engineer_advice(id),race.weather_snapshot(),race.available_pit_compounds(),race.lap_count,race.pit_loss,race.base_lap,race._next_pit_entry_lap(people[0]))
	check(checked["booked"] == 21, "native engine V21 reads")
	check(JSON.stringify(race.get_state_snapshot()) == snap, "native advisory read-only")
	for i in range(35):
		race.step(0.20)
	check(int(people[0]["pit_scheduled_lap"]) == 21 and not bool(people[0]["pit_request"]), "V21 intact during simulation")
	if fail.is_empty():
		print("PITWALL_0649_STRATEGY_PASS pure scenarios, under/overcut, safe stagger, rain, V21 native")
	quit(0 if fail.is_empty() else 1)
