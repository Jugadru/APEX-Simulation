extends RefCounted
## Hyper 2.2.0 research candidate. No runtime wiring. Core 2 numerical
## primitives are reused unchanged; the actual Alpha 2 source must be
## inspected before choosing a single integration point.
const Longitudinal = preload("res://scripts/core/race_longitudinal_069.gd")
const REVISION := "hyper22_longitudinal_candidate_01"
const STEP_S := 0.2
const MAX_PREVIEWS := 128
const ROUNDING_TOLERANCE_M := 0.001

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}

## All inputs are SI. The caller owns car state, launch, pit and racecraft.
## A non-TRACK or launch tick must retain the old authoritative movement.
## Previews are observed forward distances, not sporting lap progress.
static func propose(input: Dictionary) -> Dictionary:
	if not input.get("stage") is String or not input.get("launch_active") is bool:
		return _reject("missing_phase")
	if str(input.stage) != "TRACK" or bool(input.launch_active):
		return {"ok": true, "bypass": true, "reason": "legacy_phase"}
	for key in ["speed_mps", "target_mps", "traction", "driving_dt_s"]:
		if not _number(input.get(key)):
			return _reject("invalid_" + key)
	var speed: float = float(input.speed_mps)
	var target: float = float(input.target_mps)
	var traction: float = float(input.traction)
	var drive_dt: float = float(input.driving_dt_s)
	if speed < 0.0 or speed > Longitudinal.MAX_MPS or target < 0.0 or target > Longitudinal.MAX_MPS:
		return _reject("speed_out_of_range")
	if traction < 0.05 or traction > 1.05 or drive_dt < 0.0 or drive_dt > STEP_S:
		return _reject("traction_or_time_out_of_range")
	var previews: Variant = input.get("previews", [])
	if not previews is Array or previews.size() > MAX_PREVIEWS:
		return _reject("invalid_previews")
	var limits: Dictionary = Longitudinal.rates(speed, traction)
	var constrained: float = target
	for preview in previews:
		if not preview is Dictionary or not _number(preview.get("distance_m")) or not _number(preview.get("speed_mps")):
			return _reject("invalid_preview")
		var distance: float = float(preview.distance_m)
		var future: float = float(preview.speed_mps)
		if distance < 0.0 or distance > 100000.0 or future < 0.0 or future > Longitudinal.MAX_MPS:
			return _reject("preview_out_of_range")
		# The shared rates increase with speed. The lower endpoint
		# supplies a conservative braking preview, without an instant jump.
		var brake: float = float(Longitudinal.rates(minf(speed, future), traction).brake)
		constrained = minf(constrained, Longitudinal.braking_cap(future, brake, distance))
	var motion: Dictionary = Longitudinal.integrate(speed, constrained, float(limits.accel), float(limits.brake), drive_dt)
	return {"ok": true, "bypass": false, "revision": REVISION,
		"start_mps": speed, "target_mps": constrained, "driving_dt_s": drive_dt,
		"speed_mps": float(motion.speed_mps), "distance_m": float(motion.distance_m),
		"accel_limit_mps2": float(limits.accel), "brake_limit_mps2": float(limits.brake)}

## The existing spatial solver remains sovereign. No distance writes,
## RNG, pit commands, fuel charges or racecraft decisions are made here.
## actual_m is the accepted nonnegative TRACK distance, not a pit teleport.
## If a phase transition occurred the caller must use its old phase logic.
static func settle(proposal: Dictionary, actual_m: float, stage: String) -> Dictionary:
	if not bool(proposal.get("ok", false)):
		return _reject("invalid_proposal")
	if bool(proposal.get("bypass", false)) or stage != "TRACK":
		return {"ok": true, "bypass": true, "reason": "legacy_phase"}
	if str(proposal.get("revision", "")) != REVISION:
		return _reject("invalid_revision")
	for key in ["distance_m", "speed_mps", "driving_dt_s"]:
		if not _number(proposal.get(key)):
			return _reject("invalid_proposal")
	var distance: float = float(proposal.distance_m)
	var speed: float = float(proposal.speed_mps)
	var driving_dt: float = float(proposal.driving_dt_s)
	if distance < 0.0 or speed < 0.0 or speed > Longitudinal.MAX_MPS or driving_dt < 0.0 or driving_dt > STEP_S:
		return _reject("invalid_proposal")
	if not is_finite(actual_m) or actual_m < 0.0 or actual_m > distance + ROUNDING_TOLERANCE_M:
		return _reject("solver_distance_out_of_range")
	# Existing integer millimetre rounding may differ from SI by < 1 mm.
	# Use the shared conservative settle rule for a real restriction;
	# no unearned progress is added to the spatial solver.
	var normalized: float = distance if absf(actual_m - distance) <= ROUNDING_TOLERANCE_M else actual_m
	var terminal: float = Longitudinal.settle(proposal, normalized, STEP_S, driving_dt)
	return {"ok": true, "bypass": false, "speed_mps": terminal,
		"distance_m": actual_m, "solver_restricted": actual_m + ROUNDING_TOLERANCE_M < distance or driving_dt < STEP_S}
