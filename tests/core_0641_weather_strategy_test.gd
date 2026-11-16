extends SceneTree
## v0.6.4.1: regression for automatic hydrology and unsafe crossover gates.
const Weather = preload("res://scripts/core/race_weather.gd")
const AIDirector = preload("res://scripts/core/race_ai_director.gd")
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        printerr("APEX 0641 FAIL: ", message)
func run() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var tyres: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tyres_2012.json"))
    var specs: Dictionary = tyres["compounds"]
    var limits: Dictionary = {"MAL":[0.65, 0.96], "CHN":[0.18, 0.37], "ESP":[0.0, 0.19]}
    for idx in [1, 2, 4]:
        var track: Dictionary = season["tracks"][idx]
        var simulator = Weather.new()
        simulator.setup(track, 321 + idx * 7919, "Automático")
        var max_water: float = 0.0
        var elapsed: float = 0.0
        var duration: float = float(track["base_lap"]) * float(track["laps"]) * 1.2
        while elapsed < duration:
            elapsed += 4.0
            var state: Dictionary = simulator.advance(4.0, elapsed, elapsed/duration)
            max_water = maxf(max_water, float(state["wetness_factor"]))
        var code: String = str(track["code"])
        var bounds: Array = limits[code]
        check(max_water >= float(bounds[0]) and max_water <= float(bounds[1]),
            "%s rain scenario expected wetness %.2f..%.2f, got %.3f" % [code,float(bounds[0]),float(bounds[1]),max_water])
        print("APEX 0641 WEATHER GP ", code," max_water=",snappedf(max_water,0.001))
    # Explicit heavy-rain option must still reach wet-tyre conditions.
    var malaysia: Dictionary = season["tracks"][1]
    var heavy = Weather.new()
    heavy.setup(malaysia, 42, "Chuva intensa")
    var heavy_max: float = 0.0
    for j in range(200):
        var state: Dictionary = heavy.advance(4.0, float(j+1)*4.0, 0.2)
        heavy_max = maxf(heavy_max, float(state["wetness_factor"]))
    check(heavy_max >= 0.81, "Heavy-rain option remains flooded")
    # Forecast obeys the exact same rainfall/drainage integration as real track.
    var forecast_eligible = Weather.new()
    forecast_eligible.setup(malaysia, 8240, "Automático")
    var sec: float = 0.0
    while sec < 3000.0:
        sec += 4.0
        forecast_eligible.advance(4.0, sec, 0.5)
    var expected: Dictionary = forecast_eligible.forecast(sec, 360.0)
    for j in range(90):
        sec += 4.0
        forecast_eligible.advance(4.0, sec, 0.55)
    check(absf(float(expected["wetness_factor"]) - float(forecast_eligible.wetness)) <= 0.04,
        "Forecast and true rain integration stay synchronized")
    # A soaked circuit must not order an early switch from full-wet to inters
    # simply because the forecast will be dry several laps later.
    var example: Dictionary = {"tire":"Chuva", "wear":16.0,"stint_laps":8,"laps_done":19,
        "pace":"Normal","track_wear_factor":0.9,"last_pit_exit_lap":9,
        "used_tires":["Chuva"],"pit_request":false,"pit_left":0.0,
        "interval":1.8}
    var wet_now: Dictionary = {"wetness_factor":0.93,"rain_intensity":0.05}
    var wet_3: Dictionary = {"wetness_factor":0.08}
    var wet_6: Dictionary = {"wetness_factor":0.0}
    var state_wet: Dictionary = AIDirector.plan(example, 56,
        ["Médio","Duro","Intermediário","Chuva"],specs,wet_now,wet_3,wet_6,21.8,false)
    check(not bool(state_wet["pit_now"]) or str(state_wet["compound"]) == "Chuva",
        "Full wets protected against an early switch on standing water")
    # When tyres are genuinely exhausted, no cooldown may strand a driver.
    example["wear"] = 98.0
    var emergency: Dictionary = AIDirector.plan(example, 56,
        ["Médio","Duro","Intermediário","Chuva"],specs,wet_now,wet_3,wet_6,21.8,false)
    check(bool(emergency["pit_now"]), "Critical wear still allows an urgent stop")
    if failures.is_empty():
        print("APEX 0641 WEATHER / AI PASS: climate, forecast, unsafe crossover, emergency wear")
        quit(0)
    else:
        print("APEX 0641 WEATHER / AI FAIL ",failures)
        quit(1)
