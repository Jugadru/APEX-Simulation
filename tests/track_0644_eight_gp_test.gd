extends SceneTree
## Eight complete headless GPs, 8s integration steps for batch test speed.
## Production step() remains at its unchanged 0.20s resolution.
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
        while not sim.finished and loop_count < 2500:
            sim._advance(8.0)
            loop_count += 1
            if sim.clock <= last_clock:
                _fail(code + " clock did not progress")
                return
            last_clock = sim.clock
            if loop_count % 80 == 0:
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
                if track_temp < 4.9 or track_temp > 69.1 or grip < 0.54 or grip > 1.20:
                    _fail(code + " invalid track physics: " + str(weather))
                    return
            if loop_count % 400 == 0:
                for car in sim.cars:
                    var surface: float = float(car.get("tyre_surface_c", -1))
                    var core: float = float(car.get("tyre_core_c", -1))
                    var wear: float = float(car.get("wear", -1))
                    if is_nan(surface) or is_nan(core) or surface < 24.9 or surface > 145.1 or core < 24.9 or core > 140.1 or wear < -0.01 or wear > 100.01:
                        _fail(code + " invalid tyre on " + str(car.get("name", "unknown")))
                        return
        if not sim.finished:
            _fail(code + " unfinished after 20000 simulated seconds (8s test steps): lap=" + str(sim.lap))
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
        if stop_count > (90 if MODES[idx] == "Seco" else 120):
            _fail(code + " excessive pit-stop oscillation: " + str(stop_count))
            return
        print("GP_PASS code=%s laps=%d time=%.0f temp_min=%.1f temp_max=%.1f grip_min=%.3f grip_max=%.3f rubber_start=%.0f rubber_max=%.0f wet=%s stops=%d winner=%s" % [code, sim.lap_count, sim.clock, min_temp, max_temp, min_grip, max_grip, initial_rubber, max_rubber, str(went_wet), stop_count, str(winner["name"])])
        count += 1
    if (target == "" and count != 8) or (target != "" and count != 1):
        _fail("incorrect race count " + str(count))
        return
    print("APEX_0644_TEST_OK complete_grands_prix=%d" % count)
    quit(0)

func _fail(message: String) -> void:
    printerr("APEX_0644_TEST_FAIL " + message)
    quit(1)
