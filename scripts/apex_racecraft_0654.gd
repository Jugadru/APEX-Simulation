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
	return absf(pose.direction.dot(axis))*HALF_LENGTH + absf(normal(pose.direction).dot(axis))*HALF_WIDTH

static func overlaps(a: Dictionary,b: Dictionary) -> bool:
	var delta: Vector2 = a.position-b.position
	if delta.length_squared()>40.0: return false
	for axis in [a.direction,normal(a.direction),b.direction,normal(b.direction)]:
		if absf(delta.dot(axis))>=radius(a,axis)+radius(b,axis): return false
	return true

static func swept(a0: Dictionary,a1: Dictionary,b0: Dictionary,b1: Dictionary) -> bool:
	# Continuous SAT on relative motion. Includes the projection of both
	# endpoint orientations, so fast frames cannot tunnel through a rival.
	if overlaps(a0,b0): return overlaps(a1,b1)
	var start: Vector2 = a0.position-b0.position
	var velocity: Vector2 = (a1.position-b1.position)-start
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

static func solve(cars: Array,previous: Dictionary,dt: float,sample: Callable) -> Dictionary:
	var active := []
	for car in cars:
		if eligible(car): active.append(car)
	if dt<=0 and not previous.is_empty():
		var frozen := {}
		for car in active:
			if previous.has(int(car.id)): frozen[int(car.id)] = previous[int(car.id)]
		if frozen.size()==active.size(): return frozen
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
		var from := float(old.get("lane",lanes[id]))
		var lane := float(lanes[id]) if car.has("race_lane") else (lerpf(from,float(lanes[id]),1.0-exp(-3.8*maxf(0,dt))) if not old.is_empty() else float(lanes[id]))
		var pose: Dictionary = sample.call(car,lane,0.0)
		var retreat := 0.0
		while blocked(pose,old,result,history) and retreat<240:
			var step := .8
			for other in result:
				if overlaps(pose,result[other]):
					step = maxf(step,radius(pose,pose.direction)+radius(result[other],pose.direction)-(result[other].position-pose.position).dot(pose.direction)+.1)
			retreat += step
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
			pose["hold_frames"] = 0
		pose["resynced"] = not previous.is_empty() and previous.has(id) and not history.has(id)
		pose["visible"] = true
		pose["intent_lane"] = float(lanes[id])
		pose["target_id"] = int(car.get("combat_target_id",-1))
		pose["progress"] = float(pose.get("progress",car.progress))
		result[id] = pose
	return result
