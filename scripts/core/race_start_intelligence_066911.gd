extends RefCounted
## v0.6.6.9.11 — deterministic Race Start Intelligence 1.0.
## Pure, bounded refinements of Improvement 14's launch pace: no extra RNG,
## position bonus, movement impulse, teleport, new incident or pit action.
## No coefficients are FIA-measured telemetry; all are gameplay estimates.
## Historical 021 and older races still use race_launch_14.gd unchanged.

const LegacyLaunch = preload("res://scripts/core/race_launch_14.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
const TyreThermal = preload("res://scripts/core/race_tyre_thermal.gd")
const PHASE_SECONDS: float = LegacyLaunch.PHASE_SECONDS

static func reaction_seconds(car: Dictionary) -> float:
	var skill: float = clampf(float(car.get("skill", 80.0)), 50.0, 100.0)
	var awareness: float = clampf(float(car.get("spatial_awareness", 80.0)), 40.0, 100.0)
	var risk: float = clampf(float(car.get("risk_tolerance", 55.0)), 0.0, 100.0)
	var soul: Dictionary = car.get("driver_soul", {})
	var confidence: float = clampf(float(soul.get("confidence", 0.55)), 0.0, 1.0)
	return clampf(0.18 + (100.0 - skill) * 0.0025 +
			(100.0 - awareness) * 0.0010 +
			(1.0 - confidence) * 0.060 -
			(risk - 55.0) * 0.0008, 0.16, 0.48)

## Track-based mitigation for narrow first corners. The same first-sector
## geometry already constrains RaceSpace; no circuit name is hard-coded.
## Suppress only v9.11's incremental variation, not existing launch physics.
static func first_sector_clearance(track: Dictionary, shape: Dictionary) -> float:
	var narrowest: float = Space.MAX_LANE
	for index in range(17):
		narrowest = minf(narrowest, Space.lane_limit(track, float(index) * 0.01, shape))
	return clampf((narrowest - 1.70) / 0.40, 0.0, 1.0)

static func pace_cost(car: Dictionary, elapsed_s: float, weather: Dictionary,
		clearance: float = 1.0) -> float:
	if elapsed_s < 0.0 or elapsed_s >= PHASE_SECONDS:
		return 0.0
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var existing: float = LegacyLaunch.pace_cost(car, elapsed_s, wet)
	# Keep the established longitudinal envelope. The 9.11 personalities
	# change only the small decision-dependent reaction/traction residual,
	# limiting discontinuities that can disturb the narrow Monaco start grid.
	var awareness: float = clampf(float(car.get("spatial_awareness", 80.0)), 40.0, 100.0)
	var confidence: float = clampf(float((car.get("driver_soul", {}) as Dictionary).get("confidence", 0.55)), 0.0, 1.0)
	var risk: float = clampf(float(car.get("risk_tolerance", 55.0)), 0.0, 100.0)
	var grip: float = clampf(float(weather.get("grip_factor", 1.0)), 0.60, 1.15)
	var tyre: String = str(car.get("tire", "Médio"))
	var band: Array = TyreThermal.band(tyre)
	var cold: float = clampf((float(band[0]) - float(car.get("tyre_surface_c", 79.0))) / 30.0, 0.0, 1.0)
	var reaction: float = clampf((1.4 - elapsed_s) / 1.4, 0.0, 1.0)
	var traction: float = pow(clampf(1.0 - elapsed_s / PHASE_SECONDS, 0.0, 1.0), 1.30)
	# Reaction reflects confidence/spatial awareness; the risk advantage is
	# not free because it increases wheelspin on low-grip asphalt.
	var reaction_delta: float = ((0.55 - confidence) * 1.20 +
			(80.0 - awareness) * 0.014 -
			(risk - 55.0) * 0.008) * reaction
	var wheelspin: float = maxf(0.0, risk - 55.0) * (0.008 + wet * 0.016)
	var traction_delta: float = (cold * 0.50 +
			maxf(0.0, 1.0 - grip) * 1.00 + wheelspin) * traction
	return maxf(0.0, existing + clampf(clearance, 0.0, 1.0) * clampf(reaction_delta + traction_delta, -1.50, 1.50))
