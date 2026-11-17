extends SceneTree
const A=preload("res://experimental/apex2/scenario_adapter.gd")
const K=preload("res://experimental/apex2/simulation_kernel.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scenario:Dictionary=A.create_pair("BEL", "Chuva intensa", 4404).scenario
	var a=K.new();assert(a.initialize(scenario))
	var id:int=int(a.snapshot().cars[0].id)
	var req:Dictionary={"type":"schedule_pit", "source":"Manual", "car_id":id,"requested_lap":21,"compound":str(scenario.compounds[-1])}
	assert(a.submit(req).accepted)
	var detected:bool=false
	var seen_lap:int=0
	for i in range(16000):
		if not a.step_tick():break
		var car:Dictionary={}
		for c in a.state.cars:
			if int(c.id)==id:car=c;break
		assert(not car.is_empty())
		if int(car.pit_entry_tick)>=0:
			detected=true
			seen_lap=int(car.pit_requested_lap)
			assert(int(car.laps_done)==20)
			break
		if int(car.laps_done)<20:
			assert(int(car.pit_entry_tick)==-1)
	assert(detected and seen_lap==21)
	var entry_events:int=0
	for e in a.state.events:
		if str(e.type)=="pit_entry_boundary" and int(e.car_id)==id:
			entry_events+=1
			assert(int(e.requested_lap)==21)
	assert(entry_events==1)
	var b=K.new();assert(b.initialize(scenario));assert(b.submit(req).accepted)
	assert(b.step_ticks(int(a.state.tick))==int(a.state.tick))
	assert(a.sporting_hash()==b.sporting_hash())
	print("APEX2_PIT_ENTRY_21_PASS tick=%d lap=%d events=%d hash=%s" % [int(a.state.tick),seen_lap,entry_events,a.sporting_hash()])
	quit()
