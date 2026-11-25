extends RefCounted
## Apex v0.5.3.3 — observational telemetry/event ledger.
## IMPORTANT: this script never mutates the race engine's cars or RNG.
## Sectors are inferred from the continuous lap-progress scalar at thirds of
## the track, not physical FIA timing-loop positions or a GPS trace.

const SCHEMA_VERSION: int = 2
const SNAPSHOT_PERIOD: float = 10.0

var track_name: String = ""
var track_code: String = ""
var lap_count: int = 0
var seed_value: int = 0
var sector_history: Array[Dictionary] = []
var lap_history: Array[Dictionary] = []
var position_history: Array[Dictionary] = []
var event_history: Array[Dictionary] = []
var pit_history: Array[Dictionary] = []
var weather_history: Array[Dictionary] = []
var _next_weather_at: float = 0.0
var _drivers: Dictionary = {} # car_id -> observer state
var _next_snapshot_at: float = 0.0
var _last_event_id: int = 0

func reset(cars: Array, circuit: Dictionary, seed: int, start_clock: float = 0.0) -> void:
	track_name = str(circuit.get("name", "Circuito"))
	track_code = str(circuit.get("code", "GP"))
	lap_count = int(circuit.get("laps", 0))
	seed_value = seed
	sector_history.clear()
	lap_history.clear()
	position_history.clear()
	event_history.clear()
	pit_history.clear()
	weather_history.clear()
	_next_weather_at = start_clock
	_drivers.clear()
	_last_event_id = 0
	_next_snapshot_at = start_clock + SNAPSHOT_PERIOD
	for car in cars:
		var cid: int = int(car["id"])
		_drivers[cid] = {
			"car_id": cid, "driver": str(car["name"]), "team": str(car["team"]),
			"progress": float(car["progress"]),
			"next_marker": 1,
			"sector_started": start_clock,
			"lap_started": start_clock,
			"sector_durations": [],
			"pit_in_lap": false,
			"last_stops": int(car.get("stops", 0))
		}

func record_event(event: Dictionary) -> void:
	var item: Dictionary = event.duplicate(true)
	if not item.has("event_id"):
		_last_event_id += 1
		item["event_id"] = _last_event_id
	else:
		_last_event_id = maxi(_last_event_id, int(item["event_id"]))
	event_history.append(item)

func record_pit(record: Dictionary) -> void:
	pit_history.append(record.duplicate(true))

func record_weather(now: float, weather: Dictionary) -> void:
	# Weather readings share the same authoritative clock and state as physics.
	if now + 0.00001 < _next_weather_at:
		return
	weather_history.append({
		"sample_at": now, "track_state": str(weather.get("track_state", "Seca")),
		"wetness": int(weather.get("wetness", 0)),
		"rain_intensity": float(weather.get("rain_intensity", 0.0)),
		"rain_probability": int(weather.get("rain_probability", 0)),
		"air_c": float(weather.get("air_c", 0.0)),
		"track_c": float(weather.get("track_c", 0.0)),
		"grip": str(weather.get("grip", "Normal")),
		"drs_allowed": bool(weather.get("drs_allowed", true))
	})
	_next_weather_at = now + SNAPSHOT_PERIOD


func events_since(after_id: int) -> Array:
	# Event IDs start at one and are sequential: index is event_id - 1.
	# Avoid scanning the whole race log each time the radio updates.
	var output: Array = []
	for i in range(clampi(after_id, 0, event_history.size()), event_history.size()):
		output.append(event_history[i])
	return output

func observe(cars: Array, now: float, dt: float) -> void:
	if _drivers.is_empty() or dt <= 0.0:
		return
	var at_start: float = now - dt
	for car in cars:
		var cid: int = int(car["id"])
		if not _drivers.has(cid):
			continue
		var state: Dictionary = _drivers[cid]
		var prev: float = float(state["progress"])
		var cur: float = float(car["progress"])
		if int(car.get("stops", 0)) > int(state["last_stops"]) or float(car.get("pit_left", 0.0)) > 0.0:
			state["pit_in_lap"] = true
		state["last_stops"] = int(car.get("stops", 0))
		# An incident can temporarily move progress backwards. Keep the current
		# authoritative position and wait for it to cross the next marker again.
		if cur > prev + 0.00000001:
			var count: int = 0
			while int(state["next_marker"]) <= lap_count * 3 and count < 12:
				var marker: int = int(state["next_marker"])
				var boundary: float = float(marker) / 3.0
				if boundary > cur + 0.0000001:
					break
				if boundary >= prev - 0.0000001:
					var fraction: float = clampf((boundary - prev) / maxf(0.00000001, cur - prev), 0.0, 1.0)
					var cross_at: float = lerpf(at_start, now, fraction)
					var sector_number: int = (marker - 1) % 3 + 1
					var lap_number: int = int((marker - 1) / 3) + 1
					var duration: float = maxf(0.0, cross_at - float(state["sector_started"]))
					var sector: Dictionary = {
						"car_id": cid, "driver": str(state["driver"]), "team": str(state["team"]),
						"lap": lap_number, "sector": sector_number, "seconds": duration,
						"crossed_at": cross_at, "tire": str(car.get("tire", "")),
						"wear_percent": float(car.get("wear", 0.0))
					}
					sector_history.append(sector)
					var durations: Array = state["sector_durations"]
					durations.append(duration)
					state["sector_started"] = cross_at
					if sector_number == 3:
						var lap_time: float = maxf(0.0, cross_at - float(state["lap_started"]))
						lap_history.append({
							"car_id": cid, "driver": str(state["driver"]), "team": str(state["team"]),
							"lap": lap_number, "seconds": lap_time,
							"s1": float(durations[0]), "s2": float(durations[1]), "s3": float(durations[2]),
							"position": int(car.get("position", 0)),
							"tire": str(car.get("tire", "")), "wear_percent": float(car.get("wear", 0.0)),
							"pit_on_lap": bool(state["pit_in_lap"]),
							"pace": str(car.get("pace", "Normal")), "crossed_at": cross_at
						})
						state["lap_started"] = cross_at
						state["sector_durations"] = []
						state["pit_in_lap"] = false
				state["next_marker"] = marker + 1
				count += 1
		state["progress"] = cur
	# Snapshots are point-in-time samples, not interpolated speed/sensor data.
	if now + 0.000001 >= _next_snapshot_at:
		for car in cars:
			position_history.append({
				"sample_at": now, "car_id": int(car["id"]),
				"driver": str(car["name"]), "team": str(car["team"]),
				"position": int(car.get("position", 0)), "progress": float(car["progress"]),
				"gap_seconds": float(car.get("gap", 0.0)),
				"interval_seconds": float(car.get("interval", 0.0)),
				"tire": str(car.get("tire", "")), "wear_percent": float(car.get("wear", 0.0)),
				"pace": str(car.get("pace", "Normal")), "pit_stage": str(car.get("pit_stage", "none")),
				"kers_equipped": bool(car.get("kers_equipped", false)),
				"kers_remaining_kj": float(car.get("kers_remaining_kj", 0.0)),
				"kers_used_lap_kj": float(car.get("kers_used_lap_kj", 0.0)),
				"kers_mode": str(car.get("kers_mode", "Equilibrado")),
				"kers_active": bool(car.get("kers_active", false)),
				"kers_power_kw": float(car.get("kers_power_kw", 0.0)),
				"kers_gain_lap_s": float(car.get("kers_gain_lap_s", 0.0)),
				"drs_active": bool(car.get("drs_active", false)),
				"drs_gain_lap_s": float(car.get("drs_gain_lap_s", 0.0))
			})
			var pack:Dictionary=car.get("traffic_pack_09201",{})
			if not pack.is_empty():
				var sample:Dictionary=position_history[-1]
				sample["traffic_mode"]=str(pack.get("mode",""))
				for key in ["leader","gap_s","rear_s","group_size","drs_train","catch_s","clear_s","congestion_s","estimated_lift_s","solver_delay_s","cancelled","opportunities","confirmed_passes","yield_samples","group_transfers","kers_skipped_ticks"]:
					sample["traffic_"+key]=pack.get(key,"")
		while _next_snapshot_at <= now + 0.000001:
			_next_snapshot_at += SNAPSHOT_PERIOD

func recent_laps(car_id: int, limit: int = 5) -> Array:
	var output: Array = []
	for i in range(lap_history.size() - 1, -1, -1):
		if int(lap_history[i]["car_id"]) == car_id:
			output.append(lap_history[i])
			if output.size() >= limit:
				break
	return output

func latest_sectors(car_id: int) -> Dictionary:
	var found: Dictionary = {}
	for i in range(sector_history.size() - 1, -1, -1):
		var item: Dictionary = sector_history[i]
		if int(item["car_id"]) != car_id:
			continue
		var key: String = "s%d" % int(item["sector"])
		if not found.has(key):
			found[key] = float(item["seconds"])
		if found.size() == 3:
			break
	return found

func summary() -> Dictionary:
	return {
		"laps": lap_history.size(), "sectors": sector_history.size(),
		"position_samples": position_history.size(), "events": event_history.size(),
		"pits": pit_history.size(), "weather_samples": weather_history.size()
	}

func _csv_table(path: String, columns: PackedStringArray, entries: Array) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_csv_line(columns, ";")
	for entry in entries:
		var row := PackedStringArray()
		for column in columns:
			row.append(str(entry.get(column, "")))
		file.store_csv_line(row, ";")
	file.close()
	return true

func export_files(folder: String, metadata: Dictionary = {}) -> Dictionary:
	var err: Error = DirAccess.make_dir_recursive_absolute(folder)
	if err != OK:
		return {"ok": false, "error": "Não foi possível criar pasta (%d)." % err}
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	var prefix: String = "apex_%s_%d_%s" % [track_code.to_lower().replace(" ", "_"), seed_value, stamp]
	var files: Array[String] = []
	var definitions: Array = [
		["voltas", PackedStringArray(["car_id", "driver", "team", "lap", "seconds", "s1", "s2", "s3", "position", "tire", "wear_percent", "pit_on_lap", "pace", "crossed_at"]), lap_history],
		["setores", PackedStringArray(["car_id", "driver", "team", "lap", "sector", "seconds", "crossed_at", "tire", "wear_percent"]), sector_history],
		["posicoes", PackedStringArray(["sample_at", "car_id", "driver", "team", "position", "progress", "gap_seconds", "interval_seconds", "tire", "wear_percent", "pace", "pit_stage", "kers_equipped", "kers_remaining_kj", "kers_used_lap_kj", "kers_mode", "kers_active", "kers_power_kw", "kers_gain_lap_s", "drs_active", "drs_gain_lap_s"]), position_history],
		["eventos", PackedStringArray(["event_id", "time", "type", "driver_id", "priority", "message"]), event_history],
		["clima", PackedStringArray(["sample_at", "track_state", "wetness", "rain_intensity", "rain_probability", "air_c", "track_c", "grip", "drs_allowed"]), weather_history]
	]
	# Separate optional CSV; historical exports keep the original columns.
	var traffic_samples:Array=[]
	for sample in position_history:
		if sample.has("traffic_mode"):traffic_samples.append(sample)
	if not traffic_samples.is_empty():
		definitions.append(["trafego",PackedStringArray(["sample_at","car_id","driver","team","position","traffic_mode","traffic_leader","traffic_gap_s","traffic_rear_s","traffic_group_size","traffic_drs_train","traffic_catch_s","traffic_clear_s","traffic_congestion_s","traffic_estimated_lift_s","traffic_solver_delay_s","traffic_cancelled","traffic_opportunities","traffic_confirmed_passes","traffic_yield_samples","traffic_group_transfers","traffic_kers_skipped_ticks"]),traffic_samples])
	for item in definitions:
		var path: String = folder.path_join(prefix + "_" + str(item[0]) + ".csv")
		if not _csv_table(path, item[1], item[2]):
			return {"ok": false, "error": "Não foi possível gravar %s." % path}
		files.append(path)
	var manifest: Dictionary = {
		"schema_version": SCHEMA_VERSION, "game_version": "0.5.6.0",
		"track_name": track_name, "track_code": track_code,
		"seed": seed_value, "scheduled_laps": lap_count,
		"sample_interval_seconds": SNAPSHOT_PERIOD,
		"sector_method": "frações 1/3, 2/3 e 3/3 da progressão simulada; interpolação temporal",
		"sector_caveat": "não são setores FIA/geometria oficial; a simulação original não foi recalibrada",
		"statistics": summary(), "metadata": metadata,
		"pit_stops": pit_history
	}
	var json_path: String = folder.path_join(prefix + "_resumo.json")
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		return {"ok": false, "error": "Não foi possível gravar o manifesto JSON."}
	json_file.store_string(JSON.stringify(manifest, "\t"))
	json_file.close()
	files.append(json_path)
	return {"ok": true, "files": files, "folder": folder, "counts": summary()}
