extends RefCounted
## APEX 2 Next Engine 1.0 experimental: deterministic intent ledger.
## This object never mutates sporting state. The kernel alone applies validated intents.
const SCHEMA: int = 1
const METHODS: Array[String] = ["schedule_pit", "order_pit", "cancel_pit", "set_pace"]
const PACES: Array[String] = ["Conservar", "Normal", "Atacar"]
const SOURCES: Array[String] = ["Manual", "AI"]
const MAX_COMMANDS: int = 4096

var sequence: int = 0
var records: Array[Dictionary] = []

func _find_car(state: Dictionary, car_id: int) -> Dictionary:
	for entry in state.get("cars", []):
		if int(entry.get("id", -1)) == car_id:
			return entry
	return {}

func _current_lap(car: Dictionary) -> int:
	var progress: int = maxi(0, int(car.get("progress_units", 0)))
	return int(progress / 1000000) + 1

func _earliest_pit_lap(car: Dictionary) -> int:
	var p: int = maxi(0, int(car.get("progress_units", 0)))
	var current: int = int(p / 1000000) + 1
	return current + 1 if p % 1000000 >= 950000 else current

func _manual_protection(car_id: int, state: Dictionary) -> bool:
	var car: Dictionary = _find_car(state, car_id)
	if car.is_empty():
		return false
	if str(car.get("pit_order_source", "")) == "Manual" and int(car.get("pit_requested_lap", 0)) > 0:
		return true
	for r in records:
		if str(r.get("status", "")) == "PENDING" and str(r.get("source", "")) == "Manual" and int(r.get("car_id", -1)) == car_id and str(r.get("type", "")) in ["schedule_pit", "order_pit"]:
			return true
	return false

func _pending_conflict(car_id: int, mode: String) -> bool:
	for r in records:
		if str(r.get("status", "")) != "PENDING" or int(r.get("car_id", -1)) != car_id:
			continue
		if str(r.get("type", "")) == mode:
			return true
	return false

func submit(command: Dictionary, state: Dictionary) -> Dictionary:
	## Always submit for a future tick; never execute at submission time.
	var mode: String = str(command.get("type", ""))
	var source: String = str(command.get("source", ""))
	var id: int = int(command.get("car_id", -1))
	var car: Dictionary = _find_car(state, id)
	var target_tick: int = int(command.get("at_tick", int(state.get("tick", 0)) + 1))
	if typeof(command.get("car_id", null)) != TYPE_INT or typeof(command.get("type", null)) != TYPE_STRING or typeof(command.get("source", null)) != TYPE_STRING:
		return {"accepted": false, "reason": "invalid_command_types"}
	if command.has("at_tick") and typeof(command.at_tick) != TYPE_INT:
		return {"accepted": false, "reason": "invalid_tick_type"}
	if mode in ["schedule_pit", "order_pit"] and typeof(command.get("compound", null)) != TYPE_STRING:
		return {"accepted": false, "reason": "invalid_compound_type"}
	if mode == "schedule_pit" and typeof(command.get("requested_lap", null)) != TYPE_INT:
		return {"accepted": false, "reason": "invalid_lap_type"}
	if command.has("allow_double_stack") and typeof(command.allow_double_stack) != TYPE_BOOL:
		return {"accepted": false, "reason": "invalid_double_stack_flag"}
	if records.size() >= MAX_COMMANDS:
		return {"accepted": false, "reason": "queue_capacity"}
	if not METHODS.has(mode) or not SOURCES.has(source) or car.is_empty():
		return {"accepted": false, "reason": "method_source_or_car_invalid"}
	if bool(car.get("finished", false)):
		return {"accepted": false, "reason": "car_finished"}
	if target_tick <= int(state.get("tick", 0)) or target_tick > 400000:
		return {"accepted": false, "reason": "invalid_tick"}
	if mode in ["schedule_pit", "order_pit", "cancel_pit"]:
		if source == "AI" and _manual_protection(id, state):
			return {"accepted": false, "reason": "manual_order_protected"}
		if _pending_conflict(id, mode):
			return {"accepted": false, "reason": "duplicate_pending"}
	if mode in ["schedule_pit", "order_pit"]:
		if not (str(command.get("compound", "")) in state.get("compounds", [])):
			return {"accepted": false, "reason": "compound_not_nominated"}
		if str(car.get("pit_stage", "")) != "TRACK":
			return {"accepted": false, "reason": "car_not_on_track"}
		if int(car.get("pit_requested_lap", 0)) > 0 and str(car.get("pit_order_source", "")) == "Manual":
			return {"accepted": false, "reason": "manual_order_exists_cancel_first"}
	if mode == "schedule_pit":
		var lap: int = int(command.get("requested_lap", -1))
		if lap < _earliest_pit_lap(car) or lap >= int(state.get("race_laps", 0)):
			return {"accepted": false, "reason": "lap_out_of_pit_window"}
		if lap > 0 and not bool(command.get("allow_double_stack", false)):
			for other in state.get("cars", []):
				if int(other.get("id", -1)) != id and str(other.get("team", "")) == str(car.get("team", "")) and int(other.get("pit_requested_lap", 0)) == lap:
					return {"accepted": false, "reason": "team_pit_window_conflict"}
			for existing in records:
				if str(existing.get("status", "")) == "PENDING" and str(existing.get("type", "")) == "schedule_pit" and str(existing.get("team", "")) == str(car.get("team", "")) and int(existing.get("requested_lap", -1)) == lap and int(existing.get("car_id", -1)) != id:
					return {"accepted": false, "reason": "pending_team_pit_window_conflict"}
	if mode == "cancel_pit":
		if int(car.get("pit_requested_lap", 0)) <= 0 and not _pending_conflict(id, "schedule_pit"):
			return {"accepted": false, "reason": "nothing_to_cancel"}
		if source == "AI" and str(car.get("pit_order_source", "")) == "Manual":
			return {"accepted": false, "reason": "manual_order_protected"}
	if mode == "set_pace" and str(command.get("pace", "")) not in PACES:
		return {"accepted": false, "reason": "invalid_pace"}
	sequence += 1
	var entry: Dictionary = {"id": sequence, "type": mode, "source": source, "car_id": id, "team": str(car.get("team", "")), "at_tick": target_tick, "created_tick": int(state.get("tick", 0)), "status": "PENDING", "reason": "", "requested_lap": int(command.get("requested_lap", 0)), "compound": str(command.get("compound", "")), "pace": str(command.get("pace", "")), "allow_double_stack": bool(command.get("allow_double_stack", false))}
	records.append(entry)
	return {"accepted": true, "id": sequence, "reason": "pending"}

func due(tick: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for r in records:
		if str(r.status) == "PENDING" and int(r.at_tick) <= tick:
			list.append(r.duplicate(true))
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.at_tick) != int(b.at_tick): return int(a.at_tick) < int(b.at_tick)
		if str(a.source) != str(b.source): return str(a.source) == "Manual"
		return int(a.id) < int(b.id))
	return list

func settle(id: int, accepted: bool, reason: String) -> void:
	for i in range(records.size()):
		if int(records[i].id) == id and str(records[i].status) == "PENDING":
			records[i].status = "APPLIED" if accepted else "REJECTED"
			records[i].reason = reason
			return

func export_state() -> Dictionary:
	return {"schema": SCHEMA, "sequence": sequence, "records": records.duplicate(true)}

func restore_state(data: Dictionary) -> bool:
	if int(data.get("schema", -1)) != SCHEMA or not data.get("records", null) is Array:
		return false
	var incoming: Array = data.records
	if incoming.size() > MAX_COMMANDS or int(data.get("sequence", -1)) < 0:
		return false
	var seen: Dictionary = {}
	var last_id: int = 0
	for item in incoming:
		if not item is Dictionary or not item.has_all(["id", "at_tick", "source", "type", "car_id", "status", "reason", "requested_lap", "compound", "pace", "team", "created_tick", "allow_double_stack"]):
			return false
		if typeof(item.id) != TYPE_INT or int(item.id) <= 0 or int(item.id) > int(data.sequence) or seen.has(item.id):
			return false
		if str(item.status) not in ["PENDING", "APPLIED", "REJECTED"] or str(item.source) not in SOURCES or str(item.type) not in METHODS:
			return false
		if typeof(item.at_tick) != TYPE_INT or typeof(item.created_tick) != TYPE_INT or typeof(item.car_id) != TYPE_INT:
			return false
		if int(item.at_tick) <= int(item.created_tick) or int(item.created_tick) < 0 or int(item.id) <= last_id:
			return false
		last_id = int(item.id)
		seen[item.id] = true
	sequence = int(data.sequence)
	records.clear()
	for item in incoming:
		records.append(item.duplicate(true))
	return true
