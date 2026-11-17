extends SceneTree
## Visual CPU regression: legacy panels must stay untouched while ReBroadcast is active.
## ReBroadcast and the sporting state must still reflect the actual race.
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var count: int = 0
var failures: Array[String] = []
func check(condition: bool, reason: String) -> void:
	count += 1
	if not condition:
		failures.append(reason)
		printerr("APEX_06684_FAIL ", reason)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host.seed_picker.value = 660
	host._start_race()
	var hud = host.race_hud_0620
	check(hud != null and hud.visible, "ReBroadcast active")
	check(host.left_panel != null and not host.left_panel.is_visible_in_tree(), "legacy leaderboard hidden")
	check(host.right_panel != null and not host.right_panel.is_visible_in_tree(), "legacy pitwall hidden")
	check(host.telemetry_panel != null and not host.telemetry_panel.is_visible_in_tree(), "legacy telemetry hidden")
	check(host.player_card_strip != null and not host.player_card_strip.is_visible_in_tree(), "legacy driver cards hidden")
	var id: int = int(host.race.player_cars()[0].get("id", -1))
	var before: String = Codec.sporting_hash(host.race, host.replay_session.policy)
	var old_label: Label = host.main_rows[0]["pos"]
	var old_player: Label = host.player_cards[0]["title"]
	var old_strategy: Label = host.strategy_primary
	var old_telemetry: Label = host.telemetry_summary_label
	var old_diagnostic: Label = host.diagnostic_primary
	old_label.text = "LEGACY_ROW_SENTINEL"
	old_player.text = "LEGACY_CARD_SENTINEL"
	old_strategy.text = "LEGACY_STRATEGY_SENTINEL"
	old_telemetry.text = "LEGACY_TELEMETRY_SENTINEL"
	old_diagnostic.text = "LEGACY_DIAGNOSTIC_SENTINEL"
	for i in range(4):
		host._update_game_ui()
	check(old_label.text == "LEGACY_ROW_SENTINEL", "hidden leaderboard not redrawn")
	check(old_player.text == "LEGACY_CARD_SENTINEL", "hidden legacy card not redrawn")
	check(old_strategy.text == "LEGACY_STRATEGY_SENTINEL", "hidden legacy pit wall not redrawn")
	check(old_telemetry.text == "LEGACY_TELEMETRY_SENTINEL", "hidden legacy telemetry not redrawn")
	check(old_diagnostic.text == "LEGACY_DIAGNOSTIC_SENTINEL", "hidden diagnostics not redrawn")
	check(hud.standing_rows.size() == 24, "active leaderboard still contains 24 slots")
	check(hud.race_card_panels.size() == 2, "active HUD retains two driver cards")
	check(Codec.sporting_hash(host.race, host.replay_session.policy) == before, "rendering never modifies sporting hash")
	# Correctly recover legacy visuals if they are ever explicitly made visible.
	host.left_panel.show()
	check(host.left_panel.is_visible_in_tree(), "legacy leaderboard can be re-shown explicitly")
	host._update_game_ui()
	check(old_label.text != "LEGACY_ROW_SENTINEL", "visible legacy scoreboard is refreshed")
	host.left_panel.hide()
	check(host.race.schedule_pit(id, host.race.available_pit_compounds()[0], 21), "manual order queued in official engine")
	hud.refresh_hud()
	check(Codec.sporting_hash(host.race, host.replay_session.policy) == before, "pit order pending is non-mutating")
	check(host.replay_session.step_tick(), "queued manual order executed on tick")
	check(int(host.race.player_cars()[0].get("pit_scheduled_lap",0)) == 21, "manual V21 preserved")
	print("APEX_06684_HIDDEN_LEGACY ", JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"issues":failures}))
	quit(0 if failures.is_empty() else 1)
