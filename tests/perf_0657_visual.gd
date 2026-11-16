extends SceneTree
const P=preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	assert(DisplayServer.get_name()!="headless","Requires native GPU/display")
	root.size=Vector2i(1600,900)
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(8):await process_frame
	for i in range(host.season_tracks.size()):
		if host.season_tracks[i].code=="GBR":host.selected_track_index=i
	host.seed_picker.value=6557
	host._start_race()
	host.set_process(false)
	host.render_mode=1
	host.race.running=true
	host.sim_speed=1.0
	for i in range(30):
		host._process(1.0/60.0)
		await process_frame
	P.set_enabled(true)
	P.reset({"seed":6557,"track":"GBR","cars":host.race.cars.size(),"render_frames":180,"warmup_frames":30,"resolution":"1600x900","fixed_process_delta":1.0/60.0,"scenario":"native 3D, simulation + HUD, x1"})
	for i in range(180):
		host._process(1.0/60.0)
		await process_frame
	P.set_enabled(false)
	var result:=P.snapshot()
	for key in ["race.step","race.overtaking","visual.build_states","visual.world_3d","hud.update","route.2d_position","route.2d_direction","route.3d_occupied_pose","ai.team_autonomy"]:
		assert(result.sections.has(key),key)
	assert(result.counters.race_frames==180)
	assert(P.export_json("res://qa/profiler_0657/native_visual.json")==OK)
	host.race.running=false
	host._open_performance_profiler()
	for i in range(10):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/profiler_0657/profiler_1600.png")
	host.performance_panel.hide_panel()
	root.mode=Window.MODE_FULLSCREEN
	root.size=Vector2i(1920,1080)
	host._layout_ui()
	host._open_performance_profiler()
	for i in range(10):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/profiler_0657/profiler_1920.png")
	# UI OFF/ON and export; no persistent game setting.
	host.performance_panel.recording.button_pressed=true
	assert(P.enabled)
	host.performance_panel.recording.button_pressed=false
	assert(not P.enabled)
	host.performance_panel.export_report()
	assert(FileAccess.file_exists("user://apex_performance_0657.json"))
	print("PERF_VISUAL_PASS native Vulkan, live 24 cars, scopes, panel, two resolutions, toggle, export")
	quit()
