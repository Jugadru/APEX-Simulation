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
	for car in race.cars:
		by_id[int(car.get("id", -1))] = car
	var condition: String = _bucket(race)
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
	for car in race.cars:
		var id: int = int(car.get("id", -1))
		var state: String = str(car.get("combat_state", "clear"))
		var prior: String = str(previous_states.get(id, "clear"))
		if state == "closing" and prior != "closing": _increment("approaches", car, condition)
		if state == "duel" and prior != "duel": _increment("duel_entries", car, condition)
		if bool(car.get("race_space_blocked", false)) and float(car.get("pit_left", 0.0)) <= 0.0 and not bool(car.get("finished", false)):
			_increment("blocked_ticks", car, condition)
		previous_states[id] = state
	last_tick = tick

func summary() -> Dictionary:
	return {"schema": "APEX_RACECRAFT_AUDIT_0662", "track_code": track_code,
		"start_tick": start_tick, "end_tick": last_tick,
		"coverage": "from_start" if start_tick == 0 else "since_checkpoint",
		"counts": counts.duplicate(true), "drivers": per_driver.duplicate(true),
		"weather_and_risk": per_condition.duplicate(true),
		"sample_count": recent_samples.size(), "samples": recent_samples.duplicate(true),
		"note": "Signals only. Position gains outside combat are not overtakes; blocked_ticks are 0.2s observations. No FIA calibration."}
