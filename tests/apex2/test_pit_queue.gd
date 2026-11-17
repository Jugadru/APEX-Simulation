extends SceneTree
const A = preload("res://experimental/apex2/scenario_adapter.gd")
const K = preload("res://experimental/apex2/simulation_kernel.gd")
var checks: int = 0
var fails: Array[String] = []
func check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok: fails.append(msg); printerr("APEX2_QUEUE_FAIL ", msg)
func _initialize() -> void: call_deferred("run")
func _car(k, id: int) -> Dictionary:
	for car in k.snapshot().cars:
		if int(car.id) == id: return car
	return {}
func run() -> void:
	var scenario: Dictionary = A.create_pair("BEL", "Chuva intensa", 444).scenario
	var k = K.new()
	check(k.initialize(scenario), "init Spa heavy rain")
	var cars: Array = k.snapshot().cars
	var a: int = int(cars[0].id)
	var b: int = -1
	for car in cars:
		if int(car.id) != a and str(car.team) == str(cars[0].team): b = int(car.id)
	check(b >= 0, "second driver")
	var compound: String = str(scenario.compounds[-1])
	var manual: Dictionary = {"car_id": a, "type": "schedule_pit", "source": "Manual", "requested_lap": 21, "compound": compound}
	var m: Dictionary = k.submit(manual)
	check(bool(m.accepted), "manual V21 accepted")
	check(not bool(k.submit(manual).accepted), "duplicate pending rejected")
	var automated: Dictionary = {"car_id": a, "type": "order_pit", "source": "AI", "compound": compound}
	check(str(k.submit(automated).reason) == "manual_order_protected", "AI cannot replace pending manual")
	check(not bool(k.submit({"car_id": b, "type": "schedule_pit", "source": "Manual", "requested_lap": 21, "compound": compound}).accepted), "double stack scheduling denied by default")
	check(bool(k.submit({"car_id": b, "type": "schedule_pit", "source": "Manual", "requested_lap": 21, "compound": compound, "allow_double_stack": true}).accepted), "explicit double stack scenario permitted")
	check(k.step_tick(), "tick processes manual V21")
	check(int(_car(k,a).pit_requested_lap) == 21, "manual lap recorded")
	check(str(_car(k,a).pit_order_source) == "Manual", "manual owner recorded")
	check(not bool(k.submit(automated).accepted), "AI cannot replace confirmed manual")
	check(int(_car(k,b).pit_requested_lap) == 21, "second manual V21 registered")
	check(k.step_ticks(1600) == 1600, "reach lap 4 in rain")
	check(int(_car(k,a).pit_requested_lap) == 21, "V21 not advanced to V4")
	check(int(_car(k,a).pit_entry_tick) == -1, "no pit entry on lap 4")
	check(str(_car(k,a).pit_stage) == "TRACK", "car remains on track")
	var second_snapshot: Dictionary = k.checkpoint()
	var restored = K.new()
	check(restored.restore(second_snapshot), "queued plans survive checkpoint")
	check(restored.sporting_hash() == k.sporting_hash(), "queue hashes roundtrip")
	var cancel: Dictionary = {"car_id": a, "type": "cancel_pit", "source": "AI"}
	check(not bool(k.submit(cancel).accepted), "AI cancellation blocked")
	cancel.source = "Manual"
	check(bool(k.submit(cancel).accepted), "manual cancellation accepted")
	check(k.step_tick(), "cancel applies next tick")
	check(int(_car(k,a).pit_requested_lap) == 0, "cancel clears V21")
	check(str(_car(k,b).pit_order_source) == "Manual", "teammate plan unaffected")
	check(k.submit({"car_id": a, "type": "set_pace", "source": "Manual", "pace": "Atacar", "at_tick": int(k.state.tick) + 2}).accepted, "future command scheduled")
	check(k.step_tick(), "first wait tick")
	check(str(_car(k,a).pace) == "Normal", "future order not early")
	check(k.step_tick(), "second wait tick")
	check(str(_car(k,a).pace) == "Atacar", "future pace applied on target tick")
	check(not bool(k.submit({"car_id": a, "type": "set_pace", "source": "Manual", "pace": "FAST"}).accepted), "bad pace rejected")
	var invalid = k.checkpoint()
	invalid.queue.records[0].status = "FORGED"
	var h: String = k.sporting_hash()
	check(not k.restore(invalid), "tampered queue checkpoint rejected")
	check(k.sporting_hash() == h, "failed restoration has no effect")
	# Same-tick conflict: AI arrives first, but Manual is resolved first.
	var order_case = K.new()
	check(order_case.initialize(scenario), "same-tick fixture initialized")
	var ai_first: Dictionary = order_case.submit(automated)
	var manual_second: Dictionary = order_case.submit(manual)
	check(bool(ai_first.accepted) and bool(manual_second.accepted), "both concurrent submissions queued")
	check(order_case.step_tick(), "simultaneous commands processed")
	check(int(_car(order_case, a).pit_requested_lap) == 21, "manual V21 wins over earlier AI submission")
	check(str(_car(order_case, a).pit_order_source) == "Manual", "manual authority wins same tick")
	check(str(order_case.queue.records[0].status) == "REJECTED", "earlier automatic command rejected")
	check(str(order_case.queue.records[1].status) == "APPLIED", "later manual command applied")
	check(str(order_case.queue.records[0].reason) == "manual_order_protected", "rejection reason stored")
	check(not bool(order_case.submit({"car_id": a, "type": "schedule_pit", "source": "Manual", "requested_lap": 5, "compound": compound, "at_tick": 1}).accepted), "past tick rejected")
	check(not bool(order_case.submit({"car_id": a, "type": "schedule_pit", "source": "Manual", "requested_lap": "21", "compound": compound}).accepted), "wrong lap type rejected")
	var event_ids: Dictionary = {}
	var last_id: int = 0
	for event in k.snapshot().events:
		check(int(event.id) > last_id, "event ID order")
		event_ids[event.id] = true; last_id = int(event.id)
	check(event_ids.size() == k.snapshot().events.size(), "no duplicate event IDs")
	var ok: bool = fails.is_empty()
	print("APEX2_QUEUE_%s checks=%d failures=%s hash=%s" % ["PASS" if ok else "FAIL", checks, str(fails), k.sporting_hash()])
	quit(0 if ok else 1)
