extends SceneTree
const A=preload("res://experimental/apex2/scenario_adapter.gd")
const K=preload("res://experimental/apex2/simulation_kernel.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scenario:Dictionary=A.create_pair("ITA", "Seco", 6701).scenario
	assert(int(scenario.race_laps)==53 and scenario.cars.size()==24)
	var one=K.new();assert(one.initialize(scenario))
	var first_hash:String=one.sporting_hash()
	var checks:Dictionary={}
	for i in range(35000):
		if not one.step_tick(): break
		if int(one.state.tick) % 4000 == 0:checks[int(one.state.tick)] = one.sporting_hash()
	assert(bool(one.state.finished), "all cars must complete 53 reference laps")
	var final_hash:String=one.sporting_hash()
	var final_tick:int=int(one.state.tick)
	var finished:int=0
	for car in one.state.cars:
		if bool(car.finished) and int(car.laps_done)==53:finished+=1
	assert(finished==24)
	var independent=K.new();assert(independent.initialize(scenario));assert(independent.sporting_hash()==first_hash)
	assert(independent.step_ticks(final_tick)==final_tick)
	assert(independent.sporting_hash()==final_hash)
	for n in checks:
		var resumed=K.new();assert(resumed.initialize(scenario));assert(resumed.step_ticks(int(n))==int(n));assert(resumed.sporting_hash()==checks[n])
	print("APEX2_LONG_MONZA_PASS ticks=%d cars=%d hash=%s (EXPERIMENTAL fixed kinematics, not real race results)" % [final_tick,finished,final_hash])
	quit()
