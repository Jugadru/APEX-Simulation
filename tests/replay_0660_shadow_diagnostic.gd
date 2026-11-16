extends SceneTree
func _initialize()->void:call_deferred("run")
func capture(name:String)->void:
	for i in range(24):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/replay_0660/diagnostic_"+name+".png")
func run()->void:
	assert(DisplayServer.get_name()!="headless")
	root.size=Vector2i(1600,900)
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(8):await process_frame
	host.set_process(false)
	for i in range(host.season_tracks.size()):
		if host.season_tracks[i].code=="GBR":host.selected_track_index=i
	host.seed_picker.value=6558
	host._start_race()
	host.sim_speed=1.0
	host.race.running=true
	for i in range(210):
		host._process(1.0/60)
		await process_frame
	host.race.running=false
	await capture("original")
	var lights=host.world_view.find_children("*","DirectionalLight3D",true,false)
	for light in lights:light.shadow_enabled=false
	await capture("without_light_shadows")
	for light in lights:light.shadow_enabled=true
	var geometries=host.world_view.find_children("*","GeometryInstance3D",true,false)
	for category in ["barriers","pit","ground"]:
		var altered:=[]
		for mesh in geometries:
			var path:=str(mesh.get_path())
			if (category=="barriers" and ("SafetyMesh" in path or "CorrugatedArmco" in path)) or (category=="pit" and "PitComplex" in path) or (category=="ground" and "PitComplex" in path and mesh is MeshInstance3D and mesh.mesh is BoxMesh and mesh.mesh.size.y < .1):
				altered.append([mesh,mesh.cast_shadow])
				mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		await capture("without_"+category+"_shadows")
		for pair in altered:pair[0].cast_shadow=pair[1]
	print("SHADOW_DIAGNOSTIC_PASS ablations only in test scene, production unchanged")
	quit()
