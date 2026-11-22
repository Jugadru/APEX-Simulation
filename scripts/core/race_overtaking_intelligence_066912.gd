extends RefCounted
## APEX v0.6.6.9.12 — Overtaking Intelligence 1.0.
## Pure, deterministic pre-commit judgement; the RaceSpace corridor solver
## exclusively owns movement, collisions and sporting positions.
## Distances/thresholds are schematic gameplay estimates, not FIA telemetry.
const WIDTH: float = 2.95
const THIRD_CAR_WINDOW_M: float = 13.0
const EARLY_DECISION_M: float = 11.5

static func lane_occupied(attacker: Dictionary, defender: Dictionary, grid: Array,
		goal: float, circuit_length_m: float) -> bool:
	var attacker_id: int = int(attacker.get("id", -1))
	var defender_id: int = int(defender.get("id", -1))
	for other in grid:
		if not other is Dictionary:
			continue
		var id: int = int(other.get("id", -1))
		if id == attacker_id or id == defender_id or bool(other.get("finished", false)) \
				or float(other.get("pit_left", 0.0)) > 0.0:
			continue
		# Signed modular separation avoids treating turn-one neighbours
		# across the timing line as if they were one whole lap apart.
		var delta: float = fposmod(float(other.get("progress", 0.0)) -
				float(attacker.get("progress", 0.0)) + 0.5, 1.0) - 0.5
		if absf(delta) * maxf(100.0, circuit_length_m) > THIRD_CAR_WINDOW_M:
			continue
		if absf(goal - float(other.get("race_lane", 0.0))) < WIDTH - 0.04:
			return true
	return false

static func refine(attacker: Dictionary, defender: Dictionary, grid: Array,
		gap_m: float, advantage_s: float, usable_lane: float,
		circuit_length_m: float, weather: Dictionary, base_tactic: Dictionary) -> Dictionary:
	var tactic: Dictionary = base_tactic.duplicate()
	# No new tackle when the original physics/driver judgement says NO.
	if not bool(tactic.get("commit", false)):
		return tactic
	# Never change the attack lane in overlap or during an existing duel;
	# the authoritative corridor solver still handles third-car safety.
	if gap_m <= EARLY_DECISION_M or str(attacker.get("combat_state", "clear")) in [
			"preparing", "attacking", "duel"]:
		return tactic
	var awareness: float = clampf(float(attacker.get("spatial_awareness", 80.0)), 0.0, 100.0)
	var wear: float = clampf(float(attacker.get("wear", 0.0)), 0.0, 100.0)
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	# A marginal speed advantage is not worth an unplanned second manoeuvre
	# in rain or on heavily worn tyres. No pace or grip modifiers are created.
	var reserve_s: float = clampf(wet * 0.035 +
			maxf(0.0, 77.0 - awareness) * 0.0012 +
			maxf(0.0, wear - 72.0) * 0.0009, 0.0, 0.10)
	if advantage_s <= float(tactic.get("threshold_s", 0.12)) + reserve_s:
		tactic["commit"] = false
		tactic["overtaking_reason"] = "insufficient_racecraft_margin"
		return tactic

	var chosen: float = clampf(float(tactic.get("attack_goal", 0.0)),
			-usable_lane, usable_lane)
	if not lane_occupied(attacker, defender, grid, chosen, circuit_length_m):
		tactic["overtaking_reason"] = "clear_corridor"
		return tactic
	# Switching sides is only legitimate before committing laterally. Never
	# cross a rival from an already occupied side in response to a late blocker.
	var current: float = float(attacker.get("race_lane", 0.0))
	var alternative: float = -chosen
	var defensive_line: float = float(tactic.get("defend_goal",
			defender.get("race_lane", 0.0)))
	var required_margin: float = -0.004 + wet * 0.08 + maxf(0.0, 70.0 - awareness) * 0.002
	var alternative_margin: float = absf(alternative - defensive_line) - WIDTH
	if absf(current) <= 0.30 and absf(alternative - chosen) > 0.10 \
			and alternative_margin >= required_margin \
			and not lane_occupied(attacker, defender, grid, alternative, circuit_length_m):
		tactic["attack_goal"] = alternative
		tactic["side"] = "right" if alternative > 0.0 else "left"
		tactic["margin_m"] = alternative_margin
		tactic["overtaking_reason"] = "early_clear_side"
		return tactic
	tactic["commit"] = false
	tactic["blocked"] = true
	tactic["overtaking_reason"] = "third_car_corridor_blocked"
	return tactic
