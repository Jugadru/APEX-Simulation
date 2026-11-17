extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.seed_picker.value = 660
	scene._start_race()
	var race = scene.race
	var hud = scene.race_hud_0620
	var reference: String = Codec.sporting_hash(race, scene.replay_session.policy)
	var panels_hidden: bool = not scene.left_panel.visible and not scene.right_panel.visible and not scene.player_card_strip.visible and not scene.telemetry_panel.visible
	for i in range(20):
		scene._update_game_ui()
	var start: int = Time.get_ticks_usec()
	for i in range(160):
		scene._update_game_ui()
	var elapsed_ms: float = float(Time.get_ticks_usec() - start) / 1000.0
	var still_same: bool = Codec.sporting_hash(race, scene.replay_session.policy) == reference
	var result = {"status":"PASS" if still_same and panels_hidden else "FAIL", "count":160,"elapsed_ms":elapsed_ms, "avg_ms":elapsed_ms/160.0, "panels_hidden":panels_hidden,"sporting_hash_unchanged":still_same, "rank_rows":hud.standing_rows.size(),"hud_mode":hud.hud_mode}
	print("APEX_06684_UI_BENCH ",JSON.stringify(result))
	quit(0 if still_same and panels_hidden else 1)
