extends SceneTree
## 06492: integration and safety tests for an already-authorized automatic pit
## that meets a team-mate still occupying the one shared garage.
const Race = preload("res://scripts/race_engine.gd")
const Coordinator = preload("res://scripts/core/race_double_stack_coordinator_06492.gd")
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, label: String) -> void:
    if not value:
        errors.append(label)
        printerr("DOUBLESTACK_06492_FAIL " + label)

func build_silverstone() -> Object:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var silverstone: Dictionary = {}
    for track in season["tracks"]:
        if str(track.get("code", "")) == "GBR":
            silverstone = track
            break
    var sim = Race.new(season["teams"], "Ferrari", 6403, {"Motor":1,"Asa":1,"Chassi":1}, silverstone, {})
    sim.configure_weather("Seco")
    sim.pit_incidents_enabled = false
    return sim

func prepare_pair(sim, second_source: String = "ia_estrategia", second_wear: float = 35.0) -> Array:
    var pair: Array = sim.player_cars()
    var first: Dictionary = pair[0]
    var second: Dictionary = pair[1]
    for car in pair:
        car["pit_control_mode"] = "IA"
        car["wear"] = 35.0
        car["laps_done"] = 0
        car["stint_laps"] = 8
        car["pit_request"] = true
        car["pit_order_source"] = "ia_estrategia"
        car["pit_target"] = "Duro" if str(car.get("tire", "")) != "Duro" else "Médio"
        car["ai_plan"] = {"pit_now":true, "compound":car["pit_target"], "critical":false, "life_laps":5.0}
    first["progress"] = 0.949
    second["progress"] = 0.947
    second["pit_order_source"] = second_source
    second["wear"] = second_wear
    sim.running = true
    return pair

func _run() -> void:
    # The pure gate must reject high-risk and non-automatic calls.
    var incoming: Dictionary = {"id":1,"team":"Ferrari","tire":"Médio","wear":32.0,
        "pit_request":true,"pit_order_source":"ia_estrategia","pit_left":0.0,
        "pit_scheduled_lap":0,"pitwall49_held":false}
    var mate: Dictionary = {"id":2,"team":"Ferrari"}
    var safe_plan: Dictionary = {"critical":false,"life_laps":5.0}
    var dry: Dictionary = {"wetness_factor":0.01,"rain_intensity":0.0}
    # Exact state-driven prediction: service finished / crew released is not a conflict.
    mate["pit_left"] = 10.0
    mate["pit_stage"] = "exit"
    check(Coordinator.estimated_queue(incoming,mate,29.0,0.31) == 0.0, "exit does not monopolize garage")
    mate["pit_stage"] = "service"
    mate["pit_service_total"] = 2.0
    mate["pit_stage_elapsed"] = 0.0
    mate["pit_service_delay"] = 0.0
    mate["pit_release_delay"] = 0.0
    check(Coordinator.estimated_queue(incoming,mate,29.0,0.31) == 0.0, "near-finished service does not defer")
    mate["pit_stage"] = "approach"
    mate["pit_nominal_total"] = 29.0
    mate["pit_dock_total"] = 4.0
    mate["pit_service_total"] = 4.0
    check(Coordinator.estimated_queue(incoming,mate,29.0,0.31) >= 7.0, "real overlapping approach anticipates queue")
    check(Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,5.0,13,52), "safe dry queue can be avoided")
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,2.0,13,52), "tiny queue not worth one lap")
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,5.0,51,52), "last lap no diversion")
    incoming["pitwall49_held"] = true
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,5.0,13,52), "never twice in a stint")
    incoming["pitwall49_held"] = false
    incoming["pit_order_source"] = "ia_urgencia"
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,5.0,13,52), "urgent allowed")
    incoming["pit_order_source"] = "ordem_imediata"
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,5.0,13,52), "manual immediate allowed")
    incoming["pit_order_source"] = "ia_estrategia"
    incoming["pit_scheduled_lap"] = 21
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,5.0,13,52), "V21 cannot divert")
    incoming["pit_scheduled_lap"] = 0
    incoming["wear"] = 88.0
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,dry,5.0,13,52), "critical wear")
    incoming["wear"] = 32.0
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,dry,{"wetness_factor":0.55},5.0,13,52), "incoming rain")
    check(not Coordinator.should_stagger(incoming,mate,safe_plan,{"wetness_factor":0.55},dry,5.0,13,52), "wet track")
    # Production entry, no direct calls to _begin_pit or _advance.
    var sim = build_silverstone()
    var pair: Array = prepare_pair(sim)
    var first: Dictionary = pair[0]
    var second: Dictionary = pair[1]
    var diverted: bool = false
    for i in range(150):
        sim.step(0.20)
        if bool(second.get("pitwall49_held", false)):
            diverted = true
            break
    check(diverted, "real entry diverts safe second auto request")
    check(int(first.get("stops",0)) == 1 and int(second.get("stops",0)) == 0, "only first pitted")
    check(not bool(second.get("pit_request", true)) and str(second.get("pit_order_source","X")) == "", "optional order cancelled only")
    check(float(second.get("pit_wait",-1.0)) <= 0.0 and str(second.get("pit_stage","none")) == "none", "no queue and no invented pit")
    check(sim.pit_history.is_empty(), "no premature completed stop")
    var scheduled_target: String = str(second.get("pit_target", "Duro"))
    check(sim.schedule_pit(int(second["id"]), scheduled_target, 4), "driver remains available for future manual plan")
    check(int(second.get("pit_scheduled_lap",0)) == 4, "future manual order remains authoritative")
    # Confirm the protected actions still execute even when they queue.
    for source in ["ia_urgencia", "ordem_imediata"]:
        var urgent_sim = build_silverstone()
        var urgent_pair: Array = prepare_pair(urgent_sim, source)
        for i in range(500):
            urgent_sim.step(0.20)
            if str(urgent_pair[1].get("pit_stage", "")) == "done":
                break
        check(int(urgent_pair[1].get("stops",0)) == 1, source + " enters without diversion")
        check(not bool(urgent_pair[1].get("pitwall49_held",false)), source + " does not set hold")
        check(float(urgent_pair[1].get("pit_wait",0.0)) > 1.0, source + " retains physically serialized garage queue")
    var scheduled_sim = build_silverstone()
    var booked: Array = scheduled_sim.player_cars()
    check(scheduled_sim.schedule_pit(int(booked[0]["id"]),"Duro",21), "V21 scheduled")
    var after_booking: Dictionary = scheduled_sim.get_engineer_advice(int(booked[0]["id"]))
    check(int(booked[0].get("pit_scheduled_lap",0)) == 21 and not bool(booked[0].get("pit_request",false)), "V21 not anticipated by advice")
    check(after_booking.size() > 0, "advice available")
    if errors.is_empty():
        print("DOUBLESTACK_06492_PASS Silverstone safe queue avoided, risk gates, V21, manual and urgent respected")
    quit(0 if errors.is_empty() else 1)
