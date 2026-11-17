extends SceneTree
## 0.6.3.2: perguntas realistas; sem comandos de simulacao; UI e anti-spam.
const InteractiveReply = preload("res://scripts/core/race_engineer_interactive.gd")
const RaceScript = preload("res://scripts/race_engine.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")

func _initialize() -> void:
    call_deferred("_run")

func require_ok(ok: bool, why: String) -> bool:
    if not ok:
        printerr("FALHA 0632: " + why)
    return ok

func _run() -> void:
    var success: bool = true
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for item in season.get("tracks", []):
        if str(item.get("code", "")) == "BEL":
            track = item
    var race = RaceScript.new(season["teams"], "Ferrari", 632, {}, track, {})
    race.configure_weather("Seco")
    var car: Dictionary = race.player_cars()[0]
    var id: int = int(car["id"])
    success = require_ok(race.schedule_pit(id, "Médio", 21), "Agendamento de teste V21") and success
    var before: String = JSON.stringify(race.get_state_snapshot())
    for topic in ["pneus", "ritmo", "trafego", "box"]:
        var reply: Dictionary = InteractiveReply.answer(topic, id, race.get_state_snapshot(), race.get_engineer_advice(id))
        success = require_ok(not reply.is_empty() and str(reply.get("reply", "")) != "", "Resposta ausente " + topic) and success
        if topic == "box":
            success = require_ok(str(reply["reply"]).contains("V21"), "BOX V21 não citado") and success
    success = require_ok(InteractiveReply.answer("inexistente", id, race.get_state_snapshot(), {}).is_empty(), "Assunto desconhecido") and success
    success = require_ok(InteractiveReply.answer("pneus", -99, race.get_state_snapshot(), {}).is_empty(), "Piloto desconhecido") and success
    success = require_ok(JSON.stringify(race.get_state_snapshot()) == before, "Pergunta alterou estado da corrida") and success
    var cast = Commentary.new()
    cast.reset(632)
    cast.add_team_question(float(race.clock), "Como estão os pneus?", str(car["name"]), "Estão em observação.")
    success = require_ok(cast.formatted(2).contains("CHEFE") and cast.formatted(2).contains("ENGENHEIRO"), "Filtro da equipe") and success
    success = require_ok(not cast.formatted(1).contains("Estão em observação"), "Rádio interno vazou para TV") and success
    race.running = true
    cast.reset(632)
    for sec in [15, 50, 85, 120, 155, 190, 225]:
        race.clock = float(sec)
        race._event("battle", id, "Mark Webber prepara ataque a Kamui Kobayashi!", 61)
        cast.ingest(race, "Ferrari")
    var pair_mentions: int = 0
    for line in cast.lines:
        if str(line.get("kind", "")) == "battle":
            pair_mentions += 1
    success = require_ok(pair_mentions <= 2, "Repetição da mesma batalha: %d" % pair_mentions) and success
    race.clock = 226.0
    race._event("pass", id, "Ultrapassagem efetiva!", 85)
    cast.ingest(race, "Ferrari")
    var passed: bool = false
    for line in cast.lines:
        if str(line.get("kind", "")) == "pass":
            passed = true
    success = require_ok(passed, "Ultrapassagem real silenciada") and success
    # Abre a cena real, o menu e a corrida; confere componentes de interação.
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    success = require_ok(hud != null and hud.visible, "HUD não inicializada") and success
    if hud != null:
        hud._open_window("radio")
        success = require_ok(hud.radio_driver_ids.size() == 2 and hud.radio_history != null, "Rádio não contém seleção de pilotos") and success
        var game_id: int = hud.radio_driver_ids[0]
        var game_before: String = JSON.stringify(game.race.get_state_snapshot())
        hud._ask_engineer("pneus")
        success = require_ok(hud.radio_response_label.text.contains("ENGENHEIRO PARA"), "Botão de pergunta sem resposta") and success
        success = require_ok(hud.radio_history.text.contains("CHEFE"), "Histórico não atualizado") and success
        success = require_ok(JSON.stringify(game.race.get_state_snapshot()) == game_before, "Botão mudou corrida") and success
        success = require_ok(game_id >= 0, "Seleção inválida") and success
        hud._close_window()
    if success:
        print("APEX 0.6.3.2 PASS: perguntas, equipe/TV, cooldown de dupla, pit manual, GUI e estado imutável")
        quit(0)
    else:
        quit(1)
