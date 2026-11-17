extends SceneTree
const Dynamics = preload("res://scripts/core/race_track_dynamics.gd")
const Thermal = preload("res://scripts/core/race_tyre_thermal.gd")

func _initialize() -> void:
    var catalog: Dictionary = Dynamics.catalog()
    assert(catalog.get("tracks", {}).size() == 20)
    var state: Dictionary = {"track_c":32.0,"air_c":24.0,"wind":8.0,"sky":"Céu limpo","wetness_factor":0.0,"rain_intensity":0.0}
    var a = Dynamics.new(); var b = Dynamics.new()
    a.setup({"code":"BEL"}, state)
    b.setup({"code":"BEL"}, state)
    var before: float = a.rubber_fraction
    for i in range(100):
        a.advance(5.0, state, 24, 108.0)
        b.advance(5.0, state, 24, 108.0)
    assert(a.rubber_fraction > before)
    assert(absf(a.rubber_fraction - b.rubber_fraction) < 0.0000001)
    assert(absf(a.asphalt_c - b.asphalt_c) < 0.0000001)
    assert(a.grip_factor > 0.5 and a.grip_factor < 1.2)
    var dry_deposit: float = a.rubber_fraction
    state["wetness_factor"] = 0.82
    state["rain_intensity"] = 0.89
    state["sky"] = "Chuva forte"
    for i in range(200):
        a.advance(5.0, state, 24, 108.0)
    assert(a.rubber_fraction < dry_deposit)
    assert(a.asphalt_c < b.asphalt_c)
    for tyre in Thermal.BANDS.keys():
        var car: Dictionary = {"tire":tyre, "pace":"Atacar"}
        Thermal.reset(car,state)
        for i in range(400):
            Thermal.advance(car,state,a.characteristics,4.0,110.0)
        assert(float(car["tyre_surface_c"]) >= 25.0 and float(car["tyre_surface_c"]) <= 145.0)
        assert(float(car["tyre_core_c"]) >= 25.0 and float(car["tyre_core_c"]) <= 140.0)
        assert(float(car["thermal_wear_scale"]) >= 0.9 and float(car["thermal_wear_scale"]) <= 1.85)
    assert(float(Thermal.slick_inter_context("Intermediário", {"wetness_factor":0.0,"track_c":48.0})["wear_scale"]) > 1.0)
    assert(float(Thermal.slick_inter_context("Intermediário", {"wetness_factor":0.50,"track_c":48.0})["wear_scale"]) == 1.0)
    print("APEX_0644_UNIT_OK 20 profiles, deterministic heat/rubber, rain wash, six compounds, slick/inter crossover")
    quit(0)
