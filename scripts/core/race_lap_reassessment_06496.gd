extends RefCounted
## 0.6.4.9.6 — uma revisão determinística por volta concluída.
## Compara manter/antecipar/estender usando somente dados já observados.
## A IA somente muda a janela SE o plano-base abriu uma janela seca próxima
## e se não existem ordens, chuva instável, desgaste crítico ou fila de box.
## Não controla o double stack preventivo (futura 0.6.4.9.7).

const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]
const MIN_PACE_GAIN_S := 0.55
const CLEAR_REJOIN_S := 2.5
const MIN_STINT_LAPS := 4

static func _valid_lap(value: float, fallback: float) -> float:
	return value if value >= fallback * 0.70 and value <= fallback * 1.75 else fallback

static func _rejoin_gap(car: Dictionary, grid: Array, base_lap: float, pit_loss: float) -> float:
	# Estimativa de ar livre na saída; sem antecipar paradas dos rivais.
	var exit_progress: float = float(car.get("progress", 0.0)) - pit_loss / maxf(1.0, base_lap)
	var nearest: float = INF
	for other in grid:
		if int(other.get("id", -1)) == int(car.get("id", -1)) or bool(other.get("finished", false)):
			continue
		var delta: float = (float(other.get("progress", 0.0)) - exit_progress) * base_lap
		if delta >= 0.0 and float(other.get("pit_left", 0.0)) <= 0.0:
			nearest = minf(nearest, delta)
	return nearest if is_finite(nearest) else -1.0

static func assess(car: Dictionary, grid: Array, baseline: Dictionary, weather: Dictionary,
		base_lap: float, pit_loss: float, race_laps: int, available: Array) -> Dictionary:
	var lap: int = int(car.get("laps_done", 0))
	var next_entry: int = int(floor(maxf(0.0, float(car.get("progress", 0.0))))) + 1
	var current: String = str(car.get("tire", ""))
	var target: String = str(baseline.get("compound", ""))
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var life: float = maxf(0.0, float(baseline.get("life_laps", 0.0)))
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var w3: float = clampf(float(baseline.get("forecast_3", wet)), 0.0, 1.0)
	var w6: float = clampf(float(baseline.get("forecast_6", wet)), 0.0, 1.0)
	var dry: bool = wet < 0.11 and w3 < 0.11 and w6 < 0.12
	var near_ahead: Dictionary = {}
	var gap_ahead: float = INF
	for other in grid:
		if int(other.get("id", -1)) == int(car.get("id", -1)) or bool(other.get("finished", false)) or float(other.get("pit_left", 0.0)) > 0.0:
			continue
		var gap: float = (float(other.get("progress", 0.0)) - float(car.get("progress", 0.0))) * base_lap
		if gap > 0.0 and gap < gap_ahead:
			near_ahead = other
			gap_ahead = gap
	var lap_time: float = float(car.get("last_lap", 0.0))
	var rival_time: float = float(near_ahead.get("last_lap", 0.0))
	var has_pace: bool = lap_time >= base_lap * 0.70 and lap_time <= base_lap * 1.75 and rival_time >= base_lap * 0.70 and rival_time <= base_lap * 1.75
	var pace_gain: float = clampf(rival_time - lap_time, -3.0, 3.0) if has_pace else 0.0
	var rejoin_gap: float = _rejoin_gap(car, grid, base_lap, pit_loss)
	var booked: bool = int(car.get("pit_scheduled_lap", 0)) > 0
	var busy: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
	var protected: bool = booked or busy or bool(car.get("finished", false))
	var teammate_conflict: bool = false
	for other in grid:
		if int(other.get("id", -1)) == int(car.get("id", -1)) or str(other.get("team", "")) != str(car.get("team", "")):
			continue
		teammate_conflict = bool(other.get("pit_request", false)) or float(other.get("pit_left", 0.0)) > 0.0 or int(other.get("pit_scheduled_lap", 0)) == next_entry
		break
	var safe: bool = (not protected and not teammate_conflict and dry and current in SLICKS
		and target in available and target in SLICKS and not bool(baseline.get("critical", false))
		and wear < 70.0 and life > 2.5 and int(car.get("stint_laps", 0)) >= MIN_STINT_LAPS
		and next_entry + 1 < race_laps and not bool(car.get("pitwall49_held", false)))
	var action: String = "MANTER"
	var reason: String = "Plano de stints preservado; sem vantagem comprovada de antecipar ou estender."
	var executable: bool = false
	var base_pit: bool = bool(baseline.get("pit_now", false))
	var planner_stop: int = int(baseline.get("planned_pit_lap", 0))
	var already_adjusted: bool = int(car.get("lap_strategy_adjusted_stint_06496", -999)) == int(car.get("stops", 0))
	if protected:
		action = "ORDEM PROTEGIDA"
		reason = "Agendamento, entrada de box ou final de prova não pode ser alterado pela revisão."
	elif base_pit:
		action = "PARAR NA JANELA"
		reason = str(baseline.get("reason", "O plano de pneus abriu a janela de pit."))
	elif not dry:
		reason = "Previsão de água variável: preservar a histerese climática do motor."
	if safe and not already_adjusted and has_pace and not near_ahead.is_empty():
		# OVERCUT: a ultrapassagem em pista é plausível EM UMA volta adicional;
		# caso contrário, a IA não posterga uma parada já autorizada.
		if (base_pit and pace_gain >= MIN_PACE_GAIN_S and gap_ahead <= maxf(0.0, pace_gain * 1.35)
				and wear <= 62.0 and life >= 3.0 and not bool(baseline.get("deferred", false))):
			action = "ESTENDER"
			executable = true
			reason = "Rival %s a %.1fs perde %.2fs/volta; tentar ultrapassar antes de parar (+1V), com pneus seguros." % [str(near_ahead.get("name", "à frente")), gap_ahead, pace_gain]
		# UNDERCUT: somente V(next_entry + 1) do OTIMIZADOR, em pista seca;
		# diferença de ritmo de >0.55s e saída sem tráfego próximo.
		elif (not base_pit and planner_stop == next_entry + 1 and pace_gain <= -MIN_PACE_GAIN_S
				and gap_ahead <= 2.7 and rejoin_gap > CLEAR_REJOIN_S and wear >= 30.0):
			action = "ANTECIPAR"
			executable = true
			reason = "Preso atrás de %s (%.1fs); box 1V antes da janela prevista para tentar undercut em ar livre." % [str(near_ahead.get("name", "rival")), gap_ahead]
	if action in ["ANTECIPAR", "ESTENDER"] and not executable:
		action = "MANTER"
	return {
		"version": "0.6.4.9.6", "lap": lap, "action": action,
		"reason": reason, "executable": executable, "base_pit": base_pit,
		"planned_pit_lap": planner_stop, "next_entry": next_entry,
		"wear": wear, "life_laps": life, "wetness": wet,
		"forecast_3": w3, "forecast_6": w6,
		"gap_ahead_s": gap_ahead if is_finite(gap_ahead) else -1.0,
		"pace_advantage_s": pace_gain, "pace_valid": has_pace,
		"rejoin_gap_s": rejoin_gap, "tyre": current, "target": target,
		"safe_window": safe, "protected": protected, "teammate_conflict": teammate_conflict,
		"alternatives": ["MANTER: %.1f voltas de vida estimada" % life,
			"PIT V%d: custo base ~%.1fs; ar livre %.1fs" % [next_entry, pit_loss, rejoin_gap],
			"EXTENDER V%d: projeção sujeita a tráfego/clima" % (next_entry + 1)]
	}
