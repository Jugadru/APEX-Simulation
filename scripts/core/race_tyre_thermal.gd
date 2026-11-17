extends RefCounted
## Deterministic tyre-core/surface, graining and blistering for 2012 compounds.
## Temperatures and tuning coefficients are fictional gameplay models, NOT
## Pirelli measurements. Physics state persists on each car across ticks.
const BANDS := {
    "Supermacio":[88.0, 106.0], "Macio":[87.0, 108.0],
    "Médio":[84.0, 109.0], "Duro":[81.0, 111.0],
    "Intermediário":[65.0, 91.0], "Chuva":[57.0, 84.0]
}

static func band(name: String) -> Array:
    return BANDS.get(name, [82.0, 108.0])

static func reset(car: Dictionary, weather_now: Dictionary) -> void:
    var t: float = float(weather_now.get("track_c", 30.0))
    var name: String = str(car.get("tire", "Médio"))
    var wet: bool = name in ["Intermediário", "Chuva"]
    car["tyre_surface_c"] = clampf(t * 0.45 + (49.0 if wet else 60.0), 35.0, 103.0)
    car["tyre_core_c"] = float(car["tyre_surface_c"]) - 4.0
    car["tyre_graining"] = 0.0
    car["tyre_blistering"] = 0.0
    car["thermal_time_penalty"] = 0.0
    car["thermal_wear_scale"] = 1.0
    car["tyre_heat"] = 0.0

static func advance(car: Dictionary, weather_now: Dictionary, characteristics: Dictionary, dt: float, target_lap: float) -> Dictionary:
    var name: String = str(car.get("tire", "Médio"))
    var b: Array = band(name)
    var low: float = float(b[0]); var high: float = float(b[1])
    var wet: float = clampf(float(weather_now.get("wetness_factor",0.0)),0.0,1.0)
    var asphalt: float = float(weather_now.get("track_c",32.0))
    var load: float = float(characteristics.get("lateral_load",1.0))
    var traction: float = float(characteristics.get("traction",1.0))
    var pace: String = str(car.get("pace","Normal"))
    var intensity: float = 1.0 if pace == "Normal" else (1.27 if pace == "Atacar" else 0.82)
    var is_wet: bool = name in ["Intermediário","Chuva"]
    var dry_on_wet: float = wet * (12.0 if is_wet else 34.0)
    var target_surface: float = 53.0 + asphalt * 0.88 + (intensity - 1.0) * 16.0 + (load - 1.0) * 13.0 + (traction - 1.0) * 6.0 - dry_on_wet
    if is_wet:
        target_surface -= 6.0
        # Grooved tyres overheat when the racing line dries.
        target_surface += maxf(0.0, 0.23 - wet) * 28.0
    var current_surface: float = float(car.get("tyre_surface_c", 79.0))
    var current_core: float = float(car.get("tyre_core_c", 76.0))
    var surface: float = lerpf(current_surface, target_surface, 1.0 - exp(-maxf(dt,0.0) / 55.0))
    var core: float = lerpf(current_core, surface - 3.5, 1.0 - exp(-maxf(dt,0.0) / 170.0))
    surface = clampf(surface, 25.0, 145.0)
    core = clampf(core, 25.0, 140.0)
    var too_cold: float = maxf(0.0, low - surface)
    var too_hot: float = maxf(0.0, surface - high)
    var graining_gain: float = too_cold * 0.00019 if too_cold > 0.3 else -0.00023
    var graining: float = clampf(float(car.get("tyre_graining",0.0)) + dt * graining_gain, 0.0, 1.0)
    var blister_gain: float = too_hot * 0.00020 if too_hot > 0.3 else -0.00010
    var blistering: float = clampf(float(car.get("tyre_blistering",0.0)) + dt * blister_gain, 0.0, 1.0)
    # Mild cold/hot costs, plus progressive damage if kept outside the window.
    var penalty: float = minf(4.5, too_cold * 0.036 + too_hot * 0.050 + graining * 1.7 + blistering * 2.1)
    var multiplier: float = clampf(1.0 + too_hot * 0.018 + graining * 0.28 + blistering * 0.42 + too_cold * 0.004, 0.90, 1.85)
    var result: Dictionary = {"tyre_surface_c": surface, "tyre_core_c": core,
        "tyre_graining": graining, "tyre_blistering": blistering,
        "thermal_time_penalty": penalty, "thermal_wear_scale": multiplier,
        "tyre_heat": clampf((surface - 65.0) / 70.0, 0.0, 1.0)}
    car.merge(result,true)
    return result

static func slick_inter_context(compound: String, weather_now: Dictionary) -> Dictionary:
    # The existing wet-physics crossover remains the principal wet model.
    # This *small* modifier supplies thermal dry-inter degradation and wet grip.
    var w: float = float(weather_now.get("wetness_factor",0.0))
    var track_c: float = float(weather_now.get("track_c", 30.0))
    var dry_fraction: float = clampf((0.24 - w) / 0.24,0.0,1.0)
    if compound == "Intermediário":
        return {"extra_penalty": maxf(0.0,track_c - 32.0) * 0.017 * dry_fraction,
            "wear_scale": 1.0 + maxf(0.0,track_c - 35.0) * 0.020 * dry_fraction}
    if compound == "Chuva":
        return {"extra_penalty": maxf(0.0,track_c - 31.0) * 0.022 * dry_fraction,
            "wear_scale": 1.0 + maxf(0.0,track_c - 32.0) * 0.026 * dry_fraction}
    return {"extra_penalty": maxf(0.0,w - 0.28) * 1.4,
        "wear_scale": 1.0}
