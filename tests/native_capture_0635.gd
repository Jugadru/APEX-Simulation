extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    hud._open_window("radio")
    hud._discuss_stint()
    hud._set_radio_category(2)
    for i in range(15):
        await process_frame
    var screenshot: Image = root.get_texture().get_image()
    var err: int = screenshot.save_png("/mnt/data/Apex_0635_DiscussaoStint_Preview_Godot.png")
    print("APEX 0635 CAPTURE: ", screenshot.get_width(), "x", screenshot.get_height(), " error=", err)
    quit(0 if err == OK else 1)
