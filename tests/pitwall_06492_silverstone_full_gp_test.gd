extends SceneTree
## Silverstone 06492 native 0.20-second comparison; eight-capable GP runner through production step(0.20).
## Every integration tick is checked; no direct _advance or coarse stepping.
## Can scope one with -- --code BEL
const RaceScript = preload("res://scripts/race_engine.gd")
const TrackDynamics = preload("res://scripts/core/race_track_dynamics.gd")
const TyreThermal = preload("res://scripts/core/race_tyre_thermal.gd")
const VENUES := ["AUS", "MAL", "MON", "GBR", "BEL", "ITA", "SIN", "BRA"]
const MODES := ["Seco", "Chuva intensa", "Seco", "Variável", "Chuva intensa", "Seco", "Variável", "Seco"]

func _initialize() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var tracks: Dictionary = {}
    for circuit in season.get("tracks", []):
        tracks[str(circuit.get("code", ""))] = circuit
    var profiles: Dictionary = TrackDynamics.catalog().get("tracks", {})
    if profiles.size() != 20:
        _fail("track data missing circuits: %d" % profiles.size())
        return
    var target: String = ""
    var args: Array = OS.get_cmdline_user_args()
    if args.size() == 2 and str(args[0]) == "--code":
        target = str(args[1])
    var count: int = 0
    for idx in range(VENUES.size()):
        var code: String = VENUES[idx]
        if target != "" and target != code:
            continue
        var circuit: Dictionary = tracks.get(code, {})
        if circuit.is_empty():
            _fail("missing venue " + code)
            return
        var sim = RaceScript.new(season["teams"], "Ferrari", 6400 + idx, {"Motor":1,"Asa":1,"Chassi":1}, circuit, {})
        sim.configure_weather(MODES[idx])
        sim.running = true
        for car in sim.player_cars():
            car["pit_control_mode"] = "IA"
        var wall_started: int = Time.get_ticks_msec()
        print("GP_START code=%s seed=%d step=0.20 engine=%s" % [code, 6400 + idx, Engine.get_version_info()["string"]])
        var sample_start: Dictionary = sim.weather_snapshot()
        var initial_temp: float = float(sample_start.get("track_c", 0.0))
        var min_temp: float = initial_temp
        var max_temp: float = initial_temp
        var min_grip: float = 10.0
        var max_grip: float = -1.0
        var initial_rubber: float = float(sample_start.get("rubber", 8))
        var max_rubber: float = initial_rubber
        var went_wet: bool = false
        var loop_count: int = 0
        var last_clock: float = 0.0
        while not sim.finished and loop_count < 100000:
            sim.step(0.20)
            loop_count += 1
            if not is_finite(sim.clock) or absf(sim.clock - last_clock - 0.20) > 0.000001:
                _fail(code + " native clock increment is not 0.20s")
                return
            last_clock = sim.clock
            if loop_count % 1500 == 0:
                print("GP_PROGRESS code=%s lap=%d/%d sim_s=%.1f wall_s=%.1f" % [code, sim.lap, sim.lap_count, sim.clock, (Time.get_ticks_msec() - wall_started) / 1000.0])
            if loop_count % 100 == 0:
                var weather: Dictionary = sim.weather_snapshot()
                var track_temp: float = float(weather.get("track_c", 0.0))
                var grip: float = float(weather.get("grip_factor", 0.0))
                var rubber: float = float(weather.get("rubber", 0.0))
                min_temp = minf(min_temp, track_temp)
                max_temp = maxf(max_temp, track_temp)
                min_grip = minf(min_grip, grip)
                max_grip = maxf(max_grip, grip)
                max_rubber = maxf(max_rubber, rubber)
                went_wet = went_wet or float(weather.get("wetness_factor", 0.0)) > 0.12
                if not is_finite(track_temp) or not is_finite(grip) or track_temp < 4.9 or track_temp > 69.1 or grip < 0.54 or grip > 1.20:
                    _fail(code + " invalid track physics: " + str(weather))
                    return
            if loop_count % 100 == 0:
                for car in sim.cars:
                    var surface: float = float(car.get("tyre_surface_c", -1))
                    var core: float = float(car.get("tyre_core_c", -1))
                    var wear: float = float(car.get("wear", -1))
                    if not is_finite(surface) or not is_finite(core) or not is_finite(wear) or surface < 24.9 or surface > 145.1 or core < 24.9 or core > 140.1 or wear < -0.01 or wear > 100.01:
                        _fail(code + " invalid tyre on " + str(car.get("name", "unknown")))
                        return
        _write_result(sim, code, idx, wall_started, loop_count)
        if not sim.finished:
            _fail(code + " unfinished after 20000 simulated seconds (native 0.20s steps): lap=" + str(sim.lap))
            return
        if max_temp - min_temp < 0.15:
            _fail(code + " asphalt stayed static")
            return
        if min_grip == 10.0 or max_grip < min_grip or not sim.cars.size() == 24:
            _fail(code + " grip/grid invalid")
            return
        if MODES[idx] == "Chuva intensa" and not went_wet:
            _fail(code + " wet race never became wet")
            return
        var winner: Dictionary = sim.get_sorted()[0]
        var stop_count: int = 0
        for car in sim.cars:
            stop_count += int(car.get("stops", 0))
        for car in sim.cars:
            if int(car.get("driver_soul", {}).get("last_lap", 0)) < 1:
                _fail(code + " soul did not update")
                return
            if not bool(car.get("finished", false)) or bool(car.get("tyre_rule_violation", false)):
                _fail(code + " incomplete or illegal classification")
                return
        for car in sim.cars:
            var best: float = float(car.get("best_lap", 0.0))
            if not is_finite(best) or best < sim.base_lap * 0.70:
                _fail(code + " implausible best lap")
                return
        if stop_count > (90 if MODES[idx] == "Seco" else 120):
            _fail(code + " excessive pit-stop oscillation: " + str(stop_count))
            return
        print("GP_PASS code=%s laps=%d time=%.0f temp_min=%.1f temp_max=%.1f grip_min=%.3f grip_max=%.3f rubber_start=%.0f rubber_max=%.0f wet=%s stops=%d winner=%s" % [code, sim.lap_count, sim.clock, min_temp, max_temp, min_grip, max_grip, initial_rubber, max_rubber, str(went_wet), stop_count, str(winner["name"])])
        count += 1
    if (target == "" and count != 8) or (target != "" and count != 1):
        _fail("incorrect race count " + str(count))
        return
    print("APEX_0645_TEST_OK complete_grands_prix=%d" % count)
    quit(0)

func _fail(message: String) -> void:
    printerr("APEX_0645_TEST_FAIL " + message)
    quit(1)

func _write_result(sim, code: String, idx: int, started: int, ticks: int) -> void:
    var destination: String = "res://qa/06492/native_020/" + code + ".json"
    var file = FileAccess.open(destination, FileAccess.WRITE)
    if file == null:
        _fail("cannot save evidence " + destination)
        return
    file.store_string(JSON.stringify({"code": code, "seed": 6400 + idx, "weather_mode": MODES[idx],
        "engine": Engine.get_version_info()["string"], "step_seconds": 0.20, "ticks": ticks,
        "clock": sim.clock, "lap_count": sim.lap_count, "base_lap": sim.base_lap,
        "finished": sim.finished, "classification_validated": sim.finish_results_validated,
        "wall_seconds": (Time.get_ticks_msec() - started) / 1000.0,
        "cars": sim.get_sorted(), "pit_history": sim.get_pit_history(),
        "laps": sim.telemetry.lap_history, "events": sim.telemetry.event_history}, "  "))
    file.close()
