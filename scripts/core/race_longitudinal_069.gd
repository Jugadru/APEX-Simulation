extends RefCounted
## First longitudinal model: physical SI units on declared lap distance.
## Experimental gameplay coefficients, not a calibrated 2012 vehicle model.
## No RNG, rendering, gearbox, tyre thermal or lateral solver ownership.
const Powertrain070 = preload("res://scripts/core/race_powertrain_070.gd")
const Fuel0701 = preload("res://scripts/core/race_fuel_mass_0701.gd")
const KEY := "longitudinal_069_mps"
const PREVIEW_M := 60.0
const PIT_EXIT_MPS := 80.0 / 3.6
const MAX_MPS := 100.0

static func grip(car: Dictionary, weather: Dictionary) -> float:
	var wet := clampf(float(weather.get("wetness_factor",0.0)),0.0,1.0)
	var tyre := str(car.get("tire",""))
	var mismatch := 0.58 if tyre not in ["Intermediário","Chuva"] else (0.24 if tyre=="Intermediário" else 0.12)
	return clampf(float(weather.get("grip_factor",1.0))*(1.0-wet*mismatch)*(1.0-0.20*clampf(float(car.get("wear",0.0))/100.0,0.0,1.0)),0.28,1.05)

static func rates(speed: float, traction: float) -> Dictionary:
	# High-speed acceleration tapers; braking grows with speed as a
	# simple downforce proxy. Detailed torque/load transfer follow later.
	return {"accel":maxf(2.2,10.0-0.075*speed)*traction,
		"brake":lerpf(12.0,25.0,clampf(speed/85.0,0.0,1.0))*traction}

static func corner_speed(nominal: float, load: float, mean: float) -> float:
	# Replace only the legacy local pace redistribution in movement, not
	# tactical pace, wear, energy accounting or strategy predictions.
	return clampf(nominal*clampf(1.0+0.24*(mean-load),0.76,1.16),0.0,MAX_MPS)

static func braking_cap(future_speed: float, braking: float, distance_m: float) -> float:
	return sqrt(maxf(0.0,future_speed*future_speed+2.0*maxf(0.0,braking)*maxf(0.0,distance_m)))

## Constant-deceleration estimate in SI; zero if already at/below target.
static func braking_distance(speed: float, target: float, braking: float) -> float:
	return maxf(0.0, speed * speed - target * target) / (2.0 * maxf(0.000001, braking))

## Existing schematic apices supply forward constraints, including across
## the finish line. The local 60m preview remains an additional constraint.
static func apex_braking_cap(curve: Dictionary, nominal: float, lap_m: float, traction: float, desired: float, mass_scale: float = 1.0) -> float:
	var cap: float = desired
	var progress: float = float(curve.get("progress", 0.0))
	for corner in curve.get("corners", []):
		var distance_m: float = fposmod(float(corner.apex) - progress, 1.0) * lap_m
		var apex_speed: float = corner_speed(nominal, float(corner.severity), float(curve.mean))
		if apex_speed >= cap: continue
		# Braking rate grows with speed in this model. Use the lower-speed
		# endpoint as a conservative constant rate for the approach.
		var braking: float = float(rates(apex_speed, traction).brake)*mass_scale
		if distance_m <= braking_distance(cap, apex_speed, braking):
			cap = minf(cap, braking_cap(apex_speed, braking, distance_m))
	return cap

static func integrate(speed: float, target: float, accel: float, brake: float, dt: float) -> Dictionary:
	var start := clampf(speed,0.0,MAX_MPS)
	var goal := clampf(target,0.0,MAX_MPS)
	var time := maxf(0.0,dt)
	var rate := maxf(0.000001,accel if goal>=start else brake)
	var ramp := minf(time,absf(goal-start)/rate)
	var end := move_toward(start,goal,rate*ramp)
	# Exact constant-rate ramp, then cruise for the rest of the tick.
	return {"speed_mps":end,"distance_m":(start+end)*0.5*ramp+end*(time-ramp)}

static func propose(car: Dictionary, curve: Dictionary, pace_s: float, lap_m: float, driving_dt: float, weather: Dictionary) -> Dictionary:
	var nominal := lap_m/maxf(1.0,pace_s)*float(curve.legacy_factor)
	var desired := corner_speed(nominal,float(curve.load),float(curve.mean))
	var future := corner_speed(nominal,float(curve.ahead_load),float(curve.mean))
	# Handover at 24s preserves the existing launch/first-corner model.
	var previous := clampf(float(car.get(KEY,desired)),0.0,MAX_MPS)
	var traction: float = grip(car,weather)
	var limits := rates(previous,traction)
	var mass_kg: float = Powertrain070.REFERENCE_MASS_KG
	var mass_scale: float = 1.0
	if curve.has(Fuel0701.KEY):
		mass_kg = maxf(Fuel0701.DRY_MASS_KG,float(curve[Fuel0701.KEY]))
		mass_scale = Powertrain070.REFERENCE_MASS_KG/mass_kg
		# Force-limited reference rates; detailed tyre load transfer is 0.7.1.
		limits.accel=float(limits.accel)*mass_scale
		limits.brake=float(limits.brake)*mass_scale
	var target := minf(desired,braking_cap(future,float(limits.brake),PREVIEW_M))
	target = minf(target,apex_braking_cap(curve,nominal,lap_m,traction,desired,mass_scale))
	# 042 opt-in only. Braking and traffic remain authoritative.
	# The existing KERS/DRS/wake pace remains the target ceiling; the
	# powertrain only supplies a force limit, never adds speed to the target.
	if bool(curve.get(Powertrain070.KEY,false)):
		var drive: Dictionary = Powertrain070.advance(car.get(Powertrain070.KEY,{}),previous,1.0 if target>previous else 0.0,driving_dt,mass_kg,curve.get("power_delivery_070",{}))
		var movement: Dictionary
		if target>previous:
			var cut: float = float(drive.shift_cut_s)
			var acceleration: float = minf(float(limits.accel),float(drive.uncut_accel_mps2))
			var goal: float = previous if acceleration<=0.0 else target
			movement = integrate(previous,goal,acceleration,float(limits.brake),maxf(0.0,driving_dt-cut))
			movement.distance_m = float(movement.distance_m)+previous*cut
		else:
			movement = integrate(previous,target,float(limits.accel),float(limits.brake),driving_dt)
		movement[Powertrain070.KEY]=drive
		return movement
	return integrate(previous,target,float(limits.accel),float(limits.brake),driving_dt)

## Legacy movement has no terminal velocity; the last observed mean is
## the closest causal estimate. Safety and pit state still take priority.
static func handover_speed(actual_m: float, dt: float) -> float:
	return clampf(actual_m / dt,0.0,MAX_MPS) if dt>0.0 else 0.0

static func settle(proposal: Dictionary, actual_m: float, dt: float, driving_dt: float) -> float:
	# A collision-avoidance restriction or hesitation may require more
	# braking than the free-air model. Never restore lost progress.
	if dt<=0.0: return 0.0
	if actual_m+0.000001<float(proposal.distance_m) or driving_dt+0.000001<dt:
		return clampf(minf(float(proposal.speed_mps),actual_m/dt),0.0,MAX_MPS)
	return float(proposal.speed_mps)
