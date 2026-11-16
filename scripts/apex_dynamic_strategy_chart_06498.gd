extends Control
## v0.6.4.9.8: graph and twin timelines consume read-only snapshots.
## No random values; forecast uses race advice or recent observed wear deltas.
const ORANGE := Color("#fa9134")
const REAL := Color("#53d5c8")
const FUTURE := Color("#f2ca78")
const WHITE := Color("#eff3f6")
const MUTED := Color("#a7b5c2")
const GRID := Color("#30404d")
var data: Dictionary = {}

func set_snapshot(value: Dictionary) -> void:
	data = value.duplicate(true)
	queue_redraw()

func _point(lap: float, wear: float, origin: Vector2, dimensions: Vector2, total: int) -> Vector2:
	return Vector2(origin.x + dimensions.x * lap / float(total), origin.y + dimensions.y * (1.0 - clampf(wear, 0.0, 100.0) / 100.0))

func _compound_color(tire: String) -> Color:
	match tire:
		"Supermacio": return Color("#e86b70")
		"Macio": return Color("#e5bb49")
		"Médio": return Color("#e8edf2")
		"Duro": return Color("#a8b6c5")
		"Intermediário": return Color("#55c19b")
		"Chuva": return Color("#609ce5")
	return MUTED

func _draw() -> void:
	if data.is_empty() or size.x < 150.0 or size.y < 155.0:
		return
	var total: int = maxi(1, int(data.get("total", 1)))
	var font: Font = ThemeDB.fallback_font
	var start: Vector2 = Vector2(38.0, 15.0)
	var dimensions: Vector2 = Vector2(maxf(70.0, size.x - 52.0), maxf(55.0, size.y - 115.0))
	draw_rect(Rect2(start, dimensions), Color("#101821"), true)
	for value in [0, 25, 50, 75, 100]:
		var y: float = _point(0.0, float(value), start, dimensions, total).y
		draw_line(Vector2(start.x, y), Vector2(start.x + dimensions.x, y), GRID, 1.0)
		draw_string(font, Vector2(4.0, y + 4.0), str(value), HORIZONTAL_ALIGNMENT_LEFT, 28.0, 10, MUTED)
	for tick in range(5):
		var value: int = int(round(float(total) * float(tick) / 4.0))
		var xx: float = _point(float(value), 0.0, start, dimensions, total).x
		draw_string(font, Vector2(xx - 13.0, start.y + dimensions.y + 14.0), "V%d" % value,
			HORIZONTAL_ALIGNMENT_LEFT, 45.0, 10, MUTED)
	# A plotted baseline is a saved *pre-race* estimate, never live measurements.
	var baseline: Dictionary = data.get("baseline", {})
	if bool(baseline.get("valid", false)):
		for stint in baseline.get("stints", []):
			var begin: int = int(stint.get("from", 1)) - 1
			var finish: int = int(stint.get("to", 0))
			var end_wear: float = float(stint.get("wear_end", 0.0))
			if finish > begin:
				draw_dashed_line(_point(float(begin), 0.0, start, dimensions, total),
					_point(float(finish), end_wear, start, dimensions, total),
					_compound_color(str(stint.get("compound", ""))).darkened(0.35), 1.4, 6.0)
	# Explicit race-engine advisory window (often an exact lap, not a fabricated band).
	var ws: int = int(data.get("window_start", 0))
	var we: int = int(data.get("window_end", 0))
	if ws > 0:
		var wx: float = _point(float(ws), 0.0, start, dimensions, total).x
		var ex: float = _point(float(maxi(ws, we)), 0.0, start, dimensions, total).x
		if ex - wx >= 2.0:
			draw_rect(Rect2(wx, start.y, ex-wx, dimensions.y), Color(1.0, 0.54, 0.15, 0.12), true)
		draw_dashed_line(Vector2(wx, start.y), Vector2(wx, start.y + dimensions.y), ORANGE, 1.4, 4.0)
	# Confirmed bookings are visually different from advisory windows.
	var booked: int = int(data.get("scheduled", 0))
	if booked > 0:
		var bx: float = _point(float(booked), 0.0, start, dimensions, total).x
		draw_line(Vector2(bx, start.y), Vector2(bx, start.y + dimensions.y), Color("#ff5d78"), 2.0)
	for stop in data.get("pits", []):
		var px: float = _point(float(stop.get("lap", 0)), 0.0, start, dimensions, total).x
		draw_line(Vector2(px, start.y), Vector2(px, start.y + dimensions.y), Color("#b0c0cf", 0.5), 1.0)
	# Measured lap-to-lap paths. Discontinuities at pit and missing samples remain visible.
	var points: Array = data.get("history", [])
	for i in range(points.size()):
		var b: Dictionary = points[i]
		var pb: Vector2 = _point(float(b["lap"]), float(b["wear"]), start, dimensions, total)
		if i > 0:
			var a: Dictionary = points[i-1]
			if int(a["stops"]) == int(b["stops"]) and str(a["tire"]) == str(b["tire"]) and int(b["lap"]) == int(a["lap"]) + 1:
				draw_line(_point(float(a["lap"]), float(a["wear"]), start, dimensions, total), pb, REAL, 2.8, true)
		draw_circle(pb, 2.6, REAL)
	var forecast: Array = data.get("forecast", [])
	for i in range(1, forecast.size()):
		var a: Dictionary = forecast[i-1]
		var b: Dictionary = forecast[i]
		draw_dashed_line(_point(float(a["lap"]), float(a["wear"]), start, dimensions, total),
			_point(float(b["lap"]), float(b["wear"]), start, dimensions, total), FUTURE, 2.0, 5.0)
	# Two strategy lanes: original projected stop laps vs real service/booked/current advice.
	var lane_y: float = start.y + dimensions.y + 27.0
	for index in range(2):
		var yy: float = lane_y + float(index) * 24.0
		draw_rect(Rect2(start.x, yy, dimensions.x, 9.0), Color("#263744"), true)
		var caption: String = "INI" if index == 0 else "ATUAL"
		draw_string(font, Vector2(2.0, yy + 9.0), caption, HORIZONTAL_ALIGNMENT_LEFT, 36.0, 9, MUTED)
	if bool(baseline.get("valid", false)):
		for stint in baseline.get("stints", []):
			var a: float = _point(float(int(stint.get("from", 1))-1), 0.0, start, dimensions, total).x
			var b: float = _point(float(int(stint.get("to", 0))), 0.0, start, dimensions, total).x
			draw_rect(Rect2(a, lane_y, maxf(0.0, b-a), 9.0), _compound_color(str(stint.get("compound", ""))).darkened(0.23), true)
	var cursor: float = start.x
	var actual_tire: String = str(baseline.get("start", data.get("tire", "")))
	for stop in data.get("pits", []):
		var sx: float = _point(float(stop.get("lap", 0)), 0.0, start, dimensions, total).x
		draw_rect(Rect2(cursor, lane_y + 24.0, maxf(0.0, sx-cursor), 9.0), _compound_color(actual_tire), true)
		actual_tire = str(stop.get("new_tire", ""))
		cursor = sx
	var current_x: float = _point(float(int(data.get("lap", 0))), 0.0, start, dimensions, total).x
	draw_rect(Rect2(cursor, lane_y + 24.0, maxf(0.0, current_x-cursor), 9.0), _compound_color(actual_tire), true)
	if booked > 0:
		var bookx: float = _point(float(booked), 0.0, start, dimensions, total).x
		draw_rect(Rect2(bookx-2.0, lane_y + 21.0, 4.0, 15.0), Color("#ff5d78"), true)
	elif ws > 0:
		var recx: float = _point(float(ws), 0.0, start, dimensions, total).x
		draw_rect(Rect2(recx-2.0, lane_y + 21.0, 4.0, 15.0), ORANGE, true)
	if not bool(baseline.get("valid", false)):
		draw_string(font, Vector2(start.x+5.0, lane_y+9.0), "SEM PLANO SECO NA LARGADA", HORIZONTAL_ALIGNMENT_LEFT,-1,10,MUTED)
