extends RefCounted
## 043: deterministic fuel ledger. Every quantity names its unit.
## Work estimate, not a calibrated BSFC map. No RNG, I/O or KERS debit.
const KEY := "fuel_mass_0701"
const DRY_MASS_KG := 642.0
const LOWER_HEATING_KJ_PER_KG := 43000.0
const IDLE_KG_PER_S := 0.001
const REFERENCE_MASS_KG := 700.0
const FUEL_RATE_ESTIMATE_KG_PER_S := 0.028
const RESERVE_KG := 8.0
const EPS_KG := 0.000000001

static func initial_fuel_kg(laps: int, base_lap_s: float) -> float:
	return maxf(0.0,float(laps)*maxf(0.0,base_lap_s)*FUEL_RATE_ESTIMATE_KG_PER_S)+RESERVE_KG

static func efficiency(pace: String) -> float:
	return 0.32 if pace=="Conservar" else (0.28 if pace=="Atacar" else 0.30)

## kW * s = kJ. LHV in kJ/kg, no extra factor of 1000.
static func fuel_for_energy_kg(shaft_energy_kj: float, thermal_efficiency: float) -> float:
	return maxf(0.0,shaft_energy_kj)/(clampf(thermal_efficiency,0.01,1.0)*LOWER_HEATING_KJ_PER_KG)

static func initial_state(laps: int, base_lap_s: float) -> Dictionary:
	var load_kg: float = initial_fuel_kg(laps,base_lap_s)
	return {"initial_kg":load_kg,"remaining_kg":load_kg,"consumed_kg":0.0,"mass_kg":DRY_MASS_KG+load_kg,
		"last_burn_kg":0.0,"last_v8_work_kj":0.0,"last_speed_mps":0.0,"efficiency":0.30,"exhausted":false}

static func mass_kg(state: Dictionary) -> float:
	return DRY_MASS_KG+maxf(0.0,float(state.get("remaining_kg",0.0)))

## Estimated positive work on solved movement: change in kinetic energy
## plus road load. Wheel work (J) -> shaft work (kJ); KERS offsets only
## available shaft demand. No regeneration or fuel debit for KERS itself.
static func shaft_work_kj(mass: float, start_mps: float, end_mps: float, distance_m: float, road_load_n: float, efficiency_drive: float, kers_offer_kj: float) -> float:
	var kinetic_j: float = 0.5*maxf(1.0,mass)*(end_mps*end_mps-start_mps*start_mps)
	var wheel_work_j: float = maxf(0.0,kinetic_j+maxf(0.0,road_load_n)*maxf(0.0,distance_m))
	var required_kj: float = wheel_work_j/(1000.0*clampf(efficiency_drive,0.01,1.0))
	return maxf(0.0,required_kj-clampf(kers_offer_kj,0.0,required_kj))

static func advance(state: Dictionary, pace: String, dt: float, shaft_energy_kj: float, end_speed_mps: float) -> Dictionary:
	var remaining: float = maxf(0.0,float(state.remaining_kg))
	var eta: float = efficiency(pace)
	var demand: float = maxf(IDLE_KG_PER_S*maxf(0.0,dt),fuel_for_energy_kg(shaft_energy_kj,eta)) if dt>0.0 else 0.0
	var burn: float = minf(remaining,demand)
	var left: float = maxf(0.0,remaining-burn)
	var out: Dictionary = state.duplicate()
	out.remaining_kg=left
	out.consumed_kg=float(out.initial_kg)-left
	out.mass_kg=DRY_MASS_KG+left
	out.last_burn_kg=burn
	out.last_v8_work_kj=maxf(0.0,shaft_energy_kj)
	out.last_speed_mps=maxf(0.0,end_speed_mps)
	out.efficiency=eta
	out.exhausted=left<=EPS_KG
	return out
