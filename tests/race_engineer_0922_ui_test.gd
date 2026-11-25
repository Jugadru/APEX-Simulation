extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("ENGINEER_0922_UI_FAIL ", label)

func settle() -> void:
	for i in range(4):
		await process_frame

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_process(false)
	game.seed_picker.value = 42
	game._start_race()
	game.race.running = false
	await settle()
	var hud = game.race_hud_0620
	var before: String = Codec.sporting_hash(game.race, game.replay_session.policy)
	hud._open_window("radio")
	await settle()
	check(hud.radio_driver_ids.size() == 2, "two team drivers")
	check(hud.overlay_title.text.contains("4.0"), "new radio title")
	var voice: CheckButton = null
	var subtitles: CheckButton = null
	for node in hud.overlay_content.find_children("*", "CheckButton", true, false):
		if node.text == "VOZ LOCAL":
			voice = node
		elif node.text == "LEGENDAS PT":
			subtitles = node
	check(voice != null and subtitles != null, "voice and subtitles controls")
	if subtitles != null:
		subtitles.button_pressed = false
		check(not game.commentary.radio_subtitles, "subtitle toggle")
		subtitles.button_pressed = true
		check(game.commentary.radio_subtitles, "subtitle re-enabled")
	var sliders: Array[Node] = hud.overlay_content.find_children("*", "HSlider", true, false)
	check(not sliders.is_empty(), "independent radio volume")
	if not sliders.is_empty():
		sliders[0].value = 35
		check(game.commentary.radio_audio.volume == 35, "volume control bound")
	for topic in ["diagnostico","recuperacao","clima","estrategia","kers_drs"]:
		hud._ask_context_0922(topic)
		check(not hud.radio_response_label.text.is_empty(), "actual HUD query " + topic)
	check(Codec.sporting_hash(game.race, game.replay_session.policy) == before, "HUD read-only")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/engineer_0922"))
		for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
			root.size = resolution
			await settle()
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			check(image != null and not image.is_empty(), "native framebuffer " + str(resolution))
			if image != null and not image.is_empty():
				check(image.save_png("res://qa/engineer_0922/radio_%d.png" % resolution.x) == OK, "native capture " + str(resolution))
	print("ENGINEER_0922_UI_REPORT ", JSON.stringify({"checks":checks,"failures":failures,"graphical":DisplayServer.get_name() != "headless"}))
	if failures.is_empty():
		print("ENGINEER_0922_UI_PASS")
	quit(0 if failures.is_empty() else 1)
