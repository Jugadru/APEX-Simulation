extends SceneTree
## Godot 4.7.2:
## godot --headless --path . --script res://tests/core_0552_tyre_ai_smoke_test.gd
const Strategy = preload("res://scripts/core/race_strategy.gd")
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tyres_2012.json"))
    var specs: Dictionary = data["compounds"]
    var available: Array = ["Médio", "Duro", "Intermediário", "Chuva"]
    var car: Dictionary = {"tire": "Chuva", "wear": 99.0, "stint_laps": 19, "laps_done": 14,
        "pace": "Normal", "track_wear_factor": 1.0, "pit_request": false, "pit_left": 0.0}
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.92}) == "Chuva",
        "FULL WET at 99% must receive another W in heavy rain")
    car["wear"] = 100.0
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.92}) == "Chuva",
        "FULL WET at 100% must not be stranded")
    car["wear"] = 66.0
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.92}) == "Chuva",
        "Preventive W stop should happen within 2 laps of the actual wet tyre cliff")
    car["wear"] = 20.0
    car["stint_laps"] = 4
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.92}) == "",
        "Fresh W should not pit unnecessarily in stable rain")
    car["tire"] = "Intermediário"
    car["wear"] = 98.0
    car["stint_laps"] = 18
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.52}) == "Intermediário",
        "Worn I on intermediate track should receive a new I")
    car["tire"] = "Chuva"
    car["wear"] = 97.0
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.12}) in ["Médio", "Duro"],
        "Worn W on a drying track must switch to one of the nominated slicks")
    car["pit_request"] = true
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.92}) == "",
        "Already ordered stop must never be replaced")
    car["pit_request"] = false
    car["laps_done"] = 43
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor": 0.92}) == "",
        "Never order a pit after the final available pit entrance")

    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var belgium: Dictionary = {}
    for circuit in season["tracks"]:
        if str(circuit.get("code", "")) == "BEL":
            belgium = circuit
            break
    assert(not belgium.is_empty(), "2012 Belgium data missing")
    var race = RaceScript.new(season["teams"], "Ferrari", 37, {}, belgium, {})
    race.configure_weather("Chuva intensa")
    var ai: Dictionary = {}
    for driver in race.cars:
        if str(driver["team"]) != "Ferrari":
            ai = driver
            break
    assert(not ai.is_empty())
    race.weather.wetness = 0.94
    race.weather.state = race.weather._make_state(180.0, 0.3)
    ai["tire"] = "Chuva"
    ai["wear"] = 98.0
    ai["stint_laps"] = 19
    ai["laps_done"] = 12
    race._request_ai_pit(ai, true)
    assert(bool(ai["pit_request"]) and str(ai["pit_target"]) == "Chuva",
        "Integration: AI must request fresh W on heavy rain")
    var first_target: String = str(ai["pit_target"])
    race._request_ai_pit(ai, true)
    assert(str(ai["pit_target"]) == first_target,
        "Emergency check must not replace an existing pit order")
    print("APEX v0.5.5.2 PASS: I/W wear, safety net, weather compound selection and engine integration")
    quit(0)
