extends RefCounted
## Process-local diagnostic aggregates. Inclusive scopes; never sum parent and child.
## No RNG, race state, saved settings, frame histories or per-car labels.
static var enabled := false
static var sections: Dictionary = {}
static var counters: Dictionary = {}
static var metadata: Dictionary = {}
static var recorded_us := 0
static var window_start := 0
const MAX_SECTIONS := 64

static func set_enabled(value: bool) -> void:
	if enabled == value: return
	if value:
		window_start = Time.get_ticks_usec()
	else:
		recorded_us += maxi(0,Time.get_ticks_usec()-window_start)
	enabled = value

static func reset(context: Dictionary = {}) -> void:
	sections.clear()
	counters.clear()
	metadata = context.duplicate(true)
	recorded_us = 0
	window_start = Time.get_ticks_usec() if enabled else 0

static func begin() -> int:
	return Time.get_ticks_usec() if enabled else 0

static func end(section: StringName, started: int) -> void:
	if not enabled or started <= 0: return
	add_sample(section,maxi(0,Time.get_ticks_usec()-started))

static func add_sample(section: StringName, elapsed_us: int) -> void:
	if not enabled or elapsed_us < 0: return
	if not sections.has(section):
		if sections.size() >= MAX_SECTIONS: return
		sections[section] = {"calls":0,"total_us":0,"max_us":0,"min_us":elapsed_us}
	var s: Dictionary = sections[section]
	s.calls = int(s.calls)+1
	s.total_us = int(s.total_us)+elapsed_us
	s.max_us = maxi(int(s.max_us),elapsed_us)
	s.min_us = mini(int(s.min_us),elapsed_us)

static func count(key: StringName, amount: int = 1) -> void:
	if not enabled: return
	if not counters.has(key) and counters.size()>=MAX_SECTIONS: return
	counters[key] = int(counters.get(key,0))+amount

static func snapshot() -> Dictionary:
	var rows := {}
	for key in sections:
		var s: Dictionary = sections[key]
		rows[key] = {"calls":s.calls,"total_ms":float(s.total_us)/1000.0,"mean_ms":float(s.total_us)/maxi(1,int(s.calls))/1000.0,"max_ms":float(s.max_us)/1000.0,"min_ms":float(s.min_us)/1000.0}
	var elapsed := recorded_us+(maxi(0,Time.get_ticks_usec()-window_start) if enabled else 0)
	var headless := DisplayServer.get_name()=="headless"
	var memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	return {"schema":1,"version":"0.6.5.7","enabled":enabled,"inclusive_scopes":true,"active_wall_seconds":float(elapsed)/1000000.0,"sections":rows,"counters":counters.duplicate(),"context":metadata.duplicate(true),
		"environment":{"godot":Engine.get_version_info().string,"os":OS.get_name(),"cpu":OS.get_processor_name(),"logical_cores":OS.get_processor_count(),"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name(),"gpu":RenderingServer.get_video_adapter_name() if not headless else "unavailable/headless","debug_build":OS.is_debug_build()},
		"monitors":{"fps":Performance.get_monitor(Performance.TIME_FPS) if not headless else null,"frame_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0 if not headless else null,"godot_static_bytes":memory if memory>0 else null,"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphan_nodes":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)},
		"limitations":["CPU wall-clock inclusive scopes; nested values overlap.","No GPU time or process RSS measurement.","Godot monitors may lag one second; some unavailable in release.","Profiler overhead is included; benchmarking requires OFF/ON comparison."]}

static func export_json(path: String = "user://apex_performance_0657.json") -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  "))
	file.flush()
	return file.get_error()
