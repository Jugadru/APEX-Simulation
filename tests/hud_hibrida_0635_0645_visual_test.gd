extends SceneTree
## Regressão visual integrada: skin da 0635 + mecanismos intactos da 0645.
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")
var fails: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    if not condition:
        fails.append(message)
        printerr("HUD_HIBRIDA_FAIL " + message)

func _capture(hud, file: String) -> void:
    for i in range(7):
        await process_frame
    var img: Image = root.get_texture().get_image()
    check(img.get_width() >= 1400, "resolucao de captura")
    check(img.save_png(file) == OK, "captura " + file)

func _run() -> void:
    root.size = Vector2i(1600, 900)
    var scene: PackedScene = load("res://scenes/main.tscn")
    check(scene != null, "cena principal")
    if scene == null:
        quit(2)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    await process_frame
    var hud = game.race_hud_0620
    check(hud != null and hud.visible, "HUD acessível durante corrida")
    if hud == null:
        quit(3)
        return
    check(hud.ACCENT == HudSkin.ORANGE, "tema laranja UI01")
    check(hud.SOUL_ACCENT == HudSkin.TYRE_GREEN, "acento tecnico da UI03")
    check(hud.theme != null, "tema completo na HUD")
    check(hud.media_buttons.size() == 6, "6 atalhos (inclui engenheiro)")
    check(hud.race_card_panels.size() == 2, "2 pilotos")
    check(hud.bottom_bar.size.x <= 270, "controle compacto")
    check(hud.rank_idle_style != null, "rank styles reutilizados")
    check(hud.ranking.position.x == 12.0, "ranking mantido")
    check(hud.map_box.position.y == 157.0, "minimapa mantido")
    check(hud.tiny_top.get_theme_stylebox("panel") != null, "barra UI01")
    root.size = Vector2i(1920, 1080)
    await process_frame
    game._layout_ui()
    hud.layout_hud()
    check(hud.ranking.position.x == 12.0 and hud.map_box.position.y == 157.0, "layout 1920x1080")
    check(hud.race_card_panels[1]["base"].position.x > 1000.0, "cartao direito 1920")
    root.size = Vector2i(1600, 900)
    await process_frame
    game._layout_ui()
    hud.layout_hud()
    hud.refresh_hud()
    await _capture(hud, "res://docs/HUD_HIBRIDA_CORRIDA_1600.png")
    var before: Array = []
    for c in game.race.player_cars():
        before.append([int(c.get("id", -1)), int(c.get("pit_scheduled_lap", 0)), bool(c.get("pit_request", false))])
    hud._open_window("engineer")
    check(hud.active_window == "engineer", "painel engenheiro")
    check(hud.engineer_cards.size() == 2, "2 engenheiros")
    check(hud.overlay_title.text.contains("UI03"), "Race Engineer 2.0")
    check(hud.overlay_title.text.contains("HÍBRIDA"), "rótulo da HUD híbrida")
    await _capture(hud, "res://docs/HUD_HIBRIDA_ENGENHEIRO_1600.png")
    var after: Array = []
    for c in game.race.player_cars():
        after.append([int(c.get("id", -1)), int(c.get("pit_scheduled_lap", 0)), bool(c.get("pit_request", false))])
    check(before == after, "a HUD não executa ordens ou pit")
    hud._close_window()
    check(hud.active_window == "", "fecha modal")
    hud._open_window("radio")
    check(hud.radio_category_buttons.size() == 4, "radio com 4 filtros")
    hud._close_window()
    if fails.is_empty():
        print("HUD_HIBRIDA_PASS visual real 1600x900, 6 atalhos, engineer UI03, radio, pneus, pit intocado")
    quit(0 if fails.is_empty() else 1)
