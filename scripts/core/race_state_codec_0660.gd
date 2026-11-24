extends RefCounted
## Only script-owned data on these four known objects. Never deserialize Objects.
const Race = preload("res://scripts/race_engine.gd")
const SCHEMA := 1
const CHILDREN := ["weather", "track_dynamics", "telemetry"]
const EXCLUDED := ["command_session", "rng", "weather", "track_dynamics", "telemetry", "_engineer_advice_cache", "prediction_ledger", "prediction_staff", "driver_traffic_enabled", "driver_soul3_enabled", "pit_coordination2_enabled", "pit_queue_prevention_enabled", "wet_strategy_intelligence_enabled", "strategy_staff_intelligence_enabled", "strategy_staff_profile", "race_start_intelligence_enabled", "race_start20_enabled", "competitive_start_enabled", "merge_traffic_enabled", "traffic_hotfix_enabled", "racing_line_enabled", "following_enabled", "pass_completion_enabled", "independent_racecraft_enabled", "aero_wake_enabled", "racing_line_profile", "overtaking_intelligence_enabled"]

static func fields(obj: Object, excluded: Array = [], clone: bool = true) -> Dictionary:
	var result: Dictionary = {}
	for prop in obj.get_script().get_script_property_list():
		var key: String = prop.name
		if key in excluded or not (int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
		var value: Variant = obj.get(key)
		assert(not value is Object, "Unregistered checkpoint object: " + key)
		result[key] = value.duplicate(true) if clone and (value is Array or value is Dictionary) else value
	return result

static func capture(race) -> Dictionary:
	var state := {"schema": SCHEMA, "engine": fields(race, EXCLUDED), "rng": {"seed": race.rng.seed, "state": race.rng.state}}
	for child in CHILDREN: state[child] = fields(race.get(child))
	return state

static func apply_fields(obj: Object, values: Dictionary) -> void:
	for key in values:
		var value: Variant = values[key]
		obj.set(key, value.duplicate(true) if value is Dictionary or value is Array else value)

static func restore(state: Dictionary):
	if state.get("schema") != SCHEMA or not state.get("engine") is Dictionary or not state.get("rng") is Dictionary: return null
	if typeof(state.rng.get("seed")) != TYPE_INT or typeof(state.rng.get("state")) != TYPE_INT: return null
	var e: Dictionary = state.get("engine", {})
	if not e.has_all(["teams", "team_name", "track", "team_upgrades", "crew_levels", "cars"]): return null
	var trusted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = Race.new(trusted.teams, "Ferrari", 1, {}, trusted.tracks[0], {})
	# The serialized fields must exactly match this version's known state schema.
	if not same_fields(e, fields(race, EXCLUDED)): return null
	for child in CHILDREN:
		if not state.get(child) is Dictionary or not same_fields(state[child], fields(race.get(child))): return null
	if e.cars.size() != 24 or e.teams.size() != 12 or e.lap_count <= 0 or not is_finite(e.clock): return null
	var ids: Dictionary = {}
	for car in e.cars:
		if not car is Dictionary or not car.has_all(["id","team","name","finished","progress","wear","position"]): return null
		if typeof(car.id) != TYPE_INT or ids.has(car.id) or typeof(car.finished) != TYPE_BOOL or typeof(car.progress) != TYPE_FLOAT: return null
		ids[car.id] = true
	apply_fields(race, e)
	race.racing_line_profile = race.RacingLine.build(race.track)
	for child in CHILDREN: apply_fields(race.get(child), state[child])
	race.rng.seed = int(state.rng.seed)
	race.rng.state = int(state.rng.state)
	race._engineer_advice_cache.clear()
	return race

static func same_fields(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size(): return false
	for key in b:
		if not a.has(key) or typeof(a[key]) != typeof(b[key]): return false
	return true

static func canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort_custom(func(a,b): return str(typeof(a))+":"+str(a) < str(typeof(b))+":"+str(b))
		var result: Array = []
		for key in keys: result.append([key, canonical(value[key])])
		return ["dictionary", result]
	if value is Array:
		var result: Array = []
		for entry in value: result.append(canonical(entry))
		return ["array", result]
	return value

static func digest(value: Variant) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(value))
	return ctx.finish().hex_encode()

# 06692: only cache *names* of sporting script properties. Values are read
# freshly on every tick, and the public fields()/checkpoint schema is untouched.
# String (not StringName) keys and declaration order preserve var_to_bytes hashes.
static var _sporting_property_names: Dictionary = {}

static func _sporting_fields(obj: Object, excluded: Array = []) -> Dictionary:
	var script_ref: Script = obj.get_script()
	var script_id: int = script_ref.get_instance_id()
	if not _sporting_property_names.has(script_id):
		var names: Array[String] = []
		for prop in script_ref.get_script_property_list():
			if int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				names.append(str(prop.name))
		_sporting_property_names[script_id] = names
	var result: Dictionary = {}
	for key in _sporting_property_names[script_id]:
		if key in excluded: continue
		var value: Variant = obj.get(key)
		assert(not value is Object, "Unregistered checkpoint object: " + key)
		result[key] = value
	return result

static func sporting_hash(race, policy: Dictionary) -> String:
	# Same ordered fields, same hashing input and digest as v0.6.6.9.1.
	# This is an allocation/reflection optimization, not a replay revision.
	var e := _sporting_fields(race, EXCLUDED)
	e.erase("running")
	return digest([e, race.rng.seed, race.rng.state, _sporting_fields(race.weather), _sporting_fields(race.track_dynamics), policy])

static func canonical_hash(state: Dictionary) -> String:
	# For offline audits irrespective of Dictionary insertion order. The hot-path
	# trace uses the fixed schema's serialization order, preserved by checkpoints.
	return digest(canonical(state))
