extends RefCounted
## Only adapter imports Core 2. Simulation Kernel and Command Queue have no Core references.
const Race = preload("res://scripts/race_engine.gd")
const TRACK_DATA: String = "res://data/season_2012.json"
const UNITS_PER_LAP: int = 1000000

static func create_pair(track_code: String, weather_profile: String, seed_value: int, player_team: String = "Ferrari") -> Dictionary:
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRACK_DATA))
	if not source is Dictionary or not source.has_all(["tracks", "teams"]):
		return {}
	var selected: Dictionary = {}
	for entry in source.tracks:
		if str(entry.get("code", "")) == track_code:
			selected = entry.duplicate(true)
			break
	if selected.is_empty():
		return {}
	var core = Race.new(source.teams.duplicate(true), player_team, seed_value, {}, selected, {})
	core.configure_weather(weather_profile)
	var roster: Array = []
	for car in core.cars:
		roster.append({"id": int(car.id), "name": str(car.name), "team": str(car.team), "grid": int(car.grid), "tire": str(car.tire), "progress_units": roundi(float(car.progress) * UNITS_PER_LAP)})
	roster.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.id) < int(b.id))
	var scenario: Dictionary = {"schema": 1, "seed": seed_value, "track_code": track_code, "track_name": str(selected.get("name", "")), "race_laps": int(selected.laps), "lap_length_mm": roundi(float(selected.lap_km) * 1000000.0), "base_lap_ms": roundi(float(selected.base_lap) * 1000.0), "weather": weather_profile, "weather_observed": core.weather_snapshot().duplicate(true), "cars": roster, "compounds": core.available_pit_compounds().duplicate(true)}
	return {"core": core, "scenario": scenario}

static func side_by_side(core, next_state: Dictionary) -> Dictionary:
	## Read-only comparability contract: IDs, team mapping, entry progress, and events.
	var core_map: Dictionary = {}
	for car in core.cars:
		core_map[int(car.id)] = car
	var missing: Array = []
	var active: int = 0
	for car in next_state.get("cars", []):
		var id: int = int(car.id)
		if not core_map.has(id) or str(core_map[id].team) != str(car.team):
			missing.append(id)
		if not bool(car.finished):
			active += 1
	return {"core_car_count": core.cars.size(), "next_car_count": next_state.get("cars", []).size(), "missing_or_mismatched_ids": missing, "next_active": active, "core_time_s": float(core.clock), "next_time_s": float(next_state.get("clock_ms", 0)) / 1000.0, "core_events": core.events.size(), "next_events": next_state.get("events", []).size(), "model_equivalence": false}
