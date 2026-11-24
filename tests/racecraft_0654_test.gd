extends SceneTree
const R = preload("res://scripts/apex_racecraft_0654.gd")
var failures := 0
var width := 4.4
func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		printerr("FAIL ",label)
func car(id: int,x: float) -> Dictionary:
	return {"id":id,"progress":x/1000.0+1,"route_point":Vector2(x/.6,0),"route_direction":Vector2.RIGHT,"combat_state":"clear","combat_target_id":-1}
func sample(c: Dictionary,lane: float,retreat: float) -> Dictionary:
	lane = clampf(lane,-maxf(0,width-1.45),maxf(0,width-1.45))
	return {"position":c.route_point*.6+Vector2(-retreat,lane),"direction":Vector2.RIGHT,"lane":lane,"progress":float(c.progress)-retreat/1000}
func valid(poses: Dictionary, old: Dictionary = {}) -> void:
	for id in poses:
		check(poses[id].visible,"car remains visible")
		for other in poses:
			if id>=other: continue
			check(not R.overlaps(poses[id],poses[other]),"bodies separated")
			if old.has(id) and old.has(other): check(not R.swept(old[id],poses[id],old[other],poses[other]),"no tunnelling")
func _initialize() -> void:
	var cars := [car(0,0),car(1,12)]
	var poses := R.solve(cars,{},.016,sample)
	cars[0].combat_state = "attacking"
	cars[0].combat_target_id = 1
	var snapshot := JSON.stringify(cars)
	check(R.targets(cars,poses)[1]==0,"defender holds racing line")
	check(absf(R.targets(cars,poses)[0])>2.8,"attacker takes outside corridor")
	for i in range(180):
		cars[0].route_point.x += .7
		cars[1].route_point.x += .45
		for c in cars: c.progress = c.route_point.x*.6/1000+1
		var old := poses
		poses = R.solve(cars,poses,1.0/30,sample)
		valid(poses,old)
	check(poses[0].position.x>poses[1].position.x,"attacker can complete pass")
	check(absf(poses[1].lane)<.001,"defender never opens the door")
	check(R.solve(cars,poses,0,sample)==poses,"pause freezes all positions")
	# A speed jump must not tunnel through a car in the same corridor.
	cars = [car(0,-10),car(1,0)]
	poses = R.solve(cars,{},.016,sample)
	cars[0] = car(0,30)
	cars[1] = car(1,1)
	var old := poses
	poses = R.solve(cars,poses,1,sample)
	valid(poses,old)
	check(poses[0].position.x<poses[1].position.x,"blocked follower waits behind")
	# Single-file road and crowded initial grid.
	width = 2.0
	cars = []
	for i in range(12): cars.append(car(i,-i*.5))
	poses = R.solve(cars,{},.016,sample)
	valid(poses)
	# Early defensive move is limited; attacker chooses the other side.
	width = 4.4
	cars = [car(0,0),car(2,15)]
	cars[0].combat_state="preparing"
	cars[0].combat_target_id=2
	var lanes := R.targets(cars,{})
	check(absf(lanes[2])<=.45 and lanes[0]*lanes[2]<0,"limited early defense")
	var input := JSON.stringify(cars)
	R.solve(cars,{},.016,sample)
	check(JSON.stringify(cars)==input,"race data immutable")
	# A delayed visual pose uses bounded adaptive recovery, rather than
	# teleporting to its official target.
	cars = [car(0,0),car(1,30)]
	poses = R.solve(cars,{},.5,sample)
	poses[0].hold_frames = 2
	poses[0].official_progress = car(0,10).progress
	old = poses
	cars = [car(0,14),car(1,34)]
	input = JSON.stringify(cars)
	var old_snapshot := JSON.stringify(old)
	poses = R.solve(cars,old,.5,sample)
	check(bool(poses[0].get("gradual_recovery",false)),"bounded recovery used")
	check(absf(float(poses[0].position.x)-6.5)<.01,"adaptive catch-up limited to 6.5 units")
	check(float(poses[0].progress)<float(cars[0].progress),"visual lag not silently discarded")
	check(JSON.stringify(cars)==input and JSON.stringify(old)==old_snapshot,"recovery inputs immutable")
	valid(poses,old)
	# Continue recovering on subsequent frames rather than snap after one tick.
	old = poses
	cars = [car(0,18),car(1,38)]
	poses = R.solve(cars,old,.5,sample)
	check(bool(poses[0].get("gradual_recovery",false)),"bounded recovery continues while lag remains")
	check(absf(float(poses[0].position.x)-12.375)<.01,"second catch-up accounts for reduced lag")
	valid(poses,old)
	# Reject a synchronized candidate whose bounded move would hit a rival.
	cars = [car(0,0),car(1,6)]
	poses = R.solve(cars,{},.5,sample)
	poses[0].hold_frames = 2
	poses[0].official_progress = car(0,10).progress
	cars = [car(0,14),car(1,6.5)]
	var resolved := {0:sample(cars[0],0.0,0.0),1:sample(cars[1],0.0,0.0)}
	check(R.gradual_candidate(cars[0],poses,resolved,sample).is_empty(),"unsafe catch-up rejected")
	# A collision between unrelated endpoints cannot veto a local candidate.
	cars = [car(0,0),car(1,30),car(2,100),car(3,110)]
	poses = R.solve(cars,{},.5,sample)
	poses[0].hold_frames = 2
	poses[0].official_progress = car(0,10).progress
	cars = [car(0,14),car(1,34),car(2,105),car(3,106)]
	resolved = {}
	for c in cars:
		resolved[int(c.id)] = sample(c,0.0,0.0)
	check(not R.gradual_candidate(cars[0],poses,resolved,sample).is_empty(),"unrelated pair cannot veto local recovery")
	if failures==0: print("RACECRAFT_PASS attacker / defense / no overlap / continuous sweep / traffic / narrow road / pause / immutable / bounded recovery")
	quit(0 if failures==0 else 1)
