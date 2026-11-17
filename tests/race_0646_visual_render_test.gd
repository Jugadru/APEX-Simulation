extends SceneTree
## Renderização nativa com Godot 4.7.2 / Xvfb; 1600x900 e 1920x1080.
var errors: Array[String] = []
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, msg: String) -> void:
    if not ok:
        errors.append(msg)
        printerr("VISUAL_0646_FAIL " + msg)
func capture(path: String) -> void:
    for i in range(7):
        await process_frame
    var img: Image = root.get_texture().get_image()
    check(img.get_width() >= 1000, "resolution of screenshot")
    check(img.save_png(path) == OK, "save " + path)
func run() -> void:
    root.size=Vector2i(1600,900)
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    check(hud != null and hud.visible,"HUD is visible")
    check(hud.media_buttons.size() == 6, "hybrid six controls")
    game._layout_ui()
    hud.layout_hud()
    hud.refresh_hud()
    await capture("res://docs/RACE_ENGINEER_3_0_HUD_CORRIDA.png")
    hud._open_window("engineer")
    await process_frame
    check(hud.overlay_title.text.contains("RACE ENGINEER 3.0"),"version title")
    check(hud.engineer_cards.size() == 2,"engineer cards")
    await capture("res://docs/RACE_ENGINEER_3_0_PAINEL.png")
    root.size=Vector2i(1920,1080)
    await process_frame
    game._layout_ui()
    hud.layout_hud()
    hud._refresh_engineer_window()
    check(hud.ranking.position.x == 12.0 and hud.map_box.position.y == 157.0,"large screen layout")
    await capture("res://docs/RACE_ENGINEER_3_0_PAINEL_1920.png")
    if errors.is_empty():
        print("RE3_0646_VISUAL_PASS native Godot 1600x900 + 1920x1080, panels, screenshot")
    quit(0 if errors.is_empty() else 1)
