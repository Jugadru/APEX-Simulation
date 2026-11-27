extends RefCounted
## Campeonato 2012: registra resultados apenas na bandeirada, sem alterar a física da corrida.
const SAVE_PATH := "user://apex_championship_2012_v060.json"
const POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
const FORMAT := 1
const RivalDevelopment = preload("res://scripts/core/rival_development_0642.gd")
const SaveMigration = preload("res://scripts/core/apex_save_migration_0650.gd")
var state: Dictionary = {}
var save_path: String = SAVE_PATH

func _init(path_override: String = SAVE_PATH) -> void:
	save_path = path_override
	load_save()

func has_season() -> bool:
	return not state.is_empty() and int(state.get("format", -1)) == FORMAT

func is_complete() -> bool:
	return has_season() and int(state.get("round_index", 0)) >= (state.get("calendar", []) as Array).size()

func next_round() -> Dictionary:
	if not has_season() or is_complete():
		return {}
	return (state["calendar"] as Array)[int(state["round_index"])].duplicate(true)

func start_new(team: String, seed: int, tracks: Array, teams: Array) -> bool:
	if team.is_empty() or tracks.is_empty() or teams.is_empty():
		return false
	var serial: int = int(state.get("serial", 0)) + 1
	var calendar: Array = []
	for race_track in tracks:
		calendar.append({"code": str(race_track.get("code", "")), "name": str(race_track.get("name", "")), "country": str(race_track.get("country", "")), "laps": int(race_track.get("laps", 0))})
	var drivers: Dictionary = {}
	var constructors: Dictionary = {}
	for entry in teams:
		var name: String = str(entry["name"])
		constructors[name] = 0
		for driver in entry["drivers"]:
			drivers[str(driver["name"])] = 0
	var old_state: Dictionary = state.duplicate(true)
	state = {"format": FORMAT, "season": 2012, "serial": serial, "team": team, "seed": maxi(0, seed),
		"calendar": calendar, "round_index": 0, "results": [],
		"drivers": drivers, "constructors": constructors, "complete": false,
		"rival_development": RivalDevelopment.create(teams, team)}
	if save():
		return true
	state = old_state
	return false

func round_seed() -> int:
	if not has_season():
		return 42
	return int(state.get("seed", 42)) + int(state.get("round_index", 0)) * 7919

func record_result(track: Dictionary, order: Array, elapsed: float) -> Dictionary:
	# Called only after race.finished; preserves the classified final order, including late finishers.
	if not has_season() or is_complete() or order.is_empty():
		return {"ok": false, "error": "Temporada encerrada ou corrida sem resultado."}
	var expected: Dictionary = next_round()
	if str(track.get("code", "")) != str(expected.get("code", "")):
		return {"ok": false, "error": "Circuito diferente da proxima etapa."}
	var unique: Dictionary = {}
	var awarded: Array = []
	var dp: Dictionary = (state["drivers"] as Dictionary).duplicate(true)
	var cp: Dictionary = (state["constructors"] as Dictionary).duplicate(true)
	for i in range(order.size()):
		var car: Dictionary = order[i]
		var name: String = str(car.get("name", ""))
		var team: String = str(car.get("team", ""))
		if name.is_empty() or unique.has(name) or not dp.has(name) or not cp.has(team):
			return {"ok": false, "error": "Pilotos ou equipes invalidos no resultado."}
		unique[name] = true
		var pts: int = POINTS[i] if i < POINTS.size() and not bool(car.get("disqualified", false)) and not bool(car.get("fuel_dnf_0701",false)) else 0
		dp[name] = int(dp[name]) + pts
		cp[team] = int(cp[team]) + pts
		awarded.append({"position": i + 1, "name": name, "team": team, "points": pts,
			"best_lap": float(car.get("best_lap", 0.0)), "stops": int(car.get("stops", 0)),
			"disqualified": bool(car.get("disqualified", false))})
	if unique.size() != dp.size():
		return {"ok": false, "error": "Grid incompleto: nao registrar classificacao parcial."}
	var round_index: int = int(state["round_index"])
	var result: Dictionary = {"round": round_index + 1, "code": expected["code"], "name": expected["name"],
		"elapsed": elapsed, "seed": round_seed(), "positions": awarded}
	var updated: Dictionary = state.duplicate(true)
	var history: Array = updated["results"]
	history.append(result)
	updated["drivers"] = dp
	updated["constructors"] = cp
	updated["round_index"] = history.size()
	updated["rival_development"] = RivalDevelopment.advance(
		updated.get("rival_development", {}), history.size(), int(updated.get("seed", 42)), cp,
		str(updated.get("team", "")))
	updated["complete"] = history.size() >= (updated["calendar"] as Array).size()
	# Atomic write before committing in-memory state.
	if not _write(updated):
		return {"ok": false, "error": "Nao foi possivel salvar a classificacao."}
	state = updated
	return {"ok": true, "round": round_index + 1, "complete": is_complete(), "result": result}

func standings(key: String) -> Array:
	if not has_season():
		return []
	var values: Dictionary = state.get(key, {})
	var rows: Array = []
	for name in values.keys():
		rows.append({"name": str(name), "points": int(values[name])})
	rows.sort_custom(func(a, b):
		if int(a["points"]) == int(b["points"]):
			return str(a["name"]) < str(b["name"])
		return int(a["points"]) > int(b["points"]))
	return rows

func save() -> bool:
	return has_season() and _write(state)

func _write(payload: Dictionary) -> bool:
	var target: String = ProjectSettings.globalize_path(save_path)
	var tmp: String = target + ".tmp"
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "  "))
	file.close()
	var err: int = DirAccess.rename_absolute(tmp, target)
	if err != OK:
		DirAccess.remove_absolute(tmp)
		return false
	return true

func load_save() -> void:
	state.clear()
	var source: String = save_path
	var migrated: bool = false
	if not FileAccess.file_exists(source):
		# Path overrides used by tests are intentionally isolated.
		if save_path != SAVE_PATH:
			return
		source = SaveMigration.previous_file("apex_championship_2012_v060.json")
		if source.is_empty():
			return
		migrated = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(source))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	if int(data.get("format", -1)) != FORMAT or int(data.get("season", -1)) != 2012:
		return
	if typeof(data.get("calendar", null)) != TYPE_ARRAY or typeof(data.get("results", null)) != TYPE_ARRAY or typeof(data.get("drivers", null)) != TYPE_DICTIONARY or typeof(data.get("constructors", null)) != TYPE_DICTIONARY:
		return
	var rounds: int = (data["results"] as Array).size()
	if rounds > (data["calendar"] as Array).size() or int(data.get("round_index", -1)) != rounds:
		return
	if typeof(data.get("rival_development", null)) != TYPE_DICTIONARY:
		data["rival_development"] = RivalDevelopment.migrate(data)
	state = data
	if migrated:
		# Copy only after schema validation. Older 9.9 file remains untouched.
		_write(state)

func get_rival_development() -> Dictionary:
	if not has_season():
		return {}
	return (state.get("rival_development", {}) as Dictionary).duplicate(true)

func get_rival_levels() -> Dictionary:
	var levels: Dictionary = {}
	for name in get_rival_development().keys():
		levels[str(name)] = (state["rival_development"][name].get("levels", {}) as Dictionary).duplicate(true)
	return levels
