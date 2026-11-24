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
	for car in active:
		if not car.has("race_lane"): return {}
		var id := int(car.id)
		var pose: Dictionary = sample.call(car,float(car.race_lane),0.0)
		if not pose.has("route_length"): return {}
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
	if count>32: return {}
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
	return result
