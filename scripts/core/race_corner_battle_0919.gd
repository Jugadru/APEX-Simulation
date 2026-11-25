extends RefCounted
## 037: deterministic corner commitment judgement using existing local
## curvature/load, schematic occupancy and wetness. No speed or grip bonus.
const WIDTH := 2.95
const BODY := 6.4
const ATTACK := ["preparing","attacking","duel"]

static func phase(load: float, ahead_load: float) -> String:
	if maxf(load,ahead_load)<0.28: return "straight"
	if ahead_load>load+0.08: return "entry"
	if load>ahead_load+0.08: return "exit"
	return "apex"

static func refine(car: Dictionary, rival: Dictionary, tactic: Dictionary, gap: float,
		limit: float, load: float, ahead_load: float, wet: float, narrowing: bool) -> Dictionary:
	# Never resurrect an attack vetoed by the earlier racecraft layers.
	if not bool(tactic.get("commit",false)): return tactic
	var section: String=phase(load,ahead_load)
	if section=="straight": return tactic
	var lane: float=float(car.get("race_lane",0.0))
	var other_lane: float=float(rival.get("race_lane",0.0))
	var goal: float=float(tactic.attack_goal)
	var separation: float=absf(lane-other_lane)
	var on_same_side: bool=(lane-other_lane)*(goal-other_lane)>0.0
	var established: bool=str(car.get("combat_state","")) in ATTACK and int(car.get("combat_target_id",-1))==int(rival.get("id",-2)) and separation>=WIDTH-0.004 and on_same_side
	var result: Dictionary=tactic.duplicate()
	# Only lock at the apex: entry/exit already have the physical hold.
	# Avoid redundant tactical changes during transitions. The existing
	# third-car forecast, coordination and swept solver can still veto.
	if established and section=="apex" and gap<=BODY+1.0 and not narrowing and absf(lane)<=limit and absf(other_lane)<=limit:
		result.attack_goal=lane
		result.margin_m=separation-WIDTH
		result.defense=false
		result["corner_reason"]="hold_occupied_"+section
		return result
	# A late move must establish lateral clearance before the apex; rain
	# increases the required preparation window. No invented braking force.
	var severity: float=maxf(load,ahead_load)
	var rain: float=clampf(wet,0.0,1.0)
	var travel: float=absf(goal-lane)
	var window: float=BODY+2.0+severity*2.0+rain*3.0
	if not established and (section=="entry" or section=="apex") and gap<window and travel>1.0:
		result.commit=false
		result.defense=false
		result.blocked=true
		result["corner_reason"]="late_commit_"+section
		return result
	# On the exit, base judgement resumes; no pass is manufactured.
	return tactic
