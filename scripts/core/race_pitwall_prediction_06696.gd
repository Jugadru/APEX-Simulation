extends RefCounted
## APEX v0.6.6.9.6 — Pit Wall Prediction Ledger 1.0.
## Observer only. Record forecasts BEFORE the stop, then compare confirmed
## pit history and completed laps. Never send commands or consume race RNG.
const PitWall = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const Strategy = preload("res://scripts/core/race_strategy.gd")
const Rules = preload("res://scripts/core/race_rules.gd")
const WetPhysics = preload("res://scripts/core/race_wet_physics.gd")
const MAX_RECORDS: int = 96
const STINT_HORIZON: int = 5
const CALIBRATION_MIN_SAMPLES: int = 3
var records: Array[Dictionary] = []
var next_id: int = 1

func capture_decision(car: Dictionary, grid: Array, advice: Dictionary,
		weather: Dictionary, specs: Dictionary, staff: Dictionary, pit_loss: float,
		base_lap: float, pit_track_fraction: float, simulation_tick: int,
		time_s: float, target_lap: int, compound: String, source: String) -> void:
	# Separate a real recommendation or authorized order from pit-entry
	# estimates. A long-horizon plan is logged, NOT retrospectively graded
	# as an accurate three-lap forecast from the later entry moment.
	if not specs.has(compound) or target_lap <= 0:
		return
	var car_id: int = int(car.get("id", -1))
	var stop: int = int(car.get("stops", 0)) + 1
	for record in records:
		if int(record.get("car_id", -1)) == car_id and int(record.get("stop", -1)) == stop \
				and int(record.get("target_lap", -1)) == target_lap \
				and str(record.get("decision_source", "")) == source \
				and str(record.get("status", "")) == "RECOMMENDED":
			return
	var hypothetical: Dictionary = car.duplicate(true)
	hypothetical["pit_target"] = compound
	capture_entry(hypothetical, grid, advice, weather, specs, staff, pit_loss,
		base_lap, pit_track_fraction, simulation_tick, time_s, false)
	var item: Dictionary = records[records.size() - 1]
	item["phase"] = "DECISION"
	item["status"] = "RECOMMENDED"
	item["decision_source"] = source
	item["target_lap"] = target_lap
	item["issued_lap"] = int(car.get("laps_done", 0))
	item["long_horizon"] = target_lap > int(car.get("laps_done", 0)) + 2
	item["uncertainty_note"] = "Projeção instantânea na decisão; rever na entrada real do pit."

func cancel_decision(car_id: int, target_lap: int) -> void:
	for record in records:
		if int(record.get("car_id", -1)) == car_id \
				and int(record.get("target_lap", -1)) == target_lap \
				and str(record.get("decision_source", "")) == "agendamento_manual" \
				and str(record.get("status", "")) == "RECOMMENDED":
			record["status"] = "CANCELLED"
			record["reasons"].append("agendamento cancelado pelo jogador; não verificável")


static func _valid_pace(value: float) -> bool:
	return value > 1.0 and value < 500.0 and is_finite(value)

func _recent_bias(team: String, level: int, metric: String) -> Dictionary:
	var sum_error: float = 0.0
	var samples: int = 0
	for idx in range(records.size() - 1, -1, -1):
		var record: Dictionary = records[idx]
		if str(record.get("team", "")) != team or int(record.get("strategist_level", -1)) != level:
			continue
		if not bool(record.get("pit_verified", false)) or not record.has(metric):
			continue
		sum_error += float(record[metric])
		samples += 1
		if samples >= 8:
			break
	return {"samples":samples, "bias":sum_error / float(samples) if samples > 0 else 0.0}

func capture_entry(car: Dictionary, grid: Array, advice: Dictionary, weather: Dictionary,
		specs: Dictionary, staff: Dictionary, pit_loss: float, base_lap: float,
		pit_track_fraction: float, simulation_tick: int, time_s: float,
		link_decision: bool = true) -> void:
	var car_id: int = int(car.get("id", -1))
	if car_id < 0 or bool(car.get("finished", false)):
		return
	# Link the most recent executed recommendation, but preserve it unchanged.
	# The actual pit-entry forecast is a separate scored measurement.
	var actual_entry_lap: int = int(floor(float(car.get("progress", 0.0)))) + 1
	var linked_decision_id: int = 0
	for i in range(records.size() - 1, -1, -1):
		if not link_decision:
			break
		var proposal: Dictionary = records[i]
		if int(proposal.get("car_id", -1)) != car_id \
				or int(proposal.get("stop", -1)) != int(car.get("stops", 0)) + 1:
			continue
		if str(proposal.get("status", "")) != "RECOMMENDED":
			continue
		if int(proposal.get("target_lap", -1)) == actual_entry_lap \
				and str(proposal.get("compound_after", "")) == str(car.get("pit_target", "")):
			proposal["status"] = "EXECUTED"
			proposal["execution_tick"] = simulation_tick
			linked_decision_id = int(proposal.get("id", 0))
			break
	var target: String = str(car.get("pit_target", ""))
	var spec: Dictionary = specs.get(target, {})
	var current: Dictionary = specs.get(str(car.get("tire", "")), {})
	var level: int = clampi(int(staff.get("Estrategista", -1)), -1, 3)
	var engineer_level: int = clampi(int(staff.get("Engenheiro", -1)), -1, 3)
	var team: String = str(car.get("team", ""))
	var position: int = int(PitWall._rejoin(car, grid, pit_loss, base_lap, 0).get("position", 0))
	var loss_bias: Dictionary = _recent_bias(team, level, "pit_loss_error_s")
	var position_bias: Dictionary = _recent_bias(team, level, "position_error")
	var corrected_loss: float = maxf(0.0, pit_loss + clampf(float(loss_bias["bias"]), -4.0, 4.0)) if int(loss_bias["samples"]) >= CALIBRATION_MIN_SAMPLES else pit_loss
	if int(position_bias["samples"]) >= CALIBRATION_MIN_SAMPLES:
		position = clampi(position + roundi(clampf(float(position_bias["bias"]), -2.0, 2.0)), 1, maxi(1, grid.size()))
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var pace_data: Dictionary = Rules.PACES.get(str(car.get("pace", "Normal")), Rules.PACES["Normal"])
	var rate: float = -1.0
	var expected_pace: float = -1.0
	if not spec.is_empty():
		rate = Strategy._wear_per_lap(target, spec, wet, float(pace_data.get("wear", 1.0)),
			maxf(0.70, float(car.get("track_wear_factor", 1.0))))
		var last: float = float(car.get("last_lap", 0.0))
		if _valid_pace(last) and not current.is_empty():
			expected_pace = last + float(spec.get("delta", 0.0)) - float(current.get("delta", 0.0))
			expected_pace += float(WetPhysics.modifier(target, wet).get("penalty", 0.0))
			expected_pace -= float(WetPhysics.modifier(str(car.get("tire", "")), wet).get("penalty", 0.0))
			expected_pace = maxf(1.0, expected_pace)
	var projected_water: float = clampf(float(advice.get("forecast_3", wet)), 0.0, 1.0)
	var entry: Dictionary = {
		"id":next_id, "car_id":car_id, "team":team, "phase":"EXECUTION",
		"decision_id":linked_decision_id,
		"driver":str(car.get("name", "")), "track_lap":int(floor(float(car.get("progress", 0.0)))) + 1,
		"stop":int(car.get("stops", 0)) + 1, "tick":simulation_tick,
		"time_s":time_s, "order_origin":str(car.get("pit_order_source", "")),
		"compound_before":str(car.get("tire", "")), "compound_after":target,
		"position_before":int(car.get("position", 0)), "predicted_position":position,
		"predicted_net_loss_s":corrected_loss,
		"predicted_total_s":corrected_loss + base_lap * pit_track_fraction,
		"predicted_wear_5":minf(100.0, rate * float(STINT_HORIZON)) if rate > 0.0 else -1.0,
		"predicted_pace_5":expected_pace,
		"weather_at_prediction":wet, "predicted_water_3":projected_water,
		"strategist_level":level, "engineer_level":engineer_level,
		"confidence":str(advice.get("confidence", "NAO_CALIBRADA")),
		"calibration_samples":mini(int(loss_bias["samples"]), int(position_bias["samples"])),
		"pit_verified":false, "status":"AWAITING_EXIT", "laps_observed":0,
		"pace_sum_s":0.0, "pace_samples":0, "last_observed_lap":-1,
		"weather_verified":false, "reasons":[]
	}
	# Missing staff identity means no assumed competence; it is reported honestly.
	next_id += 1
	records.append(entry)
	while records.size() > MAX_RECORDS:
		records.pop_front()

func observe_exit(history: Dictionary, base_lap: float, pit_track_fraction: float) -> void:
	for idx in range(records.size() - 1, -1, -1):
		var record: Dictionary = records[idx]
		if int(record["car_id"]) != int(history.get("car_id", -1)) or int(record["stop"]) != int(history.get("stop", -1)) or str(record["status"]) != "AWAITING_EXIT":
			continue
		var measured: float = float(history.get("total", -1.0))
		if measured < 0.0:
			record["status"] = "UNVERIFIABLE"
			record["reasons"] = ["histórico do pit sem tempo medido"]
			return
		var actual_loss: float = measured - base_lap * pit_track_fraction
		record["pit_verified"] = true
		record["status"] = "AWAITING_HORIZON"
		record["actual_position"] = int(history.get("position_after", 0))
		record["actual_net_loss_s"] = actual_loss
		record["position_error"] = int(record["actual_position"]) - int(record["predicted_position"])
		record["pit_loss_error_s"] = actual_loss - float(record["predicted_net_loss_s"])
		record["exit_lap"] = int(history.get("lap", 0))
		record["actual_wait_s"] = float(history.get("wait", 0.0))
		record["actual_incident_delay_s"] = float(history.get("incident_delay", 0.0))
		record["actual_training_saved_s"] = float(history.get("training_saved", 0.0))
		var reasons: Array[String] = []
		if float(record["actual_wait_s"]) > 0.01:
			reasons.append("fila de garagem confirmada")
		if float(record["actual_incident_delay_s"]) > 0.01:
			reasons.append("atraso de pit confirmado: " + str(history.get("incident", "incidente")))
		if absf(float(record["actual_training_saved_s"])) > 0.01:
			reasons.append("ganho de serviço por treinamento medido")
		if int(record["position_error"]) != 0:
			reasons.append("posição divergiu; causas externas (tráfego/pits rivais) não isoladas")
		if absf(float(record["pit_loss_error_s"])) > 0.75 and reasons.is_empty():
			reasons.append("diferença residual de tempo; sem causa isolada")
		record["reasons"] = reasons
		return

func observe_lap(car: Dictionary, weather: Dictionary) -> void:
	var completed: int = int(car.get("laps_done", 0))
	for record in records:
		if int(record["car_id"]) != int(car.get("id", -1)) or str(record["status"]) != "AWAITING_HORIZON":
			continue
		var exited: int = int(record.get("exit_lap", 0))
		if completed <= exited or completed <= int(record["last_observed_lap"]):
			continue
		if completed > exited + STINT_HORIZON:
			record["status"] = "UNVERIFIABLE"
			record["reasons"].append("horizonte de cinco voltas não observado integralmente")
			continue
		# A second stop before the horizon makes this tyre forecast incomparable.
		if int(car.get("stops", 0)) != int(record["stop"]) or str(car.get("tire", "")) != str(record["compound_after"]):
			record["status"] = "INTERRUPTED"
			record["reasons"].append("novo pit ou troca de composto antes do horizonte")
			continue
		record["last_observed_lap"] = completed
		record["laps_observed"] = int(record["laps_observed"]) + 1
		var lap_time: float = float(car.get("last_lap", 0.0))
		if _valid_pace(lap_time):
			record["pace_sum_s"] = float(record["pace_sum_s"]) + lap_time
			record["pace_samples"] = int(record["pace_samples"]) + 1
		if completed >= exited + 3 and not bool(record["weather_verified"]):
			record["actual_water_3"] = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
			record["water_error_3"] = float(record["actual_water_3"]) - float(record["predicted_water_3"])
			record["weather_verified"] = true
		if completed >= exited + STINT_HORIZON:
			record["actual_wear_5"] = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
			if float(record["predicted_wear_5"]) >= 0.0:
				record["wear_error_5"] = float(record["actual_wear_5"]) - float(record["predicted_wear_5"])
			if int(record["pace_samples"]) == STINT_HORIZON and float(record["predicted_pace_5"]) > 0.0:
				record["actual_pace_5"] = float(record["pace_sum_s"]) / float(STINT_HORIZON)
				record["pace_error_5"] = float(record["actual_pace_5"]) - float(record["predicted_pace_5"])
			record["status"] = "COMPLETE"

func close_unfinished() -> void:
	for record in records:
		if str(record["status"]) in ["AWAITING_EXIT", "AWAITING_HORIZON"]:
			record["status"] = "UNVERIFIABLE"
			record["reasons"].append("corrida encerrada antes do horizonte verificável")
		elif str(record["status"]) == "RECOMMENDED":
			record["status"] = "NOT_FOLLOWED"
			record["reasons"].append("recomendação não executada até o encerramento")

func snapshot(team_filter: String = "") -> Array:
	var out: Array = []
	for record in records:
		if team_filter.is_empty() or str(record["team"]) == team_filter:
			out.append(record.duplicate(true))
	return out

func summary(team_filter: String = "") -> Dictionary:
	var count: int = 0
	var scored: int = 0
	var abs_loss: float = 0.0
	var abs_position: float = 0.0
	var by_level: Dictionary = {}
	for record in records:
		if not team_filter.is_empty() and str(record["team"]) != team_filter:
			continue
		count += 1
		if not bool(record.get("pit_verified", false)):
			continue
		scored += 1
		var loss_error: float = absf(float(record.get("pit_loss_error_s", 0.0)))
		var position_error: float = absf(float(record.get("position_error", 0)))
		abs_loss += loss_error
		abs_position += position_error
		var level: int = int(record.get("strategist_level", -1))
		var group: Dictionary = by_level.get(level, {"count":0, "abs_loss_s":0.0, "abs_position":0.0})
		group["count"] = int(group["count"]) + 1
		group["abs_loss_s"] = float(group["abs_loss_s"]) + loss_error
		group["abs_position"] = float(group["abs_position"]) + position_error
		by_level[level] = group
	return {"total":count, "verified_pits":scored,
		"mae_loss_s":abs_loss / float(scored) if scored > 0 else -1.0,
		"mae_position":abs_position / float(scored) if scored > 0 else -1.0,
		"by_strategist_level":by_level}
