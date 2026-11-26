extends RefCounted
## Experimental 2012-style reference V8, deterministic SI math.
## All ratios are overall (gear * final drive); not supplier telemetry.
const KEY := "powertrain_070"
const RATIOS := [17.0,13.0,10.8,9.2,8.0,7.0,6.0]
const RPM_POINTS := [6500.0,10000.0,13000.0,16000.0,18000.0]
const TORQUE_POINTS := [215.0,275.0,310.0,320.0,295.0]
const IDLE_RPM := 6500.0
const LIMIT_RPM := 18000.0
const UPSHIFT_RPM := 17300.0
const DOWNSHIFT_RPM := 10500.0
const SHIFT_S := 0.06
const WHEEL_RADIUS_M := 0.33
const EFFICIENCY := 0.93
const REFERENCE_MASS_KG := 700.0

static func raw_rpm(speed_mps: float, gear: int) -> float:
	return maxf(0.0,speed_mps)*float(RATIOS[clampi(gear,1,7)-1])/WHEEL_RADIUS_M*60.0/TAU

static func torque_nm(rpm: float) -> float:
	if rpm>LIMIT_RPM: return 0.0
	var x: float = clampf(rpm,IDLE_RPM,LIMIT_RPM)
	for i in range(RPM_POINTS.size()-1):
		if x<=float(RPM_POINTS[i+1]):
			var t: float = (x-float(RPM_POINTS[i]))/(float(RPM_POINTS[i+1])-float(RPM_POINTS[i]))
			return lerpf(float(TORQUE_POINTS[i]),float(TORQUE_POINTS[i+1]),t)
	return float(TORQUE_POINTS[-1])

static func power_kw(torque: float, rpm: float) -> float:
	return maxf(0.0,torque)*maxf(0.0,rpm)*TAU/60000.0

static func initial_gear(speed_mps: float) -> int:
	for gear in range(1,8):
		if raw_rpm(speed_mps,gear)<=UPSHIFT_RPM: return gear
	return 7

static func advance(previous: Dictionary, speed_mps: float, throttle: float, dt: float, mass_kg: float = REFERENCE_MASS_KG) -> Dictionary:
	var step: float = maxf(0.0,dt)
	var gear: int = clampi(int(previous.get("gear",initial_gear(speed_mps))),1,7)
	var remaining: float = clampf(float(previous.get("shift_remaining_s",0.0)),0.0,SHIFT_S)
	if step>0.0 and remaining<=0.0:
		var rpm_before: float = raw_rpm(speed_mps,gear)
		if gear<7 and rpm_before>=UPSHIFT_RPM:
			gear+=1
			remaining=SHIFT_S
		elif gear>1 and rpm_before<DOWNSHIFT_RPM and raw_rpm(speed_mps,gear-1)<UPSHIFT_RPM:
			gear-=1
			remaining=SHIFT_S
	var cut: float = minf(step,remaining)
	var drive_fraction: float = (step-cut)/step if step>0.0 else 0.0
	var raw: float = raw_rpm(speed_mps,gear)
	var rpm: float = clampf(raw,IDLE_RPM,LIMIT_RPM)
	var request: float = clampf(throttle,0.0,1.0)
	var torque: float = torque_nm(raw)*request
	var force: float = torque*float(RATIOS[gear-1])*EFFICIENCY/WHEEL_RADIUS_M
	# Reference road load only limits positive drive, never changes 041 braking.
	# Detailed aero, fuel mass and tyre load integration are later versions.
	var resistance: float = 150.0+0.48*maxf(0.0,speed_mps)*maxf(0.0,speed_mps)
	return {"gear":gear,"rpm":rpm,"shift_remaining_s":maxf(0.0,remaining-cut),"shift_cut_s":cut,
		"throttle":request,"torque_nm":torque*drive_fraction,"power_kw":power_kw(torque,rpm)*drive_fraction,
		"wheel_force_n":force*drive_fraction,"uncut_wheel_force_n":force,"road_load_n":resistance,
		"uncut_accel_mps2":maxf(0.0,force-resistance)/maxf(1.0,mass_kg)}

static func settle(proposal: Dictionary, actual_speed_mps: float) -> Dictionary:
	# Delivered power is the pre-solver estimate; RPM tracks actual speed.
	var result: Dictionary = proposal.duplicate()
	result.rpm=clampf(raw_rpm(actual_speed_mps,int(result.gear)),IDLE_RPM,LIMIT_RPM)
	return result
