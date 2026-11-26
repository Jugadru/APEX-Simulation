extends RefCounted
## APEX 0.6.6.2: diagnostic, read-only racecraft observer.
## Not an engine, RNG consumer, replay command, sporting-state field or HUD mutation.
## Counts tactical *signals*; they are not FIA-calibrated events or causal outcomes.
const SAMPLE_LIMIT := 256
const KEYS := ["approaches", "attack_signals", "defense_signals", "yield_signals", "duel_entries", "blocked_ticks", "confirmed_passes", "position_gains_other", "contacts", "driving_errors"]
var start_tick: int = 0
var last_tick: int = 0
var last_event_id: int = 0
var counts: Dictionary = {}
var per_driver: Dictionary = {}
var per_condition: Dictionary = {}
var recent_samples: Array = []
var previous_states: Dictionary = {}
var track_code: String = ""

# 9.23: bounded integrity observations, not sporting decisions or a quality score.
const QUALITY_SAMPLE_LIMIT := 64
const QUALITY_EPSILON := 0.000000001
const QUALITY_KEYS := ["grid_size_changed", "invalid_driver_id", "duplicate_driver_id",
	"invalid_position", "duplicate_position", "nonfinite_state", "tyre_wear_out_of_range",
	"negative_pit_time", "negative_gap", "reverse_on_track"]
const QUALITY_FINITE_FIELDS := ["progress", "race_lane", "wear", "pit_left", "gap", "interval"]
var quality_counts: Dictionary = {}
var quality_samples: Array = []
var quality_previous_progress: Dictionary = {}
var quality_scratch_progress: Dictionary = {}
var quality_observed_ticks: int = 0
var quality_grid_size: int = 0
var quality_seed: int = 0
# Diagnostic only: distinguish pass events from the engine's actual counter,
# and count consecutive observed blocked runs rather than infer lost time.
var behaviour_drivers: Dictionary = {}
var behaviour_previous_passes: Dictionary = {}
var behaviour_compared_ticks: int = 0

func _behaviour_reset(race) -> void:
	behaviour_drivers.clear()
	behaviour_previous_passes.clear()
	behaviour_compared_ticks = 0
	for car in race.cars:
		var id: int = int(car.get("id", -1))
		if id >= 0:
			behaviour_previous_passes[id] = int(car.get("combat_passes", 0))

func _behaviour_observe(car: Dictionary, consecutive: bool) -> void:
	var id: int = int(car.get("id", -1))
	if id < 0: return
	if not behaviour_drivers.has(id):
		behaviour_drivers[id] = {"driver_id":id,"pass_delta":0,"pass_counter_resets":0,
			"blocked_observed_ticks":0,"blocked_segments":0,"longest_blocked_run_ticks":0,"current_blocked_run_ticks":0}
	var row: Dictionary = behaviour_drivers[id]
	var passes: int = int(car.get("combat_passes", 0))
	if consecutive and behaviour_previous_passes.has(id):
		var delta: int = passes - int(behaviour_previous_passes[id])
		if delta >= 0:
			row.pass_delta += delta
		else:
			row.pass_counter_resets += 1
	behaviour_previous_passes[id] = passes
	if bool(car.get("race_space_blocked", false)) and float(car.get("pit_left", 0.0)) <= 0.0 and not bool(car.get("finished", false)) and not bool(car.get("disqualified", false)):
		row.blocked_observed_ticks += 1
		if int(row.current_blocked_run_ticks) == 0:
			row.blocked_segments += 1
		row.current_blocked_run_ticks += 1
		row.longest_blocked_run_ticks = maxi(int(row.longest_blocked_run_ticks), int(row.current_blocked_run_ticks))
	else:
		row.current_blocked_run_ticks = 0

func behaviour_report() -> Dictionary:
	var total: int = 0
	var blocked: int = 0
	var longest: int = 0
	var resets: int = 0
	for row in behaviour_drivers.values():
		total += int(row.pass_delta)
		blocked += int(row.blocked_observed_ticks)
		longest = maxi(longest,int(row.longest_blocked_run_ticks))
		resets += int(row.pass_counter_resets)
	return {"schema":"APEX_RACE_BEHAVIOUR_0923","track_code":track_code,"seed":quality_seed,
		"start_tick":start_tick,"end_tick":last_tick,"observed_ticks":quality_observed_ticks,
		"compared_ticks":behaviour_compared_ticks,"missed_ticks":maxi(0,last_tick-start_tick-quality_observed_ticks),
		"pass_event_signals":int(counts.get("confirmed_passes",0)),"observed_pass_counter_delta":total,
		"pass_counter_resets":resets,"blocked_driver_ticks":blocked,"longest_blocked_run_ticks":longest,
		"drivers":behaviour_drivers.duplicate(true),
		"note":"Counter deltas only between consecutive observations. Blocked runs are observed segments, not unique incidents or causal time loss. Missing ticks break continuity; pit, finished and disqualified cars excluded from blocked runs."}

func behaviour_snapshot() -> Dictionary:
	return {"drivers":behaviour_drivers.duplicate(true),"previous_passes":behaviour_previous_passes.duplicate(),"compared_ticks":behaviour_compared_ticks}

func restore_behaviour_snapshot(state: Dictionary) -> void:
	behaviour_drivers = state.drivers.duplicate(true)
	behaviour_previous_passes = state.previous_passes.duplicate()
	behaviour_compared_ticks = int(state.compared_ticks)

func _quality_reset(race) -> void:
	quality_counts.clear()
	for kind in QUALITY_KEYS:
		quality_counts[kind] = 0
	quality_samples.clear()
	quality_previous_progress.clear()
	quality_scratch_progress.clear()
	quality_observed_ticks = 0
	quality_grid_size = race.cars.size()
	quality_seed = race.rng.seed
	for car in race.cars:
		var progress: float = float(car.get("progress", NAN))
		if is_finite(progress) and float(car.get("pit_left", 0.0)) <= 0.0 and not bool(car.get("finished", false)):
			quality_previous_progress[int(car.get("id", -1))] = progress

func _quality_flag(kind: String, tick: int, id: int, condition: String, field: String, value: String) -> void:
	quality_counts[kind] = int(quality_counts[kind]) + 1
	if quality_samples.size() >= QUALITY_SAMPLE_LIMIT:
		quality_samples.pop_front()
	quality_samples.append({"kind": kind, "tick": tick, "driver_id": id, "condition": condition,
		"field": field, "value": value})

func _quality_observe_car(car: Dictionary, tick: int, condition: String, positions: Dictionary, grid_size: int) -> void:
	var id: int = int(car.get("id", -1))
	var position: int = int(car.get("position", -1))
	if position < 1 or position > grid_size:
		_quality_flag("invalid_position", tick, id, condition, "position", str(position))
	elif positions.has(position):
		_quality_flag("duplicate_position", tick, id, condition, "position", str(position))
	positions[position] = true
	for field in QUALITY_FINITE_FIELDS:
		var value: float = float(car.get(field, NAN))
		if not is_finite(value):
			_quality_flag("nonfinite_state", tick, id, condition, field, str(value))
	var wear: float = float(car.get("wear", NAN))
	if is_finite(wear) and (wear < -QUALITY_EPSILON or wear > 100.0 + QUALITY_EPSILON):
		_quality_flag("tyre_wear_out_of_range", tick, id, condition, "wear", str(wear))
	var pit_left: float = float(car.get("pit_left", NAN))
	if is_finite(pit_left) and pit_left < -QUALITY_EPSILON:
		_quality_flag("negative_pit_time", tick, id, condition, "pit_left", str(pit_left))
	for field in ["gap", "interval"]:
		var gap: float = float(car.get(field, NAN))
		if is_finite(gap) and gap < -QUALITY_EPSILON:
			_quality_flag("negative_gap", tick, id, condition, field, str(gap))
	var progress: float = float(car.get("progress", NAN))
	# Grid positions can start negative; pit entry/exit and finishing are not
	# comparable on-track samples. Never compare across unobserved ticks.
	if is_finite(progress) and is_finite(pit_left) and pit_left <= 0.0 and not bool(car.get("finished", false)):
		if quality_previous_progress.has(id) and not quality_scratch_progress.has(id):
			var prior: float = float(quality_previous_progress[id])
			if progress < prior - QUALITY_EPSILON:
				_quality_flag("reverse_on_track", tick, id, condition, "progress", "%.12f -> %.12f" % [prior, progress])
		quality_scratch_progress[id] = progress

func quality_report() -> Dictionary:
	var missed: int = maxi(0, last_tick - start_tick - quality_observed_ticks)
	return {"schema": "APEX_RACE_QUALITY_0923", "seed": quality_seed, "track_code": track_code,
		"start_tick": start_tick, "end_tick": last_tick, "observed_ticks": quality_observed_ticks,
		"missed_ticks": missed, "coverage": "from_start" if start_tick == 0 and missed == 0 else "partial",
		"grid_size_at_reset": quality_grid_size, "counts": quality_counts.duplicate(true),
		"samples": quality_samples.duplicate(true),
		"note": "Integrity observations only; zero findings do not certify race quality. Pit transitions and finished cars excluded from reverse check."}

# Session-only seek state; never stored in exported archives or sporting hashes.
func quality_snapshot() -> Dictionary:
	return {"counts": quality_counts.duplicate(true), "samples": quality_samples.duplicate(true),
		"previous_progress": quality_previous_progress.duplicate(true), "observed_ticks": quality_observed_ticks,
		"grid_size": quality_grid_size, "seed": quality_seed}

func restore_quality_snapshot(state: Dictionary) -> void:
	quality_counts = state.counts.duplicate(true)
	quality_samples = state.samples.duplicate(true)
	quality_previous_progress = state.previous_progress.duplicate(true)
	quality_scratch_progress.clear()
	quality_observed_ticks = int(state.observed_ticks)
	quality_grid_size = int(state.grid_size)
	quality_seed = int(state.seed)


func empty_counts() -> Dictionary:
	var out: Dictionary = {}
	for key in KEYS:
		out[key] = 0
	return out

func reset(race, from_tick: int = 0) -> void:
	start_tick = from_tick
	last_tick = from_tick
	last_event_id = 0
	# When restoring a nonzero checkpoint, previously emitted events do not
	# belong to the covered interval. Never imply full-race coverage.
	if from_tick > 0:
		for event in race.events:
			last_event_id = maxi(last_event_id, int(event.get("event_id", 0)))
	counts = empty_counts()
	per_driver.clear()
	per_condition.clear()
	recent_samples.clear()
	previous_states.clear()
	track_code = str(race.track.get("code", "unknown"))
	_quality_reset(race)
	_behaviour_reset(race)
	for car in race.cars:
		previous_states[int(car.get("id", -1))] = str(car.get("combat_state", "clear"))

func _risk_group(car: Dictionary) -> String:
	var risk: float = float(car.get("risk_tolerance", 50.0))
	if risk < 40.0: return "cautious"
	if risk >= 70.0: return "aggressive"
	return "balanced"

func _bucket(race) -> String:
	var state: Dictionary = race.weather.state
	if float(state.get("wetness_factor", 0.0)) >= 0.17: return "wet"
	return "dry"

func _increment(kind: String, car: Dictionary, condition: String) -> void:
	if not counts.has(kind): return
	counts[kind] = int(counts[kind]) + 1
	var id: int = int(car.get("id", -1))
	var key: String = str(id)
	if not per_driver.has(key):
		per_driver[key] = {"driver_id": id, "name": str(car.get("name", "unknown")), "risk_group": _risk_group(car), "counts": empty_counts()}
	per_driver[key].counts[kind] = int(per_driver[key].counts[kind]) + 1
	var condition_key: String = condition + "/" + _risk_group(car)
	if not per_condition.has(condition_key): per_condition[condition_key] = empty_counts()
	per_condition[condition_key][kind] = int(per_condition[condition_key][kind]) + 1

func _event_kind(event: Dictionary) -> String:
	match str(event.get("type", "")):
		"pass": return "confirmed_passes"
		"position_gain": return "position_gains_other"
		"contact": return "contacts"
		"incident": return "driving_errors"
		"battle":
			var message: String = str(event.get("message", ""))
			if message.contains("prepara ataque"): return "attack_signals"
			if message.contains("protege a linha"): return "defense_signals"
			if message.contains("retirou o ataque"): return "yield_signals"
	return ""

func observe(race, tick: int) -> void:
	if tick <= last_tick: return
	var by_id: Dictionary = {}
	var condition: String = _bucket(race)
	var grid_size: int = race.cars.size()
	var consecutive: bool = tick == last_tick + 1
	if consecutive:
		behaviour_compared_ticks += 1
	else:
		behaviour_previous_passes.clear()
		for row in behaviour_drivers.values():
			row.current_blocked_run_ticks = 0
		quality_previous_progress.clear()
	quality_scratch_progress.clear()
	quality_observed_ticks += 1
	if grid_size != quality_grid_size:
		_quality_flag("grid_size_changed", tick, -1, condition, "cars", "%d -> %d" % [quality_grid_size, grid_size])
	for car in race.cars:
		var id: int = int(car.get("id", -1))
		if id < 0:
			_quality_flag("invalid_driver_id", tick, id, condition, "id", str(id))
		if by_id.has(id):
			_quality_flag("duplicate_driver_id", tick, id, condition, "id", str(id))
		by_id[id] = car
	# The event ring is chronological. Skip all already-seen events in O(1)
	# on quiet ticks, but still process newly appended events in original order.
	var start: int = race.events.size()
	while start > 0 and int(race.events[start - 1].get("event_id", 0)) > last_event_id:
		start -= 1
	for index in range(start, race.events.size()):
		var event: Dictionary = race.events[index]
		var event_id: int = int(event.get("event_id", 0))
		last_event_id = event_id
		var kind: String = _event_kind(event)
		if kind.is_empty(): continue
		var id: int = int(event.get("driver_id", -1))
		if not by_id.has(id): continue
		_increment(kind, by_id[id], condition)
		if recent_samples.size() == SAMPLE_LIMIT: recent_samples.pop_front()
		recent_samples.append({"tick": tick, "event_id": event_id, "driver_id": id, "type": kind, "condition": condition})
	var positions: Dictionary = {}
	var behaviour_seen: Dictionary = {}
	for car in race.cars:
		_quality_observe_car(car, tick, condition, positions, grid_size)
		var id: int = int(car.get("id", -1))
		if not behaviour_seen.has(id):
			_behaviour_observe(car, consecutive)
			behaviour_seen[id] = true
		var state: String = str(car.get("combat_state", "clear"))
		var prior: String = str(previous_states.get(id, "clear"))
		if state == "closing" and prior != "closing": _increment("approaches", car, condition)
		if state == "duel" and prior != "duel": _increment("duel_entries", car, condition)
		if bool(car.get("race_space_blocked", false)) and float(car.get("pit_left", 0.0)) <= 0.0 and not bool(car.get("finished", false)):
			_increment("blocked_ticks", car, condition)
		previous_states[id] = state
	# A driver absent from a frame cannot contribute a continuous run/delta.
	for id in behaviour_previous_passes.keys():
		if not behaviour_seen.has(id):
			behaviour_previous_passes.erase(id)
			if behaviour_drivers.has(id):
				behaviour_drivers[id].current_blocked_run_ticks = 0
	var previous: Dictionary = quality_previous_progress
	quality_previous_progress = quality_scratch_progress
	quality_scratch_progress = previous
	last_tick = tick

func summary() -> Dictionary:
	return {"schema": "APEX_RACECRAFT_AUDIT_0662", "track_code": track_code,
		"start_tick": start_tick, "end_tick": last_tick,
		"coverage": "from_start" if start_tick == 0 else "since_checkpoint",
		"counts": counts.duplicate(true), "drivers": per_driver.duplicate(true),
		"weather_and_risk": per_condition.duplicate(true),
		"sample_count": recent_samples.size(), "samples": recent_samples.duplicate(true),
		"quality": quality_report(), "behaviour": behaviour_report(),
		"note": "Signals only. Position gains outside combat are not overtakes; blocked_ticks are 0.2s observations. No FIA calibration."}
