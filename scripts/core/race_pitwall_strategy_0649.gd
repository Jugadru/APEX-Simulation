extends RefCounted
## Apex 0.6.4.9 — Pit Wall & Strategy 3.0.
## Pure deterministic race-state analysis, not a guaranteed race outcome.
## Consumes existing car progress, lap times, weather forecast and IA 2.0 plan.
## No RNG, telemetry fabrication, in-place mutations or race commands.

const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]
const CLEAR_AIR_S: float = 2.5

static func _valid_lap(value: float, fallback: float) -> float:
	return value if value > 1.0 and value < 500.0 else fallback

static func _rejoin(car: Dictionary, grid: Array, pit_loss: float, base_lap: float, extend_laps: int) -> Dictionary:
	var own_time: float = _valid_lap(float(car.get("last_lap", 0.0)), base_lap)
	var own_progress: float = float(car.get("progress", 0.0))
	var position: int = 1
	var near_ahead: float = INF
	var near_behind: float = INF
	var closest: String = ""
	for other in grid:
		if int(other.get("id", -1)) == int(car.get("id", -1)) or bool(other.get("finished", false)):
			continue
		var other_time: float = _valid_lap(float(other.get("last_lap", 0.0)), base_lap)
		# Drifting an instantaneous gap forward is hypothetical. Cap the
		# per-lap drift to prevent outlier timing from dominating forecasts.
		var drift: float = clampf(own_time - other_time, -2.0, 2.0) * float(extend_laps)
		var delta: float = (float(other.get("progress", 0.0)) - own_progress) * base_lap + maxf(0.0, pit_loss) + drift
		if delta >= 0.0:
			position += 1
			if delta < near_ahead:
				near_ahead = delta
				closest = str(other.get("name", "Piloto"))
		else:
			near_behind = minf(near_behind, absf(delta))
	var traffic: bool = near_ahead < CLEAR_AIR_S or near_behind < CLEAR_AIR_S
	return {
		"position": position,
		"ahead_s": near_ahead if is_finite(near_ahead) else -1.0,
		"behind_s": near_behind if is_finite(near_behind) else -1.0,
		"closest_ahead": closest,
		"traffic": traffic,
		"clear_air": not traffic
	}

## v0.6.4.9.4: confiança qualitativa da projeção, não probabilidade de acerto.
## Não envia comandos ao motor e não altera as janelas de pit.
static func _confidence_assessment(car: Dictionary, grid: Array, advice: Dictionary,
		water: float, water3: float, water6: float, traffic: bool,
		overlap: bool, serious: bool, wear: float) -> Dictionary:
	var delta3: float = absf(water3 - water)
	var delta6: float = absf(water6 - water)
	if serious:
		return {"level":"BAIXA", "reason":"condições ou pneus críticos"}
	if overlap:
		return {"level":"BAIXA", "reason":"garagem compartilhada em conflito"}
	if delta3 >= 0.18 or delta6 >= 0.24:
		return {"level":"BAIXA", "reason":"mudança importante na previsão de água"}
	# Sem previsões ou dados de grid suficientes, nunca anunciar ALTA.
	if not advice.has("forecast_3") or not advice.has("forecast_6") or grid.size() < 2:
		return {"level":"MODERADA", "reason":"informações insuficientes para alta confiança"}
	if float(car.get("last_lap", 0.0)) <= 1.0 or float(car.get("last_lap", 0.0)) >= 500.0:
		return {"level":"MODERADA", "reason":"ritmo recente ainda não confiável"}
	if traffic:
		return {"level":"MODERADA", "reason":"retorno projetado próximo ao tráfego"}
	if water >= 0.12 or delta3 >= 0.08 or delta6 >= 0.12:
		return {"level":"MODERADA", "reason":"pista úmida ou previsão variável"}
	if wear >= 65.0:
		return {"level":"MODERADA", "reason":"vida do pneu reduzida"}
	return {"level":"ALTA", "reason":"pista seca, previsão estável e retorno livre no estado atual"}

static func assess(car: Dictionary, teammate: Dictionary, grid: Array, advice: Dictionary,
		weather: Dictionary, available_compounds: Array, total_laps: int,
		pit_loss: float, base_lap: float, next_entry: int) -> Dictionary:
	var result: Dictionary = {}
	var lap: int = int(car.get("laps_done", 0))
	var remaining: int = maxi(0, total_laps - lap)
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var water: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var water3: float = clampf(float(advice.get("forecast_3", water)), 0.0, 1.0)
	var water6: float = clampf(float(advice.get("forecast_6", water3)), 0.0, 1.0)
	var selected: String = str(advice.get("compound", ""))
	if not available_compounds.has(selected):
		selected = ""
	var booked: int = int(car.get("pit_scheduled_lap", 0))
	var busy: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
	var finished: bool = bool(car.get("finished", false)) or remaining <= 0
	var teammate_booked: int = int(teammate.get("pit_scheduled_lap", 0))
	var teammate_busy: bool = bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.0
	var overlap: bool = not teammate.is_empty() and (
		(booked > 0 and booked == teammate_booked)
		or (teammate_booked == next_entry and next_entry < total_laps)
		or teammate_busy)
	var wet_mismatch: bool = (str(car.get("tire", "")) in SLICKS and water >= 0.38) or (str(car.get("tire", "")) == "Chuva" and water < 0.10)
	var serious: bool = wear >= 82.0 or wet_mismatch or bool(advice.get("critical", false))
	var dry_stable: bool = water < 0.12 and water3 < 0.12 and water6 < 0.12
	var safe_extra: bool = not serious and dry_stable and wear < 65.0 and float(advice.get("life_laps", 0.0)) > 2.0 and next_entry + 1 < total_laps
	var active: bool = not finished and not busy and booked == 0 and next_entry < total_laps and selected != ""
	var now: Dictionary = _rejoin(car, grid, pit_loss, base_lap, 0)
	var later: Dictionary = _rejoin(car, grid, pit_loss, base_lap, 1)
	var plan: String = "MANTER E REAVALIAR"
	var reason: String = "O motor de stints ainda não abriu uma janela de box."
	if finished:
		plan = "CORRIDA ENCERRADA"
		reason = "Nenhum comando disponível para carro finalizado."
	elif busy:
		plan = "BOX EM CURSO"
		reason = "Já existe chamada ou serviço; não duplicar a ordem."
	elif booked > 0:
		plan = "MANTER ORDEM V%d" % booked
		reason = "Agendamento confirmado e protegido; só o jogador pode alterar no painel de estratégia."
	elif overlap and serious:
		plan = "PIT CRÍTICO / ALERTA DOUBLE STACK"
		reason = "Risco real de fila; o estado crítico impede recomendar adiamento automático."
	elif overlap and safe_extra:
		plan = "ESCALONAR PARADAS"
		reason = "Garagem pode estar ocupada; um adiamento de uma volta é viável para avaliação."
	elif bool(advice.get("pit_now", false)) and active and not bool(now.get("traffic", false)) and int(car.get("position", 0)) > 1:
		plan = "UNDERCUT NA JANELA"
		reason = "O plano do motor já recomenda box e o retorno instantâneo projeta ar livre."
	elif bool(advice.get("pit_now", false)) and active and bool(now.get("traffic", false)) and safe_extra:
		plan = "CONSIDERAR OVERCUT (+1 VOLTA)"
		reason = "Saída imediata em tráfego; pneus e pista seca permitem simular extensão curta."
	elif bool(advice.get("pit_now", false)) and active:
		plan = "BOX NA JANELA"
		reason = "O motor já recomenda parada; avaliar risco de fila, pneus e tempo perdido."
	elif serious:
		plan = "ALERTA: PNEU / CONDIÇÕES"
		reason = "Condição crítica, mas sem autorização implícita para antecipar chamada de box."
	var gate: String = "CONSULTIVO"
	if finished:
		gate = "FINALIZADO"
	elif busy:
		gate = "CHAMADO / EM SERVIÇO"
	elif booked > 0:
		gate = "ORDEM V%d PROTEGIDA" % booked
	elif next_entry >= total_laps:
		gate = "SEM ENTRADA ANTES DA CHEGADA"
	elif selected == "":
		gate = "COMPOSTO NÃO DISPONÍVEL"
	else:
		gate = "AGENDAR MANUALMENTE"
	var stack: String = "Sem conflito identificado na garagem."
	if booked > 0 and teammate_booked == booked:
		stack = "DOUBLE STACK: ambos agendados para V%d." % booked
	elif teammate_busy:
		stack = "Companheiro com box chamado / serviço em andamento."
	elif teammate_booked == next_entry:
		stack = "Companheiro agendado V%d; considerar outra volta." % teammate_booked
	var cases: Array = []
	cases.append({"kind":"MANTER", "lap":-1, "label":"Manter stint", "position":int(car.get("position", 0)), "traffic":false})
	cases.append({"kind":"PIT", "lap":next_entry, "label":"Box V%d, ~P%d" % [next_entry, int(now["position"])],
		"position":int(now["position"]), "traffic":bool(now["traffic"]), "ahead_s":float(now["ahead_s"])})
	if next_entry + 1 < total_laps:
		cases.append({"kind":"EXTEND", "lap":next_entry+1, "label":"Estender até V%d, ~P%d" % [next_entry+1, int(later["position"])],
			"position":int(later["position"]), "traffic":bool(later["traffic"]), "ahead_s":float(later["ahead_s"])})
	result["version"] = "3.0"
	result["plan"] = plan
	result["reason"] = reason
	result["gate"] = gate
	result["pit_loss"] = maxf(0.0, pit_loss)
	result["tyre"] = str(car.get("tire", "—"))
	result["compound"] = selected
	result["wear"] = wear
	result["life_laps"] = maxf(0.0, float(advice.get("life_laps", 0.0)))
	result["next_lap"] = next_entry
	result["can_schedule"] = active
	result["can_extend"] = active and safe_extra
	result["critical"] = serious
	result["booked"] = booked
	result["team_overlap"] = overlap
	result["stack_note"] = stack
	result["forecast_note"] = "Água %.0f%% → 3v %.0f%% / 6v %.0f%%; %s" % [water*100.0, water3*100.0, water6*100.0, "mudança significativa" if absf(water3-water) >= 0.15 else "tendência moderada"]
	result["now"] = now
	result["later"] = later
	result["cases"] = cases
	# Look ahead to a confirmed teammate booking, not just a box already called.
	result["auto_hold_safe"] = active and (teammate_busy or (teammate_booked > 0 and teammate_booked == next_entry)) and safe_extra and bool(advice.get("pit_now", false))
	var confidence_info: Dictionary = _confidence_assessment(car, grid, advice, water, water3, water6,
		bool(now["traffic"]), overlap, serious, wear)
	result["confidence"] = str(confidence_info["level"])
	result["confidence_reason"] = str(confidence_info["reason"])
	result["forecast_note"] += " | Confiança %s (qualitativa): %s" % [result["confidence"], result["confidence_reason"]]
	result["scope"] = "Estimativa do estado atual; não prevê incidentes, pit stops rivais futuros nem evolução exata do ritmo."
	return result

static func can_manual_schedule(analysis: Dictionary, car: Dictionary, teammate: Dictionary,
		mode: String, target_lap: int, race_laps: int) -> bool:
	if mode == "Automático" or not bool(analysis.get("can_schedule", false)):
		return false
	if int(car.get("pit_scheduled_lap", 0)) > 0 or bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0:
		return false
	if target_lap < int(analysis.get("next_lap", 999)) or target_lap >= race_laps:
		return false
	if target_lap > int(analysis.get("next_lap", 999)) + 1 or (target_lap > int(analysis.get("next_lap", 999)) and not bool(analysis.get("can_extend", false))):
		return false
	if int(teammate.get("pit_scheduled_lap", 0)) == target_lap:
		return false
	if target_lap == int(analysis.get("next_lap", -1)) and (bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.0):
		return false
	return str(analysis.get("compound", "")) != ""

static func auto_coordinate(car: Dictionary, teammate: Dictionary, analysis: Dictionary, advice: Dictionary) -> Dictionary:
	# A one-lap double-stack avoidance ONLY when the other car is already
	# heading for box, tyres are safe and there is no live critical condition.
	# This is applied only to automatic pit calls, never manual schedules.
	var plan: Dictionary = advice.duplicate(true)
	if not bool(analysis.get("auto_hold_safe", false)) or not bool(plan.get("pit_now", false)):
		return plan
	if bool(car.get("pitwall49_held", false)) or bool(plan.get("critical", false)) or bool(car.get("finished", false)):
		return plan
	var buddy_busy: bool = bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.0
	var buddy_booked: bool = int(teammate.get("pit_scheduled_lap", 0)) > 0 and int(teammate.get("pit_scheduled_lap", 0)) == int(analysis.get("next_lap", -1))
	if int(car.get("pit_scheduled_lap", 0)) > 0 or not (buddy_busy or buddy_booked):
		return plan
	plan["pit_now"] = false
	plan["pitwall49_hold"] = true
	plan["tactic"] = "EVITAR DOUBLE STACK (+1 VOLTA)"
	plan["message"] = "Adiamento tático de uma volta: colega já chamado aos boxes, pneus e clima estáveis."
	return plan
