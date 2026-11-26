extends SceneTree
## Manual native-renderer benchmark. Never run on the self-hosted headless Lab.
## Use fresh XDG directories and the same window size / renderer for both profiles.
const STEP := 0.20
const WARMUP_US := 2000000
const SAMPLE_US := 8000000
const MAX_FRAMES := 12000

func _initialize() -> void:
	call_deferred("_run")

func fail(reason: String) -> void:
	printerr("APEX_GRAPHICS_REV2_FAIL ",reason)
	quit(1)

func percentile(sorted: Array[float], q: float) -> float:
	return sorted[clampi(int(ceil(float(sorted.size())*q))-1,0,sorted.size()-1)]

func _run() -> void:
	if OS.get_environment("APEX_GRAPHICS_PROBE")!="1" or DisplayServer.get_name()=="headless":
		fail("explicit native graphical session required")
		return
	var gpu: String=RenderingServer.get_video_adapter_name()
	if gpu.is_empty() or gpu.to_lower().contains("llvmpipe") or gpu.to_lower().contains("softpipe"):
		fail("hardware renderer required")
		return
	var profile: String=OS.get_environment("APEX_GRAPHICS_PROFILE")
	if profile not in ["","gtx1650"]:
		fail("unknown graphics profile")
		return
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	var track_index: int=-1
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].code)=="ITA":track_index=i
	if track_index<0:
		fail("Monza not found")
		return
	host.championship_mode=false
	host.selected_team="Ferrari"
	host.selected_track_index=track_index
	host.seed_picker.value=660
	for i in range(host.weather_mode_picker.item_count):
		if host.weather_mode_picker.get_item_text(i)=="Seco":host.weather_mode_picker.select(i)
	host._start_race()
	if host.race==null or host.race.cars.size()!=24 or not host.game_root.visible or host.race.weather_mode!="Seco":
		fail("race setup mismatch")
		return
	var expected_msaa: int=Viewport.MSAA_2X if profile=="gtx1650" else Viewport.MSAA_4X
	if host.world_viewport.msaa_3d!=expected_msaa:
		fail("MSAA profile did not apply")
		return
	var world_env: WorldEnvironment=host.world_view.world_environment_3d
	if world_env==null or world_env.environment.ssao_enabled!=(profile!="gtx1650"):
		fail("SSAO profile did not apply")
		return
	var shadow_ok: bool=false
	for child in host.world_view.get_children():
		if child is DirectionalLight3D:
			var expected_mode: int=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if profile=="gtx1650" else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			var expected_distance: float=160.0 if profile=="gtx1650" else 240.0
			shadow_ok=child.directional_shadow_mode==expected_mode and is_equal_approx(child.directional_shadow_max_distance,expected_distance)
	if not shadow_ok:
		fail("shadow profile did not apply")
		return
	var results: Array=[]
	# Real 3D at 1x, then Auto strategic view for each accelerated mode.
	# Each mode restarts the same race. No synthetic _process(delta).
	for index in [0,3,4,5]:
		if index!=0:
			host.race.running=false
			host._end_to_menu()
			await process_frame
			host._start_race()
		if host.race==null or host.race.cars.size()!=24 or not host.game_root.visible:
			fail("race restart failed")
			return
		host._change_visual_setting(2 if index==0 else 0)
		host._change_speed(index)
		host.race.running=true
		var warm_start: int=Time.get_ticks_usec()
		while Time.get_ticks_usec()-warm_start<WARMUP_US:
			await process_frame
		if host.replay_session==null:
			fail("live replay scheduler missing")
			return
		var tick_start: int=host.replay_session.tick
		var start: int=Time.get_ticks_usec()
		var last: int=start
		var samples: Array[float]=[]
		while last-start<SAMPLE_US and samples.size()<MAX_FRAMES:
			await process_frame
			var now: int=Time.get_ticks_usec()
			samples.append(float(now-last)/1000.0)
			last=now
		if samples.size()<10 or host.race.finished:
			fail("insufficient live frames or race finished")
			return
		var ticks: int=host.replay_session.tick-tick_start
		var elapsed: float=float(last-start)/1000000.0
		samples.sort()
		results.append({"requested_x":host.sim_speed,"render_mode":host.render_mode,
			"frames":samples.size(),"seconds":elapsed,"fps":float(samples.size())/elapsed,
			"frame_p50_ms":percentile(samples,.50),"frame_p95_ms":percentile(samples,.95),
			"frame_p99_ms":percentile(samples,.99),"max_frame_ms":samples[-1],
			"sporting_ticks":ticks,"effective_x":float(ticks)*STEP/elapsed})
		host.race.running=false
	print("APEX_GRAPHICS_REV2_DONE ",JSON.stringify({"schema":1,"profile":profile if profile!="" else "default",
		"gpu":gpu,"renderer":RenderingServer.get_current_rendering_method(),"window":str(root.size),
		"viewport":str(host.world_viewport.size),"track":"ITA","weather":"Seco","seed":660,"cases":results,
		"limitations":"Wall-clock frame latency, not direct GPU timing. Visual review required; samples use a fixed wall window, not identical final ticks."}))
	quit(0)
