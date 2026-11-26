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
const Kers2012 = preload("res://scripts/core/race_kers_2012.gd")
# 0.5 * 1.2 * 0.8 = the initial reference quadratic coefficient 0.48.
const AIR_DENSITY := 1.2
const REFERENCE_CDA := 0.8
const ROLLING_FORCE_N := 150.0
const DRS_DRAG_REDUCTION := 0.15
const MAX_TOW_DRAG_REDUCTION := 0.08
const REFERENCE_TOW_FRACTION := 0.014

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

## Reference drag in SI; use only the existing authorized DRS and wake.
## No lateral/aero grip or strategy ownership. Coefficients experimental.
static func aerodynamic_drag_n(speed_mps: float, aero: Dictionary = {}) -> float:
	var speed: float = maxf(0.0,speed_mps)
	var tow: float = clampf(float(aero.get("tow_fraction",0.0))/REFERENCE_TOW_FRACTION,0.0,1.0)
	var factor: float = (1.0-DRS_DRAG_REDUCTION if bool(aero.get("drs_active",false)) else 1.0)*(1.0-MAX_TOW_DRAG_REDUCTION*tow)
	return 0.5*AIR_DENSITY*REFERENCE_CDA*factor*speed*speed

static func advance(previous: Dictionary, speed_mps: float, throttle: float, dt: float, mass_kg: float = REFERENCE_MASS_KG, delivery: Dictionary = {}) -> Dictionary:
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
	var ratio: float = float(RATIOS[gear-1])
	var v8_force: float = torque*ratio*EFFICIENCY/WHEEL_RADIUS_M
	# RaceKers2012 already debits the authorized energy. Here we consume
	# its current-tick power offer, never debit the reservoir a second time.
	# Shaft coupling uses the reference clutch/idle approximation at low rpm.
	var allocated_kw: float = clampf(float(delivery.get("kers_power_kw",0.0)),0.0,Kers2012.POWER_KW)
	var kers_kw: float = allocated_kw*request if raw<=LIMIT_RPM else 0.0
	var kers_torque: float = kers_kw*1000.0/maxf(1.0,rpm*TAU/60.0)
	var kers_force: float = kers_torque*ratio*EFFICIENCY/WHEEL_RADIUS_M
	var force: float = v8_force+kers_force
	var drag: float = aerodynamic_drag_n(speed_mps,delivery)
	var resistance: float = ROLLING_FORCE_N+drag
	var v8_kw: float = power_kw(torque,rpm)
	# Offered shaft power/energy before target/grip/traffic restrictions,
	# not measured wheel work, fuel consumption or regenerated energy.
	return {"gear":gear,"rpm":rpm,"shift_remaining_s":maxf(0.0,remaining-cut),"shift_cut_s":cut,
		"throttle":request,"torque_nm":torque*drive_fraction,"power_kw":v8_kw*drive_fraction,
		"v8_power_kw":v8_kw*drive_fraction,"kers_allocated_kw":allocated_kw,"kers_power_kw":kers_kw*drive_fraction,
		"total_power_kw":(v8_kw+kers_kw)*drive_fraction,
		"v8_energy_offer_kj":v8_kw*maxf(0.0,step-cut),"kers_energy_offer_kj":kers_kw*maxf(0.0,step-cut),
		"total_energy_offer_kj":(v8_kw+kers_kw)*maxf(0.0,step-cut),
		"wheel_force_n":force*drive_fraction,"uncut_wheel_force_n":force,"road_load_n":resistance,
		"aero_drag_n":drag,"rolling_force_n":ROLLING_FORCE_N,"drs_active":bool(delivery.get("drs_active",false)),
		"tow_fraction":clampf(float(delivery.get("tow_fraction",0.0)),0.0,REFERENCE_TOW_FRACTION),
		"uncut_accel_mps2":maxf(0.0,force-resistance)/maxf(1.0,mass_kg)}

static func settle(proposal: Dictionary, actual_speed_mps: float) -> Dictionary:
	# Delivered power is the pre-solver estimate; RPM tracks actual speed.
	var result: Dictionary = proposal.duplicate()
	result.rpm=clampf(raw_rpm(actual_speed_mps,int(result.gear)),IDLE_RPM,LIMIT_RPM)
	return result
