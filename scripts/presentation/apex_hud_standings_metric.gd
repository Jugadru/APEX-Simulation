extends RefCounted
## Pure textual metric presenter for APEX Race HUD (refactor 02).
## No node, mutable race, AI, physics, or replay dependency.
## The HUD passes its existing tyre/lap formatting callables.

static func value(sorted_cars: Array, idx: int, metric_index: int, final: bool,
		compound: Callable, format_lap: Callable) -> String:
	var car: Dictionary = sorted_cars[idx]
	match metric_index:
		0: return "—" if idx == 0 else (str(car.get("interval_label", "")) if final else "+%.2fs" % float(car.get("interval", 0.0)))
		1: return "—" if idx == 0 else (str(car.get("gap_label", "")) if final else "+%.2fs" % float(car.get("gap", 0.0)))
		2: return str(int(car.get("stops", 0)))
		3: return format_lap.call(float(car.get("best_lap", 9999.0)))
		4: return "%s %d" % [compound.call(str(car.get("tire", "Médio"))), int(car.get("stint_laps", 0))]
		5:
			if idx >= sorted_cars.size() - 1:
				return "—"
			var behind: Dictionary = sorted_cars[idx + 1]
			return str(behind.get("interval_label", "")) if final else "+%.2fs" % float(behind.get("interval", 0.0))
		6:
			var last_time: float = float(car.get("last_lap", 0.0))
			return format_lap.call(last_time) if last_time > 0.0 and last_time < 9999.0 else "—"
	return "—"
