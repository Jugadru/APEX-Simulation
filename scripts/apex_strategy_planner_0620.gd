extends Control
## Read-only past and planned stints. Planned means "explicit user order",
## not a prediction or an AI guarantee.

var drivers: Array = []
var pit_history: Array = []
var max_laps: int = 56

func set_race_state(cars: Array, history: Array, total_laps: int) -> void:
	drivers = cars.duplicate(true)
	pit_history = history.duplicate(true)
	max_laps = maxi(1, total_laps)
	queue_redraw()

func _color(compound: String) -> Color:
	match compound:
		"Macio": return Color("#e75f68")
		"Médio": return Color("#eaca66")
		"Duro": return Color("#e2e8f0")
		"Intermediário": return Color("#53c495")
		"Chuva": return Color("#6aa7f8")
	return Color("#a3b6c8")

func _draw() -> void:
	if size.x < 180.0 or size.y < 100.0:
		return
	var font: Font = ThemeDB.fallback_font
	var x_start: float = 155.0
	var x_end: float = maxf(x_start + 40.0, size.x - 14.0)
	var span: float = x_end - x_start
	var bar_h: float = 16.0
	var now_max: int = 0
	for driver in drivers:
		now_max = maxi(now_max, int(driver.get("laps_done", 0)))
	for i in range(mini(2, drivers.size())):
		var driver: Dictionary = drivers[i]
		var row_y: float = 37.0 + float(i) * 58.0
		var label: String = str(driver.get("name", "Piloto"))
		draw_string(font, Vector2(4.0, row_y + 11.0), label, HORIZONTAL_ALIGNMENT_LEFT, x_start - 12.0, 12, Color("#eaf2f8"))
		draw_rect(Rect2(x_start, row_y, span, bar_h), Color("#243447"), true)
		var id: int = int(driver.get("id", -1))
		var cuts: Array = []
		for entry in pit_history:
			if int(entry.get("car_id", -100)) == id:
				cuts.append(entry)
		cuts.sort_custom(func(a, b): return int(a.get("lap", 0)) < int(b.get("lap", 0)))
		var done: int = clampi(int(driver.get("laps_done", 0)), 0, max_laps)
		var from: int = 0
		var current: String = str(driver.get("tire", "Médio"))
		if not cuts.is_empty():
			current = str(cuts[0].get("old_tire", current))
		for entry in cuts:
			var stop: int = clampi(int(entry.get("lap", 0)), from, done)
			_segment(x_start, span, row_y, from, stop, current, 1.0)
			from = stop
			current = str(entry.get("new_tire", current))
		_segment(x_start, span, row_y, from, done, current, 1.0)
		var planned_lap: int = int(driver.get("pit_scheduled_lap", 0))
		if planned_lap > done and planned_lap < max_laps:
			_segment(x_start, span, row_y, done, planned_lap, str(driver.get("tire", current)), 0.35)
			_segment(x_start, span, row_y, planned_lap, max_laps, str(driver.get("pit_target", "Médio")), 0.40)
			var px: float = x_start + span * float(planned_lap) / float(max_laps)
			draw_line(Vector2(px, row_y - 3.0), Vector2(px, row_y + bar_h + 3.0), Color("#ffffff"), 1.6)
			draw_string(font, Vector2(px + 2.0, row_y - 5.0), "BOX V%d" % planned_lap, HORIZONTAL_ALIGNMENT_LEFT, 90.0, 10, Color("#ffffff"))
		else:
			_segment(x_start, span, row_y, done, max_laps, "", 0.0)
		if bool(driver.get("pit_request", false)):
			draw_string(font, Vector2(x_start, row_y + 37.0), "BOX chamado — aguardando entrada", HORIZONTAL_ALIGNMENT_LEFT, span, 10, Color("#ffd16c"))
		elif planned_lap > done:
			draw_string(font, Vector2(x_start, row_y + 37.0), "Agendado V%d • %s" % [planned_lap, str(driver.get("pit_target", ""))], HORIZONTAL_ALIGNMENT_LEFT, span, 10, Color("#a8c4d6"))
		else:
			draw_string(font, Vector2(x_start, row_y + 37.0), "Futuro: sem parada definida", HORIZONTAL_ALIGNMENT_LEFT, span, 10, Color("#a8c4d6"))
	var now_x: float = x_start + span * float(now_max) / float(max_laps)
	draw_line(Vector2(now_x, 22), Vector2(now_x, 148), Color("#48dbbc"), 2.0)
	draw_string(font, Vector2(x_start, 12.0), "V0", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#a3b7c8"))
	draw_string(font, Vector2(x_end - 43, 12.0), "V%d" % max_laps, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#a3b7c8"))
	draw_string(font, Vector2(minf(x_end - 75, now_x + 4), 12.0), "AGORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#48dbbc"))

func _segment(start_x: float, full_span: float, y: float, start_lap: int, end_lap: int, tire: String, opacity: float) -> void:
	var segment_start: float = start_x + full_span * float(start_lap) / float(max_laps)
	var segment_width: float = full_span * float(end_lap - start_lap) / float(max_laps)
	if segment_width <= 0.0:
		return
	if opacity <= 0.0:
		draw_rect(Rect2(segment_start, y, segment_width, 16.0), Color(0.17, 0.22, 0.28, 0.65), true)
		return
	var c: Color = _color(tire)
	c.a = opacity
	draw_rect(Rect2(segment_start, y, segment_width, 16.0), c, true)
