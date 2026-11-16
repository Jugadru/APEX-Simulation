extends RefCounted
## APEX Core 2: pit-lane state machine moved out of race_engine.gd.
## Retains the validated 0.5.4.0 transition order and numerical thresholds.
## The host owns garage occupancy, events, service completion, telemetry and RNG.
## No UI imports, no RNG calls, no engine preload or circular dependency.
## Progress follows the same pit spline phases used by pit_complex_3d.gd.

static func stage_duration(car: Dictionary, stage: String, queue_phase: float, service_begin: float, service_end: float) -> float:
	var total: float = float(car["pit_nominal_total"])
	match stage:
		"approach":
			return total * queue_phase
		"dock":
			return float(car["pit_dock_total"])
		"service":
			return float(car["pit_service_total"])
		"exit":
			return total * (1.0 - service_end)
		"repair":
			return float(car["pit_service_delay"])
		"safety_hold":
			return float(car["pit_release_delay"])
	return 0.0

static func advance(host, car: Dictionary, dt: float, queue_phase: float, service_begin: float, service_end: float) -> void:
	var old_progress: float = float(car["progress"])
	var remaining_dt: float = dt
	var iterations: int = 0
	while remaining_dt > 0.0000001 and iterations < 8:
		iterations += 1
		var stage: String = str(car["pit_stage"])
		if stage == "queue":
			if host._garage_available(car):
				host._acquire_garage(car)
				continue
			# Waiting is additional real race time. The timing position is
			# frozen at the holding point, rather than jumping to the garage.
			car["pit_wait"] = float(car["pit_wait"]) + remaining_dt
			remaining_dt = 0.0
			break
		if stage == "done" or stage == "none":
			remaining_dt = 0.0
			break
		var stage_length: float = maxf(0.001, stage_duration(car, stage, queue_phase, service_begin, service_end))
		var stage_time: float = float(car["pit_stage_elapsed"])
		var advance_by: float = minf(remaining_dt, maxf(0.0, stage_length - stage_time))
		car["pit_stage_elapsed"] = stage_time + advance_by
		if stage == "repair" or stage == "safety_hold":
			car["pit_extra_elapsed"] = float(car["pit_extra_elapsed"]) + advance_by
		else:
			car["pit_active_elapsed"] = float(car["pit_active_elapsed"]) + advance_by
		remaining_dt -= advance_by
		var ratio: float = clampf(float(car["pit_stage_elapsed"]) / stage_length, 0.0, 1.0)
		match stage:
			"approach":
				car["pit_phase"] = queue_phase * ratio
			"dock":
				car["pit_phase"] = lerpf(queue_phase, service_begin, ratio)
			"service":
				car["pit_phase"] = lerpf(service_begin, service_end, ratio)
				car["pit_service_elapsed"] = minf(float(car["pit_service_total"]), float(car["pit_service_elapsed"]) + advance_by)
			"repair":
				car["pit_phase"] = service_end - 0.005
			"safety_hold":
				car["pit_phase"] = service_end
			"exit":
				car["pit_phase"] = lerpf(service_end, 1.0, ratio)
		if ratio >= 0.999999:
			car["pit_stage_elapsed"] = 0.0
			match stage:
				"approach":
					if host._garage_available(car):
						host._acquire_garage(car)
					else:
						car["pit_stage"] = "queue"
						host._event("double_stack", int(car["id"]), "%s: DOUBLE STACK! Aguardando vaga de %s." % [car["name"], car["team"]], 96)
				"dock":
					car["pit_stage"] = "service"
				"service":
					if float(car["pit_service_delay"]) > 0.0:
						host._start_pit_repair(car)
					else:
						host._finish_service(car)
				"repair":
					host._finish_service(car)
				"safety_hold":
					host._continue_pit_exit(car)
				"exit":
					car["pit_stage"] = "done"
					car["pit_phase"] = 1.0
					car["pit_last_wait"] = float(car["pit_wait"])
					car["pit_last_extra"] = float(car["pit_extra_elapsed"])
					car["pit_last_incident"] = str(car["pit_incident_type"])
					car["pit_last_total"] = float(car["pit_active_elapsed"]) + float(car["pit_wait"]) + float(car["pit_extra_elapsed"])
					host._event("pit_exit", int(car["id"]), "%s saiu dos boxes: pneus %.2fs, fila %.1fs, incidente +%.1fs." % [car["name"], float(car["pit_last_service"]), float(car["pit_last_wait"]), float(car["pit_last_extra"])], 65)
	# pit_left is remaining active pit time. It stops falling while in queue;
	# pit_wait is the real extra delay for the double-stack.
	if str(car["pit_stage"]) == "done":
		car["pit_left"] = 0.0
	else:
		var base_left: float = maxf(0.0, float(car["pit_total"]) - float(car["pit_active_elapsed"]))
		var extra_left: float = maxf(0.0, float(car["pit_service_delay"]) + float(car["pit_release_delay"]) - float(car["pit_extra_elapsed"]))
		car["pit_left"] = maxf(0.001, base_left + extra_left)
	car["progress"] = lerpf(float(car["pit_from"]), float(car["pit_to"]), float(car["pit_phase"]))
	host._record_lap_cross(car, old_progress, false)
	if str(car["pit_stage"]) == "done":
		host._record_pit_history(car)


static func snapshot(cars: Array, garage_owners: Dictionary) -> Dictionary:
	# UI/read-only diagnostics: no mutable car references escape this boundary.
	var active_stops: Array = []
	var waiting_count := 0
	var servicing_count := 0
	for car in cars:
		var stage: String = str(car.get("pit_stage", "none"))
		if stage == "none" or stage == "done":
			continue
		if stage == "queue":
			waiting_count += 1
		elif stage in ["dock", "service", "repair", "safety_hold"]:
			servicing_count += 1
		active_stops.append({
			"id": int(car["id"]), "driver": str(car["name"]),
			"team": str(car["team"]), "stage": stage,
			"phase": clampf(float(car.get("pit_phase", 0.0)), 0.0, 1.0),
			"remaining": maxf(0.0, float(car.get("pit_left", 0.0))),
			"waiting": maxf(0.0, float(car.get("pit_wait", 0.0))),
			"service_elapsed": maxf(0.0, float(car.get("pit_service_elapsed", 0.0))),
			"service_total": maxf(0.0, float(car.get("pit_service_total", 0.0)))
		})
	return {"active": active_stops, "owners": garage_owners.duplicate(true),
		"queued": waiting_count, "servicing": servicing_count}
