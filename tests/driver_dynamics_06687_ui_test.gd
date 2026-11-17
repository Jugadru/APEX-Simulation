extends SceneTree
## End-to-end HUD test for Core 2 Driver Dynamics 2.0 dialogue.
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func check(valid: bool, reason: String) -> void:
    checks += 1
    if not valid:
        failures += 1
        printerr("DRIVER_DYNAMICS_06687_UI_FAIL: " + reason)
func run() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    check(hud != null, "HUD instance exists")
    var player: Dictionary = game.race.player_cars()[0]
    var car_id: int = int(player.id)
    var compound: String = str(game.race.available_pit_compounds()[0])
    # In a live GP, player commands enter the replay queue and apply on a tick.
    check(game.replay_session != null, "Replay command session attached")
    check(game.replay_session.enqueue("schedule_pit", [car_id, compound, 21], game.replay_session.tick + 1), "Queue V21")
    check(game.replay_session.step_tick(), "Apply V21 at next tick")
    check(int(player.get("pit_scheduled_lap", 0)) == 21, "V21 is active before discussion")
    player["laps_done"] = 9
    player["stint_laps"] = 8
    player["last_pit_exit_lap"] = 0
    player["wear"] = 52.0
    player["tyre_heat"] = 0.20
    player["best_lap"] = 100.0
    player["last_lap"] = 103.0
    hud._open_window("radio")
    # Select the first player and request the real HUD interaction.
    var ids: Array = hud.radio_driver_ids
    var idx: int = ids.find(car_id)
    check(idx >= 0, "Driver is in the radio selector")
    hud.radio_driver_picker.select(idx)
    var before: Dictionary = game.race.get_state_snapshot()
    hud._discuss_stint()
    var response: String = str(hud.radio_response_label.text)
    check(response.contains("3.00s"), "UI speaks about measured pace loss")
    check(response.contains("ENGENHEIRO"), "Engineer replies")
    check(response.contains("volta 21"), "Booked pit remains explicit in reply")
    check(int(player.pit_scheduled_lap) == 21 and not bool(player.pit_request), "Radio must never order an early pit")
    check(var_to_bytes(game.race.get_state_snapshot()) == var_to_bytes(before), "No sporting mutation from dialogue")
    var count: int = game.commentary.lines.size()
    hud._discuss_stint()
    check(game.commentary.lines.size() == count, "Cooldown prevents repeated messages")
    if failures == 0:
        print("DRIVER_DYNAMICS_06687_UI_PASS ", {"checks": checks, "booked": 21})
    quit(0 if failures == 0 else 1)
