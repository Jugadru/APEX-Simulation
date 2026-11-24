extends RefCounted
## Preventive merge judgement, schematic units. No velocity boost, RNG,
## changes to sporting grid, tyre/DRS/KERS models, or lateral teleport.
static func single_file(half_lane: float) -> bool:
	return 2.0*half_lane < 3.15

static func refine(tactic: Dictionary, gap: float, lane: float, leader_lane: float, body: float, width: float) -> Dictionary:
	var result: Dictionary=tactic.duplicate()
	var occupied_duel: bool = gap<body+1.0 and absf(lane-leader_lane)>=width-0.01
	if not occupied_duel:
		result["commit"]=false
		result["defense"]=false
		result["blocked"]=true
		result["overtaking_reason"]="approaching_single_corridor"
	return result

static func queue(order: Array, intents: Dictionary, narrowing: Dictionary, length: float, body: float, width: float) -> void:
	for c in order:
		var id: int=int(c.id)
		if not bool(narrowing.get(id,false)): continue
		var own: Dictionary=intents[id]
		var best_gap: float=INF
		var leader: Dictionary={}
		for rival in order:
			if int(rival.id)==id: continue
			var gap: float=fposmod(float(rival.progress)-float(c.progress),1.0)*length
			if gap<0.000001:
				if int(rival.id)>id: continue
				gap=0.0
			if gap>=body*2.0 or gap>=best_gap: continue
			var other: Dictionary=intents[int(rival.id)]
			if absf(float(own.lane)-float(other.lane))<width-0.01: continue
			best_gap=gap
			leader=other
		if leader.is_empty(): continue
		# At speed, an early lift creates a longitudinal opening rather than
		# demanding a stopped car. Existing safety solver still owns motion.
		var advance: float=maxf(0.0,float(own.next)-float(c.progress))
		var clearance: float=clampf(best_gap/(body*2.0),0.45,1.0)
		own.next=float(c.progress)+advance*clearance
		own.state="recovering" if best_gap<body+1.0 else "closing"


## 027: signed arc distance, positive when the rival is physically ahead.
static func relative_gap(progress: float, rival_progress: float, length: float) -> float:
	return (fposmod(rival_progress-progress+0.5,1.0)-0.5)*length

static func has_priority(car: Dictionary, rival: Dictionary) -> bool:
	# Only used at physically equal arc positions. Higher classified progress
	# wins the merge turn; identical progress uses a stable ID tie-break.
	if absf(float(car.progress)-float(rival.progress)) > 0.000000001:
		return float(car.progress)>float(rival.progress)
	return int(car.id)<int(rival.id)

static func queue_027(order: Array, intents: Dictionary, narrowing: Dictionary, length: float, body: float, width: float) -> void:
	for car in order:
		var id: int=int(car.id)
		if not bool(narrowing.get(id,false)): continue
		var own: Dictionary=intents[id]
		var nearest: float=INF
		for rival in order:
			if int(rival.id)==id: continue
			var gap: float=relative_gap(float(car.progress),float(rival.progress),length)
			if absf(gap)<=0.000001:
				if has_priority(car,rival): continue
				gap=0.0
			if gap<0.0 or gap>=body*2.0 or gap>=nearest: continue
			var other: Dictionary=intents[int(rival.id)]
			if absf(float(own.lane)-float(other.lane))<width-0.01: continue
			nearest=gap
		if nearest==INF: continue
		# Exactly one lift per tick, independent of the number of neighbors.
		# Physical same-corridor clearance remains enforced by RaceSpace.
		var advance: float=maxf(0.0,float(own.next)-float(car.progress))
		own.next=float(car.progress)+advance*clampf(nearest/(body*2.0),0.45,1.0)
		own.state="recovering" if nearest<body+1.0 else "closing"
