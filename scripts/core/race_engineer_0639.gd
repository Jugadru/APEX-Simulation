extends RefCounted
## APEX 0.6.3.9 — Race Engineer.
## Read-only strategy assessment. The RaceEngine remains the only source of truth.
## Uses pre-existing staff autonomy, tire planner and true race state.
## Does not simulate invented sensors or assign psychological traits to real drivers.

const TeamAutonomy = preload("res://scripts/core/race_team_autonomy.gd")

static func evaluate(car: Dictionary, advice: Dictionary, weather: Dictionary, staff: Dictionary, race_laps: int) -> Dictionary:
    var original: Dictionary = TeamAutonomy.decide(car, advice, weather, staff, race_laps)
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var water: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
    var lap_number: int = int(car.get("laps_done", 0))
    var left: int = maxi(0, race_laps - lap_number)
    var gap: float = float(car.get("interval", 999.0))
    var booked: int = int(car.get("pit_scheduled_lap", 0))
    var pit_busy: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
    var tyre: String = str(car.get("tire", "Médio"))
    var compound: String = str(advice.get("compound", ""))
    var urgent: bool = bool(advice.get("pit_now", false)) and not pit_busy and left >= 2
    var next_lap: int = int(advice.get("planned_pit_lap", 0))
    var stage: String = "ESTÁVEL"
    var briefing: String = "Ritmo controlado. Vamos monitorar o próximo setor e a tendência dos pneus."
    var priority: int = 0
    if bool(car.get("finished", false)) or left == 0:
        stage = "FINALIZADO"
        briefing = "Corrida encerrada para este carro. Ordens bloqueadas."
    elif pit_busy:
        stage = "BOX EM EXECUÇÃO"
        briefing = "Procedimento de box já autorizado. Aguardar entrada, serviço e saída."
    elif booked > 0:
        stage = "BOX MANUAL V%d" % booked
        briefing = "Sua ordem para a volta %d está protegida. O engenheiro não pode antecipá-la." % booked
        if urgent:
            briefing += " Os dados recomendam reavaliar, mas é necessária uma nova ordem explícita."
        priority = 2 if urgent else 1
    elif urgent:
        stage = "RECOMENDAÇÃO DE BOX"
        briefing = "Troca sugerida: %s. %s. Custo de parada e janela foram considerados." % [compound, str(advice.get("reason", "estratégia"))]
        priority = 3
    elif water >= 0.38 and tyre not in ["Chuva", "Intermediário"]:
        stage = "ADERÊNCIA EM RISCO"
        briefing = "Água na pista %.0f%%. Pneu %s exige cautela; estudando a transição." % [water * 100.0, tyre]
        priority = 2
    elif wear >= 82.0:
        stage = "DESGASTE ELEVADO"
        briefing = "%s com %.0f%% de desgaste. Evitar agressividade e acompanhar o ritmo." % [tyre, wear]
        priority = 2
    elif next_lap > lap_number and next_lap < race_laps:
        stage = "JANELA V%d" % next_lap
        briefing = "Próxima parada estimada: V%d, %s. É previsão, não ordem de box." % [next_lap, compound]
        priority = 1
    elif gap < 1.2 and int(car.get("position", 24)) > 1:
        stage = "DISPUTA PRÓXIMA"
        briefing = "Carro à frente a %.2fs. Há chance de ataque; preservar pneus se o ritmo cair." % gap
        priority = 1
    elif left <= 3:
        stage = "RETAS FINAIS"
        briefing = "Restam %d voltas. Ajustar ataque conforme desgaste e espaço disponível." % left
        priority = 1
    var confidence: String = "LIMITADA" if water >= 0.20 else ("MODERADA" if wear >= 70.0 else "NORMAL")
    var kers: String = str(original.get("kers", "Equilibrado"))
    if not bool(car.get("kers_equipped", false)):
        kers = "Sem KERS"
    var manual: bool = str(car.get("pit_control_mode", "Manual")) != "IA"
    var explanation: String = "SUGESTÃO | Ritmo %s • KERS %s • %s" % [str(original.get("pace", "Normal")), kers, str(original.get("reason", "ritmo equilibrado"))]
    if manual:
        explanation += ". Manual: nada é executado sem confirmação."
    else:
        explanation += ". IA: box automático respeita qualquer parada agendada."
    return {
        "car_id": int(car.get("id", -1)),
        "stage": stage, "briefing": briefing, "priority": priority,
        "pace": str(original.get("pace", "Normal")), "kers": kers,
        "reason": str(original.get("reason", "")),
        "pit_now": urgent, "compound": compound,
        "can_call_pit": urgent and booked == 0 and compound != "",
        "scheduled_lap": booked, "confidence": confidence,
        "explanation": explanation, "manual_pit": manual,
        "lap": lap_number, "wetness": water, "wear": wear,
        "remaining": left
    }

static func radio_key(report: Dictionary) -> String:
    # A new message only on meaningful state transitions, with a cooldown
    # enforced by the HUD. Never generate one radio message per rendering frame.
    var status: String = str(report.get("stage", ""))
    if status == "ESTÁVEL":
        return ""
    return status + "|" + str(report.get("scheduled_lap", 0))
