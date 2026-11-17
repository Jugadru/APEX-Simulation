extends SceneTree
## Run with: godot --headless --path . --script res://tests/core_0611_map_weather_smoke_test.gd
const WeatherScript = preload("res://scripts/core/race_weather.gd")
const MapScript = preload("res://scripts/track_map.gd")

func _initialize() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var spa: Dictionary = {}
    for track in season["tracks"]:
        if str(track["code"]) == "BEL":
            spa = track
    assert(not spa.is_empty())
    var scene_map = MapScript.new()
    get_root().add_child(scene_map)
    scene_map.set_track_data(spa)
    scene_map.set_view_mode(MapScript.MODE_MAP)
    assert(scene_map.route.size() > 100)
    var found_dynamic: bool = false
    for seed in range(10, 100):
        var weather = WeatherScript.new()
        weather.setup(spa, seed, "Automático")
        var a: int = weather.rain_risk_window(0, 900)
        var b: int = weather.rain_risk_window(1600, 900)
        if a != b:
            found_dynamic = true
            break
    assert(found_dynamic, "15-minute forecast still frozen")
    var dry = WeatherScript.new()
    dry.setup(spa, 42, "Seco")
    assert(dry.rain_risk_window(1400, 900) == 0)
    print("APEX 0.6.1.1 MAPA + PREVISAO MOVEL PASS")
    quit(0)
