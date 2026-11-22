extends RefCounted
## APEX v0.6.6.9.13 — Race Engineer Intelligence 1.0.
## Read-only engineer decision support from observed race state and the existing
## (imperfect) strategist forecast. Never alters pace, pits, tyres or replay.
## Heuristic game thresholds, NOT measured F1 telemetry or calibrated risk.

const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]

static func evaluate(car: Dictionary, teammate: Dictionary, advice: Dictionary,
		weather: Dictionary, staff: Dictionary, race_laps: int) -> Dictionary:
	if car.is_empty():
		return {}
	var level: int = clampi(int(staff.get("Engenheiro", 0)), 0, 3)
	var style: String = "ANALÍTICO" if level >= 2 else "OBJETIVO"
	var lap: int = maxi(0, int(car.get("laps_done", 0)))
	var booked: int = int(car.get("pit_scheduled_lap", 0))
	var finished: bool = bool(car.get("finished", false)) or lap >= race_laps
	var busy: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var water: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var forecast3: float = clampf(float(advice.get("forecast_3", water)), 0.0, 1.0)
	var tyre: String = str(car.get("tire", "desconhecido"))
	var graining: float = clampf(float(car.get("tyre_graining", 0.0)), 0.0, 1.0)
	var blistering: float = clampf(float(car.get("tyre_blistering", 0.0)), 0.0, 1.0)
	var last: float = float(car.get("last_lap", 0.0))
	var best: float = float(car.get("best_lap", 0.0))
	var lap_evidence: bool = last > 0.0 and last < 500.0 and best > 0.0 and best < 500.0
	var pace_delta: float = maxf(0.0, last - best) if lap_evidence else -1.0
	var mismatch: bool = (tyre in SLICKS and water >= 0.38) or (tyre == "Chuva" and water <= 0.10)
	var team_conflict: bool = not teammate.is_empty() and (
		booked > 0 and booked == int(teammate.get("pit_scheduled_lap", 0))
		or bool(teammate.get("pit_request", false))
		or float(teammate.get("pit_left", 0.0)) > 0.0)

	# Priority is based on evidence, never on an engineer's personality or level.
	# Protected player bookings always take precedence over new suggestions.
	var state: String = "MONITORAR"
	var priority: int = 0
	var reason: String = "Sem alerta técnico novo sustentado pelo instantâneo."
	var action: String = "Manter observação e comparar próximas voltas."
	if finished:
		state = "FINALIZADO"
		reason = "Carro finalizado: nenhuma orientação operacional."
		action = "Sem ação."
	elif busy:
		state = "BOX EM CURSO"
		priority = 1
		reason = "Parada já autorizada e em andamento."
		action = "Acompanhar serviço e retorno."
	elif booked > 0:
		state = "BOX MANUAL PROTEGIDO"
		priority = 2 if mismatch or wear >= 82.0 else 1
		reason = "BOX V%d permanece agendado. O engenheiro não antecipa a ordem." % booked
		if mismatch or wear >= 82.0:
			reason += " Condição atual sugere uma reavaliação explícita."
		action = "Respeitar V%d; somente o jogador pode alterar o agendamento." % booked
	elif mismatch:
		state = "PNEU INCOMPATÍVEL"
		priority = 3
		reason = "%s com pista %.0f%% úmida: risco de inadequação de composto." % [tyre, water * 100.0]
		action = "Consultar estrategista e janela real; sem chamada automática."
	elif wear >= 82.0:
		state = "DESGASTE ELEVADO"
		priority = 2
		reason = "%s com desgaste medido de %.0f%%." % [tyre, wear]
		action = "Orientar conservação de pneus e consultar janela existente."
	elif graining >= 0.35 or blistering >= 0.35:
		state = "SUPERFÍCIE DO PNEU"
		priority = 2
		reason = "Graining %.0f%% e blistering %.0f%% no estado simulado." % [
			graining * 100.0, blistering * 100.0]
		action = "Monitorar superfície e ritmo sem presumir causa única."
	elif absf(forecast3 - water) >= 0.18:
		state = "TENDÊNCIA METEOROLÓGICA"
		priority = 2
		reason = "Umidade atual %.0f%%, previsão a 3 voltas %.0f%% (incerta)." % [
			water * 100.0, forecast3 * 100.0]
		action = "Consultar o Pit Wall; previsão não é ordem."
	elif lap_evidence and pace_delta >= 1.40 and int(car.get("stint_laps", 0)) >= 3:
		state = "PERDA DE RITMO OBSERVADA"
		priority = 1
		reason = "Última volta %.2fs, melhor %.2fs: diferença +%.2fs, sem atribuição causal." % [
			last, best, pace_delta]
		action = "Revisar pneus, tráfego e pista antes de agir."
	elif car.has("interval") and int(car.get("position", 24)) > 1 			and float(car.get("interval", 999.0)) >= 0.0 			and float(car.get("interval", 999.0)) <= 1.20:
		state = "TRÁFEGO PRÓXIMO"
		priority = 1
		reason = "Carro à frente a %.2fs no instantâneo atual." % float(car["interval"])
		action = "Avaliar disputa sem prometer ultrapassagem."

	var strategist: Dictionary = advice.get("staff_strategy_066910", {})
	var strategy_note: String = ""
	if not strategist.is_empty():
		strategy_note = "Estratégia: %s (consultiva, sem ordem adicional)." % str(
			strategist.get("recommendation", "MANTER PLANO"))
	var team_note: String = ""
	if team_conflict:
		team_note = "Companheiro com operação de box coincidente/ativa; avaliar fila."
	var confidence: String = "MODERADA" if lap_evidence else "LIMITADA"
	var basis: String = "pneus %.0f%%, pista %.0f%% úmida" % [wear, water * 100.0]
	if lap_evidence:
		basis += ", última %.2fs / melhor %.2fs" % [last, best]
	else:
		basis += ", tempos de volta ainda não comparáveis"
	if level >= 2:
		basis += ", graining %.0f%% / blistering %.0f%%" % [graining * 100.0, blistering * 100.0]
	var summary: String = "%s — %s" % [state, reason]
	var radio: String = "ENGENHEIRO 9.13 (SIMULAÇÃO): %s %s" % [reason, action]
	if team_note != "":
		radio += " " + team_note
	# No randomness, no automatic command, no unbounded history or new save keys.
	return {
		"version":"0.6.6.9.13", "read_only":true, "state":state,
		"priority":priority, "reason":reason, "suggestion":action,
		"staff_level":level, "style":style, "confidence":confidence,
		"basis":basis, "summary":summary, "radio":radio,
		"strategy_note":strategy_note, "team_note":team_note,
		"booked_lap":booked, "can_call_pit":false,
		"limitations":"Heurísticas de jogo; sem previsão perfeita ou ação automática."
	}
