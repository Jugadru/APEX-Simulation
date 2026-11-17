extends RefCounted
## APEX Track Dynamics 0644: single, deterministic asphalt/rubber/grip state.
## The input weather model owns rainfall and wetness; this module does NOT
## rewrite it, consume RNG, or control race timing / scheduled pit stops.
const DATA_PATH := "res://data/track_physics_2012.json"
var characteristics: Dictionary = {}
var asphalt_c: float = 29.0
var rubber_fraction: float = 0.08
var grip_factor: float = 1.0
var code: String = "BEL"
var elapsed: float = 0.0

static func catalog() -> Dictionary:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func profile_for(track_code: String) -> Dictionary:
    var tracks: Dictionary = catalog().get("tracks", {})
    return (tracks.get(track_code, {}) as Dictionary).duplicate(true)

func setup(track_data: Dictionary, initial_weather: Dictionary) -> void:
    code = str(track_data.get("code", "BEL"))
    characteristics = profile_for(code)
    if characteristics.is_empty():
        characteristics = {"abrasion":1.0,"lateral_load":1.0,"surface_grip":1.0,
            "drainage":1.0,"traction":1.0,"rubber_deposition":1.0}
    elapsed = 0.0
    asphalt_c = clampf(float(initial_weather.get("track_c", 32.0)), 5.0, 69.0)
    rubber_fraction = 0.08
    grip_factor = 1.0

func advance(dt: float, weather_now: Dictionary, active_car_count: int, lap_seconds: float) -> Dictionary:
    var w: float = clampf(float(weather_now.get("wetness_factor", 0.0)), 0.0, 1.0)
    var rain: float = clampf(float(weather_now.get("rain_intensity", 0.0)), 0.0, 1.0)
    var air: float = float(weather_now.get("air_c", 23.0))
    var wind: float = float(weather_now.get("wind", 8.0))
    # A slow thermal response; rain, cloud, wind and traffic contribute independently.
    # Simulation parameters, NOT a measured solar-radiation equation.
    var cloudy: float = 0.86 if str(weather_now.get("sky", "")) in ["Chuva", "Chuva forte"] else (0.56 if str(weather_now.get("sky", "")) == "Nublado" else 0.17)
    var sunlight: float = (1.0 - cloudy) * 17.0
    var heat_load: float = 1.4 * float(active_car_count) / 24.0
    var target: float = air + sunlight + heat_load - 11.5 * w - 5.5 * rain - wind * 0.16
    target = clampf(maxf(air - 3.0, target), 8.0, 68.0)
    var relaxation: float = 1.0 - exp(-maxf(0.0, dt) / 420.0)
    asphalt_c = clampf(lerpf(asphalt_c, target, relaxation), 5.0, 69.0)
    # Rubber follows driven kilometres, rain removes deposits; no RNG.
    var deposition: float = 0.0000023 * float(active_car_count) * maxf(0.0, dt) / maxf(0.70, lap_seconds / 110.0)
    rubber_fraction = clampf(rubber_fraction + deposition * float(characteristics.get("rubber_deposition",1.0)) * (1.0 - 0.75 * w) - (rain * 0.000037 + w * 0.000003) * maxf(dt, 0.0) / maxf(0.75, float(characteristics.get("drainage", 1.0))), 0.02, 0.85)
    # Grip is dimensionless, near 1 for a dry green track, and lower in water.
    var base: float = float(characteristics.get("surface_grip", 1.0))
    var thermal_surface: float = 1.0 - 0.0018 * absf(asphalt_c - 36.0)
    var water_residual: float = clampf(float(weather_now.get("surface_moisture", 0.0)), 0.0, 1.0)
    grip_factor = clampf(base * thermal_surface + rubber_fraction * 0.125 - 0.19 * w - 0.016 * water_residual, 0.55, 1.19)
    elapsed += maxf(dt, 0.0)
    return snapshot(weather_now)

func snapshot(weather_now: Dictionary) -> Dictionary:
    var g: float = grip_factor
    return {"track_c": asphalt_c, "rubber": int(round(rubber_fraction * 100.0)),
        "rubber_factor": rubber_fraction, "grip_factor": g,
        "grip": "Alto" if g >= 1.055 else ("Normal" if g >= 0.90 else "Baixo"),
        "surface_abrasion": float(characteristics.get("abrasion", 1.0)),
        "surface_lateral_load": float(characteristics.get("lateral_load", 1.0)),
        "surface_traction": float(characteristics.get("traction", 1.0)),
        "surface_drainage": float(characteristics.get("drainage", 1.0)),
        "track_dynamics_version": "0644", "wetness_factor": float(weather_now.get("wetness_factor",0.0))}
