extends RefCounted
## APEX 0.5.7.0 - planejador deterministico de stints e recomendacoes.
## Nao altera o clima nem gera numeros aleatorios. O jogador conserva o comando de box.
## A velha regra de seguranca de desgaste continua como ultima protecao.
const Strategy = preload("res://scripts/core/race_strategy.gd")
const Rules = preload("res://scripts/core/race_rules.gd")
const WetPhysics = preload("res://scripts/core/race_wet_physics.gd")
const StintOptimizer = preload("res://scripts/core/race_stint_optimizer.gd")
const RainHysteresis = preload("res://scripts/core/race_rain_hysteresis_0642.gd")

static func _compound_cost(name: String, specs: Dictionary, wetness: float, projected_laps: int, wear_pace: float, severity: float) -> float:
	var spec: Dictionary = specs.get(name, {})
	if spec.is_empty():
		return INF
	var rate: float = Strategy._wear_per_lap(name, spec, wetness, wear_pace, severity)
	var average_wear: float = minf(100.0, rate * float(projected_laps) * 0.50)
	var cliff: float = float(spec.get("cliff", 75.0))
	var wear_penalty: float = 0.11 * pow(average_wear / 35.0, 1.55) + 0.06 * pow(maxf(0.0, average_wear - cliff), 1.60)
	return float(spec.get("delta", 0.0)) + float(WetPhysics.modifier(name, wetness)["penalty"]) + wear_penalty

static func _recommend_compound(available: Array, specs: Dictionary, wetness: float, horizon: int, wear_pace: float, severity: float) -> String:
	var winner := ""
	var score := INF
	for item in available:
		var name: String = str(item)
		var value: float = _compound_cost(name, specs, wetness, horizon, wear_pace, severity)
		if value < score:
			score = value
			winner = name
	return winner

static func _wear_penalty(wear: float, cliff: float) -> float:
	var amount: float = clampf(wear, 0.0, 100.0)
	return 0.11 * pow(amount / 35.0, 1.55) + 0.06 * pow(maxf(0.0, amount - cliff), 1.60)

static func _stint_gain(car: Dictionary, current: String, fresh: String, specs: Dictionary,
		wetness: float, in_3: float, in_6: float, horizon: int, wear_pace: float, severity: float) -> float:
	# Approximate lap-by-lap comparison: staying on old tyres against pitting
	# for the candidate compound. Includes expected compound / water crossover.
	# Pit loss is subtracted by the caller. No random traffic or false precision.
	var old_spec: Dictionary = specs.get(current, {})
	var new_spec: Dictionary = specs.get(fresh, {})
	if old_spec.is_empty() or new_spec.is_empty():
		return -INF
	var old_wear: float = float(car.get("wear", 0.0))
	var new_wear: float = 0.0
	var sum_gain: float = 0.0
	for ahead in range(1, horizon + 1):
		var level: float = lerpf(wetness, in_3, float(ahead) / 3.0) if ahead <= 3 else lerpf(in_3, in_6, clampf(float(ahead - 3) / 3.0, 0.0, 1.0))
		old_wear = minf(100.0, old_wear + Strategy._wear_per_lap(current, old_spec, level, wear_pace, severity))
		new_wear = minf(100.0, new_wear + Strategy._wear_per_lap(fresh, new_spec, level, wear_pace, severity))
		var old_time: float = float(old_spec.get("delta", 0.0)) + float(WetPhysics.modifier(current, level)["penalty"]) + _wear_penalty(old_wear, float(old_spec.get("cliff", 75.0)))
		var new_time: float = float(new_spec.get("delta", 0.0)) + float(WetPhysics.modifier(fresh, level)["penalty"]) + _wear_penalty(new_wear, float(new_spec.get("cliff", 75.0)))
		sum_gain += old_time - new_time
	return sum_gain

static func plan(car: Dictionary, race_laps: int, available: Array, specs: Dictionary,
		weather_now: Dictionary, weather_3: Dictionary, weather_6: Dictionary,
		pit_loss: float, teammate_busy: bool = false) -> Dictionary:
	var current_lap: int = maxi(0, int(car.get("laps_done", 0)))
	var remaining: int = maxi(0, race_laps - current_lap)
	var current: String = str(car.get("tire", "Médio"))
	var spec: Dictionary = specs.get(current, {})
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var wetness: float = clampf(float(weather_now.get("wetness_factor", 0.0)), 0.0, 1.0)
	var future_3: float = clampf(float(weather_3.get("wetness_factor", wetness)), 0.0, 1.0)
	var future_6: float = clampf(float(weather_6.get("wetness_factor", future_3)), 0.0, 1.0)
	var pace: Dictionary = Rules.PACES.get(str(car.get("pace", "Normal")), Rules.PACES["Normal"])
	var wear_pace: float = float(pace["wear"])
	var severity: float = maxf(0.70, float(car.get("track_wear_factor", 1.0)))
	var rate: float = Strategy._wear_per_lap(current, spec, wetness, wear_pace, severity) if not spec.is_empty() else 4.0
	var cliff: float = float(spec.get("cliff", 75.0))
	var life: float = maxf(0.0, (cliff - wear) / maxf(0.25, rate))
	var max_pit_lap: int = maxi(1, race_laps - 1)
	var window_start: int = clampi(current_lap + int(floor(life)) - 1, current_lap + 1, max_pit_lap) if remaining >= 2 else 0
	var window_end: int = clampi(current_lap + int(ceil(life)), window_start, max_pit_lap) if remaining >= 2 else 0
	var horizon: int = mini(remaining, 8)
	# A tendencia so desloca parcialmente a escolha; nao confunda previsao com fato.
	var projected_wetness: float = 0.65 * wetness + 0.35 * future_3
	var compound: String = _recommend_compound(available, specs, projected_wetness, horizon, wear_pace, severity)
	var now_choice: String = Strategy.pit_choice(car, race_laps, available, specs, weather_now, pit_loss)
	# Dry: compare complete race plans and stop counts, not 8-9 laps of soft-tyre pace.
	# Weather crossovers still use the separately tested wet strategy below.
	var stable_dry: bool = (current not in ["Intermediário", "Chuva"]
		and wetness <= 0.10 and future_3 <= 0.12 and future_6 <= 0.12)
	var dry_plan: Dictionary = StintOptimizer.optimize(car, race_laps, available, specs, pit_loss) if stable_dry else {"valid": false}
	var critical: bool = wear >= Strategy.CRITICAL_WEAR or (wear >= 72.0 and life <= 0.70)
	var in_pit: bool = float(car.get("pit_left", 0.0)) > 0.001
	var ordered: bool = bool(car.get("pit_request", false))
	var pit_now: bool = not now_choice.is_empty() and not in_pit and not ordered
	# Compare staying versus a fresh stint over a short projected horizon.
	# A marginal gain must cover the REAL pit loss before requesting a stop.
	var projected_saving: float = _stint_gain(car, current, compound, specs,
		wetness, future_3, future_6, mini(remaining, 9), wear_pace, severity) if compound != "" else 0.0
	var undercut: bool = float(car.get("interval", 999.0)) < 1.8 and float(car.get("wear", 0.0)) >= 48.0
	var value_threshold: float = pit_loss + (0.5 if undercut else 2.5)
	var value_stop: bool = projected_saving > value_threshold and int(car.get("stint_laps", 0)) >= 3 and remaining >= 4
	# 0.6.4.9.3: an early wet-for-wet value stop is not worth treating as
	# urgent when the set is still usable. Re-evaluate at the next lap;
	# keep cliff protection, crossover, and critical-wear decisions intact.
	# The 9-lap time model alone caused premature Inter->Inter stops near
	# 52% wear in variable-weather Silverstone just before a drying window.
	if (value_stop and current in ["Intermediário", "Chuva"] and compound == current
			and wear < 64.0 and life > 2.0 and not critical):
		value_stop = false
	if value_stop and not in_pit and not ordered:
		pit_now = true
	var reason := "janela de desgaste"
	if future_3 >= wetness + 0.12:
		reason = "pista ficando mais molhada"
	elif future_3 <= wetness - 0.12:
		reason = "pista secando"
	if critical:
		reason = "pneu perto do limite"
	elif value_stop and now_choice == "":
		reason = "ganho projetado de %.1fs em %d voltas" % [projected_saving, mini(remaining, 9)]
	elif pit_now and now_choice != current:
		reason = "troca de composto / aderencia"
	# In a stable dry race, full-distance minimization owns both the stop
	# decision and next compound. Avoid overriding it with the 8-lap heuristic.
	var planned_pit_lap: int = 0
	var planned_stops: Array = []
	if bool(dry_plan.get("valid", false)):
		planned_pit_lap = int(dry_plan.get("pit_lap", 0))
		planned_stops = dry_plan.get("stops", []).duplicate(true)
		compound = str(dry_plan.get("compound", current))
		pit_now = planned_pit_lap > 0 and planned_pit_lap <= current_lap + 1 and not in_pit and not ordered
		critical = critical or wear >= 92.0
		value_stop = false
		projected_saving = 0.0
		reason = "plano de corrida completo / dois compostos" if bool(dry_plan.get("requires_two_slicks", false)) else "plano de corrida completo"
		if planned_pit_lap > current_lap + 1:
			reason = "parada planejada V%d" % planned_pit_lap
	elif pit_now and now_choice != "":
		# Wet weather remains governed by the proven hysteresis / crossover rule.
		compound = now_choice
	# Avoid oscillating wet/dry strategy during temporary rain and pit cycles.
	# Emergency overheating/mismatch remains actionable; manual orders bypass this.
	var since_last_pit: int = current_lap - int(car.get("last_pit_exit_lap", -100))
	var mismatch: bool = (current in ["Macio", "Médio", "Duro", "Supermacio"] and wetness >= 0.43) or (current == "Chuva" and wetness <= 0.14)
	if pit_now and since_last_pit < (5 if wetness >= 0.12 else 7) and wear < 91.0 and not mismatch:
		pit_now = false
		reason = "aguardar estabilizacao da janela apos pit"
	# Rain transition must have a sustained benefit rather than one noisy point.
	if pit_now and not stable_dry and not critical and not mismatch and compound != current:
		var difference: float = absf(future_3 - wetness)
		if difference >= 0.28 and (future_3 < 0.13 or future_3 > 0.68) and int(car.get("stint_laps", 0)) < 5:
			pit_now = false
			reason = "aguardando tendencia da chuva se consolidar"
	# 0.6.4.2: avoid a two-stop excursion for a brief drizzle. The climate
	# model stays intact; confirm real water AND trend before crossing compounds.
	if pit_now and compound != current:
		# 0.6.4.3 distinguishes rain intensity, water (mm) and asphalt moisture.
		# Forecast shares the same track integrator: no clairvoyant pit call.
		var gate: Dictionary = RainHysteresis.validate(current, compound, wear,
			critical, wetness, float(weather_now.get("rain_intensity", 0.0)), future_3,
			float(weather_now.get("water_mm", -1.0)), float(weather_3.get("water_mm", -1.0)),
			float(weather_now.get("surface_moisture", 0.0)))
		if not bool(gate.get("allowed", true)):
			pit_now = false
			reason = str(gate.get("reason", "aguardar evolução do clima"))
	var deferred: bool = false
	# Duas garagens da mesma equipe compartilham um unico box: evite
	# double stack opcional, mas nunca bloqueie desgaste de emergencia.
	if (teammate_busy and pit_now and not critical and wear < 74.0 and life > 1.0
			and not (bool(dry_plan.get("valid", false)) and bool(dry_plan.get("requires_two_slicks", false))
			and planned_pit_lap >= race_laps - 1)):
		deferred = true
		pit_now = false
		reason = "evitar double stack; reavaliar na proxima volta"
	if remaining < 2 or spec.is_empty():
		pit_now = false
		window_start = 0
		window_end = 0
	if bool(dry_plan.get("valid", false)):
		window_start = planned_pit_lap
		window_end = planned_pit_lap
	var status := "PLANO ATIVO"
	if in_pit:
		status = "EM ATENDIMENTO"
	elif ordered:
		status = "BOX JA SOLICITADO"
	elif pit_now:
		status = "BOX RECOMENDADO AGORA"
	elif deferred:
		status = "AGUARDAR JANELA LIVRE"
	elif window_start == 0:
		status = "ATE A BANDEIRADA"
	elif window_start >= race_laps - 1 and wear < 45.0:
		status = "PROVAVELMENTE ATE O FIM"
	var window_text := "sem parada prevista" if window_start == 0 else "voltas %d-%d" % [window_start, window_end]
	var message: String = "%s | %s • %s • %s" % [status, compound, window_text, reason]
	if ordered:
		message = "BOX CHAMADO: %s; aguardar entrada." % str(car.get("pit_target", current))
	elif in_pit:
		message = "BOX EM ANDAMENTO: %s." % str(car.get("pit_target", current))
	return {
		"pit_now": pit_now, "compound": compound, "reason": reason,
		"status": status, "message": message,
		"window_start": window_start, "window_end": window_end,
		"life_laps": life, "wear_per_lap": rate, "critical": critical,
		"projected_wetness": projected_wetness, "forecast_3": future_3,
		"forecast_6": future_6, "current_wetness": wetness,
		"planned_pit_lap": planned_pit_lap, "planned_stops": planned_stops,
		"deferred": deferred, "last_lap": remaining < 2,
		"projected_saving_s": projected_saving, "projected_horizon_laps": mini(remaining, 9)
	}
