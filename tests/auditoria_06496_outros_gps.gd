extends SceneTree
## Auditoria v0.6.4.9.6 de Silverstone com revisão por volta.
## Não modifica código de produção; usa Race.step(0.20) nativo.
const Race = preload("res://scripts/race_engine.gd")
const Planner = preload("res://scripts/core/race_pre_race_strategy_06495.gd")
const CONFIG := {
    "BEL": {"mode": "Chuva intensa", "seed": 6404},
    "ITA": {"mode": "Seco", "seed": 6405},
    "SIN": {"mode": "Variável", "seed": 6406}
}
const OUTPUT := "res://qa/06496/silverstone/"
var fails: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, message: String) -> void:
    if not condition:
        fails.append(message)
        printerr("AUDIT_FAIL: " + message)

func _write(path: String, payload: Variant) -> void:
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        _check(false, "failed to write " + path)
        return
    f.store_string(JSON.stringify(payload, "  "))
    f.close()

func _run() -> void:
    var args: Array = OS.get_cmdline_user_args()
    if args.size() != 2 or str(args[0]) != "--code" or not CONFIG.has(str(args[1])):
        printerr("USAGE: -- --code GBR")
        quit(2)
        return
    var code: String = str(args[1])
    var cfg: Dictionary = CONFIG[code]
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var circuit: Dictionary = {}
    for item in season["tracks"]:
        if str(item.get("code","")) == code:
            circuit = item
            break
    _check(not circuit.is_empty(), "track missing")
    if not fails.is_empty():
        quit(2)
        return
    var sim = Race.new(season["teams"],"Ferrari",int(cfg["seed"]),{},circuit,{})
    sim.configure_weather(str(cfg["mode"]))
    var before: String = JSON.stringify(sim.get_state_snapshot())
    var plan: Dictionary = Planner.generate(sim)
    _check(JSON.stringify(sim.get_state_snapshot()) == before, "planner changed race state")
    _check(plan.get("plans",[]).size() == 2, "planner missing two pilot previews")
    var preview: Array = []
    for pilot in plan.get("plans",[]):
        var entry: Dictionary = {"name":pilot.get("name"),"valid":pilot.get("valid",false)}
        if bool(pilot.get("valid",false)):
            entry["stints"] = pilot.get("stints",[])
            var total: int = 0
            for s in entry["stints"]:
                total += int(s.get("laps",0))
                _check(float(s.get("wear_end",0.0)) <= 86.1,"projected wear limit")
            _check(total == int(sim.lap_count),"planner stints not covering race")
        else:
            entry["reason"] = pilot.get("reason","")
        preview.append(entry)
    if code == "GBR" and str(cfg["mode"]) == "Seco":
        _check(bool(preview[0].get("valid",false)) and bool(preview[1].get("valid",false)), "dry pre-race plan invalid")
    for c in sim.player_cars():
        c["pit_control_mode"] = "IA"
    sim.running = true
    var started: int = Time.get_ticks_msec()
    var ticks: int = 0
    var min_track_c: float = 999.0
    var max_track_c: float = -999.0
    var min_grip: float = 999.0
    var max_grip: float = -999.0
    var max_wear: float = 0.0
    var wet_seen: bool = false
    var last_recorded: Dictionary = {}
    var review_count: int = 0
    var changes: Dictionary = {"ANTECIPAR":0,"ESTENDER":0,"PARAR NA JANELA":0,"MANTER":0,"ORDEM PROTEGIDA":0}
    var review_errors: int = 0
    print("AUDIT_START code=%s laps=%d seed=%d weather=%s step=0.20 plan=%s" % [code,sim.lap_count,int(cfg["seed"]),str(cfg["mode"]),JSON.stringify(preview)], true)
    while not sim.finished and ticks < 100000 and fails.is_empty():
        var old_time: float = sim.clock
        sim.step(0.20)
        ticks += 1
        if ticks % 5 == 0:
            for c in sim.cars:
                var report: Dictionary = c.get("lap_strategy_06496", {})
                var id: int = int(c.get("id",-1))
                var lap_idx: int = int(report.get("lap",0))
                if lap_idx > int(last_recorded.get(id,0)):
                    last_recorded[id] = lap_idx
                    review_count += 1
                    var action: String = str(report.get("action",""))
                    changes[action] = int(changes.get(action,0)) + 1
                    if (c.get("lap_strategy_history_06496",[]) as Array).size() > 16:
                        review_errors += 1
        if not is_finite(sim.clock) or absf(sim.clock - old_time - 0.20) > 0.000001:
            _check(false, "invalid native time increment tick=" + str(ticks))
            break
        if ticks % 100 == 0:
            var w: Dictionary = sim.weather_snapshot()
            var temp: float = float(w.get("track_c",0.0))
            var grip: float = float(w.get("grip_factor",0.0))
            min_track_c = minf(min_track_c, temp)
            max_track_c = maxf(max_track_c, temp)
            min_grip = minf(min_grip, grip)
            max_grip = maxf(max_grip, grip)
            wet_seen = wet_seen or float(w.get("wetness_factor",0.0)) > 0.12
            _check(is_finite(temp) and temp >= 4.9 and temp <= 69.1, "track temp out of bounds")
            _check(is_finite(grip) and grip >= 0.54 and grip <= 1.20,"grip out of bounds")
            for c in sim.cars:
                var wear: float = float(c.get("wear",-1.0))
                max_wear = maxf(max_wear,wear)
                _check(is_finite(wear) and wear >= 0.0 and wear <= 100.01,"wear out of bounds for "+str(c.get("name","")))
                _check(is_finite(float(c.get("tyre_surface_c",0))) and is_finite(float(c.get("tyre_core_c",0))),"invalid tire temperatures")
        if ticks % 2500 == 0:
            print("AUDIT_PROGRESS code=%s lap=%d/%d ticks=%d wall_s=%.1f" % [code,int(sim.lap),int(sim.lap_count),ticks,(Time.get_ticks_msec()-started)/1000.0], true)
    _check(review_count >= 800, "too few per-lap reviews: " + str(review_count))
    _check(review_errors == 0, "unbounded lap histories")
    _check(sim.finished, "race incomplete")
    _check(sim.finish_results_validated, "results not validated")
    _check(sim.cars.size() == 24, "grid not 24")
    if str(cfg["mode"]) == "Chuva intensa":
        _check(wet_seen,"no wet conditions observed")
    var sorted: Array = sim.get_sorted()
    var count_stops: int = 0
    var finished_count: int = 0
    var violators: Array = []
    var classified: Array = []
    for i in range(sorted.size()):
        var c: Dictionary = sorted[i]
        count_stops += int(c.get("stops",0))
        if bool(c.get("finished",false)):
            finished_count += 1
        if bool(c.get("tyre_rule_violation",false)) or bool(c.get("disqualified",false)):
            violators.append(str(c.get("name","?")))
        _check(int(c.get("position",i+1)) == i+1,"classification numbering mismatch")
        _check(int(c.get("driver_soul",{}).get("last_lap",0)) > 0, "Soul Driver missing lap update")
        classified.append({"position":i+1,"name":c.get("name",""),"team":c.get("team",""),"stops":c.get("stops",0),
            "best_lap":c.get("best_lap",0),"wear_finish":c.get("wear",0),"last_tyre":c.get("tire","")})
    _check(finished_count == 24,"not all 24 drivers finished")
    _check(violators.is_empty(),"disqualification or tyre rules violated")
    _check(max_track_c-min_track_c >= 0.15, "asphalt temperature stayed static")
    var pit_hist: Array = sim.get_pit_history()
    _check(count_stops == pit_hist.size(), "pit history count differs from stop totals")
    var result: Dictionary = {
        "version":"0.6.4.9.6","code":code,"track":str(circuit.get("name","")),
        "seed":cfg["seed"],"weather":cfg["mode"],"step_seconds":0.20,
        "ticks":ticks,"elapsed_wall_s":(Time.get_ticks_msec()-started)/1000.0,
        "sim_seconds":sim.clock,"lap_count":sim.lap_count,"race_finished":sim.finished,
        "classification_validated":sim.finish_results_validated,
        "total_stops":count_stops,"finished_drivers":finished_count,
        "max_wear_observed":max_wear,"wet_seen":wet_seen,
        "track_temp_min":min_track_c,"track_temp_max":max_track_c,
        "grip_min":min_grip,"grip_max":max_grip,
        "planner_advisory":preview,"finish_order":classified,
        "pit_history":pit_hist,"review_count":review_count,"review_actions":changes,"review_errors":review_errors,"errors":fails
    }
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    _write(OUTPUT + code + ".json", result)
    print("AUDIT_%s code=%s laps=%d/ %d drivers=%d stops=%d winner=%s errors=%d tick=%d reviews=%d" % [
        "PASS" if fails.is_empty() else "FAIL",code,int(sim.lap_count),int(circuit.get("laps",0)),
        finished_count,count_stops,str(sorted[0]["name"]) if not sorted.is_empty() else "none",fails.size(),ticks,review_count],true)
    quit(0 if fails.is_empty() else 1)
