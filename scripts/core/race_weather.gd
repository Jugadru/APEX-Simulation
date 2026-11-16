extends RefCounted
## APEX 0.6.4.3: independent rainfall, asphalt moisture and on/off racing-line standing water.
## This is NOT extracted from F1 2020/F1 Manager, nor official historical session odds.
const PROFILES := ["Automático", "Seco", "Variável", "Chuva intensa"]
# Approximate per-event gameplay priors, NOT measured historical probabilities.
# Each track is independent; tropical and changeable venues have higher risk.
const CLIMATES := {
    "AUS": [22.0, 0.17], "MAL": [31.0, 0.47], "CHN": [20.0, 0.27],
    "BHR": [31.0, 0.035], "ESP": [25.0, 0.15], "MON": [23.0, 0.22],
    "CAN": [21.0, 0.24], "EUR": [28.0, 0.11], "GBR": [18.0, 0.42],
    "GER": [22.0, 0.28], "HUN": [29.0, 0.21], "BEL": [19.0, 0.44],
    "ITA": [27.0, 0.14], "SIN": [29.0, 0.42], "JPN": [24.0, 0.33],
    "KOR": [24.0, 0.25], "IND": [30.0, 0.06], "UAE": [30.0, 0.025],
    "USA": [24.0, 0.15], "BRA": [25.0, 0.37]
}

var track_code: String = "BEL"
var seed: int = 42
var profile: String = "Automático"
var base_temperature: float = 21.0
var climate_chance: float = 0.2
# Legacy race strategy reads wetness_factor/wetness; wetness remains a
# backward-compatible *effective* racing-line water fraction, not rain intensity.
var wetness: float = 0.0
var standing_water_mm: float = 0.0 # non-racing-line average; gameplay millimeters
var racing_line_water_mm: float = 0.0 # tire traffic accelerates line drainage
var surface_moisture: float = 0.0 # residual film persists after puddles vanish
const WATER_REFERENCE_MM: float = 5.0
const MAX_WATER_MM: float = 7.0
const TRACK_DRAINAGE := {"MAL": 0.87, "BRA": 0.98, "BEL": 1.12, "GBR": 1.16, "MON": 0.92}
var state: Dictionary = {}
var rain_events: Array[Dictionary] = []
var race_seconds: float = 5600.0

static func climate_profile(code: String) -> Dictionary:
    var config: Array = CLIMATES.get(code, [24.0, 0.20])
    return {"temperature_c": float(config[0]), "chance": float(config[1]),
        "source": "estimativa para balanceamento do Apex; nao oficial"}

func setup(track_data: Dictionary, race_seed: int, selected_profile: String = "Automático") -> void:
    seed = race_seed
    profile = selected_profile if PROFILES.has(selected_profile) else "Automático"
    track_code = str(track_data.get("code", "BEL"))
    var config: Dictionary = climate_profile(track_code)
    base_temperature = float(config["temperature_c"]) + float(posmod(seed, 7) - 3) * 0.3
    climate_chance = float(config["chance"])
    race_seconds = maxf(900.0, float(track_data.get("base_lap", 110.0)) * float(track_data.get("laps", 50)))
    # Rain and water are different quantities. Persistent water is set only in
    # the explicit heavy / variable profiles; seeded automatic starts dry.
    standing_water_mm = 2.65 if profile == "Chuva intensa" else (0.32 if profile == "Variável" else 0.0)
    racing_line_water_mm = 2.45 if profile == "Chuva intensa" else (0.28 if profile == "Variável" else 0.0)
    surface_moisture = 0.95 if profile == "Chuva intensa" else (0.31 if profile == "Variável" else 0.0)
    wetness = _effective_wetness(racing_line_water_mm, surface_moisture)
    rain_events.clear()
    var weather_rng := RandomNumberGenerator.new()
    weather_rng.seed = _weather_seed(seed, track_code)
    if profile == "Variável":
        _create_showers(weather_rng, 2, 0.48, 0.92)
    elif profile == "Automático" and weather_rng.randf() < climate_chance:
        var number_of_showers: int = 2 if climate_chance >= 0.40 and weather_rng.randf() < 0.27 else 1
        _create_showers(weather_rng, number_of_showers, 0.28, 0.75)
    # Dry races have no hidden forced rain. Rain events are sampled once per GP.
    state = _make_state(0.0, 0.0)

func _weather_seed(initial_seed: int, code: String) -> int:
    # Fixed cross-platform mixing; independent of RNG used by cars and incidents.
    var value: int = posmod(initial_seed, 2147483647) + 1
    for i in range(code.length()):
        value = posmod(value * 131 + code.unicode_at(i) + 37, 2147483647)
    return maxi(1, value)

func _create_showers(generator: RandomNumberGenerator, count: int, min_power: float, max_power: float) -> void:
    for i in range(count):
        var duration: float = generator.randf_range(420.0, minf(1850.0, race_seconds * 0.34))
        var begin: float = generator.randf_range(race_seconds * 0.04, maxf(race_seconds * 0.06, race_seconds - duration - 120.0))
        var intensity: float = generator.randf_range(min_power, max_power)
        rain_events.append({"start": begin, "duration": duration, "power": intensity})

func rain_at(seconds: float) -> float:
    if profile == "Seco":
        return 0.0
    if profile == "Chuva intensa":
        return clampf(0.74 + 0.04 * sin(seconds / 600.0), 0.0, 1.0)
    var current: float = 0.0
    for event in rain_events:
        var start: float = float(event["start"])
        var duration: float = float(event["duration"])
        if seconds >= start and seconds <= start + duration:
            var portion: float = (seconds - start) / duration
            var shape: float = pow(sin(PI * portion), 0.55)
            current = maxf(current, shape * float(event["power"]))
    return clampf(current, 0.0, 1.0)

# mm/s proxy: independent accumulation from precipitation, drainage and drying.
# All coefficients are original APEX gameplay values, not measured hydrology.
func _integrate_water(levels: Dictionary, dt: float, seconds: float) -> Dictionary:
    var rain: float = rain_at(seconds)
    var wind: float = 6.0 + 4.5 * absf(sin(seconds / 900.0 + 0.7))
    var temperature: float = base_temperature + 1.7 * sin(seconds / 1000.0 + 0.4)
    var sun: float = 1.0 - clampf(maxf(rain, climate_chance * 0.35), 0.0, 1.0)
    var drainage: float = float(TRACK_DRAINAGE.get(track_code, 1.0))
    var downpour: float = 0.0242 * pow(rain, 1.70)
    var evaporation: float = (0.00013 + maxf(0.0, temperature - 20.0) * 0.000012 + wind * 0.000009) * sun
    var off_line: float = clampf(float(levels.get("off", 0.0)) +
        (downpour - drainage * 0.0023 * float(levels.get("off", 0.0)) - evaporation) * dt,
        0.0, MAX_WATER_MM)
    var on_line: float = clampf(float(levels.get("line", 0.0)) +
        (downpour - drainage * 0.0023 * float(levels.get("line", 0.0)) -
        evaporation * 1.20 - float(levels.get("line", 0.0)) * 0.00085) * dt,
        0.0, MAX_WATER_MM)
    # Film on asphalt is stored independently; it can stay damp after water
    # disappears. The racing line dries faster than the untraveled line.
    var moisture: float = clampf(float(levels.get("moisture", 0.0)) +
        (rain * 0.0040 * (1.0 - float(levels.get("moisture", 0.0))) -
        (0.00022 + sun * 0.00044) * float(levels.get("moisture", 0.0))) * dt,
        0.0, 1.0)
    return {"off": off_line, "line": minf(off_line, on_line), "moisture": moisture}

func _effective_wetness(line_mm: float, moisture: float) -> float:
    return clampf(line_mm / WATER_REFERENCE_MM + moisture * 0.014, 0.0, 1.0)

func advance(dt: float, seconds: float, race_fraction: float) -> Dictionary:
    var next: Dictionary = _integrate_water({"off": standing_water_mm,
        "line": racing_line_water_mm, "moisture": surface_moisture}, dt, seconds - dt * 0.5)
    standing_water_mm = float(next["off"])
    racing_line_water_mm = float(next["line"])
    surface_moisture = float(next["moisture"])
    wetness = _effective_wetness(racing_line_water_mm, surface_moisture)
    state = _make_state(seconds, race_fraction)
    return state.duplicate(true)

func forecast(start_seconds: float, ahead_seconds: float) -> Dictionary:
    # Same integrator and same seeded rain schedule as advance; read-only.
    var levels: Dictionary = {"off": standing_water_mm, "line": racing_line_water_mm,
        "moisture": surface_moisture}
    var elapsed: float = 0.0
    var distance: float = maxf(0.0, ahead_seconds)
    while elapsed < distance:
        var dt: float = minf(8.0, distance - elapsed)
        levels = _integrate_water(levels, dt, start_seconds + elapsed + 0.5 * dt)
        elapsed += dt
    var result_water: float = _effective_wetness(float(levels["line"]), float(levels["moisture"]))
    return {"wetness_factor": result_water, "wetness": int(round(result_water * 100.0)),
        "water_mm": float(levels["line"]), "off_line_water_mm": float(levels["off"]),
        "surface_moisture": float(levels["moisture"]),
        "rain_intensity": rain_at(start_seconds + distance),
        "water_trend_mm": float(levels["line"]) - racing_line_water_mm,
        "horizon_seconds": distance, "kind": "previsão hidrológica experimental"}

func snapshot() -> Dictionary:
    return state.duplicate(true)

func rain_risk_window(seconds: float, ahead_seconds: float = 900.0) -> int:
    # Rolling, approximate weather forecast. The event schedule is seeded at
    # setup, but the on-screen estimate is NOT the static per-circuit climate
    # prior. A dry forecast remains uncertain and changes over time.
    if profile == "Seco":
        return 0
    if profile == "Chuva intensa":
        return 99
    var window: float = maxf(60.0, ahead_seconds)
    var chance: float = climate_chance * (0.20 + 0.16 * (0.5 + 0.5 * sin(seconds / 740.0 + float(posmod(seed, 37)) * 0.13)))
    # For an imminent or ongoing shower the likelihood increases as the
    # leading edge approaches the forecast interval.
    for event in rain_events:
        var begin: float = float(event["start"])
        var finish: float = begin + float(event["duration"])
        if finish < seconds or begin > seconds + window:
            continue
        var lead: float = maxf(0.0, begin - seconds)
        var proximity: float = 1.0 - lead / window
        var power: float = float(event["power"])
        chance = maxf(chance, (0.55 + 0.39 * proximity) * (0.55 + 0.45 * power))
    if rain_at(seconds) >= 0.18:
        chance = maxf(chance, 0.94)
    return clampi(int(round(chance * 100.0)), 0, 99)

func _make_state(seconds: float, race_fraction: float) -> Dictionary:
    var rain: float = rain_at(seconds)
    var max_approaching: float = rain
    for delta in [300.0, 600.0, 900.0]:
        max_approaching = maxf(max_approaching, rain_at(seconds + delta))
    var expected_risk: int = rain_risk_window(seconds, 900.0)
    var cloud: float = clampf(maxf(maxf(climate_chance * 0.4, rain * 0.91), max_approaching * 0.25) + 0.12, 0.0, 1.0)
    var air: float = base_temperature + 1.7 * sin(seconds / 1000.0 + 0.4)
    var asphalt: float = air + 4.0 + (1.0 - cloud) * 8.5
    var rubber: float = clampf(0.08 + race_fraction * 0.72, 0.0, 0.95)
    var grip: float = clampf(0.55 + rubber * 0.25 - wetness * 0.44 - surface_moisture * 0.025, 0.1, 0.95)
    var sky_label: String = "Chuva forte" if rain >= 0.66 else ("Chuva" if rain >= 0.18 else ("Nublado" if cloud >= 0.44 else "Céu limpo"))
    var track_state: String = "Encharcada" if wetness >= 0.72 else ("Molhada" if wetness >= 0.20 else ("Úmida" if surface_moisture >= 0.12 or wetness >= 0.045 else "Seca"))
    return {"sky": sky_label, "track_state": track_state,
        "air_c": air, "track_c": asphalt, "rain_probability": expected_risk,
        "rain_intensity": rain, "wetness": int(round(wetness * 100.0)),
        "wetness_factor": wetness,
        "water_mm": racing_line_water_mm, "off_line_water_mm": standing_water_mm,
        "surface_moisture": surface_moisture, "surface_moisture_percent": int(round(surface_moisture * 100.0)),
        "rain_mm_h_estimated": 3600.0 * 0.0242 * pow(rain, 1.70),
        "rubber": int(round(rubber * 100.0)),
        "grip": "Alto" if grip >= 0.72 else ("Normal" if grip >= 0.52 else "Baixo"),
        "grip_factor": grip, "wind": 6.0 + 4.5 * absf(sin(seconds / 900.0 + 0.7)),
        "drs_allowed": wetness < 0.34 and rain < 0.45, "mode": profile,
        "climate_risk": int(round(climate_chance * 100.0)), "track_code": track_code,
        "forecast_minutes": 15, "forecast_kind": "estimativa móvel",
        "rain_expected_15min": expected_risk}
