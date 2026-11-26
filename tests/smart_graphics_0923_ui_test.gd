extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("SMART_GRAPHICS_0923_FAIL ", label)

func settle() -> void:
	for i in range(4):
		await process_frame

func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	verify(img != null and not img.is_empty(), "framebuffer " + name)
	if img != null and not img.is_empty():
		verify(img.get_size() == root.size, "dimensions " + name)
		verify(img.save_png("res://qa/smart_graphics_0923/" + name + ".png") == OK, "save " + name)

func run() -> void:
	# Disposable CI process only; test legacy launch opt-in before scene creation.
	OS.set_environment("APEX_GRAPHICS_PROFILE","gtx1650")
	root.size = Vector2i(1600,900)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_process(false)
	var world = game.world_view
	var vp: SubViewport = game.world_viewport
	verify(world.graphics_profile_index == 1, "legacy environment override")
	verify(vp.msaa_3d == Viewport.MSAA_2X and world.sun_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and is_equal_approx(world.sun_light.directional_shadow_max_distance,160.0) and not world.world_environment_3d.environment.ssao_enabled, "exact historical GTX settings")
	game.seed_picker.value = 923
	game._start_race()
	game.race.running = false
	var hud = game.race_hud_0620
	var session = game.replay_session
	var baseline: String = Codec.sporting_hash(game.race,session.policy)
	# The production scene allocates live car models lazily in its first
	# presentation pass. Automatic processing is disabled in this fixture,
	# so run the real frame at zero delta with the race explicitly paused.
	# Never synthesize car nodes or advance a sporting tick to satisfy QA.
	var initial_tick: int = session.tick
	game._process(0.0)
	await settle()
	verify(session.tick == initial_tick and Codec.sporting_hash(game.race,session.policy) == baseline, "initial presentation does not advance race")
	var route_before: PackedVector2Array = world.route.duplicate()
	var model_ids: Array = []
	for node in world.car_root.get_children(): model_ids.append(node.get_instance_id())
	var original_camera: Transform3D = world.camera_3d.transform
	verify(game.race.cars.size() == 24 and model_ids.size() == 24 and world.live_cars.size() == 24, "24 actual cars/models")
	for car in game.race.cars:
		var car_id: int = int(car.id)
		var model: Node3D = world.live_cars.get(car_id)
		verify(is_instance_valid(model) and model.get_parent() == world.car_root, "real model for driver %d" % car_id)
	print("SMART_GRAPHICS_0923_GRID cars=%d models=%d live=%d tick=%d" % [game.race.cars.size(),model_ids.size(),world.live_cars.size(),session.tick])
	hud._open_window("corrida")
	await settle()
	var picker: OptionButton = hud.overlay_content.find_child("GraphicsProfile0923",true,false) as OptionButton
	verify(picker != null and picker.item_count == 3 and picker.selected == 1, "actual race control selector")
	if picker == null:
		quit(1)
		return
	var view_before: int = game.visual_setting
	var mode_before: int = game.render_mode
	for index in [0,2,1,0]:
		picker.select(index)
		picker.item_selected.emit(index)
		verify(world.graphics_profile_index == index, "profile selection " + str(index))
		var expected_msaa: int = [Viewport.MSAA_4X,Viewport.MSAA_2X,Viewport.MSAA_DISABLED][index]
		var expected_distance: float = [240.0,160.0,100.0][index]
		verify(vp.msaa_3d == expected_msaa and is_equal_approx(world.sun_light.directional_shadow_max_distance,expected_distance), "MSAA and shadow distance " + str(index))
		verify(world.world_environment_3d.environment.ssao_enabled == (index == 0), "SSAO " + str(index))
		verify(world.sun_light.directional_shadow_mode == (DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if index == 0 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS), "shadow splits " + str(index))
		verify(game.visual_setting == view_before and game.render_mode == mode_before and world.camera_3d.transform == original_camera, "view and camera unchanged " + str(index))
		verify(Codec.sporting_hash(game.race,session.policy) == baseline, "sporting hash " + str(index))
	var after_ids: Array = []
	for node in world.car_root.get_children(): after_ids.append(node.get_instance_id())
	verify(after_ids == model_ids and world.route == route_before, "no geometry or car rebuild")
	if DisplayServer.get_name() == "headless":
		verify(false,"software renderer required")
	else:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/smart_graphics_0923"))
		await capture("control_standard")
	hud._close_window()
	game._change_visual_setting(1)
	hud._choose_graphics_profile(2)
	verify(game.render_mode == 0 and world.graphics_profile_index == 2, "profile change in 2D does not force 3D")
	game._change_visual_setting(2)
	verify(game.render_mode == 1 and world.graphics_profile_index == 2, "3D resumes selected profile")
	game._process(0.0)
	if DisplayServer.get_name() != "headless":
		await capture("economy_3d")
	var resumed_ids: Array = []
	for node in world.car_root.get_children(): resumed_ids.append(node.get_instance_id())
	verify(resumed_ids == model_ids and world.live_cars.size() == 24, "2D/3D transition retains actual car models")
	verify(session.tick == initial_tick and Codec.sporting_hash(game.race,session.policy) == baseline, "view transitions preserve sporting hash")
	hud._open_window("corrida")
	picker = hud.overlay_content.find_child("GraphicsProfile0923",true,false) as OptionButton
	verify(picker != null and picker.selected == 2, "reopened control shows active profile")
	hud._choose_graphics_profile(0)
	verify(vp.msaa_3d == Viewport.MSAA_4X and world.world_environment_3d.environment.ssao_enabled, "default restored")
	print("SMART_GRAPHICS_0923_REPORT ", JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"native_gpu":false}))
	if failures.is_empty():
		print("SMART_GRAPHICS_0923_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
