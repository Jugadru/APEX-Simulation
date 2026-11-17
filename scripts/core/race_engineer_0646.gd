extends RefCounted
## Apex v0.6.4.6 — Race Engineer 3.0.
## Decision-support layer over the proven Race Engineer 2.0 and Strategy IA 2.0.
## PURE: no mutations, no RNG, no orders, no invented tyre/traffic telemetry.
## Only race_engine.gd can execute a pit stop; this module never authorizes an
## operation not already admitted by the engine's strategy and race state.

const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]

static func assess(car: Dictionary, previous: Dictionary, advice: Dictionary,
        weather: Dictionary, teammate: Dictionary, staff: Dictionary,
        available_compounds: Array, total_laps: int, pit_loss: float,
        base_lap: float, next_pit_entry: int) -> Dictionary:
    var r: Dictionary = previous.duplicate(true)
    var lap: int = int(car.get("laps_done", 0))
    var remaining: int = maxi(0, total_laps - lap)
    var booked: int = int(car.get("pit_scheduled_lap", 0))
    var busy: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
    var finished: bool = bool(car.get("finished", false)) or remaining <= 0
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
    var wet_forecast: float = clampf(float(advice.get("forecast_3", wet)), 0.0, 1.0)
    var rain_delta: float = wet_forecast - wet
    var tyre: String = str(car.get("tire", "—"))
    var compound: String = str(advice.get("compound", ""))
    var strategist: int = clampi(int(staff.get("Estrategista", 0)), 0, 3)
    var mechanic: int = clampi(int(staff.get("Engenheiro", 0)), 0, 3)
    var planned: int = int(advice.get("planned_pit_lap", 0))
    var life: float = maxf(0.0, float(advice.get("life_laps", 0.0)))
    var last: float = float(car.get("last_lap", 0.0))
    var best: float = float(car.get("best_lap", 9999.0))
    var has_pace: bool = last > 0.0 and last < 500.0 and best > 0.0 and best < 500.0
    var loss: float = maxf(0.0, last - best) if has_pace else -1.0
    var surface: float = float(car.get("tyre_surface_c", -1.0))
    var core: float = float(car.get("tyre_core_c", -1.0))
    var graining: float = clampf(float(car.get("tyre_graining", 0.0)), 0.0, 1.0)
    var blistering: float = clampf(float(car.get("tyre_blistering", 0.0)), 0.0, 1.0)
    var mismatch: bool = (tyre in SLICKS and wet >= 0.38) or (tyre == "Chuva" and wet <= 0.10)
    var thermal_warning: bool = graining >= 0.35 or blistering >= 0.35
    var forecast_warning: bool = rain_delta >= 0.15 or rain_delta <= -0.15

    # Safety gates are deliberately stronger than the UI's previous advisory flag.
    # In particular, a scheduled V21 must NEVER become an immediate V4 pit.
    var gate: String = "LIBERADA"
    if finished:
        gate = "CARRO FINALIZADO"
    elif busy:
        gate = "BOX JÁ CHAMADO / EM EXECUÇÃO"
    elif booked > 0:
        gate = "AGENDAMENTO V%d PROTEGIDO" % booked
    elif next_pit_entry >= total_laps or remaining < 2:
        gate = "SEM ENTRADA VIÁVEL ANTES DO FIM"
    elif not available_compounds.has(compound):
        gate = "COMPOSTO NÃO DISPONÍVEL"
    elif not bool(advice.get("pit_now", false)):
        gate = "PLANO NÃO RECOMENDA BOX AGORA"
    elif not bool(previous.get("can_call_pit", false)):
        gate = "AGUARDAR JANELA CONFIRMADA"
    var can_call: bool = gate == "LIBERADA"

    var teammate_booked: int = int(teammate.get("pit_scheduled_lap", 0))
    var teammate_busy: bool = bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.0
    var double_stack: bool = not teammate.is_empty() and (
        (booked > 0 and teammate_booked == booked)
        or (can_call and (teammate_busy or teammate_booked == next_pit_entry)))
    var stack_note: String = "Sem conflito de box detectado no estado atual."
    if booked > 0 and teammate_booked == booked:
        stack_note = "ATENÇÃO: os dois pilotos estão agendados para V%d. Possível double stack." % booked
    elif can_call and teammate_busy:
        stack_note = "ATENÇÃO: companheiro já foi chamado/está no box. Avaliar fila na garagem."
    elif can_call and teammate_booked == next_pit_entry:
        stack_note = "ATENÇÃO: companheiro marcado para V%d; possibilidade de double stack." % next_pit_entry

    var situation: String = "ESTÁVEL"
    var alert: String = "Sem novo gatilho crítico; seguir monitorando os próximos stints."
    var priority: int = 0
    if finished:
        situation = "FINALIZADO"
        alert = "Sem comandos ou decisões adicionais para este carro."
    elif busy:
        situation = "BOX EM EXECUÇÃO"
        alert = "Parada confirmada. Acompanhar entrada, fila e serviço."
        priority = 1
    elif booked > 0:
        situation = "ORDEM V%d PROTEGIDA" % booked
        alert = "BOX V%d confirmado. O engenheiro só sugere; alterar exige uma ação manual explícita." % booked
        if mismatch or wear >= 85.0 or forecast_warning:
            alert += " Há novas condições para reavaliar a ordem, sem antecipá-la."
        priority = 2 if mismatch or wear >= 85.0 else 1
    elif can_call and (mismatch or wear >= 85.0):
        situation = "BOX PRIORITÁRIO"
        alert = "O plano do motor já recomenda parada; desgaste/aderência exigem atenção."
        priority = 3
    elif can_call:
        situation = "JANELA DE BOX"
        alert = "A janela calculada pelo motor está aberta. Compare parada e tráfego."
        priority = 2
    elif mismatch:
        situation = "PNEU / PISTA INCOMPATÍVEIS"
        alert = "Pista %.0f%% úmida com %s; avaliar a transição com o plano de pneus." % [wet * 100.0, tyre]
        priority = 3
    elif wear >= 82.0:
        situation = "DESGASTE ALTO"
        alert = "Desgaste %.0f%%; proteger ritmo e verificar janela de box." % wear
        priority = 2
    elif forecast_warning:
        situation = "MUDANÇA DE CLIMA"
        alert = "Tendência de água %s nas próximas voltas; aguardar atualização da janela." % ("subindo" if rain_delta > 0.0 else "caindo")
        priority = 2
    elif thermal_warning:
        situation = "TEMPERATURA / SUPERFÍCIE"
        alert = "Graining/blistering em evolução; acompanhar ritmo e compostos."
        priority = 1
    elif planned > lap and planned <= lap + 2 + strategist:
        situation = "BOX NO HORIZONTE"
        alert = "Janela estimada V%d; isso não representa ordem de parada." % planned
        priority = 1

    var pace_note: String = "Última volta não consolidada; tendência de ritmo indisponível."
    if has_pace:
        pace_note = "Última %.2fs / melhor %.2fs; diferença +%.2fs (não é perda causal isolada)." % [last, best, loss]
    var thermal_note: String = "Leitura térmica indisponível."
    if surface >= 0.0 and core >= 0.0:
        thermal_note = "Superfície %.0f°C; carcaça %.0f°C; graining %.0f%% / blistering %.0f%%." % [
            surface, core, graining * 100.0, blistering * 100.0]

    var rejoin_position: int = maxi(1, int(advice.get("rejoin_position", car.get("position", 1))))
    var gap: float = float(advice.get("rejoin_gap_s", -1.0))
    var traffic_note: String = "Tráfego imediato não identificado na projeção disponível."
    if bool(advice.get("traffic_risk", false)):
        traffic_note = "Retorno projetado ~P%d, a %.1fs de tráfego; não prevê futuras paradas rivais." % [rejoin_position, maxf(0.0, gap)]
    else:
        traffic_note = "Retorno projetado ~P%d; posições podem mudar com incidentes ou boxes rivais." % rejoin_position

    var hold_note: String = "MANTER: %.1f voltas de vida estimada; %d restantes nesta corrida." % [life, remaining]
    var stop_note: String = "PARAR: ~%.1fs de custo (~%.0f%% de uma volta-base), retorno ~P%d (%s)." % [
        maxf(0.0, pit_loss), 100.0 * maxf(0.0, pit_loss) / maxf(1.0, base_lap),
        rejoin_position, compound if compound != "" else "composto indefinido"]
    var action: String = "MANTER E MONITORAR"
    if finished:
        action = "SEM AÇÃO"
    elif busy:
        action = "AGUARDAR BOX"
    elif booked > 0:
        action = "MANTER V%d / REVISAR MANUALMENTE" % booked
    elif can_call:
        action = "AVALIAR CHAMADA DE BOX"
    elif planned > lap:
        action = "REAVALIAR NA JANELA V%d" % planned

    var weather_note: String = "Pista %.0f%% úmida; previsão 3 voltas %.0f%% (%+.0f p.p.)." % [
        wet * 100.0, wet_forecast * 100.0, rain_delta * 100.0]
    var staff_note: String = "STAFF: Estrategista %d/3, Engenheiro %d/3. Atualização consultiva; sem execução automática adicional." % [
        strategist, mechanic]
    var radio_key: String = ""
    if priority >= 2 and not finished and not busy:
        radio_key = situation + ("|STACK" if double_stack else "") + ("|BOX" if can_call else "")
    # Reassign only report fields. Input car/advice/teammate are never modified.
    r["engineer_version"] = "3.0"
    r["can_call_pit"] = can_call
    r["pit_gate"] = gate
    r["condition"] = situation
    r["action"] = action
    r["priority"] = priority
    r["alert"] = alert
    r["pace_note"] = pace_note
    r["thermal_note"] = thermal_note
    r["weather_note"] = weather_note
    r["traffic_note"] = traffic_note
    r["hold_case"] = hold_note
    r["stop_case"] = stop_note
    r["double_stack"] = double_stack
    r["stack_note"] = stack_note
    r["staff_note"] = staff_note
    r["radio_key_3"] = radio_key
    r["next_entry_lap"] = next_pit_entry
    r["risk"] = "CRÍTICO" if priority >= 3 else ("ATENÇÃO" if priority >= 2 else "ACOMPANHAR")
    return r

static func answer(report: Dictionary, topic: String) -> String:
    # Different radio questions generate different data-grounded responses.
    # There are no audio samples, historical quotations or automatic orders.
    var lead: String = "Engenheiro (simulação): "
    match topic:
        "pneus":
            return lead + str(report.get("thermal_note", "")) + " " + str(report.get("pace_note", "")) + " " + str(report.get("hold_case", ""))
        "clima":
            return lead + str(report.get("weather_note", "")) + " " + str(report.get("alert", "")) + " " + str(report.get("action", ""))
        "trafego":
            return lead + str(report.get("traffic_note", "")) + " " + str(report.get("stack_note", "")) + " " + str(report.get("stop_case", ""))
        "plano":
            return lead + str(report.get("alert", "")) + " " + str(report.get("hold_case", "")) + " " + str(report.get("stop_case", "")) + " " + str(report.get("pit_gate", ""))
    return lead + "Consulta desconhecida; nenhuma ordem enviada."
