extends SceneTree
const Occupation = preload("res://scripts/apex_racecraft_0654.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(10): await process_frame
	host._start_race()
	host.set_process(false)
	host.race_hud_0620.hide()
	for child in host.game_root.get_children():
		if child is Control and child != host.world_container: child.hide()
	host.world_container.show()
	var world = host.world_view
	world.occupation.clear()
	var before := JSON.stringify(host.race.cars)
	var pair := [host.race.cars[0].duplicate(true),host.race.cars[3].duplicate(true)]
	pair[0].color = "#ec3434"
	pair[1].color = "#28aeb5"
	var canvas := CanvasLayer.new()
	canvas.layer = 120
	root.add_child(canvas)
	var title := Label.new()
	title.position = Vector2(24,20)
	title.add_theme_font_size_override("font_size",20)
	title.add_theme_color_override("font_shadow_color",Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x",2)
	title.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(title)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/racecraft/frames"))
	for frame in range(45 if "--quick" in OS.get_cmdline_user_args() else 240):
		var phase := "preparing" if frame < 60 else ("attacking" if frame < 180 else "recovering")
		var progress := 0.12+frame*0.000018
		var gap := lerpf(0.009,0.0001,clampf(float(frame)/150.0,0,1))
		if frame >= 180: gap = lerpf(0.0001,-0.015,float(frame-180)/59.0)
		for index in range(2):
			var car: Dictionary = pair[index]
			car.progress = progress-gap if index == 0 else progress
			car.route_point = host.map_view.point_on_track(car.progress)
			car.route_direction = host.map_view.direction_on_track(car.progress)
			car.combat_state = phase if index == 0 else "clear"
			car.combat_target_id = int(pair[1].id) if index == 0 else -1
			car.pit_left = 0
			car.finished = false
			car.drs_active = frame >= 60 and frame < 180
		world.set_race_cars(pair,-1,1.0/30.0)
		var attacker: Dictionary = world.occupation[int(pair[0].id)]
		var defender: Dictionary = world.occupation[int(pair[1].id)]
		assert(not Occupation.overlaps(attacker,defender),"demo cars must not overlap")
		assert(absf(defender.lane)<=.46,"defender must not yield its lane")
		if frame==230: assert((attacker.position-defender.position).dot(defender.direction)>5.6,"pass complete before returning")
		var center: Vector3 = world.track_point_to_world(host.map_view.point_on_track(progress-gap*0.5))
		var d: Vector2 = host.map_view.direction_on_track(progress)
		var forward := Vector3(d.x,0,d.y).normalized()
		var right := Vector3(-forward.z,0,forward.x)
		world.camera_3d.position = center-forward*12.0+right*11.0+Vector3.UP*7.0
		world.camera_3d.look_at(center+Vector3.UP*0.6)
		world.camera_3d.fov = 45.0
		title.text = "APEX / RACECRAFT 0.6.5.4     •     DEMONSTRAÇÃO VISUAL CONTROLADA\n" + {"preparing":"Atacante busca espaço • defensor mantém sua linha", "attacking":"Ultrapassagem pelo corredor livre • DRS aberto", "recovering":"Retorno somente com espaço livre"}[phase]
		await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png("res://qa/racecraft/frames/%04d.png" % frame)
		if frame in [40,120,230]: img.save_png("res://qa/racecraft/demo_%03d.png" % frame)
	assert(JSON.stringify(host.race.cars)==before,"presentation must not mutate race")
	print("GRAPHICS_CAPTURE_PASS 240 native frames; unchanged live race; staged visual fixture")
	quit(0)
