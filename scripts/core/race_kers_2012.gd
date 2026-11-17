extends RefCounted
## KERS (2012): at most 60 kW and 400 kJ released per completed lap.
## Three tactical power profiles and separate energy quotas for three bursts.
## The positions are gameplay approximations; not homologated KERS maps.
const POWER_KW: float = 60.0
const ENERGY_PER_LAP_KJ: float = 400.0
const MODES := ["Economizar", "Equilibrado", "Atacar"]
const NON_KERS_TEAMS := ["Marussia Cosworth", "HRT Cosworth"]

# Distribute the energy instead of draining it on the first straight.
# Window fractions and battery utilization are GAMEPLAY balancing values.
const BURST_WINDOWS := [[0.075, 0.245], [0.425, 0.665], [0.765, 0.945]]
const MODE_POWER_KW := {"Economizar": 18.0, "Equilibrado": 40.0, "Atacar": 60.0}
const MODE_ZONE_ENERGY_KJ := {
	"Economizar": [110.0, 110.0, 100.0], # 320 kJ, 17.8 s of gentle boost
	"Equilibrado": [140.0, 130.0, 130.0], # 400 kJ, 10.0 s of medium boost
	"Atacar": [150.0, 140.0, 110.0], # 400 kJ, 6.67 s of hard boost
}

static func equipped(team: String) -> bool:
	return not NON_KERS_TEAMS.has(team)

static func initial_state(car: Dictionary) -> void:
	car["kers_equipped"] = equipped(str(car.get("team", "")))
	car["kers_mode"] = "Equilibrado"
	car["kers_remaining_kj"] = ENERGY_PER_LAP_KJ if bool(car["kers_equipped"]) else 0.0
	car["kers_used_lap_kj"] = 0.0
	car["kers_active"] = false
	car["kers_power_kw"] = 0.0
	car["kers_zone_spent_kj"] = [0.0, 0.0, 0.0]
	car["kers_gain_lap_s"] = 0.0
	car["drs_gain_lap_s"] = 0.0

static func reset_lap(car: Dictionary) -> void:
	car["kers_remaining_kj"] = ENERGY_PER_LAP_KJ if bool(car.get("kers_equipped", false)) else 0.0
	car["kers_used_lap_kj"] = 0.0
	car["kers_active"] = false
	car["kers_power_kw"] = 0.0
	car["kers_zone_spent_kj"] = [0.0, 0.0, 0.0]
	car["kers_gain_lap_s"] = 0.0
	car["drs_gain_lap_s"] = 0.0

static func zone_at(progress: float) -> int:
	var fraction: float = fposmod(progress, 1.0)
	for i in range(BURST_WINDOWS.size()):
		var window: Array = BURST_WINDOWS[i]
		if fraction >= float(window[0]) and fraction <= float(window[1]):
			return i
	return -1

static func selected_mode(car: Dictionary) -> String:
	var mode: String = str(car.get("kers_mode", "Equilibrado"))
	return mode if MODE_POWER_KW.has(mode) else "Equilibrado"

static func should_deploy(car: Dictionary, progress: float, _gap: float, _track: Dictionary) -> bool:
	if not bool(car.get("kers_equipped", false)) or float(car.get("pit_left", 0.0)) > 0.0:
		return false
	if float(car.get("kers_remaining_kj", 0.0)) <= 0.0:
		return false
	var zone: int = zone_at(progress)
	if zone < 0:
		return false
	var mode: String = selected_mode(car)
	var budget: Array = MODE_ZONE_ENERGY_KJ[mode]
	var consumed: Array = car.get("kers_zone_spent_kj", [0.0, 0.0, 0.0])
	return float(consumed[zone]) < float(budget[zone]) - 0.0001

static func apply(car: Dictionary, progress: float, gap: float, dt: float, track: Dictionary) -> bool:
	car["kers_active"] = false
	car["kers_power_kw"] = 0.0
	if not should_deploy(car, progress, gap, track):
		return false
	var zone: int = zone_at(progress)
	var mode: String = selected_mode(car)
	var budgets: Array = MODE_ZONE_ENERGY_KJ[mode]
	var spent_by_zone: Array = car.get("kers_zone_spent_kj", [0.0, 0.0, 0.0])
	var zone_remaining: float = maxf(0.0, float(budgets[zone]) - float(spent_by_zone[zone]))
	var remaining: float = maxf(0.0, float(car.get("kers_remaining_kj", 0.0)))
	var consumed: float = minf(minf(remaining, zone_remaining), maxf(0.0, dt) * float(MODE_POWER_KW[mode]))
	if consumed <= 0.00001:
		return false
	car["kers_remaining_kj"] = maxf(0.0, remaining - consumed)
	car["kers_used_lap_kj"] = minf(ENERGY_PER_LAP_KJ, float(car.get("kers_used_lap_kj", 0.0)) + consumed)
	spent_by_zone[zone] = float(spent_by_zone[zone]) + consumed
	car["kers_zone_spent_kj"] = spent_by_zone
	car["kers_active"] = true
	# Effective output for the final fractional physics step; never >60 kW.
	car["kers_power_kw"] = minf(POWER_KW, consumed / maxf(0.00001, dt))
	return true
