extends RefCounted
## APEX 2 / Next Engine 1.0 — isolated deterministic simulation-contract proof.
## The 200ms kinematic integrator below is NOT competitive vehicle physics.
## It validates clocks, state ownership, queue authority, event order and replay.
const CommandQueue = preload("res://experimental/apex2/command_queue.gd")
const SCHEMA: int = 1
const STEP_MS: int = 200
const LAP_UNITS: int = 1000000
const PIT_ENTRY_UNITS: int = 950000
const MAX_TICKS: int = 400000
var state: Dictionary = {}
var queue = CommandQueue.new()
var initialized: bool = false

func initialize(scenario: Dictionary) -> bool:
	if int(scenario.get("schema", -1)) != 1 or int(scenario.get("seed", -1)) < 0:
		return false
	if int(scenario.get("race_laps", 0)) <= 1 or int(scenario.get("base_lap_ms", 0)) < 1000:
		return false
	if not scenario.get("cars", null) is Array or not scenario.get("compounds", null) is Array:
		return false
	var roster: Array = scenario.cars
	if roster.is_empty() or roster.size() > 30:
		return false
	var ids: Dictionary = {}
	var cars: Array = []
	for raw in roster:
		if not raw is Dictionary or not raw.has_all(["id", "name", "team", "progress_units", "tire", "grid"]):
			return false
		if typeof(raw.id) != TYPE_INT or ids.has(raw.id):
			return false
		if not str(raw.tire) in scenario.compounds:
			return false
		ids[raw.id] = true
		cars.append({"id": int(raw.id), "name": str(raw.name), "team": str(raw.team), "grid": int(raw.grid), "tire": str(raw.tire), "progress_units": int(raw.progress_units), "progress_remainder": 0, "laps_done": maxi(0, int(int(raw.progress_units) / LAP_UNITS)), "pace": "Normal", "reference_lap_ms": int(scenario.base_lap_ms), "pit_requested_lap": 0, "pit_order_source": "", "pit_target": "", "pit_stage": "TRACK", "pit_entry_tick": -1, "finished": false})
	cars.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.id) < int(b.id))
	var clean: Dictionary = {"schema": SCHEMA, "seed": int(scenario.seed), "track_code": str(scenario.get("track_code", "")), "track_name": str(scenario.get("track_name", "")), "weather": str(scenario.get("weather", "")), "race_laps": int(scenario.race_laps), "lap_length_mm": int(scenario.get("lap_length_mm", 0)), "tick": 0, "clock_ms": 0, "cars": cars, "compounds": scenario.compounds.duplicate(true), "events": [], "event_serial": 0, "finished": false}
	state = clean
	queue = CommandQueue.new()
	initialized = true
	return true

func snapshot() -> Dictionary:
	return state.duplicate(true)

func submit(command: Dictionary) -> Dictionary:
	if not initialized or bool(state.finished):
		return {"accepted": false, "reason": "not_running"}
	return queue.submit(command.duplicate(true), state)

func _event(kind: String, car_id: int, extra: Dictionary = {}) -> void:
	state.event_serial = int(state.event_serial) + 1
	var entry: Dictionary = {"id": int(state.event_serial), "tick": int(state.tick), "type": kind, "car_id": car_id}
	for field in extra:
		entry[field] = extra[field]
	state.events.append(entry)

func _lookup_car(car_id: int) -> Dictionary:
	for entry in state.cars:
		if int(entry.id) == car_id:
			return entry
	return {}

func _apply_command(command: Dictionary) -> Dictionary:
	var car: Dictionary = _lookup_car(int(command.car_id))
	if car.is_empty() or bool(car.finished):
		return {"ok": false, "reason": "car_not_active"}
	var origin: String = str(command.source)
	var mode: String = str(command.type)
	if origin == "AI" and str(car.pit_order_source) == "Manual" and int(car.pit_requested_lap) > 0 and mode in ["schedule_pit", "order_pit", "cancel_pit"]:
		return {"ok": false, "reason": "manual_order_protected"}
	match mode:
		"set_pace":
			car.pace = str(command.pace) # Metadata only; v1.0 has no tire/driver physics.
			return {"ok": true, "reason": "pace_metadata_only"}
		"schedule_pit", "order_pit":
			if str(car.pit_stage) != "TRACK":
				return {"ok": false, "reason": "pit_entry_already_reached"}
			if int(car.pit_requested_lap) > 0:
				return {"ok": false, "reason": "existing_plan_cancel_first"}
			var progress: int = maxi(0, int(car.progress_units))
			var current_lap: int = int(progress / LAP_UNITS) + 1
			var earliest: int = current_lap + (1 if progress % LAP_UNITS >= PIT_ENTRY_UNITS else 0)
			var requested: int = int(command.requested_lap) if mode == "schedule_pit" else earliest
			if requested < earliest or requested >= int(state.race_laps):
				return {"ok": false, "reason": "requested_lap_elapsed"}
			if not bool(command.allow_double_stack):
				for other in state.cars:
					if int(other.id) != int(car.id) and str(other.team) == str(car.team) and int(other.pit_requested_lap) == requested:
						return {"ok": false, "reason": "team_pit_window_conflict"}
			car.pit_requested_lap = requested
			car.pit_order_source = origin
			car.pit_target = str(command.compound)
			_event("pit_order_registered", int(car.id), {"requested_lap": requested, "source": origin})
			return {"ok": true, "reason": "plan_registered"}
		"cancel_pit":
			if int(car.pit_requested_lap) <= 0:
				return {"ok": false, "reason": "nothing_to_cancel"}
			var old_lap: int = int(car.pit_requested_lap)
			car.pit_requested_lap = 0
			car.pit_order_source = ""
			car.pit_target = ""
			_event("pit_plan_cancelled", int(car.id), {"requested_lap": old_lap, "source": origin})
			return {"ok": true, "reason": "cancelled"}
	return {"ok": false, "reason": "unhandled_intent"}

func step_tick() -> bool:
	if not initialized or bool(state.finished) or int(state.tick) >= MAX_TICKS:
		return false
	state.tick = int(state.tick) + 1
	# Queue resolves once per tick, strictly before motion. No wall-clock reads.
	for command in queue.due(int(state.tick)):
		var result: Dictionary = _apply_command(command)
		queue.settle(int(command.id), bool(result.ok), str(result.reason))
		_event("command_applied" if bool(result.ok) else "command_rejected", int(command.car_id), {"command_id": int(command.id), "reason": str(result.reason)})
	state.clock_ms = int(state.clock_ms) + STEP_MS
	var all_finished: bool = true
	# Cars are advanced in stable id order, not in rendering/classification order.
	for car in state.cars:
		if bool(car.finished):
			continue
		var previous: int = int(car.progress_units)
		var numerator: int = STEP_MS * LAP_UNITS + int(car.progress_remainder)
		var divisor: int = int(car.reference_lap_ms)
		car.progress_units = mini(int(state.race_laps) * LAP_UNITS, previous + int(numerator / divisor))
		car.progress_remainder = numerator % divisor
		var old_laps: int = maxi(0, int(previous / LAP_UNITS))
		car.laps_done = maxi(0, int(int(car.progress_units) / LAP_UNITS))
		if int(car.laps_done) > old_laps:
			_event("lap_crossed", int(car.id), {"laps_done": int(car.laps_done)})
		var request_lap: int = int(car.pit_requested_lap)
		if request_lap > 0 and str(car.pit_stage) == "TRACK":
			var entry: int = (request_lap - 1) * LAP_UNITS + PIT_ENTRY_UNITS
			if previous < entry and int(car.progress_units) >= entry:
				car.pit_stage = "ENTRY_OBSERVED" # No service/exit physics in v1.0.
				car.pit_entry_tick = int(state.tick)
				_event("pit_entry_boundary", int(car.id), {"requested_lap": request_lap, "compound": str(car.pit_target)})
		if int(car.progress_units) >= int(state.race_laps) * LAP_UNITS:
			car.finished = true
			_event("car_finished", int(car.id))
		else:
			all_finished = false
	if all_finished:
		state.finished = true
		_event("race_finished", -1)
	return true

func step_ticks(count: int) -> int:
	var done: int = 0
	for i in range(maxi(0, count)):
		if not step_tick():
			break
		done += 1
	return done

static func canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		var entries: Array = []
		for key in keys:
			entries.append([key, canonical(value[key])])
		return ["dict", entries]
	if value is Array:
		var entries: Array = []
		for item in value:
			entries.append(canonical(item))
		return ["array", entries]
	return value

func sporting_hash() -> String:
	if not initialized:
		return ""
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(canonical({"state": state, "queue": queue.export_state()})))
	return ctx.finish().hex_encode()

func checkpoint() -> Dictionary:
	if not initialized:
		return {}
	return {"schema": SCHEMA, "state": snapshot(), "queue": queue.export_state(), "hash": sporting_hash()}

func restore(data: Dictionary) -> bool:
	if int(data.get("schema", -1)) != SCHEMA or not data.get("state", null) is Dictionary or not data.get("queue", null) is Dictionary:
		return false
	var candidate: Dictionary = data.state.duplicate(true)
	if not candidate.has_all(["schema", "seed", "tick", "clock_ms", "cars", "race_laps", "compounds", "events", "event_serial", "finished"]):
		return false
	if int(candidate.schema) != SCHEMA or int(candidate.tick) < 0 or int(candidate.tick) > MAX_TICKS or int(candidate.clock_ms) != int(candidate.tick) * STEP_MS or int(candidate.race_laps) <= 1:
		return false
	if not candidate.cars is Array or candidate.cars.is_empty() or candidate.cars.size() > 30 or not candidate.events is Array or not candidate.compounds is Array:
		return false
	var ids: Dictionary = {}
	for car in candidate.cars:
		if not car is Dictionary or not car.has_all(["id", "progress_units", "progress_remainder", "reference_lap_ms", "pit_requested_lap", "pit_stage", "team", "finished", "laps_done"]):
			return false
		if typeof(car.id) != TYPE_INT or ids.has(car.id) or int(car.reference_lap_ms) <= 0 or int(car.progress_remainder) < 0 or int(car.progress_remainder) >= int(car.reference_lap_ms):
			return false
		if int(car.progress_units) < -1000000 or int(car.progress_units) > int(candidate.race_laps) * LAP_UNITS:
			return false
		if int(car.laps_done) != maxi(0, int(int(car.progress_units) / LAP_UNITS)):
			return false
		if int(car.pit_requested_lap) < 0 or int(car.pit_requested_lap) > int(candidate.race_laps):
			return false
		ids[car.id] = true
	var last_event_id: int = 0
	for ev in candidate.events:
		if not ev is Dictionary or not ev.has_all(["id", "tick", "type", "car_id"]):
			return false
		if typeof(ev.id) != TYPE_INT or int(ev.id) <= last_event_id or int(ev.tick) > int(candidate.tick):
			return false
		last_event_id = int(ev.id)
	if int(candidate.event_serial) != last_event_id:
		return false
	var candidate_queue = CommandQueue.new()
	if not candidate_queue.restore_state(data.queue):
		return false
	for record in candidate_queue.records:
		if str(record.status) == "PENDING" and int(record.at_tick) <= int(candidate.tick):
			return false
	var probe = get_script().new()
	probe.state = candidate
	probe.queue = candidate_queue
	probe.initialized = true
	if str(data.get("hash", "")) != probe.sporting_hash():
		return false
	# Transactional commit: no mutation of current state before successful validation.
	state = candidate
	queue = candidate_queue
	initialized = true
	return true
