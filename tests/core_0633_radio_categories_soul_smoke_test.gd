extends SceneTree
## Verifica filtros, leitura subjetiva dos pilotos, interações e estado imutável.
const RaceScript = preload("res://scripts/race_engine.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")
const DriverPerception = preload("res://scripts/core/race_driver_perception_0633.gd")
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, message: String) -> bool:
    if not ok:
        printerr("FALHA 0633: " + message)
    return ok
func _run() -> void:
    var good: bool = true
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for entry in season["tracks"]:
        if str(entry.get("code", "")) == "BEL":
            track = entry
            break
    var race = RaceScript.new(season["teams"], "Ferrari", 633, {}, track, {})
    var car: Dictionary = race.player_cars()[0]
    var id: int = int(car["id"])
    good = check(race.schedule_pit(id, "Médio", 21), "ordem V21 ausente") and good
    var snapshot: Dictionary = race.get_state_snapshot()
    var original: String = JSON.stringify(snapshot)
    var perception: Dictionary = DriverPerception.assess(id, snapshot)
    good = check(not perception.is_empty() and bool(perception.get("subjective_only", false)), "percepção inválida") and good
    good = check(DriverPerception.assess(-111, snapshot).is_empty(), "piloto desconhecido") and good
    var cast = Commentary.new()
    cast.reset(633)
    cast._push(20.0, "NARRADOR", "TV apenas", false, "ambient")
    cast._push(21.0, "BOXES", "Equipe rival no box", false, "pit")
    cast._push(22.0, "PILOTO", "RÁDIO FICTÍCIO | Teste piloto", true, "driver_radio")
    cast._push(23.0, "ENGENHEIRO", "Equipe privada", true, "engineer_reply")
    cast._push(24.0, "BOXES", "Nossa parada", true, "pit")
    cast.add_driver_consultation(25.0, str(car["name"]), str(perception["message"]), "Desgaste confirmado pelos sensores.")
    var all_text: String = cast.formatted(0)
    var tv: String = cast.formatted(1)
    var team: String = cast.formatted(2)
    var pilots: String = cast.formatted(3)
    good = check(all_text.contains("TV apenas") and all_text.contains("Nossa parada") and all_text.contains("RÁDIO FICTÍCIO"), "Todos incompleto") and good
    good = check(tv.contains("TV apenas") and tv.contains("Equipe rival no box") and not tv.contains("Equipe privada") and not tv.contains("Teste piloto"), "TV vazou rádio privado") and good
    good = check(team.contains("Equipe privada") and team.contains("Nossa parada") and team.contains("CHEFE") and not team.contains("Equipe rival no box") and not team.contains("TV apenas"), "Filtro EQUIPE incorreto") and good
    good = check(pilots.contains("Teste piloto") and pilots.contains(str(perception["message"])) and not pilots.contains("ENGENHEIRO") and not pilots.contains("CHEFE") and not pilots.contains("Nossa parada"), "Filtro PILOTOS incorreto") and good
    good = check(JSON.stringify(race.get_state_snapshot()) == original, "leitura alterou simulação") and good
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    good = check(hud != null and hud.visible, "HUD não iniciou") and good
    if hud != null:
        hud._open_window("radio")
        good = check(hud.radio_category_buttons.size() == 4 and hud.radio_driver_ids.size() == 2, "quatro filtros ou dois pilotos não aparecem") and good
        hud._set_radio_category(1)
        good = check(hud.radio_category == 1 and not hud.radio_history.text.contains("CHEFE"), "filtro TV da janela") and good
        var before: String = JSON.stringify(game.race.get_state_snapshot())
        hud._ask_driver()
        good = check(hud.radio_category == 2 and hud.radio_response_label.text.contains("ENGENHEIRO") and hud.radio_response_label.text.contains("Sebastian") == (hud.radio_driver_ids.size() > 0 and hud.radio_driver_picker.get_item_text(0).contains("Sebastian")), "consulta piloto/engenheiro incorreta") and good
        good = check(hud.radio_history.text.contains("PILOTO") and hud.radio_history.text.contains("CHEFE"), "resposta da consulta não registrada") and good
        hud._set_radio_category(3)
        good = check(hud.radio_history.text.contains("PILOTO") and not hud.radio_history.text.contains("ENGENHEIRO"), "botão pilotos falhou") and good
        hud._ask_engineer("pneus")
        good = check(hud.radio_category == 2 and hud.radio_history.text.contains("ENGENHEIRO"), "perguntas existentes não trocaram para Equipe") and good
        good = check(JSON.stringify(game.race.get_state_snapshot()) == before, "consulta GUI alterou corrida") and good
        hud._close_window()
        hud._open_window("radio")
        good = check(hud.radio_category == 2 and hud.radio_category_buttons.size() == 4, "abas após reabrir rádio") and good
    if good:
        print("APEX 0.6.3.3 PASS: quatro categorias, isolamento TV, consulta subjetiva e telemetria, sem alteração da simulação")
    quit(0 if good else 1)
