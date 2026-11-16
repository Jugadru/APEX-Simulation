extends Control
## Read-only timeline: actual stints from pit history and a faint future area.
## Does not create fake pit-stop orders or claim forecasts of race pace.

var _rows: Array[Dictionary] = []
var _max_laps: int = 44

func update_cars(cars: Array, lap_count: int, history: Array = []) -> void:
	_max_laps = maxi(1, lap_count)
	_rows.clear()
	for car in cars:
		var past: Array[Dictionary] = []
		var initial_compound: String = str(car.get("tire", "Médio"))
		var changes: Array = []
		for item in history:
			if int(item.get("car_id", -999)) == int(car.get("id", -1)):
				changes.append(item)
		changes.sort_custom(func(a, b): return int(a.get("lap", 0)) < int(b.get("lap", 0)))
		if not changes.is_empty():
			initial_compound = str(changes[0].get("old_tire", "Médio"))
		var from_lap: int = 0
		var compound: String = initial_compound
		for change in changes:
			var cut_lap: int = clampi(int(change.get("lap", 0)), from_lap, _max_laps)
			past.append({"start": from_lap, "end": cut_lap, "compound": compound})
			from_lap = cut_lap
			compound = str(change.get("new_tire", "Médio"))
		var reached: int = clampi(int(car.get("laps_done", 0)), from_lap, _max_laps)
		past.append({"start": from_lap, "end": reached, "compound": compound})
		_rows.append({"name": str(car.get("name", "Piloto")), "progress": reached, "tire": str(car.get("tire", compound)), "stints": past})
	queue_redraw()

func _tire_color(compound: String) -> Color:
	match compound:
		"Macio": return Color("#e76e70")
		"Médio": return Color("#f2ce67")
		"Duro": return Color("#e7f1fa")
	return Color("#86b7ce")

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 80.0 or h < 80.0:
		return
	var font: Font = ThemeDB.fallback_font
	var x: float = 10.0
	var right: float = maxf(50.0, w - 10.0)
	var usable: float = right - x
	draw_string(font, Vector2(x, 14.0), "STINTS / PROGRESSO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#77d6c4"))
	for index in range(mini(2, _rows.size())):
		var row: Dictionary = _rows[index]
		var base_y: float = 31.0 + index * 43.0
		var name: String = str(row["name"])
		draw_string(font, Vector2(x, base_y), name, HORIZONTAL_ALIGNMENT_LEFT, w - 25.0, 11, Color("#f0f6fb"))
		var bar_top: float = base_y + 6.0
		draw_rect(Rect2(x, bar_top, usable, 13.0), Color("#294053"))
		for stint in row["stints"]:
			var px: float = x + usable * float(stint["start"]) / float(_max_laps)
			var pw: float = usable * maxf(0.0, float(stint["end"]) - float(stint["start"])) / float(_max_laps)
			if pw > 0.1:
				draw_rect(Rect2(px, bar_top, pw, 13.0), _tire_color(str(stint["compound"])))
		var marker: float = x + usable * float(row["progress"]) / float(_max_laps)
		draw_line(Vector2(marker, bar_top - 3), Vector2(marker, bar_top + 17), Color("#55e9cc"), 2.0)
	draw_string(font, Vector2(x, h - 4.0), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#97a9bb"))
	draw_string(font, Vector2(right - 34.0, h - 4.0), str(_max_laps) + "v", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#97a9bb"))
