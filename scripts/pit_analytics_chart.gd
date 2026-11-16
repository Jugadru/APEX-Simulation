extends Control
## Small original chart for player pit service times (per completed stop).
## No third-party assets, textures, or plug-ins.
var samples: Array = []
var baseline: float = 0.0
const BG := Color("#102136")
const GRID := Color("#2c4660")
const LINE := Color("#50e0bc")
const REFERENCE := Color("#f2c76c")
const TEXT := Color("#c6d8e5")

func _ready() -> void:
	custom_minimum_size = Vector2(275, 138)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_records(records: Array) -> void:
	samples.clear()
	baseline = 0.0
	for record in records:
		samples.append(float(record.get("service", 0.0)))
		# Untrained service target = actual service + speed training saving.
		baseline += maxf(0.0, float(record.get("untrained_service", record.get("service", 0.0))))
	if samples.size() > 0:
		baseline /= float(samples.size())
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, BG, true)
	var font := ThemeDB.fallback_font
	if samples.is_empty():
		draw_string(font, Vector2(12.0, 66.0), "Gráfico disponível após o 1º pit stop", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TEXT)
		return
	var low := baseline
	var high := baseline
	for sec in samples:
		low = minf(low, float(sec))
		high = maxf(high, float(sec))
	low = maxf(0.0, low - 0.65)
	high += 0.65
	var usable := maxf(0.5, high - low)
	var left := 43.0
	var right := maxf(left + 40.0, size.x - 13.0)
	var top := 20.0
	var bottom := size.y - 20.0
	for i in range(3):
		var y := lerpf(top, bottom, float(i) / 2.0)
		var value := lerpf(high, low, float(i) / 2.0)
		draw_line(Vector2(left, y), Vector2(right, y), GRID, 1.0)
		draw_string(font, Vector2(4.0, y + 5.0), "%.1fs" % value, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT)
	var benchmark_y := bottom - (baseline - low) / usable * (bottom - top)
	draw_line(Vector2(left, benchmark_y), Vector2(right, benchmark_y), REFERENCE, 1.5)
	var previous := Vector2.ZERO
	for i in range(samples.size()):
		var x := lerpf(left, right, float(i) / float(maxi(1, samples.size() - 1)))
		var y := bottom - (float(samples[i]) - low) / usable * (bottom - top)
		var point := Vector2(x, y)
		if i > 0:
			draw_line(previous, point, LINE, 2.1, true)
		draw_circle(point, 3.6, LINE)
		previous = point
	draw_string(font, Vector2(left, size.y - 5.0), "Trocas concluídas", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT)
