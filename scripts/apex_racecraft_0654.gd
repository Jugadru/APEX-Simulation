extends RefCounted
## World-space occupation for the 3D presentation; never writes race dictionaries.
const HALF_WIDTH := 1.40
const HALF_LENGTH := 2.80
const PASS_LANE := 2.95
const MAX_CONSECUTIVE_VISUAL_HOLDS := 2

static func normal(direction: Vector2) -> Vector2:
	return Vector2(-direction.y,direction.x)

static func targets(cars: Array, previous: Dictionary) -> Dictionary:
	var lanes := {}
	var by_id := {}
	for car in cars:
		by_id[int(car.id)] = car
		lanes[int(car.id)] = 0.0
		if float(car.get("progress",0)) < 0:
			lanes[int(car.id)] = 1.45 if int(car.get("grid",1))%2 == 0 else -1.45
	var reserved := {}
	var order := cars.duplicate()
	order.sort_custom(func(a,b): return float(a.progress)>float(b.progress))
	for car in order:
		var id := int(car.id)
		var target := int(car.get("combat_target_id",-1))
		if reserved.has(id) or reserved.has(target) or not by_id.has(target): continue
		if str(car.get("combat_state","clear")) not in ["preparing","attacking","duel"]: continue
		var rival: Dictionary = by_id[target]
		if not eligible(car) or not eligible(rival): continue
		if car.route_point.distance_to(rival.route_point)>38: continue
		if car.route_direction.normalized().dot(rival.route_direction.normalized())<.65: continue
		var own := float(previous.get(id,{}).get("lane",0))
		var defend := float(previous.get(target,{}).get("lane",0))
		if int(previous.get(id,{}).get("target_id",-1))==target:
			var intent := float(previous.get(target,{}).get("intent_lane",defend))
			if absf(intent)<=.45: defend = intent
		# A defender never vacates the racing line just to animate a pass.
		# One early move is permitted before overlap; its line then stays fixed.
		if str(car.combat_state)=="preparing" and absf(own)<.1 and absf(defend)<.1 and car.route_point.distance_to(rival.route_point)*.6>9:
			defend = .45 if target%2 == 0 else -.45
		var side := signf(own) if absf(own)>.2 else (-signf(defend) if absf(defend)>.1 else (1.0 if id%2==0 else -1.0))
		lanes[id] = side*PASS_LANE
		lanes[target] = defend
		reserved[id] = true
		reserved[target] = true
	# Hold occupied lanes until both the nose and rear wing are clear.
	for car in order:
		var id := int(car.id)
		if not eligible(car) or not previous.has(id): continue
		for rival in order:
			var other := int(rival.id)
			if other==id or not previous.has(other) or not eligible(rival): continue
			var a: Dictionary = previous[id]
			var b: Dictionary = previous[other]
			var delta: Vector2 = a.position-b.position
			if absf(delta.dot(a.direction))<HALF_LENGTH*2+.6 and delta.length()<9 and absf(a.lane-b.lane)>2.0:
				lanes[id] = float(a.lane)
				break
	for car in cars:
		if car.has("race_lane"): lanes[int(car.id)] = float(car.race_lane)
	return lanes

static func eligible(car: Dictionary) -> bool:
	return float(car.get("pit_left",0))<=.001 and not bool(car.get("finished",false)) and car.has("route_point") and car.has("route_direction")

static func radius(pose: Dictionary, axis: Vector2) -> float:
	# Old fixtures and legacy A/B retain the original conservative envelope.
	# Live meshes provide their measured padded bounds in presentation units.
	return absf(pose.direction.dot(axis))*float(pose.get("half_length",HALF_LENGTH)) + absf(normal(pose.direction).dot(axis))*float(pose.get("half_width",HALF_WIDTH))

static func overlaps(a: Dictionary,b: Dictionary) -> bool:
	var delta: Vector2 = a.position-b.position
	if delta.length_squared()>40.0: return false
	for axis in [a.direction,normal(a.direction),b.direction,normal(b.direction)]:
		if absf(delta.dot(axis))>=radius(a,axis)+radius(b,axis): return false
	return true

static func swept(a0: Dictionary,a1: Dictionary,b0: Dictionary,b1: Dictionary) -> bool:
	# 06691: conservative visual broadphase for the relative linear sweep.
	# Track3D supplies unit directions. Each car fits in a circumscribed
	# radius sqrt(2.8^2+1.4^2) < 3.14; combined reach < 6.27.
	# Use 7 map units for a safety margin, before the original exact SAT.
	# If both endpoints stay on the same far side of an axis, their linear
	# relative path cannot collide. A crossing path must still run exact SAT.
	var start: Vector2 = a0.position-b0.position
	var finish: Vector2 = a1.position-b1.position
	if (start.x > 7.0 and finish.x > 7.0) or (start.x < -7.0 and finish.x < -7.0) \
			or (start.y > 7.0 and finish.y > 7.0) or (start.y < -7.0 and finish.y < -7.0):
		return false
	# Original collision/continuous SAT algorithm below is deliberately intact.
	if overlaps(a0,b0): return overlaps(a1,b1)
	var velocity: Vector2 = finish-start
	var closest := clampf(-start.dot(velocity)/maxf(.000001,velocity.length_squared()),0,1)
	if (start+velocity*closest).length_squared()>40.0: return false
	var enter := 0.0
	var leave := 1.0
	for axis in [a0.direction,normal(a0.direction),b0.direction,normal(b0.direction),a1.direction,normal(a1.direction),b1.direction,normal(b1.direction)]:
		var extent0 := radius(a0,axis)+radius(b0,axis)
		var extent1 := radius(a1,axis)+radius(b1,axis)
		var growth := extent1-extent0
		var d := start.dot(axis)
		var v := velocity.dot(axis)
		# Two linear half-space inequalities. Unlike using the maximum
		# radius for the whole frame, this does not inflate the old poses
		# into an impossible overlap when a convoy enters a bend.
		for side in [-1.0,1.0]:
			var origin: float = side*d-extent0
			var speed: float = side*v-growth
			if absf(speed)<.00001:
				if origin>=0: return false
			elif speed>0:
				leave = minf(leave,-origin/speed)
			else:
				enter = maxf(enter,-origin/speed)
			if enter>=leave: return false

	return enter<leave and leave>0 and enter<1

static func blocked(pose: Dictionary, old: Dictionary, accepted: Dictionary, previous: Dictionary) -> bool:
	for other in accepted:
		var rival: Dictionary = accepted[other]
		if overlaps(pose,rival): return true
		if not old.is_empty() and previous.has(other) and swept(old,pose,previous[other],rival): return true
	return false

# A rebased car cannot treat an unprocessed rival's LAST accepted visual pose
# as free track: that rival may still have to hold/rollback into it later in
# this same solver pass. This was the 9.17 Monaco tick-34 resync overlap.
# The guard is presentation-only and runs ONLY for a car after two visual holds.
static func pending_old_overlap(pose: Dictionary, car_id: int,
		previous: Dictionary, accepted: Dictionary, active_ids: Dictionary) -> bool:
	for other_id in previous:
		if int(other_id) == car_id or accepted.has(other_id) or not active_ids.has(other_id):
			continue
		if overlaps(pose, previous[other_id]):
			return true
	return false

static func pending_old_clearance(pose: Dictionary, car_id: int,
		previous: Dictionary, accepted: Dictionary, active_ids: Dictionary) -> float:
	var step := 0.8
	for other_id in previous:
		if int(other_id) == car_id or accepted.has(other_id) or not active_ids.has(other_id):
			continue
		var rival: Dictionary = previous[other_id]
		if overlaps(pose, rival):
			step = maxf(step, radius(pose, pose.direction)
				+ radius(rival, pose.direction)
				- (rival.position - pose.position).dot(pose.direction) + 0.1)
	return step

# Evaluate a complete simultaneous motion before the order-dependent fallback.
# The authoritative lane/progress are never modified. All accepted endpoints
# and every tested sweep must be collision-free. Legacy fixtures omit the
# explicit route length and continue to use the original solver.
static func simultaneous_clear(before: Dictionary, after: Dictionary) -> bool:
	var ids := after.keys()
	for i in range(ids.size()):
		var id = ids[i]
		for j in range(i+1,ids.size()):
			var other = ids[j]
			if overlaps(after[id],after[other]): return false
			if before.has(id) and before.has(other) and swept(before[id],after[id],before[other],after[other]): return false
	return true

static func try_official_motion(active: Array, previous: Dictionary, sample: Callable) -> Dictionary:
	var nominal := {}
	var maximum_arc := 0.0
	var maximum_lane := 0.0
	var sweep_cap := 32
	for car in active:
		if not car.has("race_lane"): return {}
		var id := int(car.id)
		var pose: Dictionary = sample.call(car,float(car.race_lane),0.0)
		if not pose.has("route_length"): return {}
		# Only a route with explicit presentation metadata may request
		# additional samples; never enlarge the per-sample displacement.
		sweep_cap = maxi(sweep_cap, clampi(int(pose.get("arc_sweep_max_steps",32)),32,64))
		if previous.has(id):
			var old: Dictionary = previous[id]
			if float(pose.progress)+0.00000001 < float(old.progress): return {}
			maximum_arc = maxf(maximum_arc,(float(pose.progress)-float(old.progress))*float(pose.route_length))
			maximum_lane = maxf(maximum_lane,absf(float(pose.lane)-float(old.lane)))
		pose["held"] = false
		pose["hold_frames"] = 0
		pose["resynced"] = false
		pose["visible"] = true
		pose["intent_lane"] = float(car.race_lane)
		pose["target_id"] = int(car.get("combat_target_id",-1))
		nominal[id] = pose
	if simultaneous_clear(previous,nominal): return nominal
	# A straight chord over a bend can falsely cross another car. Validate
	# the actual arc, using the exact same road sampler as the model.
	if previous.size()!=nominal.size() or not simultaneous_clear({},nominal): return {}
	var count := maxi(2,int(ceil(maxf(maximum_arc,maximum_lane)/1.0)))
	if count>sweep_cap: return {}
	# Never claim a route sweep unless its first sample reproduces the
	# actual preceding accepted pose, including lane and heading.
	for car in active:
		var id := int(car.id)
		if not previous.has(id): return {}
		var old: Dictionary = previous[id]
		var target: Dictionary = nominal[id]
		var retreat := (float(target.progress)-float(old.progress))*float(target.route_length)
		var origin: Dictionary = sample.call(car,float(old.lane),retreat)
		if Vector2(origin.position).distance_to(Vector2(old.position))>0.01 or Vector2(origin.direction).dot(Vector2(old.direction))<0.999: return {}
	var prior := previous
	for n in range(1,count+1):
		var fraction := float(n)/float(count)
		var next := {}
		if n==count:
			next=nominal
		else:
			for car in active:
				var id := int(car.id)
				var old: Dictionary = previous[id]
				var target: Dictionary = nominal[id]
				var retreat := (float(target.progress)-float(old.progress))*float(target.route_length)*(1.0-fraction)
				next[id]=sample.call(car,lerpf(float(old.lane),float(target.lane),fraction),retreat)
		if not simultaneous_clear(prior,next): return {}
		prior=next
	return nominal

# Coarse presentation frames can span several sporting ticks. Reconstruct
# intermediate arc/lane samples between the two observed authoritative
# endpoints, not between displaced visual poses. These are visual estimates,
# never extra sporting ticks. Keep work bounded and avoid pit/seek transitions.
static func nominal_history(cars: Array) -> Dictionary:
	var result: Dictionary = {}
	for car in cars:
		if eligible(car) and car.has("race_lane"):
			result[int(car.id)] = {"progress":float(car.progress),"lane":float(car.race_lane),"stage":str(car.get("pit_stage","none"))}
	return result

static func solve_interval(cars: Array, previous: Dictionary, dt: float, sample: Callable, last_nominal: Dictionary) -> Dictionary:
	if dt<=0.20 or previous.is_empty() or last_nominal.is_empty():
		return solve(cars,previous,dt,sample)
	var current := nominal_history(cars)
	if current.size()!=last_nominal.size() or previous.size()!=current.size() or current.is_empty():
		return solve(cars,previous,dt,sample)
	var endpoints: Dictionary = {}
	var lengths: Dictionary = {}
	for car in cars:
		if not eligible(car): continue
		var id: int = int(car.id)
		if not current.has(id) or not last_nominal.has(id) or not previous.has(id):
			return solve(cars,previous,dt,sample)
		var earlier: Dictionary = last_nominal[id]
		var later: Dictionary = current[id]
		var travel: float = float(later.progress)-float(earlier.progress)
		if earlier.stage!=later.stage or travel<0.0 or travel>0.05:
			return solve(cars,previous,dt,sample)
		var pose: Dictionary = sample.call(car,float(later.lane),0.0)
		if not pose.has("route_length"):
			return solve(cars,previous,dt,sample)
		endpoints[id]=car
		lengths[id]=float(pose.route_length)
	var count: int = clampi(int(ceil(dt/0.10)),2,12)
	var state: Dictionary = previous
	var resyncs: Dictionary = {}
	var internal_holds: Dictionary = {}
	# Use current endpoint's road projection and retreat along its arc.
	# All intermediate samples use the same world-space sampler/footprint.
	var sub_sample: Callable = func(car: Dictionary,lane: float,retreat: float) -> Dictionary:
		var id: int = int(car.id)
		var original: Dictionary = endpoints[id]
		var offset: float = (float(original.progress)-float(car.progress))*float(lengths[id])
		return sample.call(original,lane,maxf(0.0,offset+retreat))
	for n in range(1,count+1):
		var alpha: float = float(n)/float(count)
		var subcars: Array = []
		for car in cars:
			if not eligible(car):
				subcars.append(car)
				continue
			var id: int = int(car.id)
			var earlier: Dictionary = last_nominal[id]
			var later: Dictionary = current[id]
			var sub: Dictionary = car.duplicate(false)
			sub["progress"]=lerpf(float(earlier.progress),float(later.progress),alpha)
			sub["race_lane"]=lerpf(float(earlier.lane),float(later.lane),alpha)
			subcars.append(sub)
		var next: Dictionary = solve(subcars,state,dt/float(count),sub_sample)
		# Never accept an intermediate overlapping endpoint or missing car.
		if next.size()!=current.size() or not simultaneous_clear({},next):
			return solve(cars,previous,dt,sample)
		for id in next:
			if bool(next[id].get("resynced",false)): resyncs[id]=true
			if bool(next[id].get("held",false)): internal_holds[id]=int(internal_holds.get(id,0))+1
		state=next
	for id in state:
		state[id]["resynced"]=resyncs.has(id)
		state[id]["internal_holds"]=int(internal_holds.get(id,0))
		state[id]["visual_substeps"]=count
	return state

static func solve(cars: Array,previous: Dictionary,dt: float,sample: Callable, retreat_step_cap: float = INF, synchronize: bool = true) -> Dictionary:
	var active := []
	var active_ids := {}
	for car in cars:
		if eligible(car):
			active.append(car)
			active_ids[int(car.id)] = true
	if dt<=0 and not previous.is_empty():
		var frozen := {}
		for car in active:
			if previous.has(int(car.id)): frozen[int(car.id)] = previous[int(car.id)]
		if frozen.size()==active.size(): return frozen
	if synchronize:
		var synchronized := try_official_motion(active,previous,sample)
		if not synchronized.is_empty(): return synchronized
	# A visual hold must not become a permanent ordering lock after the
	# authoritative simulation passes a blocked rival. Rebase only the stuck
	# car's presentation history; no race dictionary or physics is modified.
	var history := previous.duplicate()
	for car in active:
		var id := int(car.id)
		if history.has(id) and int(history[id].get("hold_frames",0)) >= MAX_CONSECUTIVE_VISUAL_HOLDS:
			history.erase(id)
	var lanes := targets(active,previous)
	# Preserve the preceding frame's order while a pass is spatially blocked.
	active.sort_custom(func(a,b):
		var ap := float(history.get(int(a.id),{}).get("progress",a.progress))
		var bp := float(history.get(int(b.id),{}).get("progress",b.progress))
		return ap>bp if ap!=bp else int(a.id)<int(b.id))
	var result := {}
	for car in active:
		var id := int(car.id)
		var old: Dictionary = history.get(id,{})
		var recovering: bool = old.is_empty() and previous.has(id)
		var from := float(old.get("lane",lanes[id]))
		var lane := float(lanes[id]) if car.has("race_lane") else (lerpf(from,float(lanes[id]),1.0-exp(-3.8*maxf(0,dt))) if not old.is_empty() else float(lanes[id]))
		var pose: Dictionary = sample.call(car,lane,0.0)
		var retreat := 0.0
		# Short render intervals can be smaller than the 0.8-unit fallback
		# retreat. Try a safe fractional retreat before stepping backwards.
		if synchronize and dt>0.0 and dt<0.10 and not old.is_empty() and pose.has("route_length") and blocked(pose,old,result,history):
			var travel: float = (float(pose.progress)-float(old.progress))*float(pose.route_length)
			if travel>0.015 and travel<=2.0:
				for ratio in [0.25,0.5,0.75]:
					var probe: Dictionary = sample.call(car,lane,travel*ratio)
					if float(probe.progress)>=float(old.progress) and not blocked(probe,old,result,history):
						pose=probe
						retreat=travel*ratio
						break
		while (blocked(pose,old,result,history) or (recovering and pending_old_overlap(pose,id,previous,result,active_ids))) and retreat<240:
			var step := .8
			for other in result:
				if overlaps(pose,result[other]):
					step = maxf(step,radius(pose,pose.direction)+radius(result[other],pose.direction)-(result[other].position-pose.position).dot(pose.direction)+.1)
			if recovering:
				step = maxf(step, pending_old_clearance(pose,id,previous,result,active_ids))
			# Finite cap is a diagnostic option; default behavior remains unchanged.
			retreat += minf(step,maxf(0.8,retreat_step_cap))
			pose = sample.call(car,lane,retreat)
			if not old.is_empty() and float(pose.get("progress",car.progress))<float(old.progress): break
		if not old.is_empty() and (blocked(pose,old,result,history) or float(pose.get("progress",car.progress))<float(old.progress)):
			# Never hide or rewind a trapped car. Roll back the connected
			# conflicting moves to their last safe poses and wait for space.
			pose = old.duplicate()
			pose["held"] = true
			pose["hold_frames"] = int(old.get("hold_frames",0)) + 1
			result[id] = pose
			var frozen := {id:true}
			var changed := true
			while changed:
				changed = false
				for frozen_id in frozen.keys():
					for other in result.keys():
						if frozen.has(other) or not history.has(other): continue
						if overlaps(result[frozen_id],result[other]) or swept(history[frozen_id],result[frozen_id],history[other],result[other]):
							result[other] = history[other].duplicate()
							result[other]["held"] = true
							result[other]["hold_frames"] = int(history[other].get("hold_frames",0)) + 1
							frozen[other] = true
							changed = true
		else:
			pose["held"] = retreat>0
			# A cleared candidate can land exactly on its old visual position
			# after retreat. Count this as an actual hold, not a fake advance:
			# otherwise two more rollback frames yield three stationary ticks
			# without ever triggering the bounded recovery (Monaco car 7).
			var visually_still: bool = retreat > 0.0 and not old.is_empty() \
				and Vector2(pose.position).distance_squared_to(Vector2(old.position)) < 0.015 * 0.015
			pose["hold_frames"] = int(old.get("hold_frames",0)) + 1 if visually_still else 0
		pose["resynced"] = not previous.is_empty() and previous.has(id) and not history.has(id)
		pose["visible"] = true
		pose["intent_lane"] = float(lanes[id])
		pose["target_id"] = int(car.get("combat_target_id",-1))
		pose["progress"] = float(pose.get("progress",car.progress))
		result[id] = pose
	# At short cadences the experiment increased catch-up jumps; preserve the
	# established high-frequency path. Coarser updates can recover safely.
	if synchronize and dt>=0.10:
		_recover_stationary(active,previous,result,sample)
	return result

# Recover a visually stationary car only through a safe intermediate pose.
static func _recover_stationary(active: Array, previous: Dictionary, result: Dictionary, sample: Callable) -> void:
	for car in active:
		var id: int = int(car.id)
		if not previous.has(id) or not result.has(id): continue
		var old: Dictionary = previous[id]
		var current: Dictionary = result[id]
		if not bool(current.get("held",false)) or Vector2(current.position).distance_squared_to(Vector2(old.position)) >= 0.015*0.015: continue
		var target: Dictionary = sample.call(car,float(car.get("race_lane",current.lane)),0.0)
		if not target.has("route_length") or float(target.progress)<=float(old.progress): continue
		var distance: float = (float(target.progress)-float(old.progress))*float(target.route_length)
		if distance < 0.015 or distance > 32.0: continue
		for fraction in [1.0,0.75,0.5,0.25,0.125]:
			var candidate: Dictionary = sample.call(car,lerpf(float(old.lane),float(target.lane),fraction),distance*(1.0-fraction))
			if float(candidate.progress)<=float(old.progress) or Vector2(candidate.position).distance_squared_to(Vector2(old.position))<0.015*0.015: continue
			var clear := true
			for other in result:
				if other==id: continue
				if overlaps(candidate,result[other]) or (previous.has(other) and swept(old,candidate,previous[other],result[other])):
					clear=false
					break
			if not clear: continue
			candidate["held"]=false
			candidate["hold_frames"]=0
			candidate["resynced"]=false
			candidate["visible"]=true
			candidate["intent_lane"]=float(car.get("race_lane",target.lane))
			candidate["target_id"]=int(car.get("combat_target_id",-1))
			candidate["stationary_recovery"]=true
			result[id]=candidate
			break
