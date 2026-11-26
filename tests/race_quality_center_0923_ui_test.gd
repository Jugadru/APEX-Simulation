extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("RACE_QUALITY_CENTER_FAIL " + label)

func settle() -> void:
	for i in range(4):
		await process_frame

func run() -> void:
	root.gui_embed_subwindows = true
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_process(false)
	game._open_performance_profiler()
	var panel = game.performance_panel
	verify(panel.visible and panel.tabs.get_tab_count() == 2, "existing F8 window and two tabs")
	verify(panel.session_snapshot().state == "inactive", "management no active race")
	panel.hide_panel()
	game.seed_picker.value = 923
	game._start_race()
	if game.race == null or game.replay_session == null:
		verify(false, "real race starts")
		quit(1)
		return
	game.race.running = false
	game._open_performance_profiler()
	panel.tabs.current_tab = 1
	panel.refresh()
	verify(panel.session_snapshot().quality_state == "not_observed", "zero ticks not certified")
	verify(panel.quality_status.text.contains("Aguardando"), "explicit unavailable observation label")
	var session = game.replay_session
	verify(session.step_tick(), "one actual sporting tick")
	game.race.running = false
	var baseline: String = Codec.sporting_hash(game.race,session.policy)
	panel.refresh()
	var s: Dictionary = panel.session_snapshot()
	verify(s.quality_state == "observed" and s.quality.observed_ticks == 1, "observer reused")
	verify(s.effective_x == null and panel.speed_status.text.contains("pausada"), "paused speed unavailable")
	session.racecraft_audit_enabled = false
	panel.refresh()
	verify(panel.session_snapshot().quality_state == "disabled", "disabled observer distinct")
	session.racecraft_audit_enabled = true
	# Presentation fixture only: add a diagnostic sample without modifying sporting state.
	session.racecraft_audit._quality_flag("negative_gap",session.tick,int(game.race.cars[0].id),"dry","gap","-0.1")
	panel.refresh()
	verify(panel.quality_status.text.contains("1 ocorrências"), "observed counter shown")
	verify(panel.quality_tree.get_root().get_child(1).get_child_count() == 1, "sample rendered")
	verify(panel.export_quality() == OK, "quality JSON exported")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://apex_quality_0923.json"))
	verify(data is Dictionary and data.schema == "APEX_QUALITY_CENTER_0923" and data.session.quality.counts.negative_gap == 1, "JSON includes actual diagnosis")
	panel.recording.button_pressed = true
	Perf.add_sample(&"fixture.cpu",1234)
	panel.tabs.current_tab = 0
	panel.refresh()
	verify(panel.report.get_root().get_child_count() >= 1, "CPU sections retained")
	panel.export_report()
	var original: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://apex_performance_0657.json"))
	verify(original is Dictionary and original.schema == 1 and original.sections.has("fixture.cpu"), "original CPU export preserved")
	panel.recording.button_pressed = false
	game.presentation_race = game.race
	game.race.running = true
	game.effective_speed_sample_valid = true
	game.effective_speed_x = 0.0
	verify(panel.session_snapshot().effective_x == 0.0, "zero measured speed is distinct from unavailable")
	game._change_speed(4)
	verify(not game.effective_speed_sample_valid and panel.session_snapshot().effective_x == null, "speed transition invalidates sample")
	game.race.running = false
	verify(Codec.sporting_hash(game.race,session.policy) == baseline, "panel and diagnostic controls preserve sporting hash")
	panel.tabs.current_tab = 1
	panel.refresh()
	if DisplayServer.get_name() == "headless":
		verify(false, "software framebuffer required")
	else:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/quality_0923"))
		for resolution in [Vector2i(1280,720),Vector2i(1600,900)]:
			root.size = resolution
			panel.size = Vector2i(960,620)
			panel.position = (resolution-panel.size)/2
			await settle()
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			verify(image != null and not image.is_empty(), "framebuffer " + str(resolution))
			if image != null and not image.is_empty():
				verify(image.save_png("res://qa/quality_0923/center_%d.png" % resolution.x) == OK, "capture saved")
	panel.hide_panel()
	verify(not panel.visible and not panel.is_processing(), "closed panel stops refresh")
	print("RACE_QUALITY_CENTER_0923_REPORT ", JSON.stringify({"checks":checks,"failures":failures,"graphical":DisplayServer.get_name()!="headless"}))
	if failures.is_empty():
		print("RACE_QUALITY_CENTER_0923_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
