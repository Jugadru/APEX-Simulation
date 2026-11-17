extends SceneTree
const P=preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5):await process_frame
	host._start_race()
	host.set_process(false)
	assert(not P.enabled and P.sections.is_empty())
	var saved_before:=JSON.stringify(host.garage.team_data)
	var key:=InputEventKey.new()
	key.keycode=KEY_F8
	key.pressed=true
	host._input(key)
	assert(host.performance_panel.visible)
	assert(not P.enabled)
	assert(P.metadata.latest_panel_context.has("seed"))
	assert(P.metadata.latest_panel_context.has("weather"))
	host.performance_panel.recording.button_pressed=true
	assert(P.enabled)
	host.performance_panel.recording.button_pressed=false
	assert(not P.enabled)
	host.performance_panel.export_report()
	assert(FileAccess.file_exists("user://apex_performance_0657.json"))
	assert(JSON.stringify(host.garage.team_data)==saved_before)
	host.performance_panel.hide_panel()
	assert(not host.performance_panel.visible)
	print("PERF_PANEL_PASS F8, off by default, context, toggle, export, no garage mutation")
	quit()
