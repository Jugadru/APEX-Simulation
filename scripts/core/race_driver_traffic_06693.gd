extends RefCounted
## v0.6.6.9.3 — passive deterministic blue-flag awareness.
## The existing RaceSpace corridor solver still owns all movement/positions.
## No RNG, speed modifiers, visual state or commands are created here.

static func evaluate(follower: Dictionary, obstacle: Dictionary,
		gap_m: float, available_lane_m: float, weather: Dictionary,
		passing_lane_m: float = 0.0) -> Dictionary:
	var lap_delta: float = float(follower.get("progress", 0.0)) - float(obstacle.get("progress", 0.0))
	# This is physical circuit proximity, not classification order. A car
	# nearly one lap ahead must still catch the obstacle before blue flags.
	var lapping: bool = lap_delta >= 0.95
	var active: bool = lapping and gap_m > 0.0 and gap_m <= 38.0 \
			and not bool(obstacle.get("finished", false)) \
			and float(obstacle.get("pit_left", 0.0)) <= 0.0
	# Driver awareness affects required advance notice, not outright pace.
	# Wet asphalt demands greater margin and nobody changes lane at overlap.
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var awareness: float = clampf(float(obstacle.get("spatial_awareness", 80.0)), 0.0, 100.0)
	var safe_gap: float = 12.0 + 6.0 * wet + (100.0 - awareness) * 0.025
	var can_yield: bool = active and gap_m >= safe_gap and available_lane_m >= 2.94
	var current: float = float(obstacle.get("race_lane", 0.0))
	# Make room on the OPPOSITE side of the attacker-selected passing lane.
	# The fallback only applies if the attacker has no side preference yet.
	var preferred: float = -signf(passing_lane_m) if absf(passing_lane_m) > 0.10 else (
			-1.0 if float(follower.get("race_lane", 0.0)) >= 0.0 else 1.0)
	var target_lane: float = clampf(preferred * minf(available_lane_m, 1.25),
			-available_lane_m, available_lane_m)
	return {"lapping": active, "yield_early": can_yield,
			"yield_lane": target_lane, "hold_lane": current}
