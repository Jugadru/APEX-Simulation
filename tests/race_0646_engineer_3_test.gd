extends SceneTree
## Native v0.6.4.6 regression. Actual engine + actual HUD, no mocks for pit commands.
const RE3 = preload("res://scripts/core/race_engineer_0646.gd")
const Race = preload("res://scripts/race_engine.gd")
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func require(ok: bool, message: String) -> void:
    if not ok:
        errors.append(message)
        printerr("RE3_0646_FAIL " + message)

func assess(car: Dictionary, advice: Dictionary, mate: Dictionary = {}, weather: Dictionary = {"wetness_factor":0.10}, staff: Dictionary = {"Engenheiro":2, "Estrategista":2}, end: int = 50, entry: int = 5) -> Dictionary:
    return RE3.assess(car, {"can_call_pit": true, "tactic":"MANTER"},
        advice, weather, mate, staff, ["Macio","Médio","Intermediário","Chuva"],
        end, 22.0, 90.0, entry)

func _run() -> void:
    var car: Dictionary = {"id":1,"name":"Piloto fictício","laps_done":4,"position":4,"progress":4.2,
        "wear":58.0,"tire":"Médio","stint_laps":4,"pit_scheduled_lap":0,"pit_request":false,
        "pit_left":0.0,"last_lap":91.2,"best_lap":90.7,"tyre_surface_c":90.0,"tyre_core_c":84.0,
        "tyre_graining":0.05,"tyre_blistering":0.1}
    var advice: Dictionary = {"pit_now":true,"compound":"Macio","planned_pit_lap":5,
        "forecast_3":0.12,"life_laps":8.0,"rejoin_position":8,"rejoin_gap_s":1.1,"traffic_risk":true}
    var mate: Dictionary = {"id":2,"pit_scheduled_lap":0,"pit_request":false,"pit_left":0.0}
    var before: String = JSON.stringify([car,advice,mate])
    var r: Dictionary = assess(car,advice,mate)
    require(JSON.stringify([car,advice,mate]) == before, "no input state mutations")
    require(r.get("engineer_version") == "3.0" and r.get("can_call_pit", false), "valid immediate pit within window")
    require(str(r.get("traffic_note","")).contains("P8"), "grounded rejoin projection")
    require(str(r.get("stop_case","")).contains("22.0s"), "pit loss from true state")
    require(str(r.get("pace_note","")).contains("+0.50s"), "actual lap trend")
    require(not bool(r.get("double_stack",true)), "no double stack without overlap")
    var booked: Dictionary = car.duplicate(true)
    booked["pit_scheduled_lap"] = 21
    var wet: Dictionary = {"wetness_factor":0.83}
    r = assess(booked, advice, mate, wet)
    require(not r.get("can_call_pit",true) and str(r["pit_gate"]).contains("V21"), "V21 protected even under 83 pct rain")
    require(str(r["action"]).contains("V21") and r.get("priority",0)>=1, "protected order disclosed in briefing")
    for state in ["pit_request","pit_left","finished"]:
        var changing: Dictionary = car.duplicate(true)
        changing[state] = 10.0 if state == "pit_left" else true
        r = assess(changing, advice, mate)
        require(not r["can_call_pit"], "blocked terminal or busy state " + state)
    r = assess(car,advice,mate,{"wetness_factor":0.1},{},50,50)
    require(not r["can_call_pit"] and str(r["pit_gate"]).contains("FIM"), "no pit at final entry")
    var wrong: Dictionary = advice.duplicate(true)
    wrong["compound"] = "Pneu inventado"
    r = assess(car,wrong,mate)
    require(not r["can_call_pit"], "not authorized for invalid compound")
    wrong = advice.duplicate(true)
    wrong["pit_now"] = false
    r = assess(car,wrong,mate)
    require(not r["can_call_pit"], "no recommendation cannot create pit")
    var mate_busy: Dictionary = mate.duplicate()
    mate_busy["pit_request"]=true
    r = assess(car,advice,mate_busy)
    require(r["double_stack"] and r["can_call_pit"], "double stack warns but leaves player decision")
    mate_busy = mate.duplicate()
    mate_busy["pit_scheduled_lap"]=5
    r = assess(car,advice,mate_busy)
    require(r["double_stack"] and r["can_call_pit"], "future teammate overlap")
    var both: Dictionary=mate.duplicate()
    both["pit_scheduled_lap"]=21
    r = assess(booked,advice,both)
    require(r["double_stack"] and not r["can_call_pit"], "both booked same lap cannot overwrite orders")
    wrong=advice.duplicate(true)
    wrong["pit_now"] = false
    wrong["forecast_3"] = 0.48
    r = assess(car,wrong,mate)
    require(str(r["condition"]) == "MUDANÇA DE CLIMA", "forecast change priority")
    wrong=advice.duplicate(true)
    wrong["pit_now"] = false
    wrong["planned_pit_lap"] = 9
    wrong["forecast_3"] = 0.10
    var low: Dictionary = assess(car,wrong,mate,{"wetness_factor":0.1},{"Estrategista":0,"Engenheiro":0})
    var high: Dictionary = assess(car,wrong,mate,{"wetness_factor":0.1},{"Estrategista":3,"Engenheiro":3})
    require(str(low["condition"]) == "ESTÁVEL" and str(high["condition"]) == "BOX NO HORIZONTE", "staff improves planning warning horizon")
    var queries: Array[String] = []
    for topic in ["plano","pneus","clima","trafego"]:
        queries.append(RE3.answer(r,topic))
    require(queries.size() == 4 and queries[0] != queries[1] and queries[2] != queries[3], "specific grounded radio answers")
    require(RE3.answer(r,"not-a-question").contains("desconhecida"), "radio rejects unknown topic")
    # Authoritative engine: explicit scheduled lap must survive hundreds of native ticks.
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var sim = Race.new(season["teams"], "Ferrari", 646, {}, season["tracks"][0], {})
    sim.running = true
    var pilot: Dictionary = sim.player_cars()[0]
    var id: int = int(pilot["id"])
    require(sim.schedule_pit(id,sim.available_pit_compounds()[1],21), "manual pit booking accepted")
    var rng_at: int = sim.rng.state
    var actual_advice: Dictionary = sim.get_engineer_advice(id)
    var actual_report: Dictionary = RE3.assess(pilot,{"can_call_pit":true},actual_advice,sim.weather_snapshot(),{},
        {"Engenheiro":3,"Estrategista":3},sim.available_pit_compounds(),sim.lap_count,sim.pit_loss,sim.base_lap,sim._next_pit_entry_lap(pilot))
    require(sim.rng.state == rng_at, "RE3 doesn't consume RNG")
    require(not actual_report["can_call_pit"] and str(actual_report["pit_gate"]).contains("V21"), "native engine V21 guard")
    sim.configure_weather("Chuva intensa")
    require(float(sim.weather_snapshot().get("wetness_factor", 0.0)) >= 0.38, "native heavy rain above wet tyre threshold")
    var rain_advice: Dictionary = sim.get_engineer_advice(id)
    var rain_report: Dictionary = RE3.assess(pilot, {"can_call_pit":true}, rain_advice, sim.weather_snapshot(), {},
        {"Engenheiro":3,"Estrategista":3}, sim.available_pit_compounds(),sim.lap_count,sim.pit_loss,sim.base_lap,sim._next_pit_entry_lap(pilot))
    require(not rain_report["can_call_pit"] and str(rain_report["pit_gate"]).contains("V21"), "heavy rainy native scenario keeps V21")
    for n in range(70):
        sim.step(0.20)
    require(int(pilot.get("pit_scheduled_lap",0)) == 21 and not bool(pilot.get("pit_request",false)), "native 0.20 step preserves manual V21 in rain")
    # Real rendered HUD integration: radio 4 topics, no pit orders, logs bounded.
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    hud._open_window("engineer")
    await process_frame
    require(hud.overlay_title.text.contains("RACE ENGINEER 3.0"), "UI v3 title")
    require(hud.engineer_cards.size() == 2, "two engineer cards")
    for ui in hud.engineer_cards:
        require(ui.has("ask_weather") and ui.has("ask_tyres") and ui.has("ask_traffic"), "independent interactive radio buttons")
        require(str(ui["tradeoff"].text).contains("PARAR:"), "stop vs hold scenario shown")
        require(str(ui["order"].text).contains("GATILHO BOX"), "UI has authoritative pit gate")
    var ui_car: Dictionary = game.race.player_cars()[0]
    var ui_id: int = int(ui_car["id"])
    var pit_before: bool = bool(ui_car.get("pit_request",false))
    var rng_before: int = game.race.rng.state
    var events_before: int = game.race.events.size()
    hud._engineer_ask(ui_id,"clima")
    require(str(hud.engineer_radio_answers[ui_id]).contains("Pista"), "live weather reply displayed")
    require(game.race.events.size()==events_before+1, "first query generates one radio event")
    hud._engineer_ask(ui_id,"clima")
    require(game.race.events.size()==events_before+1, "same-topic spam throttled")
    hud._engineer_ask(ui_id,"trafego")
    require(game.race.events.size()==events_before+2, "different topic allowed")
    require(bool(ui_car.get("pit_request",false)) == pit_before, "questions never trigger pit")
    require(game.race.rng.state == rng_before, "HUD engineer no RNG")
    hud._engineer_accept_pit(ui_id)
    require(not bool(ui_car.get("pit_request",false)), "cannot force pit without planner recommendation")
    game.queue_free()
    await process_frame
    if errors.is_empty():
        print("RE3_0646_PASS: pure planning, staff horizon, rain 83, V21, double stack, 4 radios, UI, manual pit, 0.20 native")
    quit(0 if errors.is_empty() else 1)
