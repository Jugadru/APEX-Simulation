extends SceneTree
const Space=preload("res://scripts/core/race_space_0655.gd")
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;printerr("FAIL ",label)
func c(id:int,p:float,lane:float=0)->Dictionary:
	return {"id":id,"progress":p,"race_lane":lane,"skill":80,"wear":0,"defense_aggression":50,"combat_state":"clear","combat_target_id":-1,"attack_charge":0}
func update(cars:Array,plan:Dictionary)->void:
	for car in cars:
		if plan.has(int(car.id)):
			car.merge(plan[int(car.id)].states,true)
			car.progress=plan[int(car.id)].progress
func safety(cars:Array)->void:
	for a in cars:
		for b in cars:
			if a.id>=b.id:continue
			var distance:=absf(float(a.progress)-float(b.progress))*1000
			if distance<6.399:check(absf(float(a.race_lane)-float(b.race_lane))>=Space.WIDTH-.00001,"occupied bodies separated")
func run_pair(width:float,defense:float=50,skill:float=80,advantage:float=3)->Dictionary:
	var cars=[c(0,.20),c(1,.207 if advantage<1 else .212)]
	cars[1].defense_aggression=defense
	cars[1].skill=skill
	var metrics={0:{"target":100-advantage},1:{"target":100.0}}
	var track={"race_width_m":width,"overtake_zones":[[0.0,1.0]]}
	var passed:=false
	var defended:=false
	var side_seen:=false
	for i in range(2400):
		var before:=JSON.stringify(cars)
		var plan=Space.plan(cars,metrics,.2,track,{"length":1000.0})
		check(JSON.stringify(cars)==before,"frozen input immutable")
		update(cars,plan)
		safety(cars)
		if absf(float(cars[1].race_lane))>.1:defended=true
		if absf(float(cars[0].race_lane))>2:side_seen=true
		if cars[0].progress>cars[1].progress:
			passed=true
			check(side_seen,"must leave racing line before pass")
			break
	return {"passed":passed,"defended":defended,"cars":cars}
func _initialize()->void:
	check(run_pair(8.8).passed,"open corridor permits natural pass")
	check(not run_pair(4.2).passed,"narrow road blocks stronger attacker")
	check(run_pair(8.8).defended,"defender protects a line")
	check(not run_pair(8.8,100,99,.3).passed,"strong defender holds marginal attacker")
	check(run_pair(8.8,0,60,.3).passed,"weaker defense permits same marginal attack")
	# Third car blocks the chosen corridor and the braking leader constrains followers.
	var cars=[c(0,.2),c(1,.207),c(2,.208,2.95)]
	cars[0].combat_state="attacking";cars[0].combat_target_id=1;cars[0].attack_charge=2
	var metrics={0:{"target":80.0},1:{"target":100.0},2:{"target":120.0}}
	for i in range(80):
		update(cars,Space.plan(cars,metrics,.2,{"race_width_m":8.8,"overtake_zones":[[0,1]]},{"length":1000.0}))
		safety(cars)
	# Same physical lane across the timing line, with a lapped car ahead.
	cars=[c(0,1.995),c(1,1.002)]
	var result=Space.plan(cars,{0:{"target":50.0},1:{"target":100.0}},.2,{"race_width_m":4.2},{"length":1000.0})
	check(float(result[0].progress)<=float(result[1].progress)+1-.0064+.000001,"lapped traffic across finish line")
	# Independent of input array ordering.
	var forward=Space.plan(cars,metrics,.2,{}, {"length":1000.0})
	cars.reverse()
	var reverse=Space.plan(cars,metrics,.2,{}, {"length":1000.0})
	check(forward==reverse,"array order independent")
	if failures==0:print("SIM_SPACE_PASS natural pass / no room / defense / third car / lapped traffic / deterministic / immutable")
	quit(0 if failures==0 else 1)
