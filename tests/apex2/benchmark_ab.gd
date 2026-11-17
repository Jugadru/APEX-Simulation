extends SceneTree
## This measures runtimes, NOT engine superiority: Next Engine omits race physics.
const Adapter = preload("res://experimental/apex2/scenario_adapter.gd")
const Kernel = preload("res://experimental/apex2/simulation_kernel.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const TICKS: int = 128
func _initialize() -> void: call_deferred("run")
func rss_kb() -> int:
	var text: String = FileAccess.get_file_as_string("/proc/self/status")
	for line in text.split("\n"):
		if line.begins_with("VmRSS:"):
			return int(line.replace("VmRSS:", "").replace("kB", "").strip_edges())
	return -1
func run() -> void:
	var rows: Array = []
	for case in [{"track":"GBR", "weather":"Seco"}, {"track":"BEL", "weather":"Chuva intensa"}, {"track":"ITA", "weather":"Seco"}, {"track":"SIN", "weather":"Chuva intensa"}]:
		var pair: Dictionary = Adapter.create_pair(case.track, case.weather, 6701)
		var core = pair.core
		var next = Kernel.new()
		assert(next.initialize(pair.scenario))
		var start_rss: int = rss_kb()
		var start: int = Time.get_ticks_usec()
		var replay = Replay.new()
		replay.attach(core)
		for i in range(TICKS): assert(replay.step_tick())
		var core_elapsed: int = Time.get_ticks_usec() - start
		var rss_core: int = rss_kb()
		start = Time.get_ticks_usec()
		assert(next.step_ticks(TICKS) == TICKS)
		var next_elapsed: int = Time.get_ticks_usec() - start
		var rss_next: int = rss_kb()
		var match: Dictionary = Adapter.side_by_side(core, next.snapshot())
		assert(match.missing_or_mismatched_ids.is_empty())
		var row: Dictionary = {"scenario": str(case.track), "weather": str(case.weather), "seed": 6701, "ticks": TICKS, "core_usec_per_tick": float(core_elapsed) / TICKS, "next_usec_per_tick": float(next_elapsed) / TICKS, "core_ticks_per_second": TICKS * 1000000.0 / maxf(1.0, float(core_elapsed)), "next_ticks_per_second": TICKS * 1000000.0 / maxf(1.0, float(next_elapsed)), "rss_before_kb": start_rss, "rss_after_core_kb": rss_core, "rss_after_next_kb": rss_next, "core_events": int(match.core_events), "next_events": int(match.next_events), "core_clock_s": float(core.clock), "next_clock_s": float(next.state.clock_ms) / 1000.0, "core_hash": str(replay.hashes[-1]), "next_hash": next.sporting_hash(), "physics_rules_equal": false, "comparability": "inputs and tick count only; not a speed ranking"}
		rows.append(row)
		print("APEX2_BENCH_ROW ", JSON.stringify(row))
	var path: String = "res://qa/apex2_next_engine_10/benchmark_ab.json"
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(f != null)
	f.store_string(JSON.stringify({"status":"PASS", "comparability":"NOT_COMPARABLE_PHYSICS", "notes":"Core 2 simulates weather, racecraft, strategy, pits; Next Engine 1.0 tests only kinematic clock and queue; do not claim superiority", "rows": rows}, "  "))
	f.close()
	print("APEX2_BENCH_PASS scenarios=%d ticks=%d" % [rows.size(), TICKS])
	quit()
