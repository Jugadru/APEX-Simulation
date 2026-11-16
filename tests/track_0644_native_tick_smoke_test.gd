extends SceneTree
## Native race tick, uses production RaceEngine.step (0.20s internal steps).
const RaceScript = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for item in season["tracks"]:
        if str(item.get("code", "")) == "BEL":
            track = item
    var sim = RaceScript.new(season["teams"], "Ferrari", 64044, {}, track, {})
    sim.configure_weather("Variável")
    sim.running = true
    var prior_c: float = float(sim.weather_snapshot().get("track_c",0.0))
    for i in range(160):
        sim.step(4.0)
        if sim.finished:
            break
    assert(sim.clock > 600.0 and sim.clock < 650.0)
    assert(sim.lap >= 3 and sim.lap <= 12)
    assert(absf(float(sim.weather_snapshot().get("track_c",0.0)) - prior_c) > 0.03)
    for driver in sim.cars:
        assert(float(driver.get("tyre_surface_c",0)) >= 25 and float(driver.get("tyre_surface_c",0)) <= 145)
        assert(float(driver.get("wear",0)) >= 0 and float(driver.get("wear",0)) <= 100)
    print("APEX_0644_NATIVE_TICK_OK 0.20s time steps, clock=%.1f, lap=%d, 24 cars" % [sim.clock, sim.lap])
    quit(0)
