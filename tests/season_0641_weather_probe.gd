extends SceneTree
const Weather = preload("res://scripts/core/race_weather.gd")
func _initialize() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    for n in range(8):
        var t: Dictionary = data["tracks"][n]
        var seed: int = 321 + n * 7919
        var w = Weather.new()
        w.setup(t, seed, "Automático")
        var duration: float = float(t["base_lap"]) * float(t["laps"]) * 1.20
        var max_w: float = 0.0
        var max_rain: float = 0.0
        var wet_seconds: int = 0
        var flooded_seconds: int = 0
        var phases: int = 0
        var was_wet: bool = false
        var seconds: float = 0.0
        while seconds < duration:
            seconds += 4.0
            var state: Dictionary = w.advance(4.0, seconds, seconds/duration)
            var water: float = float(state["wetness_factor"])
            max_w = maxf(max_w, water)
            max_rain = maxf(max_rain, float(state["rain_intensity"]))
            if water >= 0.17:
                wet_seconds += 4
            if water >= 0.81:
                flooded_seconds += 4
            if water >= 0.17 and not was_wet:
                phases += 1
            was_wet = water >= 0.17
        print("WEATHER_0641 ", JSON.stringify({"gp": n+1,"code":t["code"],"max_water":snappedf(max_w,0.001),"max_rain":snappedf(max_rain,0.001),"wet_minutes":int(wet_seconds/60),"flood_minutes":int(flooded_seconds/60),"wet_phases":phases,"showers":w.rain_events.size(),"events":w.rain_events,"temp":w.base_temperature}))
    quit()
