extends RefCounted
## Core 2 Race Combat — state-based overtaking, deterministic by construction.
## Race position is still a scalar along the track. This is not wheel-to-wheel
## physical collision/trajectory simulation; passing zones are gameplay proxies.

const CLEAR := "clear"
const CLOSING := "closing"
const PREPARING := "preparing"
const ATTACKING := "attacking"
const DUEL := "duel"
const DEFENDING := "defending"
const RECOVERING := "recovering"
const BattleGeometry = preload("res://scripts/core/race_battle_geometry.gd")

const MIN_FOLLOW_DISTANCE := 0.00076  # Fraction of a lap; ~0.08s at 105s/lap.
const ATTACK_READY := 1.15
const DUEL_SECONDS := 1.25

static func find_ahead(order: Array, progress: float, own_id: int = -1) -> Variant:
	var candidate: Variant = null
	for rival in order:
		if int(rival.get("id", -1)) == own_id:
			continue
		if float(rival["progress"]) > progress and (candidate == null or float(rival["progress"]) < float(candidate["progress"])):
			candidate = rival
	return candidate

static func in_passing_zone(progress: float, track: Dictionary) -> bool:
	var fraction: float = fposmod(progress, 1.0)
	var zones: Array = track.get("overtake_zones", [])
	if zones.is_empty():
		# Explicitly schematic until all circuit-specific passing zones exist.
		zones = [[0.09, 0.24], [0.43, 0.57], [0.77, 0.91]]
	for zone in zones:
		if zone is Array and zone.size() >= 2:
			if fraction >= float(zone[0]) and fraction <= float(zone[1]):
				return true
	return false

static func advance(car: Dictionary, prev: float, proposed: float, ahead: Variant,
		base_lap: float, self_lap: float, ahead_lap: float, dt: float,
		track: Dictionary) -> Dictionary:
	var previous_cooldown: float = float(car.get("combat_cooldown", 0.0))
	var remaining_cooldown: float = maxf(0.0, previous_cooldown - dt)
	car["combat_cooldown"] = remaining_cooldown
	if previous_cooldown > 0.0 and remaining_cooldown <= 0.0:
		car["combat_pass_pending"] = false
	var charge: float = float(car.get("attack_charge", 0.0))
	var duel_time: float = float(car.get("combat_duel_time", 0.0))
	var last_target: int = int(car.get("combat_target_id", -1))
	var result: Dictionary = {"progress": proposed, "event": "", "defender_id": -1}
	if ahead == null or bool(ahead.get("finished", false)) or float(ahead.get("pit_left", 0.0)) > 0.0:
		car["combat_state"] = RECOVERING if remaining_cooldown > 0.0 else CLEAR
		car["combat_target_id"] = -1
		car["combat_duel_time"] = 0.0
		car["attack_charge"] = maxf(0.0, charge - dt * 0.24)
		return result

	var target_id: int = int(ahead["id"])
	if last_target != target_id:
		duel_time = 0.0
		charge = minf(charge, 0.40)
	car["combat_target_id"] = target_id
	var gap: float = maxf(0.0, (float(ahead["progress"]) - prev) * base_lap)
	var advantage: float = ahead_lap - self_lap
	# Defensive confidence incorporates driver skill and tyre wear, without RNG.
	var defensive_strength: float = clampf((float(ahead.get("skill", 80)) - float(car.get("skill", 80))) * 0.011
		+ (float(car.get("wear", 0.0)) - float(ahead.get("wear", 0.0))) * 0.003, -0.25, 0.25)
	var needed_advantage: float = 0.12 + maxf(0.0, defensive_strength)
	var close_enough: bool = gap <= 2.0
	if close_enough and advantage > 0.04 and remaining_cooldown <= 0.0:
		charge = minf(2.5, charge + dt * clampf(0.20 + advantage * 0.20, 0.20, 0.62))
	else:
		charge = maxf(0.0, charge - dt * 0.22)
	car["attack_charge"] = charge
	# Predict the rival at the END of this tick. Comparing to its previous
	# position would artificially freeze the following car behind it.
	var predicted_ahead: float = float(ahead["progress"]) + dt / maxf(1.0, ahead_lap)
	var collision_gap: float = predicted_ahead - proposed
	if remaining_cooldown > 0.0:
		car["combat_state"] = RECOVERING
	elif close_enough and charge >= ATTACK_READY and advantage > needed_advantage:
		car["combat_state"] = PREPARING
	elif close_enough:
		car["combat_state"] = CLOSING
	else:
		car["combat_state"] = CLEAR
	if collision_gap > MIN_FOLLOW_DISTANCE * 1.35:
		car["combat_duel_time"] = 0.0
		return result
	if remaining_cooldown > 0.0 or advantage <= needed_advantage or charge < ATTACK_READY or not in_passing_zone(prev, track):
		car["combat_duel_time"] = 0.0
		result["progress"] = maxf(prev, minf(proposed, predicted_ahead - MIN_FOLLOW_DISTANCE))
		return result
	# A passing attempt can only succeed after a sustained battle. While
	# parallel, the following car is kept just behind in the scalar model.
	if duel_time <= 0.0:
		result["event"] = "attack"
		car["combat_attempts"] = int(car.get("combat_attempts", 0)) + 1
	duel_time += dt
	car["combat_duel_time"] = duel_time
	car["combat_state"] = ATTACKING if duel_time < DUEL_SECONDS else DUEL
	result["defender_id"] = target_id
	if duel_time < DUEL_SECONDS:
		result["progress"] = maxf(prev, minf(proposed, predicted_ahead - MIN_FOLLOW_DISTANCE * 0.40))
		return result
	# Before resolving a pass, test whether two approximate car widths fit
	# on the chosen side of this corner. No scripted incidents or random rolls.
	var geometry: Dictionary = BattleGeometry.evaluate(car, ahead, track)
	car["combat_last_side"] = str(geometry["side"])
	car["combat_last_margin_m"] = float(geometry["margin_m"])
	var outcome: String = str(geometry["outcome"])
	car["combat_duel_time"] = 0.0
	car["attack_charge"] = 0.0
	car["combat_state"] = RECOVERING
	if outcome != "clear":
		car["combat_cooldown"] = 3.5 if outcome == "contact" else 1.6
		car["combat_pass_pending"] = false
		result["event"] = outcome
		result["side"] = str(geometry["side"])
		result["margin_m"] = float(geometry["margin_m"])
		result["progress"] = maxf(prev, minf(proposed, predicted_ahead - MIN_FOLLOW_DISTANCE))
		# Time loss is applied over following physics ticks, never by
		# teleporting the car backwards on the circuit.
		car["combat_hesitation_s"] = maxf(float(car.get("combat_hesitation_s", 0.0)), float(geometry["attacker_loss_s"]))
		if outcome == "contact":
			car["combat_contacts"] = int(car.get("combat_contacts", 0)) + 1
			result["defender_loss_s"] = float(geometry["defender_loss_s"])
		return result
	car["combat_cooldown"] = 3.5
	car["combat_pass_pending"] = true
	result["event"] = "release"
	# One short passing-resolution impulse models the decisive corner exit.
	# It is capped at 0.06s/lap and is NOT a physical car trajectory.
	# Without this resolution a scalar-track model may trap both cars forever.
	result["progress"] = maxf(proposed, minf(predicted_ahead + 0.00004, proposed + 0.00055))
	return result
