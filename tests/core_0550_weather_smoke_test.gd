extends SceneTree
## APEX 0.5.5.0 — Godot 4.7.2 headless weather/race regression.
## Run: godot --headless --path . --script res://tests/core_0550_weather_smoke_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")
const WeatherScript = preload("res://scripts/core/race_weather.gd")
const WetPhysics = preload("res://scripts/core/race_wet_physics.gd")
const PerformanceScript = preload("res://scripts/core/race_performance.gd")
const StrategyScript = preload("res://scripts/core/race_strategy.gd")

func _initialize() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var spa: Dictionary = {}
    for item in season["tracks"]:
        if str(item.get("code", "")) == "BEL":
            spa = item
            break
    assert(not spa.is_empty())
    var levels: Dictionary = {"Motor": 0, "Asa": 0, "Chassi": 0}
    var first = RaceScript.new(season["teams"], "Ferrari", 42, levels, spa)
    var twin = RaceScript.new(season["teams"], "Ferrari", 42, levels, spa)
    var dry = RaceScript.new(season["teams"], "Ferrari", 42, levels, spa)
    first.configure_weather("Variável")
    twin.configure_weather("Variável")
    dry.configure_weather("Seco")
    assert(first.available_pit_compounds() == ["Médio", "Duro", "Intermediário", "Chuva"])
    var target_id: int = int(first.player_cars()[0]["id"])
    first.order_pit(target_id, "Intermediário")
    twin.order_pit(target_id, "Intermediário")
    assert(bool(first.player_cars()[0]["pit_request"]))
    assert(first.weather_snapshot() == twin.weather_snapshot())
    var first_weather = WeatherScript.new()
    first_weather.setup(spa, 42, "Chuva intensa")
    assert(float(first_weather.snapshot()["wetness_factor"]) > 0.4)
    first.running = true
    twin.running = true
    dry.running = true
    for i in range(350):
        first.step(4.0)
        twin.step(4.0)
        dry.step(4.0)
        assert(first.weather_snapshot() == twin.weather_snapshot())
    for i in range(first.cars.size()):
        var a: Dictionary = first.cars[i]
        var b: Dictionary = twin.cars[i]
        assert(is_equal_approx(float(a["progress"]), float(b["progress"])))
        assert(is_equal_approx(float(a["wear"]), float(b["wear"])))
        assert(int(a["stops"]) == int(b["stops"]))
    assert(first.telemetry.weather_history.size() > 10)
    assert(dry.weather_snapshot()["wetness"] == 0)
    assert(first.weather_snapshot()["mode"] == "Variável")
    var w: Dictionary = first.weather_snapshot()
    assert(int(w["wetness"]) >= 0 and int(w["wetness"]) <= 100)
    var slick_penalty: float = float(WetPhysics.modifier("Médio", 0.55)["penalty"])
    var inter_penalty: float = float(WetPhysics.modifier("Intermediário", 0.55)["penalty"])
    assert(slick_penalty > inter_penalty + 8.0)
    assert(float(WetPhysics.modifier("Chuva", 0.90)["penalty"]) < float(WetPhysics.modifier("Intermediário", 0.90)["penalty"]))
    var car: Dictionary = first.player_cars()[0].duplicate(true)
    car["tire"] = "Médio"
    car["stint_laps"] = 3
    car["wear"] = 20.0
    var choice: String = StrategyScript.pit_choice(car, 44, first.available_pit_compounds(), first.tyre_specs, {"wetness_factor": 0.40})
    assert(choice == "Intermediário")
    var ctx: Dictionary = {"gap": 8.0, "lap": 6, "race_laps": 44,
        "base_lap": first.base_lap, "upgrades": levels, "player_car": false,
        "tyre_specs": first.tyre_specs, "tyre_track_severity": 1.0,
        "weather": {"wetness_factor": 0.65, "rain_intensity": 0.6, "drs_allowed": false}}
    var wet_slick: Dictionary = PerformanceScript.evaluate(car, ctx)
    car["tire"] = "Intermediário"
    var wet_inter: Dictionary = PerformanceScript.evaluate(car, ctx)
    assert(float(wet_slick["target"]) > float(wet_inter["target"]) + 7.0)
    var exported: Dictionary = first.telemetry.export_files("user://apex_test_weather", {"weather": first.weather_snapshot()})
    assert(bool(exported.get("ok", false)))
    assert(exported["files"].size() == 6) # 5 CSV + JSON manifest
    print("APEX v0.5.5.0 WEATHER SMOKE OK: deterministic, rain tyres, AI, lap times, logs")
    quit(0)
