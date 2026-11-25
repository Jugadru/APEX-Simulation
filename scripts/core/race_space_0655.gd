extends RefCounted
## Authoritative deterministic traffic in schematic circuit units, not FIA metres.
const Combat = preload("res://scripts/core/race_combat.gd")
const DriverDynamics = preload("res://scripts/core/race_driver_dynamics_0661.gd")
const DriverTraffic = preload("res://scripts/core/race_driver_traffic_06693.gd")
const Overtaking = preload("res://scripts/core/race_overtaking_intelligence_066912.gd")
const CompetitiveStart = preload("res://scripts/core/race_start_competitive_0669172.gd")
const LENGTH := 6.4
const WIDTH := 2.95
const MAX_LANE := 2.95
const AeroWake = preload("res://scripts/core/race_aero_wake_091711.gd")
const Coordination = preload("res://scripts/core/race_tactical_coordination_091712.gd")
const CornerBattle = preload("res://scripts/core/race_corner_battle_0919.gd")
const Traffic0920 = preload("res://scripts/core/race_driver_traffic_0920.gd")
const TrafficPack = preload("res://scripts/core/race_traffic_pack_09201.gd")
const Independent = preload("res://scripts/core/race_independent_racecraft_091710.gd")
const MergeTraffic = preload("res://scripts/core/race_merge_traffic_0669174.gd")

static func route_points(track: Dictionary) -> Array[Vector2]:
	var route: Array[Vector2] = []
	for point in track.get("points",[]): route.append(Vector2(float(point[0])*660,float(point[1])*540))
	if route.size()<4: return []
	if route[0].distance_to(route[-1])<.001: route.pop_back()
	for iteration in range(3):
		var next: Array[Vector2] = []
		for i in range(route.size()):
			next.append(route[i].lerp(route[(i+1)%route.size()],.25))
			next.append(route[i].lerp(route[(i+1)%route.size()],.75))
		route=next
	return route

static func profile(track: Dictionary) -> Dictionary:
	var route: Array[Vector2] = route_points(track)
	if route.is_empty(): return {"length":1000.0}
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

# 034: prevent simultaneous lateral convergence before longitudinal resolution.
# Existing overlaps are not teleported apart; only new swept-corridor conflicts
# are vetoed. Re-evaluate after cancelling a move because a third car may rely on it.
static func prevent_convergence(order: Array, intents: Dictionary, length: float) -> void:
	for iteration in range(order.size()):
		var changed := false
		for i in range(order.size()):
			var a: Dictionary = intents[int(order[i].id)]
			for j in range(i+1,order.size()):
				var b: Dictionary = intents[int(order[j].id)]
				if absf(float(a.lane)-float(b.lane))<WIDTH: continue
				if float(a.next_lane)==float(a.lane) and float(b.next_lane)==float(b.lane): continue
				var gap: float = MergeTraffic.relative_gap(float(order[i].progress),float(order[j].progress),length)
				var projected: float = gap+(float(b.next)-float(order[j].progress)-float(a.next)+float(order[i].progress))*length
				if gap*projected>0.0 and minf(absf(gap),absf(projected))>=LENGTH+0.25: continue
				if not corridor_crosses(float(a.lane),float(a.next_lane),float(b.lane),float(b.next_lane)): continue
				a.next_lane=float(a.lane)
				b.next_lane=float(b.lane)
				changed=true
		if not changed: break

# A pit-lane car may enter the active sporting set only with an actual opening.
# Use frozen main-track plans, plus releases already reserved this tick.
static func pit_exit_clear(exit_progress: float, order: Array, plan: Dictionary, released: Array, length: float) -> bool:
	for other in order:
		if not plan.has(int(other.id)): continue
		var before: float = MergeTraffic.relative_gap(exit_progress,float(other.progress),length)
		var after: float = before+(float(plan[int(other.id)].progress)-float(other.progress))*length
		if before*after<=0.0 or minf(absf(before),absf(after))<LENGTH+1.0: return false
	for position in released:
		if absf(MergeTraffic.relative_gap(exit_progress,float(position),length))<LENGTH+1.0: return false
	return true

static func straight_hold_allowed(load: float, ahead_load: float, held: bool, narrowing: bool, lane: float, limit: float, wet: float, wet_line_stability: bool) -> bool:
	# In low grip, a continuous own line is preferable to stop/start lane holds.
	if wet_line_stability and wet>=0.45: return false
	return load<(0.18 if held else 0.12) and ahead_load<0.22 and not narrowing and absf(lane)<=limit

static func plan(cars: Array,metrics: Dictionary,dt: float,track: Dictionary,shape: Dictionary, weather: Dictionary = {}, traffic_enabled: bool = true, soul3_enabled: bool = false,
		overtaking_enabled: bool = false, competitive_start_enabled: bool = false,
		start_clock_s: float = 0.0, merge_traffic_enabled: bool = false, traffic_hotfix_enabled: bool = false, following_enabled: bool = false, completion_enabled: bool = false, independent_enabled: bool = false, aero_wake_enabled: bool = false, aero_wake_corrected: bool = true, wake_stability: bool = false, wet_line_stability: bool = false, coordination_enabled: bool = false, corner_battle_enabled: bool = false, traffic_intelligence_enabled: bool = false, traffic_pack_enabled: bool = false) -> Dictionary:
	var length: float=shape.length
	following_enabled = following_enabled and start_clock_s>=24.0
	completion_enabled = completion_enabled and following_enabled
	independent_enabled = independent_enabled and completion_enabled
	aero_wake_enabled = aero_wake_enabled and independent_enabled
	wake_stability = wake_stability and aero_wake_enabled
	coordination_enabled = coordination_enabled and independent_enabled
	corner_battle_enabled = corner_battle_enabled and coordination_enabled
	traffic_intelligence_enabled = traffic_intelligence_enabled and corner_battle_enabled and traffic_enabled
	traffic_pack_enabled = traffic_pack_enabled and traffic_intelligence_enabled and start_clock_s>=24.0
	var hotfix: bool = merge_traffic_enabled and traffic_hotfix_enabled
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
		var hold_grid_corridor: bool = competitive_start_enabled and CompetitiveStart.active(start_clock_s, float(c.progress))
		intents[id]={"lane":lane,"goal":(lane if hold_grid_corridor else 0.0),"pace":float(metrics[id].target),"state":"clear","target":-1,"event":"","defender_id":-1,"charge":maxf(0,float(c.get("attack_charge",0))-dt*.12),"defending":-1,"defense_line":0.0,"defense_event":false,"side":"","margin":0.0,"hesitation":maxf(0,hesitation-dt),"driving_dt":maxf(0,dt-hesitation)}
	# Voluntary line only in free air. Tactical attack/defense and the
	# existing occupancy solver retain authority. No lateral teleport.
	for c in order:
		var id: int = int(c.id)
		if not metrics[id].has("line_ratio"): continue
		var clear: bool = true
		for other in order:
			if other.id==id: continue
			var signed_gap: float=MergeTraffic.relative_gap(float(c.progress),float(other.progress),length)
			if absf(signed_gap)<LENGTH*3.0:
				# A rear follower in the same corridor must not monopolize
				# the leader's racing line. A side-by-side rival still vetoes it.
				if following_enabled and signed_gap<0.0 and (absf(signed_gap)>=LENGTH+1.0 or absf(float(c.get("race_lane",0.0))-float(other.get("race_lane",0.0)))<WIDTH-0.01): continue
				clear=false
				break
		if clear:
			var limit: float=minf(lane_limit(track,float(c.progress),shape),lane_limit(track,float(c.progress)+LENGTH*2.0/length,shape))
			intents[id].goal=clampf(float(metrics[id].line_ratio),-1.0,1.0)*limit
	# Look ahead once per car; no new RNG or changes to the road geometry.
	var narrowing: Dictionary = {}
	if merge_traffic_enabled:
		for c in order:
			var p: float = float(c.progress)
			var min_lane: float = MAX_LANE
			for offset in [0.0,LENGTH,2.0*LENGTH,3.0*LENGTH,4.0*LENGTH]:
				min_lane=minf(min_lane,lane_limit(track,p+float(offset)/length,shape))
			narrowing[int(c.id)]=MergeTraffic.single_file(min_lane)
	var traffic_observations:Dictionary={}
	if traffic_pack_enabled:
		var traffic_rates:Dictionary=TrafficPack.rate_frame(cars)
		for c in order:
			traffic_observations[int(c.id)]=TrafficPack.observe(c,cars,metrics,length,weather,dt,traffic_rates)
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
		if ahead.is_empty() or gap > 38.0 or (float(c.progress) < 0.0 and not competitive_start_enabled): continue
		var id: int = int(c.id)
		var rival: int = int(ahead.id)
		var a: Dictionary = intents[id]
		var d: Dictionary = intents[rival]
		var advantage: float = float(d.pace) - float(a.pace)
		if following_enabled:
			advantage = float(metrics[rival].get("decision_pace",d.pace))-float(metrics[id].get("decision_pace",a.pace))
		a.target = rival
		a.state = "closing"
		var previous_target: int = int(c.get("combat_target_id", -1))
		var previous_charge: float = float(c.get("attack_charge", 0.0))
		if previous_target != rival:
			previous_charge = minf(previous_charge, 0.40)
			if traffic_pack_enabled:previous_charge+=TrafficPack.preparation_bonus(c,rival,advantage)
		if advantage > 0.03:
			a.charge = minf(2.50, previous_charge + dt * clampf(0.20 + advantage * 0.22, 0.20, 0.55))
		else:
			a.charge = maxf(0.0, previous_charge - dt * 0.22)
		var limit: float = minf(lane_limit(track,float(c.progress),shape),
				lane_limit(track,float(ahead.progress)+LENGTH*2.0/length,shape))
		var driver: Dictionary = c.duplicate()
		driver["attack_charge"] = float(a.charge)
		var tactic: Dictionary = DriverDynamics.choose(driver,ahead,gap,advantage,limit,track,weather,soul3_enabled,following_enabled)
		if competitive_start_enabled:
			tactic = CompetitiveStart.refine_tactic(driver,ahead,gap,advantage,limit,weather,tactic,start_clock_s)
		if overtaking_enabled:
			tactic = Overtaking.refine(c, ahead, order, gap, advantage, limit,
				length, weather, tactic)
		if merge_traffic_enabled and bool(narrowing.get(id,false)):
			# Existing overlap retains its corridor; do not begin a new
			# attack/defense when two full corridors cannot continue ahead.
			tactic=MergeTraffic.refine(tactic,gap,float(a.lane),float(d.lane),LENGTH,WIDTH)
		# Blue flags are decisions about a physical backmarker, not a sporting
		# position override. A safe early yield uses the existing corridor solver.
		var traffic: Dictionary = DriverTraffic.evaluate(c, ahead, gap, limit, weather, float(tactic.attack_goal)) if traffic_enabled else {"lapping": false, "yield_early": false}
		if traffic_intelligence_enabled:
			var tm: Dictionary=metrics[rival]
			var own_load: float=float(tm.get("line_load",0.0))
			var blue_limit: float=minf(limit,lane_limit(track,float(ahead.progress),shape))
			var blue_context:Dictionary={"gap":gap,"length":length,"limit":blue_limit,"wet":weather.get("wetness_factor",0.0),"load":own_load,"ahead_load":tm.get("ahead_load",own_load),"narrowing":bool(narrowing.get(id,false)) or bool(narrowing.get(rival,false)),"busy":int(d.defending)>=0 or str(d.state) in Independent.ATTACK or str(a.get("defense_origin",""))=="blue_flag","advantage":advantage,"passing_lane":tactic.attack_goal}
			traffic=TrafficPack.blue(c,ahead,order,metrics,blue_context) if traffic_pack_enabled else Traffic0920.evaluate(c,ahead,order,metrics,blue_context)
			if bool(traffic.lapping): a["traffic_reason"]=traffic.reason
		if bool(traffic.lapping):
			tactic["defense"] = false
			if bool(traffic.yield_early) and int(d.defending) < 0:
				d.goal = float(traffic.yield_lane)
				d.defending = id
				d.defense_line = float(d.goal)
				if coordination_enabled: d["defense_origin"]="blue_flag"
				if traffic_intelligence_enabled: d["traffic_yield_to"]=id
		# A player-approved order may suppress only an EARLY aggressive block.
		# Already occupied lanes, overlap, third cars and safety still apply.
		if int(ahead.get("team_yield_to_id", -1)) == id \
				and int(ahead.get("team_yield_ticks", 0)) > 0 \
				and str(ahead.get("team", "")) == str(c.get("team", "")):
			tactic["defense"] = false
		var cooling: bool = float(c.get("combat_cooldown", 0.0)) > 0.0
		if completion_enabled and str(c.get("combat_state","")) in ["preparing","attacking","duel"] and previous_target==rival and advantage>0.0 and absf(float(a.lane)-float(d.lane))>=WIDTH-0.01 and float(tactic.margin_m)>=-0.004 and not bool(tactic.get("blocked",false)) and not bool(narrowing.get(id,false)):
			# Continue a physically established attack while it retains real pace advantage.
			# No new attack outside the passing zone; no override of occupied lanes.
			if Combat.in_passing_zone(float(c.progress),track): tactic.commit=true
		if corner_battle_enabled and not bool(traffic.lapping) and not cooling:
			var corner_metrics: Dictionary=metrics[id]
			var local_load: float=float(corner_metrics.get("line_load",0.0))
			tactic=CornerBattle.refine(c,ahead,tactic,gap,limit,local_load,float(corner_metrics.get("ahead_load",local_load)),float(weather.get("wetness_factor",0.0)),bool(narrowing.get(id,false)))
			if tactic.has("corner_reason"):
				a["corner_reason"]=tactic.corner_reason
				a["corner_recovery_target"]=rival
		if traffic_pack_enabled and not bool(traffic.lapping):
			tactic=TrafficPack.refine(c,ahead,order,metrics,tactic,traffic_observations[id],gap,length)
			if tactic.has("pack_reason"):a["pack_reason"]=tactic.pack_reason
		# A safely reserved blue-flag yield precedes a fresh attack on a
		# different car. Already established battles never receive a reservation.
		if traffic_intelligence_enabled and a.has("traffic_yield_to"):
			tactic.commit=false
			tactic.defense=false
		if independent_enabled:
			var memory: Dictionary = c.get("racecraft_memory",{})
			# Keep the chosen attacking side until the manoeuvre ends. A blocked
			# corridor cancels the attack instead of immediately switching sides.
			if bool(tactic.commit) and (Coordination.side_locked(c,rival) if coordination_enabled else int(memory.get("attack_target",-1))==rival) and str(memory.get("attack_side","")) not in ["",str(tactic.side)]:
				tactic.commit=false
			if str(memory.get("mode",""))=="ABORT" and float(memory.get("timer",0.0))>0.0:
				tactic.commit=false
			if bool(tactic.commit):
				# Short constant-nominal-pace forecast of third-car occupancy.
				# A veto only; the existing sweep remains the final authority.
				for third in order:
					if third.id==id or third.id==rival: continue
					var g: float=MergeTraffic.relative_gap(float(c.progress),float(third.progress),length)
					if absf(g)>40.0: continue
					var predicted: float=g+0.8*length*(1.0/maxf(1.0,float(metrics[int(third.id)].target))-1.0/maxf(1.0,float(metrics[id].target)))
					if (g*predicted<=0.0 or minf(absf(g),absf(predicted))<LENGTH+2.0) and absf(float(tactic.attack_goal)-float(third.get("race_lane",0.0)))<WIDTH-0.01:
						tactic.commit=false
						break
		var rival_attacking: bool=coordination_enabled and str(d.state) in Independent.ATTACK
		if int(d.defending) < 0 and not rival_attacking:
			# Once the cars approach overlap, the defender must HOLD its actual
			# lane. No late squeeze or return to the racing line during a duel.
			if gap <= LENGTH + 4.0 and (not following_enabled or (gap < LENGTH+1.0 and absf(float(a.lane)-float(d.lane))>=WIDTH-0.01) or bool(tactic.commit)):
				d.goal = float(d.lane)
				d.defending = id
				d.defense_line = float(d.lane)
				if coordination_enabled: d["defense_origin"]="overlap" if gap<LENGTH+1.0 else "attack"
			elif bool(tactic.defense) and (not following_enabled or bool(tactic.commit)) and str(d.state) not in ["attacking", "duel", "preparing"]:
				d.goal = Coordination.defense_goal(ahead,id,gap,float(tactic.defend_goal),limit) if coordination_enabled else clampf(float(tactic.defend_goal),-limit,limit)
				if coordination_enabled: d["defense_origin"]="attack"
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
		var defend_lane: float = float(d.goal) if int(d.defending) == id or rival_attacking else float(d.lane)
		if absf(float(tactic.attack_goal)-defend_lane) < WIDTH - 0.004:
			if str(c.get("combat_state","")) in ["preparing","attacking","duel"]: a.event="yield"
			continue
		a.goal = float(tactic.attack_goal)
		if coordination_enabled: a["committed_goal"]=float(a.goal)
		a.state = "preparing" if absf(float(a.lane)-defend_lane) < WIDTH else ("duel" if gap < LENGTH*2.0 else "attacking")
		a.defender_id = rival
		a.side = str(tactic.side)
		a.margin = float(tactic.margin_m)
		if previous_target != rival or str(c.get("combat_state","clear")) not in ["preparing","attacking","duel"]:
			a.event = "attack"
		if int(d.defending) < 0 and not rival_attacking:
			d.defending = id
			if coordination_enabled: d["defense_origin"]="attack"
			d.goal = float(d.lane) # Too late to make a new defensive move.
			d.defense_line = float(d.lane)
		if str(d.state) == "clear": d.state = "defending"
		# Every duel has a small, symmetric time cost; no boost is granted.
		a.pace += 0.22
		d.pace += 0.08
	if coordination_enabled:
		Coordination.resolve(order,intents)
	# 029: close the loop after tactical commitment. A driver who cannot
	# make a real attack yields longitudinally before seeking the leader's wake.
	# The unchanged occupancy solver decides whether the lane is safe.
	if following_enabled and start_clock_s>=24.0:
		for c in order:
			var id:int=int(c.id)
			var a:Dictionary=intents[id]
			if str(a.state) in ["preparing","attacking","duel"]: continue
			var nearest:Dictionary={}
			var gap:float=INF
			for other in order:
				if other.id==id: continue
				var g:float=MergeTraffic.relative_gap(float(c.progress),float(other.progress),length)
				if absf(g)<=0.000001:
					if MergeTraffic.has_priority(c,other): continue
					g=0.0
				if g>=0.0 and g<gap:
					gap=g
					nearest=other
			if nearest.is_empty() or gap>38.0: continue
			var d:Dictionary=intents[int(nearest.id)]
			var separation:float=absf(float(a.lane)-float(d.lane))
			if separation>0.8 and gap<LENGTH+2.2:
				# Modest lift from nominal forward pace; never halt or reverse.
				# The faster driver can still commit when a safe pass opens.
				a.pace=maxf(float(a.pace),minf(float(a.pace)*1.16,float(d.pace)*1.12))
			if not independent_enabled and (gap>=LENGTH+1.0 or (gap>=LENGTH-0.00001 and separation<=0.8)) and int(a.defending)<0:
				a.goal=float(d.goal)
			# Wake gain only on straights, close and physically aligned.
			if not independent_enabled and gap>=LENGTH and gap<=30.0 and separation<=0.8:
				var load:float=float(metrics[id].get("line_load",1.0))
				var wet:float=clampf(float(weather.get("wetness_factor",0.0)),0.0,1.0)
				if load<0.22:
					a.pace-=0.75*(1.0-gap/38.0)*(1.0-separation/0.8)*(1.0-load/0.22)*(1.0-0.85*wet)
	# 031: own line and frozen observations, not a neighbor's goal.
	if independent_enabled:
		for c in order:
			var id: int = int(c.id)
			var a: Dictionary = intents[id]
			var m: Dictionary = metrics[id]
			var leader: Dictionary = {}
			var gap: float = INF
			var wake_candidates: Array = []
			var lap_km: float = float(track.get("lap_km",0.0))
			var wake_range: float = AeroWake.MAX_RANGE_M*length/(lap_km*1000.0) if lap_km>0.3 else INF
			for other in order:
				if other.id==id: continue
				var g: float = MergeTraffic.relative_gap(float(c.progress),float(other.progress),length)
				if wake_stability and (wake_range==INF or (g>0.0 and g<=wake_range+0.000001)):
					wake_candidates.append(other)
				if g>0.000001 and g<gap and g<=38.0:
					gap=g;leader=other
			var limit: float = minf(lane_limit(track,float(c.progress),shape),lane_limit(track,float(c.progress)+LENGTH*2.0/length,shape))
			var wet: float = clampf(float(weather.get("wetness_factor",0.0)),0.0,1.0)
			var own: float = clampf(float(m.get("line_ratio",0.0)),-1.0,1.0)*limit
			var load: float = float(m.get("line_load",1.0))
			var memory: Dictionary = Independent.decide(c,a,leader,gap,own,limit,load,float(m.get("ahead_load",1.0)),wet,dt,not (wet_line_stability and wet>=0.45))
			# Hold the actual lane in a non-tactical straight. A stable return
			# resumes before the next curve or narrowing; never chase wake laterally.
			if wake_stability and str(a.state) not in Independent.ATTACK and int(a.defending)<0:
				var held: bool = str(c.get("racecraft_memory",{}).get("mode",""))=="STRAIGHT_HOLD"
				var settle: bool = straight_hold_allowed(load,float(m.get("ahead_load",load)),held,bool(narrowing.get(id,false)),float(a.lane),limit,wet,wet_line_stability)
				if corner_battle_enabled:
					settle = CornerBattle.passive_line_settled(load,float(m.get("ahead_load",load)),held,bool(narrowing.get(id,false)),float(a.lane),limit,wet)
				if settle:
					memory.mode="STRAIGHT_HOLD"
					memory.aim=float(a.lane)
					memory.wanted=float(a.lane)
					memory.velocity=0.0
			# 037: after declining a corner attack, settle in the occupied lane
			# until exit instead of immediately seeking a different racing line.
			# Defense, narrowing and the physical solver remain authoritative.
			if corner_battle_enabled and CornerBattle.recovery_hold(str(a.get("corner_reason","")),str(a.state),int(a.defending),float(a.lane),limit,bool(narrowing.get(id,false))):
				memory.mode="CORNER_WAIT"
				memory.aim=float(a.lane)
				memory.wanted=float(a.lane)
				memory.velocity=0.0
				memory["corner_recovery_target"]=int(a.corner_recovery_target)
			if traffic_pack_enabled and TrafficPack.group_hold(c,traffic_observations[id],a,limit,bool(narrowing.get(id,false))):
				memory.mode="BLUE_GROUP_HOLD";memory.aim=float(a.lane);memory.wanted=float(a.lane);memory.velocity=0.0
			a.goal=memory.aim
			a["independent_memory"]=memory
			if aero_wake_enabled:
				# Replace 031 longitudinal aero, do not stack it. Direction and tactical
				# judgement stay independent. Effects apply to attackers too.
				var effect: Dictionary = AeroWake.choose(c,wake_candidates if wake_stability else order,length,lap_km,load,float(m.get("ahead_load",load)),wet,aero_wake_corrected)
				a.pace=AeroWake.apply(float(a.pace),effect)
				a["aero_wake_032"]=effect
			elif not leader.is_empty() and str(a.state) not in Independent.ATTACK:
				a.pace=Independent.longitudinal(float(a.pace),gap,absf(float(a.lane)-float(leader.get("race_lane",0.0))),load,wet)
	if traffic_pack_enabled:
		for c in order:
			var id:int=int(c.id)
			var a:Dictionary=intents[id]
			var policy:Dictionary=TrafficPack.policy(c,traffic_observations[id],a,float(metrics[id].get("line_load",0.0)),float(weather.get("wetness_factor",0.0)),bool(narrowing.get(id,false)))
			a["traffic_policy"]=policy
			a["traffic_kers_skipped"]=bool(metrics[id].get("traffic_kers_skipped",false))
			a.pace=float(a.pace)*(1.0+float(policy.lift))
	# Hold lateral occupancy through overlap, including a recently passed car.
	for c in order:
		var id := int(c.id)
		var a: Dictionary=intents[id]
		for other in order:
			if other.id==id: continue
			# Reject same-lane neighbors before computing circular distance.
			if absf(float(a.lane)-float(other.get("race_lane",0)))<WIDTH-.01: continue
			var gap := absf(MergeTraffic.relative_gap(float(c.progress),float(other.progress),length)) if hotfix else absf(float(c.progress)-float(other.progress))*length
			if gap<LENGTH+1:
				a.goal=a.lane
				break
		var limit := minf(lane_limit(track,float(c.progress),shape),lane_limit(track,float(c.progress)+LENGTH*2/length,shape))
		var wanted := move_toward(float(a.lane),clampf(float(a.goal),-limit,limit),dt*1.8)
		if independent_enabled and a.has("independent_memory") and is_equal_approx(float(a.goal),float(a.independent_memory.aim)):
			wanted = float(a.independent_memory.wanted)
		# Do not enter a third car's occupied corridor.
		for other in order:
			# An unchanged lane cannot newly cross a separated corridor.
			if wanted==float(a.lane): break
			if other.id==id:continue
			if absf(float(a.lane)-float(other.get("race_lane",0)))<WIDTH: continue
			var gap := absf(MergeTraffic.relative_gap(float(c.progress),float(other.progress),length)) if hotfix else absf(float(c.progress)-float(other.progress))*length
			if gap<LENGTH+2 and corridor_crosses(float(a.lane),wanted,float(other.get("race_lane",0)),float(other.get("race_lane",0))):
				if absf(float(a.lane)-float(other.get("race_lane",0)))>=WIDTH:
					wanted=float(a.lane)
					# Never freeze BOTH cars in an exact same-progress, narrow-lane
					# tie. Stable ID order grants one car the forward turn while the
					# other yields, keeping the original no-squeeze lane constraint.
					# This is an experimental diagnostic for the Monaco seed case.
					var ahead_progress: float = float(other.progress)
					var our_progress: float = float(c.progress)
					if hotfix:
						# A stopped lateral move is not a reason for a second brake.
						# queue_027 applies the single longitudinal yield later.
						var relative: float = MergeTraffic.relative_gap(our_progress,ahead_progress,length)
						if absf(float(a.lane))>limit and (relative>0.000001 or (absf(relative)<=0.000001 and not MergeTraffic.has_priority(c,other))):
							a.state="recovering"
					elif absf(float(a.lane))>limit and (
						our_progress < ahead_progress or (
						our_progress == ahead_progress and int(c.id) > int(other.id))):
						a.driving_dt=float(a.driving_dt)*0.55 if merge_traffic_enabled else 0.0
						a.state="recovering"
		a.next_lane=wanted
		a.next=float(c.progress)+float(a.driving_dt)/maxf(1,float(a.pace))
	# Before entering a single corridor, the trailing side yields gradually.
	# Only the trailing car's existing proposed displacement is reduced.
	if merge_traffic_enabled:
		if hotfix:
			MergeTraffic.queue_027(order,intents,narrowing,length,LENGTH,WIDTH)
		else:
			MergeTraffic.queue(order,intents,narrowing,length,LENGTH,WIDTH)
	if wake_stability:
		prevent_convergence(order,intents,length)
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
		if independent_enabled and a.has("independent_memory"):
			var memory: Dictionary = a.independent_memory.duplicate()
			memory.erase("wanted")
			if coordination_enabled and a.has("coordination_reason"):
				memory["coordination_reason"]=a.coordination_reason
			if corner_battle_enabled and a.has("corner_reason"):
				memory["corner_reason"]=a.corner_reason
			if traffic_intelligence_enabled and a.has("traffic_reason"):
				memory["traffic_reason"]=a.traffic_reason
			if traffic_intelligence_enabled and a.has("traffic_yield_to") and str(a.get("defense_origin",""))=="blue_flag" and int(a.defending)==int(a.traffic_yield_to):
				memory["traffic_yield_to"]=int(a.traffic_yield_to)
				memory["traffic_yield_goal"]=float(a.defense_line)
			if str(a.state) in Independent.ATTACK:
				memory["attack_target"]=int(a.target)
				memory["attack_side"]=str(a.side)
			memory.velocity=(float(a.next_lane)-float(a.lane))/maxf(dt,0.00001)
			states["racecraft_memory"]=memory
		if aero_wake_enabled and a.has("aero_wake_032"):
			states["aero_wake_032"]=a.aero_wake_032
		result[id]={"progress":next,"states":states,"event":reaction,"defender_id":int(a.defender_id)}
	# Physical traffic also includes lapped cars; distance wraps at the line.
	for iteration in range(order.size()):
		var changed := false
		for c in order:
			var id := int(c.id)
			for other in order:
				if other.id==id:continue
				var gap := fposmod(float(other.progress)-float(c.progress),1)
				if wake_stability and (gap<.00000001 or gap>1.0-.00000001):
					if MergeTraffic.has_priority(c,other): continue
					gap=0.0
				elif gap>.25 or gap<.00000001:continue
				var b: Dictionary=result[int(other.id)]
				if completion_enabled and gap*length<LENGTH+2.2 and str(intents[id].state) not in ["preparing","attacking","duel"] and absf(float(c.get("race_lane",0))-float(other.get("race_lane",0)))>=WIDTH-0.01:
					# Compare the leader's RESOLVED advance, not nominal lap time.
					# A passive pair must not swap every time the lead car queues
					# behind a third car. A truly stationary leader does not impose
					# this voluntary constraint (free corridor escape remains).
					var leader_advance:float=maxf(0.0,float(b.progress)-float(other.progress))
					if leader_advance>0.00000001:
						var voluntary_limit:float=float(c.progress)+leader_advance*0.88
						if voluntary_limit<float(result[id].progress)-0.000000001:
							result[id].progress=voluntary_limit
							changed=true
				if not corridor_crosses(float(c.get("race_lane",0)),float(result[id].states.race_lane),float(other.get("race_lane",0)),float(b.states.race_lane)): continue
				var offset := float(c.progress)+gap-float(other.progress)
				var allowed := maxf(float(c.progress),float(b.progress)+offset-LENGTH/length)
				# Use remaining headway progressively, not all at once. This is
				# a one-sided speed cap; no minimum speed or collision override.
				if wake_stability and gap*length<LENGTH+4.0:
					var advance: float=maxf(0.0,float(b.progress)-float(other.progress))
					var headroom: float=maxf(0.0,gap-LENGTH/length)
					allowed=minf(allowed,float(c.progress)+advance+headroom*0.5)
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
		if traffic_pack_enabled:result[id].states[TrafficPack.KEY]=TrafficPack.settle(c,traffic_observations[id],intents[id],float(result[id].progress),dt)
	return result
