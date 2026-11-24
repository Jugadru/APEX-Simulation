extends SceneTree
func _initialize()->void:call_deferred("run")
func capture(name:String)->void:
	for i in range(12):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/replay_0660/"+name+".png")
func run()->void:
	root.mode=Window.MODE_FULLSCREEN;root.size=Vector2i(1920,1080)
	var h=load("res://scenes/main.tscn").instantiate();root.add_child(h)
	for i in range(8):await process_frame
	h.set_process(false)
	for i in range(h.season_tracks.size()):
		if h.season_tracks[i].code=="GBR":h.selected_track_index=i
	h.replay_recording_enabled = true
	h.seed_picker.value=6558;h._start_race();h.race.running=true;h.sim_speed=1
	for i in range(210):h._process(1.0/60)
	h.race.running=false;h._process(1.0/60)
	await capture("visual_race_1080")
	var world=h.world_view
	var pit=world.pit_complex
	var slot:int=pit.slot_for("Ferrari")
	var center:Vector3=pit.to_global(Vector3(8,1,pit._slot_z(slot)))
	world.camera_3d.position=pit.to_global(Vector3(-12,14,pit._slot_z(slot)+18))
	world.camera_3d.look_at(center,Vector3.UP)
	await capture("visual_pit_1080")
	var campus=world.course_root.get_node("CircuitLife0660")
	var halls=campus.get_node_or_null("HospitalityBuildings")
	assert(halls!=null and halls.multimesh.instance_count>0)
	var building:Vector3=halls.multimesh.get_instance_transform(0).origin
	world.camera_3d.position=building+Vector3(48,42,56);world.camera_3d.look_at(building,Vector3.UP)
	await capture("visual_campus_1080")
	var replay=load("res://scripts/race_replay_panel_0660.gd").new();h.add_child(replay);replay.setup(h);h.replay_ui=replay
	replay.watch();replay.target.value=10;replay.seek_target();replay.open()
	await capture("visual_replay_1080")
	replay.leave()
	print("VISUAL_0660_PASS 1920x1080 circuit campus, pit, race and replay")
	quit()
