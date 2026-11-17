extends SceneTree
const Adapter = preload("res://experimental/apex2/scenario_adapter.gd")
const Kernel = preload("res://experimental/apex2/simulation_kernel.gd")
var fails: Array[String] = []
var checks: int = 0
func ck(test: bool, name: String) -> void:
	checks += 1
	if not test: fails.append(name); printerr("APEX2_REPLAY_FAIL ", name)
func _initialize() -> void: call_deferred("run")
func create(scenario: Dictionary):
	var k = Kernel.new()
	ck(k.initialize(scenario), "initialize")
	return k
func run() -> void:
	var scenario: Dictionary = Adapter.create_pair("ITA", "Seco", 12345).scenario
	var original = create(scenario)
	var car_id: int = int(original.snapshot().cars[0].id)
	var tire: String = str(scenario.compounds[-1])
	var tape: Array = [
		{"when": 0, "data": {"type":"set_pace", "source":"AI", "car_id":car_id, "pace":"Atacar"}},
		{"when": 0, "data": {"type":"schedule_pit", "source":"Manual", "car_id":car_id, "requested_lap":6, "compound":tire}},
		{"when": 0, "data": {"type":"order_pit", "source":"AI", "car_id":car_id, "compound":tire}},
		{"when": 300, "data": {"type":"set_pace", "source":"Manual", "car_id":car_id, "pace":"Conservar"}},
		{"when": 450, "data": {"type":"cancel_pit", "source":"Manual", "car_id":car_id}}
	]
	var checkpoints: Dictionary = {}
	var hashes: Dictionary = {}
	for tick in range(800):
		for action in tape:
			if int(action.when) == tick:
				var reply: Dictionary = original.submit(action.data)
				ck(bool(reply.accepted) == (str(action.data.type) != "order_pit"), "expected command acceptance")
		ck(original.step_tick(), "record tick")
		if int(original.state.tick) in [150,300,450,600,800]:
			hashes[int(original.state.tick)] = original.sporting_hash()
			checkpoints[int(original.state.tick)] = original.checkpoint()
	var final_hash: String = original.sporting_hash()
	var serialized: PackedByteArray = var_to_bytes(checkpoints[450])
	var decoded: Variant = bytes_to_var(serialized)
	ck(decoded is Dictionary, "binary checkpoint decode")
	var clone = Kernel.new()
	ck(clone.restore(decoded), "binary restored at 450")
	ck(clone.sporting_hash() == str(hashes[450]), "checkpoint hash matched")
	ck(bool(clone.submit(tape[4].data).accepted), "remaining command after checkpoint resubmitted")
	ck(clone.step_ticks(350) == 350, "continued checkpoint to 800")
	ck(clone.sporting_hash() == final_hash, "checkpoint reached original hash")
	var recorder_state: Dictionary = original.snapshot()
	var replay = create(scenario)
	for tick in range(800):
		for action in tape:
			if int(action.when) == tick:
				replay.submit(action.data)
		ck(replay.step_tick(), "replay tick")
		if int(replay.state.tick) in hashes:
			ck(replay.sporting_hash() == str(hashes[int(replay.state.tick)]), "intermediate replay hash")
	ck(replay.sporting_hash() == final_hash, "deterministic event replay")
	ck(original.snapshot() == recorder_state and original.sporting_hash() == final_hash, "replay never mutated original")
	var guard: Dictionary = decoded.duplicate(true)
	guard.queue.records[0].id = -99
	var unchanged: String = clone.sporting_hash()
	ck(not clone.restore(guard), "reject bad command ledger")
	ck(clone.sporting_hash() == unchanged, "reject is transactional")
	var ok: bool = fails.is_empty()
	print("APEX2_REPLAY_%s checks=%d failures=%s hash=%s" % ["PASS" if ok else "FAIL", checks, str(fails), final_hash])
	quit(0 if ok else 1)
