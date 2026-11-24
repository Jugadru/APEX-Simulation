extends RefCounted
## Presentation only. No progress, timing, RNG or race dictionaries are modified.
static func targets(cars: Array, previous_lanes: Dictionary = {}) -> Dictionary:
	var result := {}
	var by_id := {}
	for car in cars:
		var id := int(car.get("id", -1))
		by_id[id] = car
		result[id] = 0.0
		if float(car.get("progress",0)) < 0.0:
			result[id] = 1.45 if int(car.get("grid",1)) % 2 == 0 else -1.45
	var ordered := cars.duplicate()
	ordered.sort_custom(func(a,b): return int(a.id) < int(b.id))
	var paired := {}
	for car in ordered:
		var id := int(car.id)
		var target := int(car.get("combat_target_id",-1))
		var state := str(car.get("combat_state","clear"))
		if paired.has(id) or paired.has(target) or not by_id.has(target): continue
		if state not in ["preparing","attacking","duel"]: continue
		var rival: Dictionary = by_id[target]
		if float(car.get("pit_left",0)) > 0 or float(rival.get("pit_left",0)) > 0: continue
		if bool(car.get("finished",false)) or bool(rival.get("finished",false)): continue
		if not car.has("route_point") or not rival.has("route_point"): continue
		var a: Vector2 = car.route_point
		var b: Vector2 = rival.route_point
		var heading: Vector2 = car.get("route_direction",Vector2.RIGHT)
		var other_heading: Vector2 = rival.get("route_direction",Vector2.RIGHT)
		# Exclude other laps, remote targets and close but opposing track sections.
		if absf(float(car.progress)-float(rival.progress)) > 0.02 or a.distance_to(b) > 38.0: continue
		if heading.normalized().dot(other_heading.normalized()) < 0.65: continue
		var side := 1.0 if id % 2 == 0 else -1.0
		var full_duel := state in ["attacking","duel"]
		result[id] = side * (1.55 if full_duel else 0.85)
		result[target] = -side * (1.55 if full_duel else 0.45)
		paired[id] = true
		paired[target] = true
	# Keep the visual corridor while the bodies still overlap longitudinally.
	# Recovery never pulls two side-by-side cars through one another.
	for car in ordered:
		var id := int(car.id)
		if paired.has(id) or absf(float(previous_lanes.get(id,0.0))) < 0.3: continue
		if float(car.get("pit_left",0)) > 0 or bool(car.get("finished",false)): continue
		for rival in ordered:
			var other := int(rival.id)
			if other == id or paired.has(other): continue
			if float(previous_lanes.get(id,0.0))*float(previous_lanes.get(other,0.0)) >= -0.09: continue
			if float(rival.get("pit_left",0)) > 0 or bool(rival.get("finished",false)): continue
			if not car.has("route_point") or not rival.has("route_point"): continue
			if absf(float(car.progress)-float(rival.progress)) > 0.02: continue
			var direction: Vector2 = car.get("route_direction",Vector2.RIGHT)
			var other_direction: Vector2 = rival.get("route_direction",Vector2.RIGHT)
			if direction.normalized().dot(other_direction.normalized()) < 0.65: continue
			var origin: Vector2 = car.route_point
			if origin.distance_to(rival.route_point) >= 10.0: continue
			result[id] = signf(float(previous_lanes[id]))*1.55
			result[other] = signf(float(previous_lanes[other]))*1.55
			paired[id] = true
			paired[other] = true
			break
	return result

static func advance(current: float, target: float, delta: float) -> float:
	# Exponential smoothing is independent of render FPS; bounded road corridor.
	return lerpf(current, clampf(target,-1.55,1.55), 1.0-exp(-4.0*maxf(0.0,delta)))
