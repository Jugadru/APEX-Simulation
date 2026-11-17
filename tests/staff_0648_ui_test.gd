extends SceneTree
## Teste de interação real com a cena, com captura de interface no Xvfb.
var fails: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    if not ok:
        fails.append(label)
        printerr("STAFF_UI_0648_FAIL " + label)

func _run() -> void:
    root.size = Vector2i(1600, 900)
    var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame
    check(game.staff_root != null and not game.staff_root.visible, "tela criada e inicialmente oculta")
    game._open_staff()
    await process_frame
    check(game.staff_root.visible and not game.menu_root.visible, "rota de menu para Staff")
    check(game.staff_market_buttons.size() == 12, "12 candidatos disponíveis")
    check(game.staff_roster_labels.size() == 4, "4 departamentos")
    check(game.staff_card.size.x > 1000 and game.staff_card.size.y > 600, "layout da tela")
    var before: int = int(game.garage.get_team(game.selected_team)["budget"])
    game._hire_staff_candidate("Estrategista", "est_b")
    check(game.staff_notice.text.contains("Miguel"), "feedback do contrato")
    check(int(game.garage.get_team(game.selected_team)["budget"]) == before - 420000, "orçamento real")
    check(game.staff_market_buttons["est_a"].disabled, "bloqueio de novas contratações no cargo")
    game._hire_staff_candidate("Chefe de Mecânica", "mec_c")
    game._hire_staff_candidate("Chefe de Aerodinâmica", "aero_b")
    check(game.staff_roster_labels["Chefe de Mecânica"].text.contains("Nina"), "organograma reflete titular")
    check(game.garage.effective_crew_levels(game.selected_team).get("Precisão", 0) == 2, "mecânica no box")
    game._refresh_staff()
    for step in range(6):
        await process_frame
    var img: Image = root.get_texture().get_image()
    check(img.save_png("res://docs/APEX_0648_TEAM_STAFF_REAL.png") == OK, "screenshot tela")
    for size in [Vector2i(1920, 1080), Vector2i(1600, 900)]:
        root.size = size
        await process_frame
        game._layout_ui()
        check(game.staff_card.position.x >= 0 and game.staff_card.position.y >= 0, "tela dentro da resolução")
    game._show_menu()
    check(not game.staff_root.visible and game.menu_root.visible, "retorno ao menu")
    game._start_race()
    await process_frame
    await process_frame
    check(game.race != null and game.race_hud_0620.visible, "inicia corrida")
    check(not game.staff_root.visible, "gerenciador não sobrepõe a corrida")
    var expected_mechanics: Dictionary = game.garage.effective_crew_levels(game.selected_team)
    check(game.race != null, "motor de produção criado")
    check(int(expected_mechanics.get("Precisão", -1)) == 2, "efeitos ainda vigentes durante GP")
    var original: Array = []
    for car in game.race.player_cars():
        original.append([int(car.get("pit_scheduled_lap", 0)), bool(car.get("pit_request", false))])
    game.race_hud_0620._open_window("engineer")
    check(game.race_hud_0620.overlay_title.text.contains("RACE ENGINEER 3.0"), "Engineer 3 preservado")
    var later: Array = []
    for car in game.race.player_cars():
        later.append([int(car.get("pit_scheduled_lap", 0)), bool(car.get("pit_request", false))])
    check(original == later, "consultar engineer não dispara ordens")
    if fails.is_empty():
        print("STAFF_UI_0648_PASS screen/roster/budget/race/mechanics/Engineer3/responsive")
    quit(0 if fails.is_empty() else 1)
