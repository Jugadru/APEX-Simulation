extends SceneTree
## 02: compare extracted HUD metric formatting against its original implementation.
const Hud = preload("res://scripts/apex_race_hud_0622.gd")
const Metric = preload("res://scripts/presentation/apex_hud_standings_metric.gd")

class FakeRace:
	extends RefCounted
	var finished: bool = false
	func tyre_code(tire: String) -> String:
		return {"Médio": "M", "Macio": "S", "Duro": "H"}.get(tire, tire.left(1))

class FakeHost:
	extends RefCounted
	var race = FakeRace.new()
	func _format_lap(t: float) -> String:
		return "L%.3f" % t

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	printerr("HUD_METRIC_REFACTOR_FAIL " + reason)
	quit(1)

func _old_value(sorted_cars: Array, idx: int, metric_index: int, final: bool, host) -> String:
	var car: Dictionary = sorted_cars[idx]
	match metric_index:
		0: return "—" if idx == 0 else (str(car.get("interval_label", "")) if final else "+%.2fs" % float(car.get("interval", 0.0)))
		1: return "—" if idx == 0 else (str(car.get("gap_label", "")) if final else "+%.2fs" % float(car.get("gap", 0.0)))
		2: return str(int(car.get("stops", 0)))
		3: return host._format_lap(float(car.get("best_lap", 9999.0)))
		4: return "%s %d" % [str(host.race.tyre_code(str(car.get("tire", "Médio")))), int(car.get("stint_laps", 0))]
		5:
			if idx >= sorted_cars.size() - 1:
				return "—"
			var behind: Dictionary = sorted_cars[idx + 1]
			return str(behind.get("interval_label", "")) if final else "+%.2fs" % float(behind.get("interval", 0.0))
		6:
			var last_time: float = float(car.get("last_lap", 0.0))
			return host._format_lap(last_time) if last_time > 0.0 and last_time < 9999.0 else "—"
	return "—"

func _run() -> void:
	var host = FakeHost.new()
	var hud = Hud.new()
	hud.host = host
	var rows: Array = [
		{"name":"A", "interval":0.0, "interval_label":"—", "gap":0.0,
		 "gap_label":"LÍDER", "stops":0, "best_lap":82.495,
		 "tire":"Médio", "stint_laps":3, "last_lap":0.0},
		{"name":"B", "interval":1.2345, "interval_label":"+1 volta", "gap":4.8765,
		 "gap_label":"+4.9s", "stops":2, "best_lap":85.201,
		 "tire":"Macio", "stint_laps":12, "last_lap":85.901},
		{"name":"C", "interval":0.1122, "interval_label":"DNF", "gap":120.01,
		 "gap_label":"DNF", "stops":1, "best_lap":9999.0,
		 "tire":"Duro", "stint_laps":0, "last_lap":9999.0}
	]
	var original: PackedByteArray = var_to_bytes(rows)
	for completed in [false, true]:
		host.race.finished = completed
		for metric in range(8):
			hud.metric_index = metric
			for i in range(rows.size()):
				var expected: String = _old_value(rows, i, metric, completed, host)
				var actual: String = hud._standing_value(rows, i)
				var direct: String = Metric.value(rows, i, metric, completed,
					Callable(hud, "_compound"), Callable(host, "_format_lap"))
				if actual != expected or direct != expected:
					hud.free()
					_fail("metric %d row %d finished=%s: '%s' != '%s'" % [
						metric, i, completed, actual, expected])
					return
	if var_to_bytes(rows) != original:
		hud.free()
		_fail("Presenting metrics changed input car state")
		return
	hud.free()
	print("HUD_METRIC_REFACTOR_PASS")
	quit(0)
