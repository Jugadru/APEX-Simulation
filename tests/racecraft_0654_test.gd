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
func official_sample(c: Dictionary,lane: float,retreat: float) -> Dictionary:
	var p := sample(c,lane,retreat)
	p["route_length"]=1000.0
	p["half_length"]=2.4
	p["half_width"]=1.25
	return p

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
	# The default envelope remains intact for legacy poses. A measured visual
	# footprint is explicit per pose, not a global reduction in collision safety.
	var a := sample(car(0,0),0.0,0.0)
	var b := sample(car(1,5),0.0,0.0)
	check(R.overlaps(a,b),"legacy envelope unchanged")
	for p in [a,b]:
		p["half_length"] = 2.40
		p["half_width"] = 1.25
	check(not R.overlaps(a,b),"padded scaled meshes have clearance at five units")
	b.position = Vector2(4.7,0)
	check(R.overlaps(a,b),"scaled mesh contact still rejected")
	# Synchronized nominal convoy stays on official poses; crossing still rejects.
	cars=[car(0,0),car(1,8)]
	for c in cars: c["race_lane"]=0.0
	poses=R.solve(cars,{},.5,official_sample)
	for c in cars:
		c.route_point.x+=10.0/.6
		c.progress+=.01
	old=poses
	poses=R.solve(cars,old,.5,official_sample)
	valid(poses,old)
	check(absf(float(poses[0].progress)-float(cars[0].progress))<.000001,"synchronized convoy uses official progress")
	cars[0]=car(0,30)
	cars[0]["race_lane"]=0.0
	check(R.try_official_motion(cars,poses,official_sample).is_empty(),"synchronized crossing rejected")
	# A local lane conflict must not freeze an unrelated convoy.
	cars=[car(0,0),car(1,0),car(2,35)]
	cars[0]["race_lane"]=-2.0
	cars[1]["race_lane"]=2.0
	cars[2]["race_lane"]=0.0
	old=R.solve(cars,{},.5,official_sample)
	for c in cars:
		c.route_point.x+=10.0/.6
		c.progress+=.01
	cars[0]["race_lane"]=0.0
	cars[1]["race_lane"]=0.0
	var repaired := R.try_local_motion(cars,old,official_sample)
	check(repaired.size()==3,"local repair resolves pair")
	if repaired.size()==3:
		valid(repaired,old)
		check(absf(float(repaired[2].progress)-float(cars[2].progress))<.000001,"unrelated car remains official")
		check(float(repaired[0].progress)>=float(old[0].progress) and float(repaired[1].progress)>=float(old[1].progress),"local repair no reverse")
	if failures==0: print("RACECRAFT_PASS attacker / defense / no overlap / continuous sweep / traffic / narrow road / pause / immutable")
	quit(0 if failures==0 else 1)
