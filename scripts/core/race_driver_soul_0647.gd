extends RefCounted
## Apex 0.6.4.7 — Apex Soul Driver 2.0.
## Emotional model and race-local requests. Fictional gameplay personalities.
## Never changes pace, grip, timing, pit orders, tyres or engine RNG.
## This state advances in RaceEngine at each completed lap, even without the HUD.

const BaseSoul = preload("res://scripts/core/race_driver_soul_0645.gd")
const VERSION := "2.0"
const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]

static func initial(car: Dictionary) -> Dictionary:
    var soul: Dictionary = BaseSoul.initial(car)
    var id: int = int(car.get("id", 0))
    # Distinct, reproducible fictional characteristics for each driver ID.
    var sensitivity: float = (float(posmod(id * 13 + 3, 11)) - 5.0) * 1.8
    var initiative: float = 0.35 + float(posmod(id * 7 + 5, 9)) * 0.055
    var teamwork: float = 0.38 + float(posmod(id * 11 + 1, 9)) * 0.058
    soul.merge({
        "version": VERSION, "temperament": "ASSERTIVO" if initiative >= 0.65 else ("CAUTELOSO" if sensitivity >= 3.5 else "EQUILIBRADO"),
        "sensitivity": sensitivity, "initiative": initiative, "teamwork": teamwork,
        "trust": 0.58, "morale": 0.58, "perceived_wear": 0.0,
        "pace_streak": 0, "team_streak": 0, "request_seq": 0,
        "last_request_lap": -100, "kind_last_laps": {},
        "request": {}, "notes": []
    }, true)
    return soul

static func _candidate(kind: String, message: String, reason: String, priority: int) -> Dictionary:
    return {"kind": kind, "message": message, "reason": reason, "priority": priority}

static func update(car: Dictionary, weather: Dictionary, teammate: Dictionary = {}) -> void:
    var lap: int = int(car.get("laps_done", 0))
    var state: Dictionary = car.get("driver_soul", {})
    if state.is_empty():
        state = initial(car)
    # Compatibility for any race initialized before this module was adopted.
    if not state.has("version"):
        var expanded: Dictionary = initial(car)
        expanded.merge(state, true)
        state = expanded
    if lap <= int(state.get("last_lap", 0)) or bool(car.get("finished", false)):
        return
    car["driver_soul"] = state
    # Keep the tested 0645 emotional dynamics and bounded 8-entry history.
    BaseSoul.update(car, weather)
    var soul: Dictionary = car.get("driver_soul", {}).duplicate(true)
    var pos: int = int(car.get("position", 24))
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
    var tire: String = str(car.get("tire", ""))
    var booked: int = int(car.get("pit_scheduled_lap", 0))
    var in_pit: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
    var pressure: float = clampf(float(soul.get("pressure", 0.15)), 0.0, 1.0)
    var confidence: float = clampf(float(soul.get("confidence", 0.55)), 0.20, 0.90)
    var morale: float = clampf(float(soul.get("morale", 0.58)), 0.15, 0.90)
    var initiative: float = clampf(float(soul.get("initiative", 0.55)), 0.0, 1.0)
    var sensitivity: float = float(soul.get("sensitivity", 0.0))
    # Subjective sensation differs from measured wear and never overwrites telemetry.
    var perceived: float = clampf(wear + sensitivity + pressure * 7.0 - (confidence - 0.50) * 24.0, 0.0, 100.0)
    soul["perceived_wear"] = perceived
    var best: float = float(car.get("best_lap", 9999.0))
    var last: float = float(car.get("last_lap", 0.0))
    var valid: bool = best > 25.0 and best < 500.0 and last > 25.0 and last < 500.0
    var slow: bool = valid and last - best >= 1.6 and not in_pit and lap >= 3
    var gap: float = float(car.get("interval", 999.0))
    var mate_ahead: bool = not teammate.is_empty() and pos == int(teammate.get("position", -100)) + 1 and gap >= 0.0 and gap <= 1.5
    var mate_last: float = float(teammate.get("last_lap", 0.0))
    var faster: bool = valid and mate_last > 25.0 and mate_last < 500.0 and (mate_last - last) >= 0.55
    soul["pace_streak"] = int(soul.get("pace_streak", 0)) + 1 if slow else 0
    soul["team_streak"] = int(soul.get("team_streak", 0)) + 1 if mate_ahead and faster else 0
    morale = clampf(morale + (0.009 if not slow else -0.016) - pressure * 0.006, 0.15, 0.90)
    soul["morale"] = morale
    var choices: Array[Dictionary] = []
    if not in_pit:
        if booked > 0 and (wear >= 82.0 or (tire in SLICKS and wet >= 0.42)):
            choices.append(_candidate("revisar_plano",
                "Temos a parada V%d marcada. As condições mudaram; podemos conversar sobre o plano? Não estou pedindo para antecipar automaticamente." % booked,
                "V%d agendada • desgaste %.0f%% • pista %.0f%% úmida" % [booked, wear, wet * 100.0], 98))
        elif booked == 0 and ((tire in SLICKS and wet >= 0.48) or wear >= 86.0):
            choices.append(_candidate("avaliar_box",
                "A aderência está piorando. Peço uma revisão da janela de box; não execute a parada sem a decisão da equipe.",
                "desgaste %.0f%% • pista %.0f%% úmida • %s" % [wear, wet * 100.0, tire], 94))
        if int(soul["team_streak"]) >= 2 and float(soul.get("teamwork", 0.5)) < 0.85:
            choices.append(_candidate("troca_equipe",
                "Estou mais rápido que o companheiro e perto dele. Podemos avaliar a ordem de equipe? Vou aguardar a decisão do pit wall.",
                "P%d / companheiro P%d • gap %.2fs • diferença de volta %.2fs" % [
                    pos, int(teammate.get("position", 0)), gap, mate_last - last], 73))
        if int(soul["pace_streak"]) >= 2 and wear >= 42.0 and booked == 0:
            choices.append(_candidate("perda_ritmo",
                "Não estou encontrando o ritmo. Podemos comparar pneus e tráfego antes de decidir uma parada?",
                "última %.2fs • melhor %.2fs • desgaste %.0f%%" % [last, best, wear], 66))
        if booked == 0 and lap >= 4 and wear >= 27.0 and wear <= 65.0 and wet < 0.18 and perceived < wear - 6.0 and initiative > 0.55:
            choices.append(_candidate("estender_stint",
                "Ainda sinto boa aderência e gostaria de ficar mais algumas voltas. Confirme nos dados antes de mudar o plano.",
                "sensação %.0f%% / desgaste medido %.0f%%" % [perceived, wear], 47))
    choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["priority"]) > int(b["priority"]))
    for item in choices:
        var kind: String = str(item.get("kind", ""))
        var previous_kind: int = int((soul.get("kind_last_laps", {}) as Dictionary).get(kind, -100))
        if lap - previous_kind < 6 or lap - int(soul.get("last_request_lap", -100)) < 3:
            continue
        # Prior requests stay visible until a new meaningful event replaces them.
        var seq: int = int(soul.get("request_seq", 0)) + 1
        soul["request_seq"] = seq
        soul["last_request_lap"] = lap
        var kinds: Dictionary = (soul.get("kind_last_laps", {}) as Dictionary).duplicate()
        kinds[kind] = lap
        soul["kind_last_laps"] = kinds
        soul["request"] = {
            "id": seq, "lap": lap, "kind": kind, "message": str(item["message"]),
            "reason": str(item["reason"]), "priority": int(item["priority"]),
            "answered": false, "answer": ""
        }
        var notes: Array = soul.get("notes", []).duplicate()
        notes.append("V%d · %s: %s" % [lap, kind, str(item["reason"])])
        while notes.size() > 10:
            notes.pop_front()
        soul["notes"] = notes
        break
    car["driver_soul"] = soul

static func latest(car: Dictionary) -> Dictionary:
    return (car.get("driver_soul", {}) as Dictionary).get("request", {}).duplicate(true)

static func respond(car: Dictionary, request_id: int, choice: String) -> Dictionary:
    # Pure soul-memory action; no call into RaceEngine set_pace/order_pit/schedule_pit.
    if choice not in ["ouvir", "explicar"]:
        return {"applied": false, "reason": "Resposta inválida."}
    var soul: Dictionary = (car.get("driver_soul", {}) as Dictionary).duplicate(true)
    var request: Dictionary = soul.get("request", {}).duplicate(true)
    if request.is_empty() or int(request.get("id", -1)) != request_id or bool(request.get("answered", false)):
        return {"applied": false, "reason": "Pedido já respondido ou não encontrado."}
    request["answered"] = true
    request["answer"] = choice
    soul["request"] = request
    var trust: float = float(soul.get("trust", 0.58))
    var morale: float = float(soul.get("morale", 0.58))
    if choice == "ouvir":
        trust = clampf(trust + 0.05, 0.15, 0.95)
        morale = clampf(morale + 0.025, 0.15, 0.90)
    else:
        trust = clampf(trust + 0.015, 0.15, 0.95)
        morale = clampf(morale - 0.008, 0.15, 0.90)
    soul["trust"] = trust
    soul["morale"] = morale
    var text: String = ("Ouvido. Vou manter o foco e atualizar minhas sensações. Entendi que nenhuma ordem foi enviada." if choice == "ouvir"
        else "Entendido. Vou seguir o plano confirmado e avisar se as condições mudarem.")
    var notes: Array = soul.get("notes", []).duplicate()
    notes.append("V%d · resposta: %s" % [int(car.get("laps_done", 0)), choice])
    while notes.size() > 10:
        notes.pop_front()
    soul["notes"] = notes
    car["driver_soul"] = soul
    return {"applied": true, "driver": text, "engineer":
        "Recebido. Rádio registrado; sem alteração de pit, ritmo, pneus ou ordens."}

static func summary(car: Dictionary) -> String:
    var soul: Dictionary = car.get("driver_soul", initial(car))
    var result: String = "SOUL %s · %s · pressão %d%% · foco %d%% · moral %d%% · confiança equipe %d%% · %s" % [
        str(soul.get("version", VERSION)), str(soul.get("temperament", "EQUILIBRADO")), int(float(soul.get("pressure", 0.0)) * 100.0),
        int(float(soul.get("focus", 0.85)) * 100.0), int(float(soul.get("morale", 0.58)) * 100.0),
        int(float(soul.get("trust", 0.58)) * 100.0), str(soul.get("cause", "Pista"))]
    if str(soul.get("version", "")) == "3.0":
        result += " · decisão " + str(soul.get("racing_intent", "MANTER"))
    return result
