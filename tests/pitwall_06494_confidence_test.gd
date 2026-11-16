extends SceneTree
## 0.6.4.9.4 - somente nível/evidência de confiança mudam. Nada de auto pit.
const Planner = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const Race = preload("res://scripts/race_engine.gd")
var fail: Array[String] = []
func check(ok: bool, why: String) -> void:
    if not ok:
        fail.append(why)
        printerr("CONF_06494_FAIL ",why)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var car: Dictionary = {"id":1,"team":"Ferrari","name":"Piloto A","laps_done":4,
        "position":3,"progress":4.0,"last_lap":95.0,"wear":32.0,
        "tire":"Macio","pit_request":false,"pit_left":0.0,"pit_scheduled_lap":0}
    var teammate: Dictionary = {"id":2,"team":"Ferrari","name":"Piloto B",
        "progress":3.18,"last_lap":95.0,"pit_request":false,"pit_left":0.0,"pit_scheduled_lap":0}
    var opponent: Dictionary = {"id":3,"team":"Outros","progress":3.20,"last_lap":94.6}
    var grid: Array = [car, teammate, opponent]
    var advice: Dictionary = {"pit_now":true,"compound":"Médio","life_laps":6.0,
        "planned_pit_lap":5,"forecast_3":0.02,"forecast_6":0.02,"critical":false}
    var before: String = JSON.stringify([car,teammate,grid,advice])
    var dry: Dictionary = Planner.assess(car,teammate,grid,advice,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(dry["confidence"] == "ALTA", "dry and stable confidence ALTA")
    check(not bool(dry["now"]["traffic"]),"free rejoin")
    check(str(dry["confidence_reason"]).contains("seca"),"evidence for dry")
    check(str(dry["forecast_note"]).contains("Confiança ALTA"),"confidence visible in existing UI")
    check(JSON.stringify([car,teammate,grid,advice]) == before, "read-only")
    check(dry["can_schedule"] and dry["can_extend"],"unchanged decision gates")
    var traffic_grid: Array = [car, teammate, {"id":3,"team":"Outros","progress":3.79,"last_lap":95.0}]
    var traffic: Dictionary = Planner.assess(car,teammate,traffic_grid,advice,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(traffic["now"]["traffic"] and traffic["confidence"] == "MODERADA", "traffic moderate")
    var wet: Dictionary = Planner.assess(car,teammate,grid,advice,{"wetness_factor":0.19},["Macio","Médio"],52,20.0,95.0,5)
    check(wet["confidence"] == "MODERADA", "wet moderate")
    var mild_advice: Dictionary = advice.duplicate(true)
    mild_advice["forecast_3"] = 0.12
    mild_advice["forecast_6"] = 0.14
    var mild: Dictionary = Planner.assess(car,teammate,grid,mild_advice,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(mild["confidence"] == "MODERADA", "forecast variation moderate")
    var shift_advice: Dictionary = advice.duplicate(true)
    shift_advice["forecast_3"] = 0.40
    shift_advice["forecast_6"] = 0.55
    var shift: Dictionary = Planner.assess(car,teammate,grid,shift_advice,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(shift["confidence"] == "BAIXA", "rapid rainfall low")
    var high_wear: Dictionary = car.duplicate(true)
    high_wear["wear"] = 91.0
    var critical: Dictionary = Planner.assess(high_wear,teammate,grid,advice,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(critical["confidence"] == "BAIXA" and critical["critical"], "critical wear low")
    var busy_mate: Dictionary = teammate.duplicate(true)
    busy_mate["pit_scheduled_lap"] = 5
    var stack: Dictionary = Planner.assess(car,busy_mate,grid,advice,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(stack["confidence"] == "BAIXA" and stack["team_overlap"],"double stack low")
    var no_forecast: Dictionary = advice.duplicate(true)
    no_forecast.erase("forecast_3")
    no_forecast.erase("forecast_6")
    var missing: Dictionary = Planner.assess(car,teammate,grid,no_forecast,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(missing["confidence"] == "MODERADA", "no high with missing forecasts")
    car["pit_scheduled_lap"] = 21
    var scheduled: Dictionary = Planner.assess(car,teammate,grid,advice,{"wetness_factor":0.02},["Macio","Médio"],52,20.0,95.0,5)
    check(scheduled["booked"] == 21 and not scheduled["can_schedule"] and not scheduled["auto_hold_safe"],"V21 protected")
    var manual: Dictionary = Planner.auto_coordinate(car,busy_mate,scheduled,advice)
    check(bool(manual["pit_now"]), "scheduled stop cannot be auto held")
    # Integration with production, including real engine weather and grid.
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var silverstone: Dictionary = {}
    for track in season["tracks"]:
        if str(track.get("code","")) == "GBR":
            silverstone = track
            break
    check(not silverstone.is_empty(),"Silverstone exists")
    if silverstone.is_empty():
        quit(2)
        return
    var sim = Race.new(season["teams"], "Ferrari", 6403, {}, silverstone, {})
    sim.running = true
    var players: Array = sim.player_cars()
    var id: int = int(players[0]["id"])
    var original_state: String = JSON.stringify(sim.get_state_snapshot())
    var live: Dictionary = Planner.assess(players[0], players[1], sim.get_sorted(),
        sim.get_engineer_advice(id), sim.weather_snapshot(), sim.available_pit_compounds(),
        sim.lap_count, sim.pit_loss, sim.base_lap, sim._next_pit_entry_lap(players[0]))
    check(str(live.get("confidence","")) in ["BAIXA","MODERADA","ALTA"],"live confidence classified")
    check(JSON.stringify(sim.get_state_snapshot()) == original_state,"real engine state unchanged by query")
    for i in range(30):
        sim.step(0.20)
    check(sim.clock > 0.0,"real native 0.20 tick")
    if fail.is_empty():
        print("CONF_06494_PASS dry, rain, traffic, wear, stack, missing data, V21, purity, Silverstone live")
    quit(0 if fail.is_empty() else 1)
