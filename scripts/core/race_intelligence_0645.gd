extends RefCounted
## IA Estratégica 2.0. Pure assessment over the proven full-race planner.
## Traffic projection assumes current gaps; never claims a guaranteed position.
static func refine(car: Dictionary, grid: Array, base: Dictionary, weather: Dictionary,
		pit_loss: float, base_lap: float, race_laps: int) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	var lap: int = int(car.get("laps_done", 0))
	var wear: float = float(car.get("wear", 0.0))
	var water: float = float(weather.get("wetness_factor", 0.0))
	var exit_progress: float = float(car.get("progress", 0.0)) - pit_loss / maxf(1.0, base_lap)
	var ahead_gap: float = INF
	var projected_position: int = 1
	for other in grid:
		if int(other.get("id", -1)) == int(car.get("id", -1)) or bool(other.get("finished", false)):
			continue
		var delta: float = (float(other.get("progress", 0.0)) - exit_progress) * base_lap
		if delta > 0.0:
			projected_position += 1
			if float(other.get("pit_left", 0.0)) <= 0.0 and not bool(other.get("pit_request", false)):
				ahead_gap = minf(ahead_gap, delta)
	var traffic: bool = ahead_gap < 2.0
	var uncertainty: float = absf(float(base.get("forecast_3", water)) - water)
	var confidence: String = "BAIXA" if uncertainty >= 0.20 else ("MODERADA" if traffic or water > 0.12 else "ALTA")
	var tactic: String = "MANTER PLANO"
	var note: String = "Plano de stints e regulamento preservados."
	var stop: int = int(base.get("planned_pit_lap", 0))
	var clear_dry: bool = water <= 0.10 and float(base.get("forecast_3", water)) <= 0.12 and float(base.get("forecast_6", water)) <= 0.12
	var protected: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0 or int(car.get("pit_scheduled_lap", 0)) > 0 or bool(car.get("finished", false))
	# Defer at most ONE lap from the optimizer's original window. Never bypass
	# wet crossover, critical wear, compulsory final stop or explicit orders.
	if not protected and bool(base.get("pit_now", false)) and clear_dry and traffic and not bool(base.get("critical", false)) and wear < 65.0 and float(base.get("life_laps", 0.0)) > 2.0 and stop == lap + 1 and lap < race_laps - 3:
		var previous: Dictionary = car.get("ai_plan", {})
		if not bool(previous.get("traffic_deferred", false)):
			result["pit_now"] = false
			result["traffic_deferred"] = true
			result["deferred"] = true
			result["planned_pit_lap"] = stop + 1
			result["window_start"] = stop + 1
			result["window_end"] = stop + 1
			tactic = "ESTENDER UMA VOLTA"
			note = "Retorno previsto em tráfego; pneu permite reavaliar na próxima volta."
	elif bool(base.get("pit_now", false)) and not traffic and int(car.get("position", 1)) > 1 and float(car.get("interval", 999.0)) < 1.8:
		tactic = "UNDERCUT NA JANELA"
		note = "Parada já viável pelo plano; retorno estimado em ar livre."
	elif traffic:
		note = "Retorno estimado a menos de 2s de outro carro; risco de perder tempo."
	if protected:
		tactic = "ORDEM PROTEGIDA"
		note = "Avaliação consultiva; nenhuma ordem existente foi alterada."
	result["intelligence_version"] = "2.0"
	result["tactic"] = tactic
	result["decision_confidence"] = confidence
	result["rejoin_position"] = projected_position
	result["rejoin_gap_s"] = ahead_gap if is_finite(ahead_gap) else -1.0
	result["traffic_risk"] = traffic
	result["intelligence_note"] = note
	result["alternatives"] = ["Manter stint: %.1f voltas até o limite estimado" % float(base.get("life_laps", 0.0)), "Parar: custo %.1fs; retorno ~P%d" % [pit_loss, projected_position]]
	if bool(result.get("traffic_deferred", false)):
		result["reason"] = note
		result["status"] = "REAVALIAR TRÁFEGO"
		result["message"] = "%s | %s" % [tactic, note]
	return result
