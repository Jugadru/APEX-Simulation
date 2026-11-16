extends SceneTree
## Run in Godot 4.7.2:
## godot --headless --path . --script res://tests/core_0551_wet_balance.gd
const WetPhysics = preload("res://scripts/core/race_wet_physics.gd")
const Strategy = preload("res://scripts/core/race_strategy.gd")

func _initialize() -> void:
    var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tyres_2012.json"))
    var specs: Dictionary = catalog["compounds"]
    var available: Array = ["Médio", "Duro", "Intermediário", "Chuva"]
    for water in [0.25, 0.40, 0.55, 0.65]:
        var inter_cost: float = float(specs["Intermediário"]["delta"]) + float(WetPhysics.modifier("Intermediário", water)["penalty"])
        var wet_cost: float = float(specs["Chuva"]["delta"]) + float(WetPhysics.modifier("Chuva", water)["penalty"])
        assert(inter_cost < wet_cost, "Inter should be quicker at light/moderate wetness")
    for water in [0.85, 0.90, 0.95, 1.0]:
        var inter_cost: float = float(specs["Intermediário"]["delta"]) + float(WetPhysics.modifier("Intermediário", water)["penalty"])
        var wet_cost: float = float(specs["Chuva"]["delta"]) + float(WetPhysics.modifier("Chuva", water)["penalty"])
        var gain: float = inter_cost - wet_cost
        assert(gain > 0.0 and gain < 2.5, "W advantage should be modest")
        assert(gain * 8.0 < 20.0, "No unrealistic 70 second gain in eight laps")
    var car: Dictionary = {"tire":"Intermediário", "stint_laps":3, "laps_done":4, "pace":"Normal", "wear":10.0}
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor":0.95}) == "Chuva")
    car["tire"] = "Chuva"
    assert(Strategy.pit_choice(car, 44, available, specs, {"wetness_factor":0.55}) == "Intermediário")
    print("APEX v0.5.5.1 OK — tyre penalties and AI strategy cross-over")
    quit(0)
