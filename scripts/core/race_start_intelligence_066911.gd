extends RefCounted
## v0.6.6.9.11 — deterministic Race Start Intelligence 1.0.
## Pure launch-phase pace cost, not a position grant or an overtaking solver.
## Gameplay approximations: NOT measured FIA reaction times or tyre telemetry.
## Replays 021 and older continue to use race_launch_14.gd unchanged.

const TyreThermal = preload("res://scripts/core/race_tyre_thermal.gd")
const PHASE_SECONDS: float = 8.0

static func reaction_seconds(car: Dictionary) -> float:
	var skill: float = clampf(float(car.get("skill", 80.0)), 50.0, 100.0)
	var awareness: float = clampf(float(car.get("spatial_awareness", 80.0)), 40.0, 100.0)
	var risk: float = clampf(float(car.get("risk_tolerance", 55.0)), 0.0, 100.0)
	var soul: Dictionary = car.get("driver_soul", {})
	var confidence: float = clampf(float(soul.get("confidence", 0.55)), 0.0, 1.0)
	# Fast reactions reward skill/focus; higher risk shortens reaction but may
	# sacrifice traction (below). No separate draw from the race RNG.
	return clampf(0.18 + (100.0 - skill) * 0.0025 +
			(100.0 - awareness) * 0.0010 +
			(1.0 - confidence) * 0.060 -
			(risk - 55.0) * 0.0008, 0.16, 0.48)

static func pace_cost(car: Dictionary, elapsed_s: float, weather: Dictionary) -> float:
	if elapsed_s < 0.0 or elapsed_s >= PHASE_SECONDS:
		return 0.0
	var skill: float = clampf(float(car.get("skill", 80.0)), 50.0, 100.0)
	var awareness: float = clampf(float(car.get("spatial_awareness", 80.0)), 40.0, 100.0)
	var rating: float = clampf(float(car.get("car_rating", 80.0)), 50.0, 100.0)
	var risk: float = clampf(float(car.get("risk_tolerance", 55.0)), 0.0, 100.0)
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var grip: float = clampf(float(weather.get("grip_factor", 1.0)), 0.60, 1.15)
	var reaction: float = clampf(
			(reaction_seconds(car) + 0.55 - elapsed_s) / 0.70, 0.0, 1.0)
	var traction: float = pow(clampf(1.0 - elapsed_s / PHASE_SECONDS, 0.0, 1.0), 1.30)
	# Read the existing tyre temperature state; never generate private tyre
	# temperatures or replace the wet-tyre model in RacePerformance.
	var tyre: String = str(car.get("tire", "Médio"))
	var tyre_band: Array = TyreThermal.band(tyre)
	var surface_c: float = float(car.get("tyre_surface_c", 79.0))
	var cold: float = clampf((float(tyre_band[0]) - surface_c) / 30.0, 0.0, 1.0)
	# Aggressive drivers may gain on reaction but lose traction on low grip.
	# This is a trade-off, not a universal risk/speed bonus.
	var wheelspin: float = clampf((risk - 55.0) / 45.0, 0.0, 1.0) * (0.08 + 0.12 * wet)
	var grip_difficulty: float = clampf(1.0 + 0.38 * wet +
			maxf(0.0, 1.0 - grip) * 0.50 + cold * 0.12 + wheelspin,
			0.90, 1.75)
	var reaction_cost: float = (8.5 + (100.0 - skill) * 0.12 +
			(100.0 - awareness) * 0.08) * reaction
	var traction_cost: float = (22.0 - (rating - 80.0) * 0.16 -
			(skill - 80.0) * 0.09) * traction * grip_difficulty
	return clampf(reaction_cost + traction_cost, 0.0, 58.0)
