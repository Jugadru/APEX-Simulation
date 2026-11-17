extends RefCounted
## v0.6.4.9.8 — strictly read-only, race-derived chart data.
## Samples only observed lap crossings; missing laps are never fabricated.
## Initial plan comes from the existing 0.6.4.9.5 deterministic planner.
const PreRacePlanner = preload("res://scripts/core/race_pre_race_strategy_06495.gd")

var initial_plans: Dictionary = {}
var observations: Dictionary = {}
var last_lap_by_id: Dictionary = {}
var track_name: String = ""
var source_race_id: int = 0

func reset(race) -> void:
	initial_plans.clear()
	observations.clear()
	last_lap_by_id.clear()
	track_name = str(race.track.get("name", ""))
	source_race_id = race.get_instance_id()
	var plans: Dictionary = PreRacePlanner.generate(race)
	for plan in plans.get("plans", []):
		initial_plans[int(plan.get("id", -1))] = plan.duplicate(true)
	capture(race)

func capture(race) -> void:
	if race == null:
		return
	if source_race_id != race.get_instance_id():
		reset(race)
		return
	for car in race.player_cars():
		var id: int = int(car.get("id", -1))
		var lap: int = int(car.get("laps_done", 0))
		var last: int = int(last_lap_by_id.get(id, -1))
		if lap <= last:
			continue
		var series: Array = observations.get(id, [])
		series.append({"lap":lap, "wear":clampf(float(car.get("wear", 0.0)), 0.0, 100.0),
			"stops":int(car.get("stops", 0)), "tire":str(car.get("tire", "")),
			"stint":int(car.get("stint_laps", 0))})
		observations[id] = series
		last_lap_by_id[id] = lap

static func _actual_pits(race, id: int) -> Array:
	var result: Array = []
	for stop in race.pit_history:
		if int(stop.get("car_id", -99)) == id:
			result.append({"lap":int(stop.get("lap", 0)), "old_tire":str(stop.get("old_tire", "")),
				"new_tire":str(stop.get("new_tire", ""))})
	result.sort_custom(func(a, b): return int(a["lap"]) < int(b["lap"]))
	return result

static func _measured_rate(series: Array) -> float:
	# Only consecutive completed laps of exactly the same stint can contribute.
	var rates: Array[float] = []
	for i in range(series.size() - 1, 0, -1):
		var a: Dictionary = series[i-1]
		var b: Dictionary = series[i]
		if int(b["stops"]) != int(a["stops"]) or str(b["tire"]) != str(a["tire"]):
			break
		if int(b["lap"]) != int(a["lap"]) + 1:
			break
		var increment: float = float(b["wear"]) - float(a["wear"])
		if increment < 0.0:
			break
		rates.append(increment)
		if rates.size() == 4:
			break
	if rates.is_empty():
		return -1.0
	var total: float = 0.0
	for value in rates:
		total += value
	return total / float(rates.size())

func view(race, car: Dictionary) -> Dictionary:
	var id: int = int(car.get("id", -1))
	var series: Array = observations.get(id, [])
	var lap: int = int(car.get("laps_done", 0))
	var total: int = int(race.lap_count)
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var advice: Dictionary = race.get_engineer_advice(id)
	var scheduled: int = int(car.get("pit_scheduled_lap", 0))
	var recommendation: int = int(advice.get("planned_pit_lap", 0))
	var window_start: int = int(advice.get("window_start", 0))
	var window_end: int = int(advice.get("window_end", 0))
	if window_start <= lap or window_start >= total:
		window_start = 0
		window_end = 0
	elif window_end < window_start:
		window_end = window_start
	# Prefer the simulator's own advice; observed wear slope is presented separately
	# and used for a *measured trend* forecast after at least one real delta.
	var measured: float = _measured_rate(series)
	var engine_rate: float = float(advice.get("wear_per_lap", -1.0))
	var rate: float = measured if measured > 0.0 else engine_rate
	var rate_source: String = "voltas reais" if measured > 0.0 else "modelo atual do motor"
	var estimate: Array = []
	var horizon: int = total
	if scheduled > lap:
		horizon = mini(horizon, scheduled)
	elif window_start > lap:
		horizon = mini(horizon, window_end)
	if rate > 0.0 and not bool(car.get("finished", false)):
		for future_lap in range(lap, horizon + 1):
			var projection: float = minf(100.0, wear + float(future_lap-lap) * rate)
			estimate.append({"lap":future_lap, "wear":projection})
			if projection >= 100.0:
				break
	var actual: Array = _actual_pits(race, id)
	var baseline: Dictionary = initial_plans.get(id, {})
	return {"id":id, "name":str(car.get("name", "Piloto")), "tire":str(car.get("tire", "")),
		"lap":lap, "total":total, "wear":wear, "history":series.duplicate(true),
		"forecast":estimate, "rate":rate, "measured_rate":measured, "rate_source":rate_source,
		"engine_rate":engine_rate, "baseline":baseline.duplicate(true), "pits":actual,
		"scheduled":scheduled, "window_start":window_start, "window_end":window_end,
		"recommended_lap":recommendation, "target":str(advice.get("compound", "")),
		"pit_called":bool(car.get("pit_request", false)), "pit_active":float(car.get("pit_left", 0.0)) > 0.0,
		"stops":int(car.get("stops", 0)), "cliff":float(race.tyre_spec(str(car.get("tire", ""))).get("cliff", 100.0)),
		"status":str(advice.get("status", "")), "review":car.get("lap_strategy_06496", {}).duplicate(true)}

static func garage_status(a: Dictionary, b: Dictionary) -> Dictionary:
	if a.is_empty() or b.is_empty():
		return {"kind":"INDEFINIDO", "message":"Sem dois pilotos para comparar."}
	var aa: int = int(a.get("scheduled", 0))
	var bb: int = int(b.get("scheduled", 0))
	var ar: int = int(a.get("window_start", 0))
	var br: int = int(b.get("window_start", 0))
	var ab: bool = bool(a.get("pit_called", false)) or bool(a.get("pit_active", false))
	var busy: bool = bool(b.get("pit_called", false)) or bool(b.get("pit_active", false))
	if aa > 0 and aa == bb:
		return {"kind":"CONFIRMADO", "lap":aa, "message":"DOUBLE STACK AGENDADO: ambos com ordem V%d." % aa}
	if ab and busy:
		return {"kind":"ATENÇÃO", "message":"Os dois carros solicitaram/ocupam a garagem; verificar fila real."}
	if (aa > 0 and aa == br) or (bb > 0 and bb == ar) or (ar > 0 and ar == br):
		var conflict_lap: int = aa if aa > 0 and aa == br else (bb if bb > 0 and bb == ar else ar)
		return {"kind":"POTENCIAL", "lap":conflict_lap, "message":"Janelas de box se sobrepõem na V%d; ainda não são duas ordens." % conflict_lap}
	if ab or busy:
		return {"kind":"MONITORAR", "message":"Um carro já chamou o box; verificar o tempo de ocupação da garagem."}
	return {"kind":"LIVRE", "message":"Sem coincidência nas janelas ou agendamentos conhecidos."}
