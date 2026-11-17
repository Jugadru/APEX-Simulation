extends RefCounted
## APEX 0.6.4.9.9 — Strategy Simulator 1.0. READ ONLY.
## Models six possible entries from the next legal entry through +5 laps.
## No race.step, RNG, schedule_pit, requests, car mutation or engine callbacks.
## Relative future pace uses observed last-lap timing (or engine base lap if
## unavailable); other cars are assumed not to pit. Estimates are not results.
const StrategyGraph = preload("res://scripts/core/race_strategy_graph_data_06498.gd")
const PitWall = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const MAX_EXTENSION := 5

static func _lap_time(car: Dictionary, base: float) -> float:
	var measured: float = float(car.get("last_lap", 0.0))
	return PitWall._valid_lap(measured, base)

static func _future_water(now: float, forecast3: float, forecast6: float, advance: int) -> float:
	if advance <= 3:
		return lerpf(now, forecast3, clampf(float(advance) / 3.0, 0.0, 1.0))
	return lerpf(forecast3, forecast6, clampf(float(advance - 3) / 3.0, 0.0, 1.0))

static func _proposed_rejoin(car: Dictionary, grid: Array, base_lap: float, pit_loss: float,
		steps: float) -> Dictionary:
	# Normalize future positions at the SAME hypothetical time. One pit is
	# applied only to the selected car; no future stops by rivals are invented.
	var own_lap: float = _lap_time(car, base_lap)
	var own_progress: float = float(car.get("progress", 0.0)) + steps * base_lap / own_lap - pit_loss / base_lap
	var position: int = 1
	var closest_gap: float = INF
	var nearest_name: String = ""
	var nearest_id: int = -1
	var rival_gap: float = INF
	var rival_name: String = ""
	var rival_id: int = -1
	var current_ahead: float = INF
	# For under/overcut focus on the immediately preceding real rival.
	for other in grid:
		if int(other.get("id", -1)) == int(car.get("id", -1)) or bool(other.get("finished", false)):
			continue
		if float(other.get("progress", 0.0)) > float(car.get("progress", 0.0)) and str(other.get("team", "")) != str(car.get("team", "")):
			var initial_gap: float = float(other.get("progress", 0.0)) - float(car.get("progress", 0.0))
			if initial_gap < current_ahead:
				current_ahead = initial_gap
				rival_id = int(other.get("id", -1))
				rival_name = str(other.get("name", "Piloto"))
	for other in grid:
		if int(other.get("id", -1)) == int(car.get("id", -1)) or bool(other.get("finished", false)):
			continue
		var other_time: float = _lap_time(other, base_lap)
		var future_progress: float = float(other.get("progress", 0.0)) + steps * base_lap / other_time
		var gap: float = (future_progress - own_progress) * base_lap
		if gap >= 0.0:
			position += 1
		if absf(gap) < absf(closest_gap):
			closest_gap = gap
			nearest_name = str(other.get("name", "Piloto"))
			nearest_id = int(other.get("id", -1))
		if int(other.get("id", -1)) == rival_id:
			rival_gap = gap
	# The traffic threshold is inherited from the existing Pit Wall model.
	return {"position":position, "nearest_gap_s":closest_gap if is_finite(closest_gap) else 0.0,
		"nearest":nearest_name, "nearest_id":nearest_id,
		"traffic":absf(closest_gap) < PitWall.CLEAR_AIR_S,
		"rival":rival_name, "rival_id":rival_id,
		"rival_gap_s":rival_gap if is_finite(rival_gap) else 0.0,
		"has_rival":rival_id >= 0}

static func _garage(target: int, offset: int, teammate: Dictionary, mate_advice: Dictionary,
		mate_entry: int) -> Dictionary:
	if teammate.is_empty():
		return {"level":"DESCONHECIDO", "message":"Sem segundo piloto na equipe."}
	var booked: int = int(teammate.get("pit_scheduled_lap", 0))
	var active: bool = bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.0
	if booked == target:
		return {"level":"ALTO", "message":"Colega já tem ordem confirmada para V%d; double stack hipotético." % target}
	if active and offset == 0:
		return {"level":"ALTO", "message":"Garagem ocupada/solicitada pelo colega nesta entrada."}
	var start: int = int(mate_advice.get("window_start", 0))
	var end: int = maxi(start, int(mate_advice.get("window_end", 0)))
	var planned: int = int(mate_advice.get("planned_pit_lap", 0))
	if booked > 0 and abs(booked - target) == 1:
		return {"level":"POTENCIAL", "message":"Ordem do colega na volta adjacente V%d; tempo de garagem não garantido." % booked}
	if (start > 0 and target >= start and target <= end) or planned == target:
		return {"level":"POTENCIAL", "message":"Janela prevista do colega coincide; não é uma ordem confirmada."}
	if active or (booked > 0 and abs(booked - target) <= 2):
		return {"level":"MONITORAR", "message":"Colega em serviço ou próximo da janela; reavaliar ocupação."}
	return {"level":"LIVRE", "message":"Sem conflito indicado pelas ordens/janelas atuais (não é garantia)."}

static func evaluate(race, car: Dictionary, teammate: Dictionary, chart_model) -> Dictionary:
	var next_entry: int = int(race._next_pit_entry_lap(car))
	var total: int = int(race.lap_count)
	var view: Dictionary = chart_model.view(race, car)
	var advice: Dictionary = race.get_engineer_advice(int(car.get("id", -1)))
	var teammate_advice: Dictionary = race.get_engineer_advice(int(teammate.get("id", -1))) if not teammate.is_empty() else {}
	var weather: Dictionary = race.weather_snapshot()
	var water: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var water3: float = clampf(float(advice.get("forecast_3", water)), 0.0, 1.0)
	var water6: float = clampf(float(advice.get("forecast_6", water3)), 0.0, 1.0)
	var base_lap: float = float(race.base_lap)
	var pit_loss: float = float(race.pit_loss)
	var grid: Array = race.get_sorted()
	var rate: float = float(view.get("measured_rate", -1.0))
	var rate_source: String = "voltas observadas"
	if rate <= 0.0:
		rate = float(advice.get("wear_per_lap", -1.0))
		rate_source = "modelo de desgaste do motor"
	var cliff: float = float(race.tyre_spec(str(car.get("tire", ""))).get("cliff", 100.0))
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var has_real_pace: bool = float(car.get("last_lap", 0.0)) > 1.0 and float(car.get("last_lap", 0.0)) < 500.0
	var booked: int = int(car.get("pit_scheduled_lap", 0))
	var protected: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0 or booked > 0
	var finished: bool = bool(car.get("finished", false)) or bool(race.finished)
	var scenarios: Array = []
	var available: bool = base_lap > 1.0 and pit_loss > 0.0 and not finished
	for offset in range(MAX_EXTENSION + 1):
		var target: int = next_entry + offset
		if not available or target >= total:
			continue
		# Pit entry is 95% of the numbered lap; at the grid V1 is NOT
		# 'now at zero distance': the car must drive almost a full lap.
		# Preserve race_engine PIT_ENTRY_FRACTION without changing it.
		var driving_laps: float = maxf(0.0, float(target - 1) + 0.950 - float(car.get("progress", 0.0)))
		var projected: Dictionary = _proposed_rejoin(car, grid, base_lap, pit_loss, driving_laps)
		var expected_wear: float = minf(100.0, wear + maxf(0.0, rate) * driving_laps) if rate > 0.0 else -1.0
		var remaining: float = cliff - expected_wear if expected_wear >= 0.0 else -1.0
		var next_water: float = _future_water(water, water3, water6, offset)
		var weather_shift: float = absf(next_water - water)
		var garage: Dictionary = _garage(target, offset, teammate, teammate_advice,
			int(race._next_pit_entry_lap(teammate)) if not teammate.is_empty() else 0)
		var confidence: String = "ALTA"
		var reasons: Array[String] = []
		if not has_real_pace:
			confidence = "BAIXA"
			reasons.append("sem volta cronometrada: ritmo-base do motor")
		elif offset >= 4:
			confidence = "MODERADA"
			reasons.append("horizonte de 4–5 voltas")
		if rate <= 0.0:
			confidence = "BAIXA"
			reasons.append("sem taxa de desgaste calculável")
		elif float(view.get("measured_rate", -1.0)) <= 0.0 and confidence == "ALTA":
			confidence = "MODERADA"
			reasons.append("desgaste baseado no motor, ainda sem série observada")
		if weather_shift >= 0.12 or water >= 0.12:
			confidence = "BAIXA" if weather_shift >= 0.20 else ("MODERADA" if confidence == "ALTA" else confidence)
			reasons.append("previsão de chuva variável")
		if bool(projected.get("traffic", false)) or str(garage.get("level", "")) in ["ALTO", "POTENCIAL"]:
			if confidence == "ALTA":
				confidence = "MODERADA"
			reasons.append("tráfego ou garagem compartilhada")
		if expected_wear >= cliff:
			confidence = "BAIXA"
			reasons.append("limite de desgaste do composto ultrapassado")
		var risk: String = "CRÍTICO" if expected_wear >= cliff and expected_wear >= 0.0 else ("ALTO" if str(garage.get("level", "")) == "ALTO" or weather_shift >= 0.20 else ("ATENÇÃO" if str(garage.get("level", "")) == "POTENCIAL" or bool(projected["traffic"]) or expected_wear >= cliff * 0.90 else "MONITORAR"))
		scenarios.append({"offset":offset, "lap":target, "rejoin_position":int(projected["position"]),
			"traffic":bool(projected["traffic"]), "nearest":str(projected["nearest"]),
			"nearest_gap_s":float(projected["nearest_gap_s"]), "rival":str(projected["rival"]),
			"has_rival":bool(projected["has_rival"]), "rival_gap_s":float(projected["rival_gap_s"]),
			"wear":expected_wear, "wear_to_cliff":remaining, "wear_source":rate_source,
			"rain_now":water, "rain_estimated":next_water, "rain_change":weather_shift,
			"garage":garage, "risk":risk, "confidence":confidence,
			"uncertainty":"; ".join(reasons) if not reasons.is_empty() else "ritmo atual e clima mantidos; rivais sem pits futuros",
			"pit_loss_s":pit_loss, "protected_order":protected})
	var original_lap: int = int(advice.get("planned_pit_lap", 0))
	return {"driver_id":int(car.get("id", -1)), "name":str(car.get("name", "Piloto")),
		"position":int(car.get("position", 0)), "tire":str(car.get("tire", "")),
		"lap":int(car.get("laps_done", 0)), "total":total,
		"next_entry":next_entry, "engine_lap":original_lap,
		"booked":booked, "protected":protected, "finished":finished,
		"rate":rate, "rate_source":rate_source, "wear":wear,
		"scenarios":scenarios, "weather":weather, "advice":str(advice.get("status", ""))}

static func explain(scenarios: Array, chosen: Dictionary) -> String:
	if chosen.is_empty():
		return "RACE ENGINEER: Sem entrada válida antes do fim da corrida."
	var text: String = "RACE ENGINEER: Retorno estimado ~P%d na V%d." % [int(chosen["rejoin_position"]), int(chosen["lap"])]
	if bool(chosen["has_rival"]):
		var gap: float = float(chosen["rival_gap_s"])
		text += " Contra %s: %s de %.1fs no retorno hipotético." % [str(chosen["rival"]), "atrás" if gap >= 0.0 else "à frente", absf(gap)]
	if bool(chosen["traffic"]):
		text += " Atenção: tráfego previsto perto de %s." % str(chosen["nearest"])
	if str(chosen["garage"].get("level", "")) in ["ALTO", "POTENCIAL"]:
		text += " %s" % str(chosen["garage"].get("message", ""))
	if float(chosen["wear_to_cliff"]) <= 0.0 and float(chosen["wear"]) >= 0.0:
		text += " A extensão ultrapassa o limite estimado do pneu."
	var immediate: Dictionary = scenarios[0] if not scenarios.is_empty() else {}
	if not immediate.is_empty() and int(chosen["offset"]) > 0 and bool(chosen["has_rival"]) and bool(immediate["has_rival"]):
		var improvement: float = float(immediate["rival_gap_s"]) - float(chosen["rival_gap_s"])
		if improvement >= 0.15:
			text += " Esperar favorece o confronto relativo em ~%.1fs (possível overcut; rival sem pit simulado)." % improvement
		elif improvement <= -0.15:
			text += " Antecipar preservaria ~%.1fs frente ao rival (potencial undercut; sem simular parada dele)." % absf(improvement)
	text += " Confiança %s. Apenas consultivo; nenhuma ordem foi enviada." % str(chosen["confidence"])
	return text
