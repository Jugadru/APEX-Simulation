extends SceneTree
## Godot 4.7.2 — testes do rádio, respostas e preservação de ordens.
const DriverFeedback = preload("res://scripts/core/race_driver_feedback.gd")
const EngineerReply = preload("res://scripts/core/race_engineer_reply.gd")
const RaceScript = preload("res://scripts/race_engine.gd")
const CommentaryScript = preload("res://scripts/apex_commentary.gd")

func _initialize() -> void:
    call_deferred("_run")

func _require(value: bool, detail: String) -> bool:
    if not value:
        printerr("APEX 0631 FALHA: " + detail)
    return value

func _run() -> void:
    var success: bool = true
    var sample: Dictionary = {
        "name": "Piloto de teste", "laps_done": 12, "stint_laps": 12,
        "wear": 86.0, "tire": "Médio", "tyre_heat": 0.1,
        "position": 3, "interval": 0.8, "pit_request": false,
        "pit_left": 0.0, "finished": false, "driver_radio_last_lap": -100,
        "driver_radio_last_kind": "", "pit_scheduled_lap": 21,
        "pit_control_mode": "Manual"
    }
    var report: Dictionary = DriverFeedback.assess(sample, {"wetness_factor": 0.0}, {"cliff": 76.0})
    success = _require(str(report.get("kind", "")) == "aderencia", "Pneu crítico não relatado") and success
    var plan: Dictionary = {"pit_now": true, "compound": "Duro"}
    var response: String = EngineerReply.compose(report, sample, {"wetness_factor": 0.0}, plan, ["Médio", "Duro", "Chuva"])
    success = _require(response.contains("86%") and response.contains("BOX V21") and response.contains("Duro"), "Resposta não usa desgaste, plano e agendamento") and success
    success = _require(not bool(sample["pit_request"]) and int(sample["pit_scheduled_lap"]) == 21,
        "Gerador modificou ordem de box") and success
    sample["driver_radio_last_lap"] = 12
    sample["driver_radio_last_kind"] = "aderencia"
    sample["laps_done"] = 16
    success = _require(DriverFeedback.assess(sample, {"wetness_factor": 0.0}, {"cliff": 76.0}).is_empty(),
        "Mesmo problema repetiu-se após quatro voltas") and success
    sample["laps_done"] = 20
    success = _require(not DriverFeedback.assess(sample, {"wetness_factor": 0.0}, {"cliff": 76.0}).is_empty(),
        "Cooldown impediu reporte após oito voltas") and success
    sample["laps_done"] = 16
    sample["tire"] = "Médio"
    var wet_report: Dictionary = DriverFeedback.assess(sample, {"wetness_factor": 0.74}, {"cliff": 76.0})
    success = _require(str(wet_report.get("kind", "")) == "grip_molhado", "Problema diferente não ganhou prioridade") and success
    var wet_reply: String = EngineerReply.compose(wet_report, sample, {"wetness_factor": 0.74}, {}, ["Intermediário", "Chuva"])
    success = _require(wet_reply.contains("Chuva") and wet_reply.contains("74%"), "Resposta chuva inadequada") and success

    var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    success = _require(season is Dictionary, "Temporada não encontrada") and success
    if not (season is Dictionary):
        quit(1)
        return
    var track: Dictionary = {}
    for entry in season["tracks"]:
        if str(entry.get("code", "")) == "BEL":
            track = entry
            break
    success = _require(not track.is_empty(), "Spa ausente") and success
    if track.is_empty():
        quit(1)
        return
    var race = RaceScript.new(season["teams"], "Ferrari", 631, {}, track, {})
    race.configure_weather("Seco")
    var car: Dictionary = race.player_cars()[0]
    car["laps_done"] = 12
    car["stint_laps"] = 10
    car["wear"] = 86.0
    car["tyre_heat"] = 0.1
    car["interval"] = 3.2
    success = _require(race.schedule_pit(int(car["id"]), "Médio", 21), "Agendamento V21 falhou") and success
    race._on_lap_cross(car)
    success = _require(int(car.get("pit_scheduled_lap", 0)) == 21 and not bool(car.get("pit_request", false)),
        "Rádio alterou ordem V21") and success
    var pilot_lines: int = 0
    var engineer_lines: int = 0
    for event in race.events:
        if int(event.get("driver_id", -1)) != int(car["id"]):
            continue
        if str(event.get("type", "")) == "driver_radio":
            pilot_lines += 1
        if str(event.get("type", "")) == "engineer_reply":
            engineer_lines += 1
    success = _require(pilot_lines == 1 and engineer_lines == 1, "Rádio não produziu exatamente um diálogo") and success
    var cast = CommentaryScript.new()
    cast.reset(631)
    cast.ingest(race, "Ferrari")
    success = _require(cast.formatted(2).contains("Engenheiro para") and cast.formatted(2).contains("BOX V21"),
        "Filtro EQUIPE não apresenta resposta") and success
    success = _require(not cast.formatted(1).contains("Engenheiro para"), "Filtro TV exibiu áudio interno") and success

    var broadcast_race = RaceScript.new(season["teams"], "Ferrari", 632, {}, track, {})
    broadcast_race.running = true
    var cast2 = CommentaryScript.new()
    cast2.reset(632)
    cast2.ingest(broadcast_race, "Ferrari")
    var speaker_id: int = int(broadcast_race.cars[0]["id"])
    for second in range(10, 85, 2):
        broadcast_race.clock = float(second)
        broadcast_race._event("battle", speaker_id, "Simula ataque em pista", 61)
        cast2.ingest(broadcast_race, "Ferrari")
    var battles: int = 0
    for line in cast2.lines:
        if str(line.get("kind", "")) == "battle":
            battles += 1
    success = _require(battles <= 3, "Analista gerou spam de disputas: " + str(battles)) and success
    broadcast_race._event("pass", speaker_id, "Ultrapassagem confirmada", 85)
    cast2.ingest(broadcast_race, "Ferrari")
    var pass_present: bool = false
    for line in cast2.lines:
        if str(line.get("kind", "")) == "pass":
            pass_present = true
    success = _require(pass_present, "Filtro removeu ultrapassagem real") and success
    if not success:
        quit(1)
        return
    print("APEX 0.6.3.1 PASS: diálogo factual, BOX V21, filtros, cooldown, transmissão e ultrapassagem")
    quit(0)
