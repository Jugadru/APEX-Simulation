extends RefCounted
## 036: reconcile competitive intents before movement. No position, RNG or
## aerodynamic changes. The existing swept corridor solver owns all motion.
const ATTACK := ["preparing","attacking","duel"]
const WIDTH := 2.95
const EARLY_GAP := 11.5

static func side_locked(car: Dictionary, rival: int) -> bool:
	var memory: Dictionary=car.get("racecraft_memory",{})
	return int(memory.get("attack_target",-1))==rival and str(car.get("combat_state","")) in ATTACK

static func defense_goal(defender: Dictionary, attacker_id: int, gap: float, proposed: float, limit: float) -> float:
	# Late defence holds the actual lane. A prior defence at zero is a
	# valid lock, not an unset value. Never command a move beyond the road.
	if gap<=EARLY_GAP: return clampf(float(defender.get("race_lane",0.0)),-limit,limit)
	if int(defender.get("race_defending_against",-1))==attacker_id:
		return clampf(float(defender.get("race_defense_line",defender.get("race_lane",0.0))),-limit,limit)
	return clampf(proposed,-limit,limit)

static func resolve(order: Array, intents: Dictionary) -> void:
	# Snapshot the final proposed competitive lanes; this makes a
	# three-car chain independent of the order of reconciliation.
	var goals: Dictionary={}
	for car in order:
		var id: int=int(car.id)
		var a: Dictionary=intents[id]
		goals[id]=float(a.get("committed_goal",a.goal)) if str(a.state) in ATTACK else float(a.goal)
	var veto: Array[int]=[]
	# Recheck after a front attack is cancelled. Each round can only
	# remove commitments, so the number of rounds is bounded by the grid.
	for iteration in range(order.size()):
		var round_veto: Array[int]=[]
		for car in order:
			var id: int=int(car.id)
			var a: Dictionary=intents[id]
			if id in veto or not str(a.state) in ATTACK: continue
			var rival: int=int(a.defender_id)
			if not goals.has(rival) or absf(float(goals[id])-float(goals[rival]))<WIDTH-0.004:
				round_veto.append(id)
		if round_veto.is_empty(): break
		for id in round_veto:
			veto.append(id)
			var a: Dictionary=intents[id]
			goals[id]=float(a.defense_line) if int(a.defending)>=0 and str(a.get("defense_origin",""))!="attack" else float(a.lane)
	veto.sort()
	# Cancel only incompatible commitments. Costs/events are paired with
	# the accepted attack; physical occupancy and blue flags remain intact.
	for id in veto:
		var a: Dictionary=intents[id]
		var rival: int=int(a.defender_id)
		a.pace=float(a.pace)-0.22
		a.state="closing"
		a.goal=float(a.defense_line) if int(a.defending)>=0 else float(a.lane)
		a.event="yield" if str(a.event)!="attack" else ""
		a.defender_id=-1
		a.side=""
		a.margin=0.0
		a["coordination_reason"]="conflicting_corridor"
		if not intents.has(rival): continue
		var d: Dictionary=intents[rival]
		d.pace=float(d.pace)-0.08
		if int(d.defending)==id and str(d.get("defense_origin",""))=="attack":
			d.defending=-1
			d.defense_event=false
			if str(d.state)=="defending": d.state="clear"
			if not str(d.state) in ATTACK: d.goal=float(d.lane)
	# A car attacking ahead cannot be directed to defend on another lane.
	for car in order:
		var a: Dictionary=intents[int(car.id)]
		if str(a.state) in ATTACK:
			a.goal=float(a.get("committed_goal",a.goal))
			if int(a.defending)>=0 and str(a.get("defense_origin",""))=="attack":
				a.defending=-1
				a.defense_event=false
