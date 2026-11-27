extends RefCounted
## 044 reference tyre/load envelope. Pure deterministic SI calculations.
## Four normal loads, not four independent wheel/suspension solvers.
## Schematic curvature and all coefficients require gameplay calibration.
const KEY := "tyre_grip_071"
const Thermal = preload("res://scripts/core/race_tyre_thermal.gd")
const G := 9.81
const WHEELBASE_M := 3.2
const TRACK_WIDTH_M := 1.45
const CG_HEIGHT_M := 0.33
const FRONT_STATIC_FRACTION := 0.46
const FRONT_AERO_FRACTION := 0.43
const REFERENCE_WHEEL_LOAD_N := 700.0*G/4.0
const DOWNFORCE_N_PER_MPS2 := 1.0
const CURVATURE_PER_M := 0.009
const COMPOUND_SCALE := {"Supermacio":1.04,"Macio":1.02,"Médio":1.0,"Duro":0.97,"Intermediário":0.98,"Chuva":0.96}

static func signed_curvature(curve: Dictionary, ahead: bool = false) -> float:
	var load: float = clampf(float(curve.get("ahead_load" if ahead else "load",0.0)),0.0,1.0)
	var progress: float = float(curve.get("ahead_progress" if ahead else "progress",0.0))
	var direction: float = 1.0
	var best: float = 0.0
	for c in curve.get("corners",[]):
		var delta: float = fposmod(progress-float(c.apex)+0.5,1.0)-0.5
		var span: float = float(c.get("brake_bins",4.0) if delta<0.0 else c.get("exit_bins",4.0))/256.0
		var weight: float = float(c.severity)*maxf(0.0,1.0-absf(delta)/maxf(0.000001,span))
		if weight>best:
			best=weight
			direction=signf(float(c.get("direction",1.0)))
	return load*CURVATURE_PER_M*direction

static func downforce_n(speed_mps: float, aero: Dictionary) -> float:
	var dirty: float = clampf(float(aero.get("dirty_fraction",0.0))/0.020,0.0,1.0)
	var factor: float = (1.0-0.12*dirty)*(0.88 if bool(aero.get("drs_active",false)) else 1.0)
	return DOWNFORCE_N_PER_MPS2*maxf(0.0,speed_mps)*maxf(0.0,speed_mps)*factor

## Positive ax transfers load to the rear. Positive ay transfers to left.
## Nonnegative corner loads, exact total mg+downforce; bounded transfer.
static func wheel_loads(mass_kg: float, ax_mps2: float, ay_mps2: float, aero_n: float) -> Dictionary:
	var mass: float = maxf(1.0,mass_kg)
	var weight: float = mass*G
	var down: float = maxf(0.0,aero_n)
	var total: float = weight+down
	var transfer: float = mass*ax_mps2*CG_HEIGHT_M/WHEELBASE_M
	var front: float = clampf(weight*FRONT_STATIC_FRACTION+down*FRONT_AERO_FRACTION-transfer,0.05*total,0.95*total)
	var rear: float = total-front
	var side_transfer: float = mass*ay_mps2*CG_HEIGHT_M/TRACK_WIDTH_M
	var front_side: float = clampf(side_transfer*FRONT_STATIC_FRACTION,-0.48*front,0.48*front)
	var rear_side: float = clampf(side_transfer*(1.0-FRONT_STATIC_FRACTION),-0.48*rear,0.48*rear)
	return {"fl_n":0.5*front+front_side,"fr_n":0.5*front-front_side,"rl_n":0.5*rear+rear_side,"rr_n":0.5*rear-rear_side,"front_n":front,"rear_n":rear,"total_n":total}

static func compound_grip(car: Dictionary, weather: Dictionary, base_grip: float) -> float:
	# Reuse the 069 weather/wear factor and the thermal model's existing band.
	# No temperature, graining, blistering or wear is created here.
	var compound: String = str(car.get("tire","Médio"))
	var band: Array = Thermal.band(compound)
	var temp: float = float(car.get("tyre_surface_c",(float(band[0])+float(band[1]))*0.5))
	var outside: float = maxf(0.0,maxf(float(band[0])-temp,temp-float(band[1])))
	var thermal: float = clampf(1.0-0.004*outside-0.07*clampf(float(car.get("tyre_graining",0.0)),0.0,1.0)-0.09*clampf(float(car.get("tyre_blistering",0.0)),0.0,1.0),0.65,1.0)
	var wet: float = clampf(float(weather.get("wetness_factor",0.0)),0.0,1.0)
	var matching: float = 1.0
	if compound=="Chuva": matching=lerpf(0.78,1.0,wet)
	elif compound=="Intermediário": matching=1.0-0.10*absf(wet-0.5)
	return 1.55*clampf(base_grip,0.0,1.05)*float(COMPOUND_SCALE.get(compound,1.0))*thermal*matching

## Load sensitivity: more normal load yields more grip, but less than linearly.
static func tyre_force_n(normal_n: float, mu: float) -> float:
	return maxf(0.0,mu)*REFERENCE_WHEEL_LOAD_N*pow(maxf(0.0,normal_n)/REFERENCE_WHEEL_LOAD_N,0.90)

static func evaluate(car: Dictionary, weather: Dictionary, mass_kg: float, speed_mps: float, curvature: float, ax_mps2: float, base_grip: float, aero: Dictionary) -> Dictionary:
	var mass: float = maxf(1.0,mass_kg)
	var speed: float = maxf(0.0,speed_mps)
	var ay: float = speed*speed*curvature
	var down: float = downforce_n(speed,aero)
	var mu: float = compound_grip(car,weather,base_grip)
	var loads: Dictionary = wheel_loads(mass,clampf(ax_mps2,-35.0,35.0),ay,down)
	var front_force: float = tyre_force_n(float(loads.fl_n),mu)+tyre_force_n(float(loads.fr_n),mu)
	var rear_force: float = tyre_force_n(float(loads.rl_n),mu)+tyre_force_n(float(loads.rr_n),mu)
	var total_force: float = front_force+rear_force
	var lateral_use: float = absf(ay)*mass/maxf(0.000001,total_force)
	# Combined grip ellipse with 2% lateral headroom for recovery. A real
	# overspeed is reported, never turned into permission to accelerate.
	var lateral_fraction: float = minf(0.98,lateral_use)
	var available: float = sqrt(maxf(0.0,1.0-lateral_fraction*lateral_fraction))
	var accel: float = rear_force*available/mass if lateral_use<1.0 else 0.0
	var brake: float = total_force*available/mass
	return {"mass_kg":mass,"speed_mps":speed,"curvature_per_m":curvature,"ax_mps2":ax_mps2,"ay_mps2":ay,
		"downforce_n":down,"mu":mu,"base_grip":base_grip,"aero":aero.duplicate(),"loads":loads,
		"lateral_capacity_mps2":total_force/mass,"lateral_utilization":lateral_use,"accel_limit_mps2":accel,"brake_limit_mps2":brake,
		"combined_utilization":sqrt(lateral_use*lateral_use+pow(absf(ax_mps2)/maxf(0.000001,(rear_force if ax_mps2>=0.0 else total_force)/mass),2.0))}

static func corner_cap(nominal_mps: float, curvature: float, lateral_capacity_mps2: float) -> float:
	if absf(curvature)<0.000001: return nominal_mps
	return minf(nominal_mps,sqrt(maxf(0.0,lateral_capacity_mps2)*0.98/absf(curvature)))

static func settle(proposal: Dictionary, car: Dictionary, weather: Dictionary, actual_speed: float, dt: float) -> Dictionary:
	var ax: float = (actual_speed-float(proposal.speed_mps))/maxf(0.000001,dt)
	return evaluate(car,weather,float(proposal.mass_kg),actual_speed,float(proposal.curvature_per_m),ax,float(proposal.base_grip),proposal.aero)

static func wear_scale(state: Dictionary) -> float:
	# Bounded additional load-related wear, on top of the existing owner.
	var utilization: float = clampf(float(state.get("combined_utilization",0.0)),0.0,1.0)
	return 1.0+0.12*smoothstep(0.65,1.0,utilization)
