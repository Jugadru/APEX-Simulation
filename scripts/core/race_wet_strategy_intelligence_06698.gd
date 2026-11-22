extends RefCounted
## APEX v0.6.6.9.8 — Wet Strategy Intelligence.
## Deterministic observation-only wet-weather nowcast. The weather simulator
## knows the future shower schedule; a strategist does NOT. Never call rain_at()
## or weather.forecast() from this module. No RNG, no car mutation.
## Coefficients are APEX gameplay approximations, not meteorological data.

const MAX_WATER_MM: float = 7.0
const WATER_REFERENCE_MM: float = 5.0
const STEPSIZE_S: float = 8.0
const PERSISTENCE_S: float = 520.0
const DRAINAGE := {"MAL":0.87, "BRA":0.98, "BEL":1.12, "GBR":1.16, "MON":0.92}
const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]

static func forecast(observed: Dictionary, horizon_seconds: float,
		track_code: String = "", strategist_level: int = 1) -> Dictionary:
	# Only public, present-tense observations are accepted. In particular
	# rain_probability is omitted: the legacy weather model derives it partly
	# from a hidden event schedule, which would create perfect-foresight AI.
	var horizon: float = clampf(horizon_seconds, 0.0, 1800.0)
	var line: float = clampf(float(observed.get("water_mm", 0.0)), 0.0, MAX_WATER_MM)
	var off: float = maxf(line, clampf(float(observed.get("off_line_water_mm", line)), 0.0, MAX_WATER_MM))
	var moisture: float = clampf(float(observed.get("surface_moisture", 0.0)), 0.0, 1.0)
	var rain_now: float = clampf(float(observed.get("rain_intensity", 0.0)), 0.0, 1.0)
	var air: float = clampf(float(observed.get("air_c", 20.0)), -10.0, 55.0)
	var wind: float = clampf(float(observed.get("wind", 8.0)), 0.0, 50.0)
	var drainage: float = float(DRAINAGE.get(track_code, 1.0))
	# A selected continuous-rain mode is an observable session condition.
	# Otherwise the current shower can decay or persist: no future showers
	# are assumed known to the strategist.
	var continuous: bool = str(observed.get("mode", "")) == "Chuva intensa"
	var elapsed: float = 0.0
	while elapsed + 0.000001 < horizon:
		var dt: float = minf(STEPSIZE_S, horizon - elapsed)
		var at: float = elapsed + dt * 0.5
		var rain: float = rain_now if continuous else rain_now * exp(-at / PERSISTENCE_S)
		var downpour: float = 0.0242 * pow(rain, 1.70)
		var sunlight: float = 1.0 - rain
		var evaporation: float = (0.00013 + maxf(0.0, air - 20.0) * 0.000012 + wind * 0.000009) * sunlight
		off = clampf(off + (downpour - drainage * 0.0023 * off - evaporation) * dt,
			0.0, MAX_WATER_MM)
		line = clampf(line + (downpour - drainage * 0.0023 * line -
			evaporation * 1.20 - line * 0.00085) * dt, 0.0, MAX_WATER_MM)
		line = minf(line, off)
		moisture = clampf(moisture + (rain * 0.0040 * (1.0 - moisture) -
			(0.00022 + sunlight * 0.00044) * moisture) * dt, 0.0, 1.0)
		elapsed += dt
	var level: float = clampf(line / WATER_REFERENCE_MM + moisture * 0.014, 0.0, 1.0)
	# Bands communicate unknown future rainfall instead of smuggling the
	# true seeded schedule into a seemingly probabilistic prediction.
	var prior: float = clampf(float(observed.get("climate_risk", 20.0)) / 100.0, 0.0, 1.0)
	var expertise: int = clampi(strategist_level, 0, 3)
	var spread: float = (0.045 + (horizon / 900.0) * (0.095 + prior * 0.095)
		+ rain_now * 0.045) * (1.08 - 0.07 * float(expertise))
	var lower: float = clampf(level - spread, 0.0, 1.0)
	var upper: float = clampf(level + spread, 0.0, 1.0)
	var rain_end: float = rain_now if continuous else rain_now * exp(-horizon / PERSISTENCE_S)
	return {
		"wetness_factor": level, "wetness": int(round(level * 100.0)),
		"water_mm": line, "off_line_water_mm": off,
		"surface_moisture": moisture, "rain_intensity": rain_end,
		"wetness_min": lower, "wetness_max": upper,
		"uncertainty": spread, "horizon_seconds": horizon,
		"forecast_source": "observacoes_atual", "kind": "nowcast imperfeito",
		"confidence": "BAIXA" if spread >= 0.22 else ("MODERADA" if spread >= 0.105 else "ALTA")
	}

static func review_plan(car: Dictionary, proposal: Dictionary, observed: Dictionary,
		ahead_three: Dictionary, ahead_six: Dictionary) -> Dictionary:
	# One conservative decision gate for *automatic* crossovers. Critical wear
	# and a physically wrong tyre must never be suppressed by uncertainty.
	var result: Dictionary = proposal.duplicate(true)
	var current: String = str(car.get("tire", ""))
	var chosen: String = str(proposal.get("compound", ""))
	var water_now: float = clampf(float(observed.get("wetness_factor", 0.0)), 0.0, 1.0)
	var lower: float = clampf(float(ahead_three.get("wetness_min", water_now)), 0.0, 1.0)
	var upper: float = clampf(float(ahead_three.get("wetness_max", water_now)), 0.0, 1.0)
	result["wet_strategy"] = {
		"source":"observacoes_atual", "confidence":str(ahead_three.get("confidence", "MODERADA")),
		"three_lap_range":[lower, upper],
		"six_lap_range":[float(ahead_six.get("wetness_min", water_now)),
			float(ahead_six.get("wetness_max", water_now))],
		"note":"Intervalo indicativo, não probabilidade calibrada nem conhecimento do futuro."
	}
	if not bool(proposal.get("pit_now", false)) or chosen == current:
		return result
	if bool(proposal.get("critical", false)) or float(car.get("wear", 0.0)) >= 78.0 \
			or float(proposal.get("life_laps", 99.0)) <= 1.2:
		return result
	if current in SLICKS and water_now >= 0.43:
		return result
	if current == "Chuva" and water_now <= 0.10:
		return result
	var threshold: float = -1.0
	if chosen == "Chuva":
		threshold = 0.81
	elif chosen == "Intermediário" and current in SLICKS:
		threshold = 0.17
	elif chosen in SLICKS and current in ["Intermediário", "Chuva"]:
		threshold = 0.10
	elif chosen == "Intermediário" and current == "Chuva":
		threshold = 0.70
	if threshold < 0.0 or lower > threshold or upper < threshold:
		return result
	result["pit_now"] = false
	result["deferred"] = true
	result["reason"] = "transicao climatica incerta; reavaliar agua observada na proxima volta"
	result["status"] = "AGUARDAR CONFIRMACAO DA PISTA"
	result["message"] = "%s | %s; previsao imperfeita e intervalo cruza a faixa de troca" % [
		str(result["status"]), str(result["reason"])]
	result["wet_strategy"]["deferred_crossover"] = true
	return result
