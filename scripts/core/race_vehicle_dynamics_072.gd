extends RefCounted
## 045 unified vehicle step, deterministic SI. Pure proposal/settlement;
## engine remains the sole owner of fuel, tyre wear, KERS debit, commands,
## collision occupancy, pit transitions and racing classification.
const KEY := "vehicle_dynamics_072"
const L = preload("res://scripts/core/race_longitudinal_069.gd")
const P = preload("res://scripts/core/race_powertrain_070.gd")
const T = preload("res://scripts/core/race_tyre_grip_071.gd")
const F = preload("res://scripts/core/race_fuel_mass_0701.gd")
const EPS := 0.000000001

## Constant-force phase. All forces in N; drag is never negative.
## Wheel demand includes road resistance, so cruise requires real work.
## Brake and drive are mutually exclusive; a shift disables drive only.
static func phase(start_mps: float, target_mps: float, dt_s: float, mass_kg: float, road_n: float, max_drive_n: float, max_brake_n: float) -> Dictionary:
	var mass: float = maxf(1.0,mass_kg)
	var start: float = clampf(start_mps,0.0,L.MAX_MPS)
	var duration: float = maxf(0.0,dt_s)
	var goal: float = clampf(target_mps,0.0,L.MAX_MPS)
	var road: float = maxf(0.0,road_n)
	var drive: float = 0.0
	var brake: float = 0.0
	if duration>0.0:
		var request_n: float = mass*(goal-start)/duration+road
		drive=clampf(request_n,0.0,maxf(0.0,max_drive_n))
		brake=clampf(-request_n,0.0,maxf(0.0,max_brake_n))
	var net: float = drive-brake-road
	var accel: float = net/mass if duration>0.0 else 0.0
	# Exact ramp to the admissible terminal speed; stop at zero, not backwards.
	var end: float = clampf(start+accel*duration,0.0,L.MAX_MPS)
	var ramp: float = minf(duration,absf(end-start)/absf(accel)) if absf(accel)>EPS else duration
	var distance: float = (start+end)*0.5*ramp+end*(duration-ramp)
	return {"speed_mps":end,"distance_m":distance,"drive_force_n":drive,"brake_force_n":brake,"road_load_n":road,"net_force_n":net,
		"duration_s":duration,"drive_work_kj":drive*distance/(1000.0*P.EFFICIENCY)}

## Shared 044 trajectory/grip envelope; one powertrain offer and two
## ordered phases (shift cut, powered). No duplicated aero source or RNG.
static func propose(car: Dictionary, curve: Dictionary, pace_s: float, lap_m: float, driving_dt: float, weather: Dictionary) -> Dictionary:
	var envelope: Dictionary = L.motion_envelope(car,curve,pace_s,lap_m,weather)
	var start: float = float(envelope.previous)
	var target: float = float(envelope.target)
	var mass: float = float(envelope.mass_kg)
	var limits: Dictionary = envelope.limits
	var tyre: Dictionary = envelope.tyre_state
	var step: float = maxf(0.0,driving_dt)
	var delivery: Dictionary = curve.get("power_delivery_070",{})
	var offer: Dictionary = P.advance(car.get(P.KEY,{}),start,1.0,step,mass,delivery)
	var road: float = float(offer.road_load_n)
	var cut: float = float(offer.shift_cut_s)
	var drive_dt: float = maxf(0.0,step-cut)
	var brake_cap_n: float = mass*float(limits.brake)
	var coast: Dictionary = phase(start,target,cut,mass,road,0.0,brake_cap_n)
	var tyre_drive_n: float = mass*float(tyre.get("accel_limit_mps2",limits.accel))
	var ref_drive_n: float = road+mass*float(limits.accel)
	# Bound work by the offered shaft energy over the powered phase. Use an
	# upper bound on speed; at low speed the reference clutch is approximate.
	var max_speed: float = maxf(1.0,maxf(float(coast.speed_mps),minf(L.MAX_MPS,float(coast.speed_mps)+float(limits.accel)*drive_dt)))
	var energy_force_n: float = float(offer.total_energy_offer_kj)*P.EFFICIENCY*1000.0/maxf(EPS,max_speed*drive_dt) if drive_dt>0.0 else 0.0
	var drive_cap_n: float = minf(minf(float(offer.uncut_wheel_force_n),tyre_drive_n),minf(ref_drive_n,energy_force_n))
	var powered: Dictionary = phase(float(coast.speed_mps),target,drive_dt,mass,road,drive_cap_n,brake_cap_n)
	var distance: float = float(coast.distance_m)+float(powered.distance_m)
	var shaft: float = minf(float(offer.total_energy_offer_kj),float(powered.drive_work_kj))
	var kers_share: float = float(offer.kers_energy_offer_kj)/maxf(EPS,float(offer.total_energy_offer_kj))
	var kers: float = minf(float(offer.kers_energy_offer_kj),shaft*kers_share)
	var state: Dictionary = {"start_speed_mps":start,"target_speed_mps":target,"proposed_speed_mps":float(powered.speed_mps),
		"proposed_distance_m":distance,"mass_before_kg":mass,"road_load_n":road,"drive_cap_n":drive_cap_n,"brake_cap_n":brake_cap_n,
		"drive_force_n":float(powered.drive_force_n),"brake_force_n":float(powered.brake_force_n),"net_force_n":float(powered.net_force_n),
		"shift_net_force_n":float(coast.net_force_n),"shift_cut_s":cut,"driving_dt_s":step,
		"v8_offer_kj":float(offer.v8_energy_offer_kj),"kers_offer_kj":float(offer.kers_energy_offer_kj),"kers_allocated_kw":float(offer.kers_allocated_kw),
		"proposed_v8_kj":shaft-kers,"proposed_kers_kj":kers,
		"requested_pace_s":pace_s,"pace_mode":str(car.get("pace","Normal"))}
	var result: Dictionary = {"speed_mps":float(powered.speed_mps),"distance_m":distance}
	result[P.KEY]=offer
	if not tyre.is_empty(): result[T.KEY]=tyre
	result[KEY]=state
	return result

## Solver owns actual position/speed. Store the difference, not a second
## movement decision; do not mutate the earlier proposal.
static func settle(proposal: Dictionary, actual_m: float, actual_speed_mps: float, dt_s: float) -> Dictionary:
	var state: Dictionary = proposal.duplicate()
	state["actual_distance_m"]=maxf(0.0,actual_m)
	state["actual_speed_mps"]=maxf(0.0,actual_speed_mps)
	state["actual_ax_mps2"]=(actual_speed_mps-float(state.start_speed_mps))/maxf(EPS,dt_s)
	state["solver_limited"]=actual_m+0.000001<float(state.proposed_distance_m) or actual_speed_mps+0.000001<float(state.proposed_speed_mps)
	return state

## Reconcile once using final progress (including a truncated pit entry).
## Accepted energy is an estimate bounded by proposal, offers, and actual
## positive mechanical demand. Unused authorized KERS remains debited by
## the historic owner; it is reported explicitly, never refunded or debited twice.
static func account(state: Dictionary, actual_m: float, actual_speed_mps: float, dt_s: float) -> Dictionary:
	var result: Dictionary = settle(state,actual_m,actual_speed_mps,dt_s)
	var scale: float = clampf(actual_m/maxf(EPS,float(state.proposed_distance_m)),0.0,1.0)
	var demand: float = F.shaft_work_kj(float(state.mass_before_kg),float(state.start_speed_mps),actual_speed_mps,actual_m,float(state.road_load_n),P.EFFICIENCY,0.0)
	var proposed: float = float(state.proposed_v8_kj)+float(state.proposed_kers_kj)
	var accepted: float = minf(demand,proposed*scale)
	var kers: float = minf(float(state.proposed_kers_kj),accepted*float(state.proposed_kers_kj)/maxf(EPS,proposed))
	var v8: float = minf(float(state.proposed_v8_kj),maxf(0.0,accepted-kers))
	result["accepted_v8_kj"]=v8
	result["accepted_kers_kj"]=kers
	result["unused_authorized_kers_kj"]=maxf(0.0,float(state.kers_allocated_kw)*maxf(0.0,dt_s)-kers)
	result["estimated_shaft_demand_kj"]=demand
	return result
