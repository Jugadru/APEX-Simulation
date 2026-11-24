extends RefCounted
## v0.6.6.9.17.2 — competitive 2012 start, pure sporting geometry.
## Never awards a position or a velocity impulse. RaceSpace alone resolves
## forward movement and legal corridor occupancy.
const START_WINDOW_SECONDS: float = 24.0
const FIRST_CORNER_EXIT: float = 0.12
const GRID_ROW_UNITS: float = 9.0
const GRID_STAGGER_UNITS: float = 4.1
const GRID_LANE: float = 2.92
const MIN_DUAL_LANE: float = 2.90
const LANE_CLEARANCE: float = 2.95

static func supported(initial_lane_limit: float) -> bool:
	# In Monaco-like narrows, a physical two-column grid would clip models
	# into the same road corridor. Keep old single-file spacing there.
	return initial_lane_limit >= MIN_DUAL_LANE

static func slot(index: int, length: float, initial_lane_limit: float) -> Dictionary:
	var safe_length: float = maxf(100.0, length)
	if not supported(initial_lane_limit):
		return {"progress": -maxf(0.0018, 6.6 / safe_length) * float(index),
			"lane": 0.0, "dual": false}
	var row: int = index / 2
	var column: int = index % 2
	var distance: float = float(row) * GRID_ROW_UNITS + float(column) * GRID_STAGGER_UNITS
	return {"progress": -distance / safe_length,
		"lane": (-1.0 if column == 0 else 1.0) * minf(GRID_LANE, initial_lane_limit),
		"dual":true}

static func active(elapsed_s: float, progress: float) -> bool:
	return elapsed_s >= 0.0 and elapsed_s < START_WINDOW_SECONDS \
		and progress < FIRST_CORNER_EXIT

static func refine_tactic(car: Dictionary, rival: Dictionary,
		gap: float, advantage: float, width: float, weather: Dictionary,
		tactic: Dictionary, elapsed_s: float) -> Dictionary:
	if not active(elapsed_s, float(car.get("progress", 0.0))) \
			or not supported(width) or gap <= 0.0 or gap >= 38.0 \
			or bool(tactic.get("commit", false)):
		return tactic
	var wet: float = clampf(float(weather.get("wetness_factor",0.0)),0.0,1.0)
	var risk: float = clampf(float(car.get("risk_tolerance",55.0)),0.0,100.0)
	var awareness: float = clampf(float(car.get("spatial_awareness",80.0)),0.0,100.0)
	var charge: float = float(car.get("attack_charge",0.0))
	var threshold: float = float(tactic.get("threshold_s",0.12))
	# The existing DriverDynamics decision still owns pace/skill judgement;
	# this only opens a legal first-corner passing WINDOW in a clear width.
	if charge < 0.58 + 0.20 * wet or \
			advantage <= threshold + 0.02 + 0.12 * wet + \
			maxf(0.0, 70.0-awareness) * 0.002:
		return tactic
	var current: float = float(car.get("race_lane",0.0))
	var defender: float = float(rival.get("race_lane",0.0))
	var goal: float = current
	if absf(goal-defender) < LANE_CLEARANCE:
		# Crossing to the other corridor must begin early, never while noses
		# overlap. RaceSpace/Oversaking still check any THIRD car.
		if gap < 11.5: return tactic
		goal = (-width if defender >= 0.0 else width)
	var margin: float = absf(goal-defender) - LANE_CLEARANCE
	if margin < 0.0: return tactic
	var decision: Dictionary = tactic.duplicate()
	decision["commit"] = true
	decision["attack_goal"] = goal
	decision["side"] = "right" if goal > 0.0 else "left"
	decision["margin_m"] = margin
	decision["overtaking_reason"] = "first_corner_clear_corridor"
	return decision
