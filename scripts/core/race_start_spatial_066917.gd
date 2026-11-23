extends RefCounted
## APEX v0.6.6.9.17 — Largada 2.0: first-corner congestion.
## Pure, deterministic addition to the existing 9.11 reaction/traction model.
## No RNG, instant position changes, lane teleports or invented collisions.
## Distances are APEX schematic circuit units, not measured FIA metres.

const StartV1 = preload("res://scripts/core/race_start_intelligence_066911.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
const CORNER_PHASE_SECONDS: float = 18.0
const EXIT_PROGRESS: float = 0.14
const LOOKAHEAD_UNITS: float = 26.0

## The closest car ahead in the SAME occupied corridor at this frozen tick.
## An adjacent, fully separated car does not produce a phantom brake demand.
static func headway_units(car: Dictionary, grid: Array, circuit_length: float) -> float:
	var progress: float = float(car.get("progress", 0.0))
	var lane: float = float(car.get("race_lane", 0.0))
	var nearest: float = INF
	for other in grid:
		if not other is Dictionary:
			continue
		if int(other.get("id", -1)) == int(car.get("id", -1)) \
				or bool(other.get("finished", false)) \
				or float(other.get("pit_left", 0.0)) > 0.0:
			continue
		# The first straight begins with negative grid progress; no modulo
		# wrap here, as a car behind the start line is NOT a lapped leader.
		var gap: float = (float(other.get("progress", 0.0)) - progress) * maxf(100.0, circuit_length)
		if gap > 0.0001 and gap < nearest \
				and absf(lane - float(other.get("race_lane", 0.0))) < Space.WIDTH - 0.04:
			nearest = gap
	return nearest

## A bounded positive pace cost as cars compress towards the first corner.
## The authoritative RaceSpace solver still enforces all safety corridors.
static func congestion_cost(car: Dictionary, elapsed_s: float, weather: Dictionary,
		grid: Array, circuit_length: float, first_sector_clearance: float) -> float:
	if elapsed_s < 0.0 or elapsed_s >= CORNER_PHASE_SECONDS \
			or float(car.get("progress", 0.0)) >= EXIT_PROGRESS:
		return 0.0
	var gap: float = headway_units(car, grid, circuit_length)
	if gap >= LOOKAHEAD_UNITS:
		return 0.0
	var density: float = clampf((LOOKAHEAD_UNITS - gap) / 22.0, 0.0, 1.0)
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var awareness: float = clampf(float(car.get("spatial_awareness", 80.0)), 40.0, 100.0)
	var risk: float = clampf(float(car.get("risk_tolerance", 55.0)), 0.0, 100.0)
	var narrowness: float = 1.0 - clampf(first_sector_clearance, 0.0, 1.0)
	var driver_caution: float = clampf(1.04 - (awareness - 75.0) * 0.004 +
			maxf(0.0, risk - 55.0) * wet * 0.004, 0.75, 1.35)
	var remaining_time: float = clampf(1.0 - elapsed_s / CORNER_PHASE_SECONDS, 0.0, 1.0)
	var remaining_road: float = clampf(1.0 -
			maxf(0.0, float(car.get("progress", 0.0))) / EXIT_PROGRESS, 0.0, 1.0)
	# Model coefficients are conservative gameplay estimates. Both dense
	# traffic and a narrow/wet approach INCREASE time cost, never add speed.
	return clampf(2.5 * density * (0.70 + 0.85 * narrowness) *
			(1.0 + 0.80 * wet) * driver_caution * remaining_time *
			remaining_road, 0.0, 5.0)

## Preserve the v9.11 reaction/traction curve exactly, then add congestion.
## Older replays bypass this service entirely through a sporting revision gate.
static func pace_cost(car: Dictionary, elapsed_s: float, weather: Dictionary,
		first_sector_clearance: float, grid: Array, circuit_length: float) -> float:
	return StartV1.pace_cost(car, elapsed_s, weather, first_sector_clearance) + \
			congestion_cost(car, elapsed_s, weather, grid, circuit_length,
					first_sector_clearance)
