extends RefCounted
## 038: predictive, locked blue-flag yield. Pure judgement in existing
## schematic circuit units. No pace modifier, RNG, teleport or forced pass.
const Merge = preload("res://scripts/core/race_merge_traffic_0669174.gd")
const WIDTH := 2.95
const BODY := 6.4
const ATTACK := ["preparing","attacking","duel"]

static func active(car: Dictionary) -> bool:
	return not bool(car.get("finished",false)) and float(car.get("pit_left",0.0))<=0.0

static func lapping(fast: Dictionary, slow: Dictionary, gap: float, length: float) -> bool:
	if length<=0.0 or gap<=0.000001 or gap>38.0 or not active(fast) or not active(slow): return false
	var delta: float=float(fast.get("progress",0.0))-float(slow.get("progress",0.0))
	# Physical gap wraps at the line. A whole unwrapped lap of separation,
	# rather than a fixed 0.95 threshold, works on short and long circuits.
	return delta>0.0 and delta+gap/length>=1.0-0.00000001 and absf(fposmod(-delta,1.0)*length-gap)<0.0001

static func swept_clear(slow: Dictionary, fast: Dictionary, grid: Array, metrics: Dictionary, goal: float, length: float) -> bool:
	var lane: float=float(slow.get("race_lane",0.0))
	var own_pace: float=maxf(1.0,float(metrics.get(int(slow.id),{}).get("target",100.0)))
	var horizon: float=clampf(absf(goal-lane)/1.4+0.4,0.4,3.0)
	for third in grid:
		if int(third.id)==int(slow.id) or int(third.id)==int(fast.id) or not active(third): continue
		var gap: float=Merge.relative_gap(float(slow.progress),float(third.progress),length)
		var other_pace: float=maxf(1.0,float(metrics.get(int(third.id),{}).get("target",100.0)))
		var projected: float=gap+horizon*length*(1.0/other_pace-1.0/own_pace)
		if gap*projected>0.0 and minf(absf(gap),absf(projected))>=BODY+2.0: continue
		var third_lane: float=float(third.get("race_lane",0.0))
		if minf(lane,goal)<third_lane+WIDTH and maxf(lane,goal)>third_lane-WIDTH: return false
	return true

static func evaluate(fast: Dictionary, slow: Dictionary, grid: Array, metrics: Dictionary, context: Dictionary) -> Dictionary:
	var gap: float=float(context.gap)
	var length: float=float(context.length)
	var limit: float=float(context.limit)
	var lane: float=float(slow.get("race_lane",0.0))
	var result: Dictionary={"lapping":lapping(fast,slow,gap,length),"yield_early":false,"yield_lane":lane,"hold_lane":lane,"reason":"not_lapping"}
	if not bool(result.lapping): return result
	result.reason="waiting"
	# Never interrupt a backmarker's established battle, a narrowing road
	# or an already reserved incompatible intent.
	if bool(context.get("narrowing",false)) or limit<2.94 or absf(lane)>limit or str(slow.get("combat_state","")) in ATTACK or bool(context.get("busy",false)):
		result.reason="occupied_or_narrow"
		return result
	var wet: float=clampf(float(context.get("wet",0.0)),0.0,1.0)
	var load: float=maxf(float(context.get("load",0.0)),float(context.get("ahead_load",0.0)))
	var awareness: float=clampf(float(slow.get("spatial_awareness",80.0)),0.0,100.0)
	var safe_gap: float=12.0+6.0*wet+(100.0-awareness)*0.025
	var memory: Dictionary=slow.get("racecraft_memory",{})
	var locked: bool=int(memory.get("traffic_yield_to",-1))==int(fast.id)
	var goal: float=clampf(float(memory.get("traffic_yield_goal",lane)),-limit,limit)
	if locked:
		# Retain a legal occupied corridor, not a moving target. Once close,
		# in a corner, or blocked by a third car, hold the actual lane.
		if gap<safe_gap or load>=0.28 or not swept_clear(slow,fast,grid,metrics,goal,length): goal=lane
		result.yield_early=true
		result.yield_lane=goal
		result.reason="locked_yield"
		return result
	if gap<safe_gap or load>=0.28 or float(context.get("advantage",0.0))<=0.03:
		result.reason="wait_safe_window"
		return result
	var passing: float=float(context.get("passing_lane",0.0))
	var preferred: float=-signf(passing) if absf(passing)>0.10 else (-1.0 if float(fast.get("race_lane",0.0))>=0.0 else 1.0)
	goal=preferred*minf(limit,1.25)
	# A third car may already occupy the requested corridor or arrive
	# while the backmarker moves. No new lane request in either case.
	if not swept_clear(slow,fast,grid,metrics,goal,length):
		result.reason="third_car_corridor"
		return result
	result.yield_early=true
	result.yield_lane=goal
	result.reason="early_yield"
	return result
