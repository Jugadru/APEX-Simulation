extends SceneTree
const Adapter = preload("res://experimental/apex2/scenario_adapter.gd")
const Kernel = preload("res://experimental/apex2/simulation_kernel.gd")
var checks: int = 0
var errors: Array[String] = []
func verify(ok: bool, desc: String) -> void:
	checks += 1
	if not ok:
		errors.append(desc)
		printerr("APEX2_KERNEL_FAIL ", desc)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var pair: Dictionary = Adapter.create_pair("GBR", "Seco", 2100)
	verify(not pair.is_empty(), "official 2012 Silverstone scenario found")
	var scenario: Dictionary = pair.scenario
	verify(scenario.cars.size() == 24 and scenario.race_laps == 52, "24 cars and 52 laps")
	var k = Kernel.new()
	verify(k.initialize(scenario), "initialize isolated kernel")
	verify(k.snapshot().cars.size() == 24, "car identities")
	var before: Dictionary = k.snapshot()
	var view: Dictionary = k.snapshot()
	view.cars[0].tire = "BAD"
	verify(k.snapshot() == before, "snapshot mutation isolated")
	verify(not k.initialize({"cars": []}), "invalid init rejected")
	verify(k.step_ticks(500) == 500, "500 ticks advanced")
	verify(int(k.snapshot().clock_ms) == 100000, "elapsed sports clock 100 sec")
	verify(int(k.snapshot().tick) == 500, "tick index exact")
	verify(k.snapshot().cars.size() == 24, "no entities lost")
	var one = Kernel.new()
	verify(one.initialize(scenario), "restart from seed")
	for i in range(500): verify(one.step_tick(), "tick step %d" % i)
	verify(one.sporting_hash() == k.sporting_hash(), "500 scalar vs grouped hash")
	var checkpoint: Dictionary = k.checkpoint()
	var restore = Kernel.new()
	verify(restore.restore(checkpoint), "checkpoint restored")
	verify(restore.sporting_hash() == k.sporting_hash(), "hash after restore")
	verify(restore.step_ticks(128) == k.step_ticks(128), "post restore same ticks")
	verify(restore.sporting_hash() == k.sporting_hash(), "post restore same hash")
	var broken: Dictionary = checkpoint.duplicate(true)
	broken.state.cars[0].progress_units = 10000000000
	var old_hash: String = restore.sporting_hash()
	verify(not restore.restore(broken), "forged state hash rejected")
	verify(restore.sporting_hash() == old_hash, "invalid restore transactional")
	var replay = Kernel.new()
	verify(replay.initialize(scenario) and replay.step_ticks(628) == 628, "pure replay on independent object")
	verify(replay.sporting_hash() == k.sporting_hash(), "independent replay matches")
	verify(k.sporting_hash() == old_hash, "replay cannot mutate original")
	var different: Dictionary = scenario.duplicate(true)
	different.seed = 2101
	var alt = Kernel.new()
	verify(alt.initialize(different), "alternate seed initialized")
	verify(alt.sporting_hash() != k.sporting_hash(), "seed participates in hash")
	var ids: Dictionary = {}
	for car in k.snapshot().cars: ids[int(car.id)] = true
	verify(ids.size() == 24, "all IDs unique")
	verify( not k.snapshot().events.is_empty(), "lap events generated")
	var success: bool = errors.is_empty()
	print("APEX2_KERNEL_%s checks=%d errors=%s hash=%s" % ["PASS" if success else "FAIL", checks, str(errors), k.sporting_hash()])
	quit(0 if success else 1)
