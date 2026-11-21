extends RefCounted
## Authoritative deterministic traffic in schematic circuit units, not FIA metres.
const Combat = preload("res://scripts/core/race_combat.gd")
const DriverDynamics = preload("res://scripts/core/race_driver_dynamics_0661.gd")
const DriverTraffic = preload("res://scripts/core/race_driver_traffic_06693.gd")
const LENGTH := 6.4
const WIDTH := 2.95
const MAX_LANE := 2.95

static func profile(track: Dictionary) -> Dictionary:
	var route: Array[Vector2] = []
	for point in track.get("points",[]): route.append(Vector2(float(point[0])*660,float(point[1])*540))
	if route.size()<4: return {"length":1000.0}
	if route[0].distance_to(route[-1])<.001: route.pop_back()
	for iteration in range(3):
		var next: Array[Vector2] = []
		for i in range(route.size()):
			next.append(route[i].lerp(route[(i+1)%route.size()],.25))
			next.append(route[i].lerp(route[(i+1)%route.size()],.75))
		route=next
	var total := 0.0
	var distances: Array[float] = []
	var raw: Array[float] = []
	for i in range(route.size()):
		distances.append(total)
		var incoming := route[i]-route[(i+route.size()-1)%route.size()]
		var outgoing := route[(i+1)%route.size()]-route[i]
		total+=outgoing.length()
		var angle := acos(clampf(incoming.normalized().dot(outgoing.normalized()),-1,1))
		var radius := (incoming.length()+outgoing.length())*.5/maxf(angle,.001)
		raw.append(clampf(radius*.45+.35,1,4.4))
	var widths: Array[float] = []
	for i in range(route.size()):
		var sum := 0.0
		for offset in range(-4,5):sum+=raw[(i+offset+route.size())%route.size()]*(5-abs(offset))
		widths.append(sum/25.0)
	return {"length":maxf(total,100),"distances":distances,"widths":widths}

static func lane_limit(track: Dictionary,progress: float,shape: Dictionary = {}) -> float:
	var width := float(track.get("race_width_m",8.8))
	if shape.has("widths"):
		var index := clampi(shape.distances.bsearch(fposmod(progress,1)*float(shape.length))-1,0,shape.widths.size()-1)
		width=minf(width,2*minf(float(shape.widths[index]),float(shape.widths[(index+1)%shape.widths.size()])))
	for sector in track.get("racecraft_sectors",[]):
		var fraction := fposmod(progress,1)
		if fraction>=float(sector.start) and fraction<float(sector.end): width=minf(width,float(sector.width))
	return clampf(width*.5-1.45,0,MAX_LANE)

static func active(car: Dictionary) -> bool:
	return not bool(car.get("finished",false)) and float(car.get("pit_left",0))<=0

static func corridor_crosses(a0: float,a1: float,b0: float,b1: float) -> bool:
	return minf(a0,a1)<maxf(b0,b1)+WIDTH and maxf(a0,a1)>minf(b0,b1)-WIDTH

static func plan(cars: Array,metrics: Dictionary,dt: float,track: Dictionary,shape: Dictionary, weather: Dictionary = {}, traffic_enabled: bool = true, soul3_enabled: bool = false) -> Dictionary:
	var length: float=shape.length
	# 06686: RaceEngine normally supplies a sorted frozen sporting snapshot.
	# Filtering out inactive cars preserves its order. Avoid sorting 24
	# dictionaries a SECOND time if progress / ID tie ordering is valid.
	# External callers with unordered input are still sorted identically.
	var order: Array = []
	for car in cars:
		if active(car) and metrics.has(int(car.id)):
			order.append(car)
	var must_sort: bool = false
	for index in range(1, order.size()):
		var previous: Dictionary = order[index - 1]
		var current: Dictionary = order[index]
		if float(previous.progress) < float(current.progress) or (
				float(previous.progress) == float(current.progress) and int(previous.id) > int(current.id)):
			must_sort = true
			break
	if must_sort:
		order.sort_custom(func(a,b): return float(a.progress)>float(b.progress) if a.progress!=b.progress else int(a.id)<int(b.id))
	var intents := {}
	var by_id := {}
	for c in order:
		var id := int(c.id)
		by_id[id]=c
		var hesitation := maxf(0,float(c.get("combat_hesitation_s",0)))
		var lane := float(c.get("race_lane",0))
		intents[id]={"lane":lane,"goal":0.0,"pace":float(metrics[id].target),"state":"clear","target":-1,"event":"","defender_id":-1,"charge":maxf(0,float(c.get("attack_charge",0))-dt*.12),"defending":-1,"defense_line":0.0,"defense_event":false,"side":"","margin":0.0,"hesitation":maxf(0,hesitation-dt),"driving_dt":maxf(0,dt-hesitation)}
	# Decide from the same frozen start-of-tick positions. Only the corridor
	# solver below changes sporting progress; tactics may not teleport a car.
	for c in order:
		var ahead: Dictionary = {}
		var gap := INF
		for other in order:
			if other.id == c.id: continue
			var physical_gap := fposmod(float(other.progress)-float(c.progress),1.0)*length
			if physical_gap > 0.000001 and physical_gap < gap:
				gap = physical_gap
				ahead = other
		if ahead.is_empty() or gap > 38.0 or float(c.progress) < 0.0: continue
		var id: int = int(c.id)
		var rival: int = int(ahead.id)
		var a: Dictionary = intents[id]
		var d: Dictionary = intents[rival]
		var advantage: float = float(d.pace) - float(a.pace)
		a.target = rival
		a.state = "closing"
		var previous_target: int = int(c.get("combat_target_id", -1))
		var previous_charge: float = float(c.get("attack_charge", 0.0))
		if previous_target != rival: previous_charge = minf(previous_charge, 0.40)
		if advantage > 0.03:
			a.charge = minf(2.50, previous_charge + dt * clampf(0.20 + advantage * 0.22, 0.20, 0.55))
		else:
			a.charge = maxf(0.0, previous_charge - dt * 0.22)
		var limit: float = minf(lane_limit(track,float(c.progress),shape),
				lane_limit(track,float(ahead.progress)+LENGTH*2.0/length,shape))
		var driver: Dictionary = c.duplicate()
		driver["attack_charge"] = float(a.charge)
		var tactic: Dictionary = DriverDynamics.choose(driver,ahead,gap,advantage,limit,track,weather,soul3_enabled)
		# Blue flags are decisions about a physical backmarker, not a sporting
		# position override. A safe early yield uses the existing corridor solver.
		var traffic: Dictionary = DriverTraffic.evaluate(c, ahead, gap, limit, weather, float(tactic.attack_goal)) if traffic_enabled else {"lapping": false, "yield_early": false}
		if bool(traffic.lapping):
			tactic["defense"] = false
			if bool(traffic.yield_early) and int(d.defending) < 0:
				d.goal = float(traffic.yield_lane)
				d.defending = id
				d.defense_line = float(d.goal)
		# A player-approved order may suppress only an EARLY aggressive block.
		# Already occupied lanes, overlap, third cars and safety still apply.
		if int(ahead.get("team_yield_to_id", -1)) == id \
				and int(ahead.get("team_yield_ticks", 0)) > 0 \
				and str(ahead.get("team", "")) == str(c.get("team", "")):
			tactic["defense"] = false
		var cooling: bool = float(c.get("combat_cooldown", 0.0)) > 0.0
		if int(d.defending) < 0:
			# Once the cars approach overlap, the defender must HOLD its actual
			# lane. No late squeeze or return to the racing line during a duel.
			if gap <= LENGTH + 4.0:
				d.goal = float(d.lane)
				d.defending = id
				d.defense_line = float(d.lane)
			elif bool(tactic.defense) and str(d.state) not in ["attacking", "duel", "preparing"]:
				d.goal = clampf(float(tactic.defend_goal),-limit,limit)
				d.defending = id
				d.defense_line = float(d.goal)
				d.defense_event = bool(int(ahead.get("race_defending_against",-1)) != id and absf(float(d.goal)-float(d.lane)) > 0.15)
		# A genuine early defensive move is evaluated before the attacker
		# commits. If already locked, use the locked line, not a new squeeze.
		if not bool(tactic.commit) or cooling:
			if bool(tactic.blocked) and str(c.get("combat_state", "")) in ["preparing","attacking","duel"]:
				a.event = "yield"
			continue
		if int(d.defending) >= 0 and int(d.defending) != id: continue
		var defend_lane: float = float(d.goal) if int(d.defending) == id else float(d.lane)
		if absf(float(tactic.attack_goal)-defend_lane) < WIDTH - 0.004:
			if str(c.get("combat_state","")) in ["preparing","attacking","duel"]: a.event="yield"
			continue
		a.goal = float(tactic.attack_goal)
		a.state = "preparing" if absf(float(a.lane)-defend_lane) < WIDTH else ("duel" if gap < LENGTH*2.0 else "attacking")
		a.defender_id = rival
		a.side = str(tactic.side)
		a.margin = float(tactic.margin_m)
		if previous_target != rival or str(c.get("combat_state","clear")) not in ["preparing","attacking","duel"]:
			a.event = "attack"
		if int(d.defending) < 0:
			d.defending = id
			d.goal = float(d.lane) # Too late to make a new defensive move.
			d.defense_line = float(d.lane)
		if str(d.state) == "clear": d.state = "defending"
		# Every duel has a small, symmetric time cost; no boost is granted.
		a.pace += 0.22
		d.pace += 0.08
	# Hold lateral occupancy through overlap, including a recently passed car.
	for c in order:
		var id := int(c.id)
		var a: Dictionary=intents[id]
		for other in order:
			if other.id==id: continue
			var gap := absf(float(c.progress)-float(other.progress))*length
			if gap<LENGTH+1 and absf(float(a.lane)-float(other.get("race_lane",0)))>=WIDTH-.01:
				a.goal=a.lane
				break
		var limit := minf(lane_limit(track,float(c.progress),shape),lane_limit(track,float(c.progress)+LENGTH*2/length,shape))
		var wanted := move_toward(float(a.lane),clampf(float(a.goal),-limit,limit),dt*1.8)
		# Do not enter a third car's occupied corridor.
		for other in order:
			if other.id==id:continue
			var gap := absf(float(c.progress)-float(other.progress))*length
			if gap<LENGTH+2 and corridor_crosses(float(a.lane),wanted,float(other.get("race_lane",0)),float(other.get("race_lane",0))):
				if absf(float(a.lane)-float(other.get("race_lane",0)))>=WIDTH:
					wanted=float(a.lane)
					if absf(float(a.lane))>limit and float(c.progress)<=float(other.progress):
						a.driving_dt=0.0
						a.state="recovering"
		a.next_lane=wanted
		a.next=float(c.progress)+float(a.driving_dt)/maxf(1,float(a.pace))
	# Resolve all same-corridor followers against already-resolved leaders,
	# including a leader held by a third car. No resolution impulse exists.
	var result := {}
	for c in order:
		var id := int(c.id)
		var a: Dictionary=intents[id]
		var next := float(a.next)
		for leader_id in result:
			var leader: Dictionary=result[leader_id]
			var old_leader: Dictionary=by_id[leader_id]
			if corridor_crosses(float(a.lane),float(a.next_lane),float(old_leader.get("race_lane",0)),float(leader.states.race_lane)):
				next=minf(next,float(leader.progress)-LENGTH/length)
		next=maxf(float(c.progress),next)
		var passed := false
		if by_id.has(int(a.target)) and result.has(int(a.target)):
			passed=next>float(result[int(a.target)].progress) and float(c.progress)<=float(by_id[int(a.target)].progress)
		var attempts := int(c.get("combat_attempts",0))+(1 if a.event=="attack" else 0)
		var reaction: String = "defend" if bool(a.defense_event) and str(a.event).is_empty() else str(a.event)
		var states := {"race_lane":float(a.next_lane),"race_lane_goal":float(a.goal),"race_defending_against":int(a.defending),"race_defense_line":float(a.defense_line),"race_space_blocked":next<float(a.next)-.00000001,"combat_state":str(a.state),"combat_target_id":int(a.target),"attack_charge":float(a.charge),"combat_attempts":attempts,"combat_pass_pending":bool(c.get("combat_pass_pending",false)) or passed,"combat_hesitation_s":float(a.hesitation),
			"combat_last_side":str(a.side) if not str(a.side).is_empty() else str(c.get("combat_last_side","")),
			"combat_last_margin_m":float(a.margin) if not str(a.side).is_empty() else float(c.get("combat_last_margin_m",0.0)),
			"combat_cooldown":maxf(0.0,float(c.get("combat_cooldown",0.0))-dt)}
		result[id]={"progress":next,"states":states,"event":reaction,"defender_id":int(a.defender_id)}
	# Physical traffic also includes lapped cars; distance wraps at the line.
	for iteration in range(order.size()):
		var changed := false
		for c in order:
			var id := int(c.id)
			for other in order:
				if other.id==id:continue
				var gap := fposmod(float(other.progress)-float(c.progress),1)
				if gap>.25 or gap<.00000001:continue
				var b: Dictionary=result[int(other.id)]
				if not corridor_crosses(float(c.get("race_lane",0)),float(result[id].states.race_lane),float(other.get("race_lane",0)),float(b.states.race_lane)): continue
				var offset := float(c.progress)+gap-float(other.progress)
				var allowed := maxf(float(c.progress),float(b.progress)+offset-LENGTH/length)
				if allowed<float(result[id].progress)-.000000001:
					result[id].progress=allowed
					result[id].states.race_space_blocked=true
					changed=true
		if not changed:break
	for c in order:
		var id := int(c.id)
		var target := int(result[id].states.combat_target_id)
		var passed := false
		if result.has(target):passed=float(result[id].progress)>float(result[target].progress) and float(c.progress)<=float(by_id[target].progress)
		result[id].states.combat_pass_pending=bool(c.get("combat_pass_pending",false)) or passed
	return result
