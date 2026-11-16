extends SceneTree
## Execute in Godot: godot --headless --path . --script res://tests/core_0610_weather_and_speed_test.gd
const WeatherScript = preload("res://scripts/core/race_weather.gd")
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var all_tracks: Array = data["tracks"]
    assert(all_tracks.size() == 20)
    var codes: Dictionary = {}
    var rainy_by_code: Dictionary = {}
    for track in all_tracks:
        var code: String = str(track["code"])
        assert(not codes.has(code))
        codes[code] = true
        var rainy: int = 0
        for trial in range(180):
            var probe = WeatherScript.new()
            probe.setup(track, 1000 + trial, "Automático")
            if probe.rain_events.size() > 0:
                rainy += 1
            var twin = WeatherScript.new()
            twin.setup(track, 1000 + trial, "Automático")
            assert(probe.rain_events == twin.rain_events)
            assert(probe.snapshot() == twin.snapshot())
            var dry = WeatherScript.new()
            dry.setup(track, trial, "Seco")
            assert(dry.rain_events.is_empty())
            assert(dry.rain_at(150.0) == 0.0)
            assert(dry.rain_at(2500.0) == 0.0)
            assert(dry.rain_at(5000.0) == 0.0)
        rainy_by_code[code] = rainy
    assert(int(rainy_by_code["MAL"]) > int(rainy_by_code["BHR"]))
    assert(int(rainy_by_code["BEL"]) > int(rainy_by_code["UAE"]))
    var tracks: Array = data["tracks"]
    var seed_value: int = 42
    var campaign_rainy: int = 0
    for index in range(tracks.size()):
        var w = WeatherScript.new()
        var track: Dictionary = tracks[index]
        w.setup(track, seed_value + index * 7919, "Automático")
        if not w.rain_events.is_empty():
            campaign_rainy += 1
        var sim = RaceScript.new(data["teams"], "Ferrari", 42, {}, track, {})
        assert(str(sim.track.get("code", "")) == str(track["code"]))
        assert(int(sim.lap_count) == int(track["laps"]))
    assert(campaign_rainy < 18)
    print("APEX 0.6.1 GODOT WEATHER CHECK OK: %d/20 GP rainy in sampled campaign, all 20 circuits distinct" % campaign_rainy)
    print("Weather event totals over 180 seeds per circuit: %s" % str(rainy_by_code))
    quit(0)
