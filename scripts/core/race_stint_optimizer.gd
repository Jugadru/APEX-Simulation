extends RefCounted
## APEX v0.6.2.5 - dry-race whole-distance stint planner, no RNG.
## Uses game balance tyre curves (NOT official lap-time telemetry).
## Decision is advisory; manual schedules are never overwritten.
const Strategy = preload("res://scripts/core/race_strategy.gd")
const Rules = preload("res://scripts/core/race_rules.gd")
const MAX_STOPS: int = 5
const MAX_USABLE_WEAR: float = 96.0
const BIG_COST: float = 1.0e12
# 066723: dry-strategy suffix tables depend only on the *zero-wear* tyre
# prefixes and race horizon, not on the driver's current tyre wear. Keep
# a bounded exact-input cache outside RaceEngine and its replay/sporting state.
const MAX_SHARED_CONTEXTS: int = 28
static var _shared_tail_memos: Dictionary = {}
static var _shared_tail_order: Array[String] = []

static func _shared_memo(ctx: Dictionary) -> Dictionary:
	# byte-exact identity; no rounded floats and no approximate weather keys.
	# The first-stint prefix (which DOES depend on current wear) is deliberately
	# omitted: it is computed afresh for every call to optimize().
	var key: String = var_to_bytes([ctx["names"], ctx["prefixes"],
		ctx["required_mask"],ctx["start_lap"],ctx["remaining"],ctx["pit_loss"]]).hex_encode()
	if _shared_tail_memos.has(key):
		_shared_tail_order.erase(key)
		_shared_tail_order.append(key)
		return _shared_tail_memos[key]
	var table: Dictionary = {}
	_shared_tail_memos[key] = table
	_shared_tail_order.append(key)
	while _shared_tail_order.size() > MAX_SHARED_CONTEXTS:
		var gone: String = _shared_tail_order.pop_front()
		_shared_tail_memos.erase(gone)
	return table

static func _penalty(wear: float, cliff: float) -> float:
	return 0.11 * pow(wear / 35.0, 1.55) + 0.06 * pow(maxf(0.0, wear - cliff), 1.60)

static func _prefix(name: String, spec: Dictionary, initial_wear: float, remaining: int, rate: float) -> Array:
	var result: Array = [0.0]
	var total: float = 0.0
	for n in range(1, remaining + 1):
		var wear: float = initial_wear + float(n) * rate
		if wear > MAX_USABLE_WEAR:
			result.append(BIG_COST)
			continue
		total += float(spec.get("delta", 0.0)) + _penalty(wear, float(spec.get("cliff", 75.0)))
		result.append(total)
	return result

static func _tail(position: int, tyre_idx: int, mask: int, stops_done: int,
		ctx: Dictionary, memo: Dictionary) -> Dictionary:
	var key: int = (((position * 2 + tyre_idx) * 4 + mask) * (MAX_STOPS + 1) + stops_done)
	if memo.has(key):
		return memo[key]
	var remaining: int = int(ctx["remaining"]) - position
	var names: Array = ctx["names"]
	var name: String = str(names[tyre_idx])
	var prefixes: Dictionary = ctx["prefixes"]
	var prefix: Array = prefixes[name]
	var total_mask: int = int(ctx["required_mask"])
	var best: Dictionary = {"cost": BIG_COST, "stops": []}
	if remaining >= 0 and (mask & total_mask) == total_mask and float(prefix[remaining]) < BIG_COST:
		best = {"cost": float(prefix[remaining]), "stops": []}
	if stops_done >= MAX_STOPS:
		memo[key] = best
		return best
	# Candidate segments include only stint lengths which do not consume a tyre
	# beyond the modelled safe wear limit. One-lap changes are possible only when
	# needed, but the full pit-loss cost makes needless stops unattractive.
	for duration in range(1, remaining):
		var segment_cost: float = float(prefix[duration])
		if segment_cost >= BIG_COST:
			break
		for next_idx in range(names.size()):
			var next_mask: int = mask | (1 << next_idx)
			var next_result: Dictionary = _tail(position + duration, next_idx, next_mask,
				stops_done + 1, ctx, memo)
			var candidate: float = segment_cost + float(ctx["pit_loss"]) + float(next_result["cost"])
			if candidate < float(best["cost"]) - 0.00001:
				var sequence: Array = [{"lap": int(ctx["start_lap"]) + position + duration,
					"compound": str(names[next_idx])}]
				sequence.append_array(next_result["stops"])
				best = {"cost": candidate, "stops": sequence}
	memo[key] = best
	return best

static func optimize(car: Dictionary, race_laps: int, nominated: Array,
		specs: Dictionary, pit_loss: float) -> Dictionary:
	var names: Array = []
	for item in nominated:
		var compound: String = str(item)
		if compound not in ["Intermediário", "Chuva"] and specs.has(compound) and not names.has(compound):
			names.append(compound)
	if names.size() != 2:
		return {"valid": false}
	var current: String = str(car.get("tire", ""))
	if not names.has(current):
		return {"valid": false}
	var start_lap: int = maxi(0, int(car.get("laps_done", 0)))
	var remaining: int = race_laps - start_lap
	if remaining <= 0:
		return {"valid": false}
	var pace: Dictionary = Rules.PACES.get(str(car.get("pace", "Normal")), Rules.PACES["Normal"])
	var multiplier: float = float(pace["wear"]) * maxf(0.7, float(car.get("track_wear_factor", 1.0)))
	var prefixes: Dictionary = {}
	for item in names:
		var compound: String = str(item)
		var spec: Dictionary = specs[compound]
		var rate: float = Strategy._wear_per_lap(compound, spec, 0.0, multiplier, 1.0)
		prefixes[compound] = _prefix(compound, spec, 0.0, remaining, rate)
	var current_spec: Dictionary = specs[current]
	var current_rate: float = Strategy._wear_per_lap(current, current_spec, 0.0, multiplier, 1.0)
	var first_prefix: Array = _prefix(current, current_spec,
		clampf(float(car.get("wear", 0.0)), 0.0, 100.0), remaining, current_rate)
	var mask: int = 0
	var used: Array = car.get("used_tires", [current])
	for idx in range(names.size()):
		if used.has(names[idx]) or current == names[idx]:
			mask |= (1 << idx)
	var was_wet: bool = used.has("Intermediário") or used.has("Chuva")
	var required_mask: int = 0 if was_wet else (1 << names.size()) - 1
	var ctx: Dictionary = {"names": names, "prefixes": prefixes, "required_mask": required_mask,
		"start_lap": start_lap, "remaining": remaining, "pit_loss": maxf(1.0, pit_loss)}
	var best: Dictionary = {"cost": BIG_COST, "stops": []}
	if (mask & required_mask) == required_mask and float(first_prefix[remaining]) < BIG_COST:
		best = {"cost": float(first_prefix[remaining]), "stops": []}
	var memo: Dictionary = _shared_memo(ctx)
	for duration in range(1, remaining):
		var first_cost: float = float(first_prefix[duration])
		if first_cost >= BIG_COST:
			break
		for next_idx in range(names.size()):
			var next_mask: int = mask | (1 << next_idx)
			var tail: Dictionary = _tail(duration, next_idx, next_mask, 1, ctx, memo)
			var cost: float = first_cost + maxf(1.0, pit_loss) + float(tail["cost"])
			if cost < float(best["cost"]) - 0.00001:
				var sequence: Array = [{"lap": start_lap + duration, "compound": str(names[next_idx])}]
				sequence.append_array(tail["stops"])
				best = {"cost": cost, "stops": sequence}
	if float(best["cost"]) >= BIG_COST:
		return {"valid": false}
	var chosen: Array = best["stops"]
	var first_stop: Dictionary = chosen[0] if not chosen.is_empty() else {}
	return {"valid": true, "pit_lap": int(first_stop.get("lap", 0)),
		"compound": str(first_stop.get("compound", current)),
		"stops": chosen.duplicate(true), "stop_count": chosen.size(),
		"requires_two_slicks": not was_wet,
		"estimated_cost": float(best["cost"])}
