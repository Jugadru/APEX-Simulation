extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    hud._open_window("radio")
    hud._ask_driver()
    hud._set_radio_category(2)
    for i in range(20):
        await process_frame
    var shot: Image = root.get_texture().get_image()
    var err: int = shot.save_png("/mnt/data/Apex_0633_CategoriasRadio_Preview_Godot.png")
    print("APEX 0633 CAPTURE ", shot.get_width(), "x", shot.get_height(), " err=", err)
    quit(0 if err == OK else 1)
