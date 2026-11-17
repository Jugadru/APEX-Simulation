extends RefCounted
## APEX v0.6.4.0 — evidence layer for Race Engineer recommendations.
## Only derives explanations from the race snapshot. No RNG, fabricated
## telemetry, implicit orders or access to mutable external state.

const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]

static func enrich(car: Dictionary, existing: Dictionary, advice: Dictionary,
		weather: Dictionary, teammate: Dictionary, pit_loss: float) -> Dictionary:
	var result: Dictionary = existing.duplicate(true)
	var tire: String = str(car.get("tire", "—"))
	var stint: int = int(car.get("stint_laps", 0))
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var water: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var lap: int = int(car.get("laps_done", 0))
	var booked: int = int(car.get("pit_scheduled_lap", 0))
	var wet_delta: float = float(advice.get("forecast_3", water)) - water
	var facts: Array[String] = []
	facts.append("%s: %dv, %.0f%% de desgaste" % [tire, stint, wear])
	facts.append("Água na pista: %.0f%%" % (water * 100.0))
	var last: float = float(car.get("last_lap", 9999.0))
	var best: float = float(car.get("best_lap", 9999.0))
	if last > 0.0 and last < 500.0 and best > 0.0 and best < 500.0:
		facts.append("Última %.2fs / melhor %.2fs (+%.2fs)" % [last, best, maxf(0.0, last - best)])
	else:
		facts.append("Sem volta completa suficiente para avaliar a tendência")
	if bool(car.get("kers_equipped", false)):
		facts.append("KERS restante nesta volta: %.0f/400 kJ" % clampf(float(car.get("kers_remaining_kj", 0.0)), 0.0, 400.0))
	else:
		facts.append("Sem KERS instalado")

	var forecast: String = "Clima sem tendência expressiva no horizonte consultado"
	if wet_delta >= 0.12:
		forecast = "Previsão: mais água nas próximas voltas (estimativa)"
	elif wet_delta <= -0.12:
		forecast = "Previsão: pista secando (estimativa)"

	var tradeoff: String = "Manter o stint e acompanhar ritmo, pneus e janela estimada."
	if bool(car.get("finished", false)):
		tradeoff = "Corrida concluída; sem comandos pendentes."
	elif booked > 0:
		tradeoff = "BOX V%d é ordem confirmada. A avaliação do STAFF não a antecipa." % booked
	elif bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0:
		tradeoff = "Parada em andamento ou já chamada; não enviar uma segunda ordem."
	elif bool(advice.get("pit_now", false)):
		tradeoff = "Comparar troca por %s com custo estimado de %.1fs no pit lane." % [str(advice.get("compound", tire)), maxf(0.0, pit_loss)]
	else:
		var next_stop: int = int(advice.get("planned_pit_lap", 0))
		if next_stop > lap:
			tradeoff = "Janela sugerida V%d; ainda não é uma chamada aos boxes." % next_stop

	var teammate_note: String = ""
	if not teammate.is_empty():
		var team_booked: int = int(teammate.get("pit_scheduled_lap", 0))
		if booked > 0 and booked == team_booked:
			teammate_note = "ATENÇÃO: companheiro agendado na mesma volta (risco de double stack)."
		elif bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.0:
			teammate_note = "Garagem possivelmente ocupada pelo companheiro; confirmar fila antes da troca."
		elif bool(advice.get("pit_now", false)) and team_booked == lap + 1:
			teammate_note = "Companheiro tem box agendado na próxima volta; avaliar possível fila."

	var wet_warning: bool = water >= 0.38 and tire in SLICKS
	var risk: String = "ATENÇÃO" if wear >= 82.0 or wet_warning else "ACOMPANHAR"
	if bool(advice.get("pit_now", false)) and booked == 0:
		risk = "DECISÃO DE BOX"
	elif booked > 0:
		risk = "ORDEM PROTEGIDA"
	elif bool(car.get("finished", false)):
		risk = "FINALIZADO"
	result["evidence"] = "  •  ".join(facts)
	result["forecast_note"] = forecast
	result["tradeoff"] = tradeoff
	result["teammate_note"] = teammate_note
	result["risk"] = risk
	result["facts"] = facts.duplicate()
	return result

static func meaningful_key(report: Dictionary) -> String:
	var stage: String = str(report.get("stage", ""))
	if stage == "ESTÁVEL" or stage == "FINALIZADO":
		return ""
	# The lap is deliberately absent: no radio event on every redraw/lap.
	return "%s|%d|%s" % [stage, int(report.get("scheduled_lap", 0)), str(report.get("risk", ""))]
