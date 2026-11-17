extends SceneTree
## Capturas diretas do viewport do Godot 4.7.2 + inspeção dos controles.
var fails: Array[String] = []
func verify(ok: bool, text: String) -> void:
    if not ok:
        fails.append(text)
        printerr("SOUL_0650_UI_FAIL: " + text)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.size = Vector2i(1600, 900)
    root.add_child(game)
    await process_frame
    verify(game.staff_root != null and not game.staff_root.visible, "inicialização da nova tela")
    game._open_staff()
    await process_frame
    verify(game.staff_root.visible and not game.menu_root.visible, "rota do menu")
    verify(game.staff_culture_summary.text.contains("SOUL STAFF"), "resumo humanizado")
    verify(game.staff_factory_summary.text.contains("Motor"), "visão de fábrica existente")
    verify(game.staff_soul_action_buttons.size() == 3, "três decisões de gestão")
    verify(game.staff_market_buttons.size() == 12, "12 candidatos preservados")
    verify(game.staff_soul_meters.size() == 4, "4 departamentos")
    verify(game.staff_soul_action_buttons["briefing"].disabled, "sem temporada não permite ação")
    var before: int = int(game.garage.get_team(game.selected_team)["budget"])
    game._hire_staff_candidate("Estrategista", "est_b")
    game._hire_staff_candidate("Engenheiro", "eng_b")
    game._hire_staff_candidate("Chefe de Mecânica", "mec_b")
    game._hire_staff_candidate("Chefe de Aerodinâmica", "aero_b")
    game._refresh_staff()
    await process_frame
    verify(game.staff_roster_labels["Estrategista"].text.contains("Miguel"), "titular exibido")
    verify(game.staff_soul_profile_labels["Estrategista"].text.contains("Analítico"), "personalidade exibida")
    verify(game.staff_soul_voice_labels["Estrategista"].text.contains("dados"), "fala específica do staff")
    verify((game.staff_soul_meters["Estrategista"]["morale"] as ProgressBar).value == 70, "moral inicial medido")
    verify(game.staff_relations_label.text.contains("Estrategista"), "relacionamentos entre departamentos")
    verify(int(game.garage.get_team(game.selected_team)["budget"]) < before, "contratação desconta valores")
    # Rejeitar ação sem temporada mesmo se callback for chamado diretamente.
    var sum_before: int = int(game.garage.get_team(game.selected_team)["budget"])
    game._staff_soul_action("integration")
    verify(int(game.garage.get_team(game.selected_team)["budget"]) == sum_before, "sem gasto em GP avulso")
    for size in [Vector2i(1600, 900), Vector2i(1920, 1080)]:
        root.mode = Window.MODE_FULLSCREEN if size.x == 1920 else Window.MODE_WINDOWED
        root.size = size
        await process_frame
        game._layout_ui()
        for _i in range(7):
            await process_frame
        var card: Control = game.staff_card
        var virtual_size: Vector2 = game.get_viewport_rect().size
        verify(card.position.x >= 0.0 and card.position.y >= 0.0 and
            card.position.x + card.size.x <= virtual_size.x + 1.0 and
            card.position.y + card.size.y <= virtual_size.y + 1.0,
            "layout dentro do canvas virtual em %d x %d" % [size.x, size.y])
        verify(game.staff_relations_label.visible, "indicador de relações disponível")
        var image: Image = root.get_texture().get_image()
        var filename: String = "res://docs/APEX_0650_SOUL_STAFF_%d.png" % size.x
        verify(image.get_width() == size.x and image.get_height() == size.y,
            "captura produz resolução real %d x %d" % [size.x, size.y])
        verify(image.save_png(filename) == OK, "captura nativa %d" % size.x)
    # Fluxo do campeonato libera escolha, uma única vez.
    game._show_menu()
    game._new_championship()
    game._open_staff()
    await process_frame
    verify(not game.staff_soul_action_buttons["briefing"].disabled, "gestão habilitada durante temporada")
    root.mode = Window.MODE_WINDOWED
    root.size = Vector2i(1600,900)
    for _wait in range(6):
        await process_frame
    game._layout_ui()
    verify(root.get_texture().get_image().save_png("res://docs/APEX_0650_TEMPORADA_ACOES_1600.png") == OK,
        "captura gestão habilitada")
    var budget_before: int = int(game.garage.get_team(game.selected_team)["budget"])
    game._staff_soul_action("briefing")
    verify(game.staff_notice.text.contains("BRIEFING"), "feedback de ação")
    verify(int(game.garage.get_team(game.selected_team)["budget"]) == budget_before - 85000, "custo real")
    verify(game.staff_soul_action_buttons["recovery"].disabled, "bloqueio de segunda ação")
    for _wait in range(3):
        await process_frame
    verify(root.get_texture().get_image().save_png("res://docs/APEX_0650_POS_BRIEFING_1600.png") == OK,
        "captura após decisão real")
    var result: String = game.garage.staff_soul_action(game.selected_team, "recovery", 1, 1, 20)
    verify(result.contains("já foi realizada") or result.contains("Ações de equipe"), "sem exploração de cooldown")
    game._show_menu()
    game._start_race()
    await process_frame
    await process_frame
    verify(game.race != null, "motor original inicia")
    verify(game.race_hud_0620 != null, "HUD híbrida existente")
    var pit_before: Array = []
    for car in game.race.player_cars():
        pit_before.append([car.get("pit_scheduled_lap", 0), car.get("pit_request", false)])
    game.race_hud_0620._open_window("simulator")
    var pit_after: Array = []
    for car in game.race.player_cars():
        pit_after.append([car.get("pit_scheduled_lap", 0), car.get("pit_request", false)])
    verify(pit_before == pit_after, "simulador 9.9 não emite ordem de box")
    if fails.is_empty():
        print("SOUL_0650_UI_PASS contract/trait/meters/cohesion/economy/actions/factory/HUD/1600/1920")
    quit(0 if fails.is_empty() else 1)
