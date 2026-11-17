extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    for i in range(game.season_tracks.size()):
        if str(game.season_tracks[i].get("code", "")) == "BRA":
            game.selected_track_index = i
            break
    game._start_race()
    await process_frame
    game.race.running = false
    var hud = game.race_hud_0620
    hud._open_window("engineer")
    for i in range(24):
        await process_frame
    var pic: Image = root.get_texture().get_image()
    var result: Error = pic.save_png("user://APEX_0639_Race_Engineer_Preview.png")
    print("APEX 0639 VISUAL CAPTURE: ", pic.get_width(), "x", pic.get_height(), " result=", result,
        " cards=", hud.engineer_cards.size(), " modal=", hud.active_window)
    quit(0 if result == OK and hud.engineer_cards.size() == 2 else 1)
