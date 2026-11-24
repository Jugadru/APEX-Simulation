extends RefCounted
## v0.6.6.1 Driver Dynamics: pure, deterministic tactical decisions.
## This does not move cars. The v0.6.5.5 corridor solver remains authoritative.
## Numerical values are gameplay approximations, not FIA-measured behavior.

const CAR_WIDTH := 2.95
const GripDefense = preload("res://scripts/core/race_defense_grip_06688.gd")
const Soul3 = preload("res://scripts/core/race_driver_soul_06694.gd")

static func choose(attacker: Dictionary, defender: Dictionary,
		gap_m: float, advantage_s: float, usable_lane: float,
		track: Dictionary, weather: Dictionary, soul3_enabled: bool = false, following_enabled: bool = false) -> Dictionary:
	var risk: float = clampf(float(attacker.get("risk_tolerance", 55.0)), 0.0, 100.0)
	var awareness: float = clampf(float(attacker.get("spatial_awareness", 80.0)), 0.0, 100.0)
	var aggression: float = clampf(float(defender.get("defense_aggression", 55.0)), 0.0, 100.0)
	var defender_skill: float = clampf(float(defender.get("skill", 80.0)), 0.0, 100.0)
	var attacker_skill: float = clampf(float(attacker.get("skill", 80.0)), 0.0, 100.0)
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var wear_delta: float = float(attacker.get("wear", 0.0)) - float(defender.get("wear", 0.0))
	# The pace model already includes DRS, KERS, tyres and weather. This is a
	# modest judgement threshold, not another artificial speed advantage.
	var required: float = clampf(0.12 +
			(defender_skill - attacker_skill) * 0.009 +
			aggression * 0.0009 +
			maxf(0.0, wear_delta) * 0.0016 +
			wet * (0.09 + (100.0 - awareness) * 0.0015) -
			(risk - 55.0) * 0.0015, 0.04, 0.58)
	# The 9.4 personality influences commitment only, not lap-time or grip.
	# Older sporting replays retain the exact 9.3 decision formula.
	if soul3_enabled:
		required = clampf(required + Soul3.attack_bias(attacker, weather), 0.04, 0.58)
	var defend_lane: float = float(defender.get("race_lane", 0.0))
	var previous_defender: int = int(defender.get("race_defending_against", -1))
	var same_duel: bool = previous_defender == int(attacker.get("id", -2))
	# A defender may make ONE early move. After the attacker is within
	# 1.8 car lengths, line changes are prohibited, even with high aggression.
	var can_move: bool = gap_m > 11.5 and gap_m < 36.0
	var grip_defense: Dictionary = GripDefense.evaluate(defender, gap_m, weather)
	var defensive_move: bool = bool(grip_defense["early_move"])
	if same_duel and absf(float(defender.get("race_defense_line", 0.0))) > 0.10:
		defend_lane = clampf(float(defender.get("race_defense_line")), -usable_lane, usable_lane)
	elif defensive_move and absf(defend_lane) < 0.20:
		# Stable, driver-specific preference is a tie breaker, not an RNG roll.
		var facing: float = signf(float(attacker.get("race_lane", 0.0)))
		if absf(facing) < 0.1:
			facing = 1.0 if int(defender.get("id", 0)) % 2 == 0 else -1.0
		defend_lane = facing * minf(0.72, usable_lane * 0.32) * clampf(aggression / 65.0, 0.5, 1.0)
	# Attacker holds an established side instead of oscillating every tick.
	var current_lane: float = float(attacker.get("race_lane", 0.0))
	var preferred: float = signf(current_lane) if absf(current_lane) > 0.30 else -signf(defend_lane)
	if absf(preferred) < 0.1:
		preferred = -1.0 if int(attacker.get("id", 0)) % 2 == 0 else 1.0
	var side: float = preferred
	var goal: float = side * usable_lane
	var margin: float = absf(goal - defend_lane) - CAR_WIDTH
	# A previous attacking side may be impossible at a narrow turn. An early
	# alternative is permitted; neither side may cross an occupied car.
	var following_aligned: bool = following_enabled and gap_m >= 6.4 - 0.00001 and absf(current_lane-float(defender.get("race_lane",0.0))) <= 0.8 and str(attacker.get("combat_state","clear")) not in ["preparing","attacking","duel"]
	if margin < 0.12 and ((gap_m > 11.5 and absf(current_lane) < 0.30) or following_aligned):
		var alternate: float = -side * usable_lane
		if absf(alternate - defend_lane) > absf(goal - defend_lane):
			goal = alternate
			side = -side
			margin = absf(goal - defend_lane) - CAR_WIDTH
	var overlap: bool = gap_m <= 11.5
	var prepared: bool = float(attacker.get("attack_charge", 0.0)) >= clampf(
			0.64 + aggression * 0.002 + wet * 0.15 - (risk - 55.0) * 0.002, 0.48, 1.02)
	var good_gap: bool = margin >= -0.004 + wet * 0.08 + maxf(0.0, 70.0 - awareness) * 0.002
	var eligible: bool = CombatZone(attacker, track)
	var commit: bool = eligible and prepared and advantage_s > required and good_gap
	# Very wet tracks and worn tyres amplify judgement errors without adding
	# any stochastic crash or invented speed boost.
	return {"commit": commit, "defense": defensive_move or same_duel,
		"defend_goal": defend_lane, "attack_goal": goal,
		"side": "right" if side > 0.0 else "left",
		"margin_m": margin, "threshold_s": required,
		"overlap": overlap, "advantage_s": advantage_s,
		"blocked": eligible and prepared and advantage_s > required and not good_gap,
		"defense_caution": float(grip_defense["caution"]),
		"defense_effective_aggression": float(grip_defense["effective_aggression"])}

static func CombatZone(car: Dictionary, track: Dictionary) -> bool:
	# Keep a single source for circuit passing zones.
	return preload("res://scripts/core/race_combat.gd").in_passing_zone(float(car.get("progress", 0.0)), track)
