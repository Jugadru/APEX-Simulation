extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    hud._open_window("radio")
    hud._discuss_stint()
    hud._answer_stint("piloto")
    for i in range(12):
        await process_frame
    var screenshot: Image = root.get_texture().get_image()
    var path: String = "/mnt/data/Apex_0636_SoulDriver_Preview.png"
    var err: int = screenshot.save_png(path)
    print("APEX 0636 VISUAL:", screenshot.get_width(), "x", screenshot.get_height(), " error=", err)
    quit(0 if err == OK else 1)
