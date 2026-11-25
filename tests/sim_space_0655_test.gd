extends SceneTree
const Space=preload("res://scripts/core/race_space_0655.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
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
# Exact pre-optimization solver from a0d5765d, test-only oracle.
func reference_physical(order:Array,intents:Dictionary,result:Dictionary,length:float,completion_enabled:bool,wake_stability:bool)->void:
	# Physical traffic also includes lapped cars; distance wraps at the line.
	for iteration in range(order.size()):
		var changed := false
		for c in order:
			var id := int(c.id)
			for other in order:
				if other.id==id:continue
				var gap := fposmod(float(other.progress)-float(c.progress),1)
				if wake_stability and (gap<.00000001 or gap>1.0-.00000001):
					if Merge.has_priority(c,other): continue
					gap=0.0
				elif gap>.25 or gap<.00000001:continue
				var b: Dictionary=result[int(other.id)]
				if completion_enabled and gap*length<Space.LENGTH+2.2 and str(intents[id].state) not in ["preparing","attacking","duel"] and absf(float(c.get("race_lane",0))-float(other.get("race_lane",0)))>=Space.WIDTH-0.01:
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
				if not Space.corridor_crosses(float(c.get("race_lane",0)),float(result[id].states.race_lane),float(other.get("race_lane",0)),float(b.states.race_lane)): continue
				var offset := float(c.progress)+gap-float(other.progress)
				var allowed := maxf(float(c.progress),float(b.progress)+offset-Space.LENGTH/length)
				# Use remaining headway progressively, not all at once. This is
				# a one-sided speed cap; no minimum speed or collision override.
				if wake_stability and gap*length<Space.LENGTH+4.0:
					var advance: float=maxf(0.0,float(b.progress)-float(other.progress))
					var headroom: float=maxf(0.0,gap-Space.LENGTH/length)
					allowed=minf(allowed,float(c.progress)+advance+headroom*0.5)
				if allowed<float(result[id].progress)-.000000001:
					result[id].progress=allowed
					result[id].states.race_space_blocked=true
					changed=true
		if not changed:break

func compare_physical(order:Array,intents:Dictionary,initial:Dictionary,length:float,label:String)->void:
	var frozen:PackedByteArray=var_to_bytes([order,intents,initial])
	for completion in [false,true]:
		for wake in [false,true]:
			var expected:Dictionary=initial.duplicate(true)
			var actual:Dictionary=initial.duplicate(true)
			reference_physical(order,intents,expected,length,completion,wake)
			Space.resolve_physical(order,intents,actual,length,completion,wake)
			check(var_to_bytes(expected)==var_to_bytes(actual),"physical complete result "+label+"/"+str(completion)+"/"+str(wake))
	check(var_to_bytes([order,intents,initial])==frozen,"physical frozen fixture "+label)

func physical_fixture()->void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=93202
	var tactical_states:Array[String]=["clear","preparing","attacking","duel","recovering"]
	for scenario in range(96):
		var length:float=1000.0 if scenario%2==0 else 5300.0
		var center:float=1.0 if scenario%3==0 else 0.4
		var grid:Array=[]
		var intents:Dictionary={}
		var initial:Dictionary={}
		for i in range(24):
			var p:float=center+rng.randf_range(-40.0,40.0)/length
			if i==0 or i==1:p=center
			if i==2:p=center+1.0
			if i==3:p=center+0.000000005
			if i==4:p=center-0.000000005
			if i==5:p=center+0.25
			if i==6:p=center+(Space.LENGTH+2.2)/length
			if i==7:p=center+(Space.LENGTH+4.0)/length
			var lane:float=float(rng.randi_range(-1,1))*Space.WIDTH
			if i==0:lane=0.0
			if i==1:lane=Space.WIDTH
			if i==2:lane=Space.WIDTH-0.01
			var next_lane:float=float(rng.randi_range(-1,1))*Space.WIDTH
			if scenario%4==0:next_lane=lane
			var car:Dictionary=c(i,p,lane)
			grid.append(car)
			intents[i]={"state":tactical_states[rng.randi_range(0,4)]}
			initial[i]={"progress":p+rng.randf_range(0.0,20.0)/length,
				"states":{"race_lane":next_lane,"race_space_blocked":i%4==0,"untouched":i},
				"event":"keep","defender_id":-1}
		if scenario%2==0:grid.reverse()
		compare_physical(grid,intents,initial,length,str(scenario))
	# Deliberately place the follower before the intermediate and stationary
	# leader: the next iteration must propagate the newly resolved constraint.
	var chain:Array=[c(0,0.2),c(1,0.21),c(2,0.22)]
	var intents:Dictionary={}
	var initial:Dictionary={}
	for car in chain:
		var id:int=int(car.id)
		intents[id]={"state":"clear"}
		initial[id]={"progress":float(car.progress)+(0.03 if id<2 else 0.0),
			"states":{"race_lane":0.0,"race_space_blocked":false}}
	compare_physical(chain,intents,initial,1000.0,"multi-pass chain")
	var actual:Dictionary=initial.duplicate(true)
	Space.resolve_physical(chain,intents,actual,1000.0,false,false)
	check(float(actual[0].progress)<=float(actual[1].progress)-Space.LENGTH/1000.0+0.000000001 and bool(actual[0].states.race_space_blocked),"live leader propagation across iterations")
	compare_physical([],{}, {},1000.0,"empty")
	compare_physical([chain[0]],intents,initial,1000.0,"singleton")

func _initialize()->void:
	physical_fixture()
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
