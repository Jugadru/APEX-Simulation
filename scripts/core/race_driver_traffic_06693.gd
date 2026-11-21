extends RefCounted
## v0.6.6.9.3: deterministic blue-flag awareness for physical traffic.
## No RNG, no speed boost, no sporting position writes.
## A lapping driver has more completed distance than the slower car immediately
## ahead on the physical circuit. The ordinary corridor solver stays authoritative.
static func evaluate(follower: Dictionary, obstacle: Dictionary,
		gap_m: float, available_lane_m: float, weather: Dictionary) -> Dictionary:
	var lap_delta: float = float(follower.get("progress", 0.0)) - float(obstacle.get("progress", 0.0))
	var lapping: bool = lap_delta >= 0.95
	var active: bool = lapping and gap_m > 0.0 and gap_m <= 38.0 			and not bool(obstacle.get("finished", false)) and float(obstacle.get("pit_left", 0.0)) <= 0.0
	# Do not order a lateral move during overlap or where a car cannot fit.
	# Wetness demands more advance warning; the lane solver still checks third cars.
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var safe_gap: float = 12.0 + 6.0 * wet
	var can_yield: bool = active and gap_m >= safe_gap and available_lane_m >= 2.94
	var current: float = float(obstacle.get("race_lane", 0.0))
	var preferred: float = -1.0 if float(follower.get("race_lane", 0.0)) >= 0.0 else 1.0
	# The yielding car moves only a little, preserving a predictable approach.
	var target_lane: float = clampf(preferred * minf(available_lane_m, 1.25),
			-available_lane_m, available_lane_m)
	return {"lapping": active, "yield_early": can_yield,
			"yield_lane": target_lane, "hold_lane": current}
