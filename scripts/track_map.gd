extends Node2D
const GeometrySampler = preload("res://scripts/track_geometry_sampler_0659.gd")
var geometry_sampler := GeometrySampler.new()
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
const StaticLayer = preload("res://scripts/track_map_static_066722.gd")
## Dual visual track renderer.
## Mode 0: strategic 2D map. Mode 1: close aerial / pseudo-3D TV map.

const MODE_MAP: int = 0
const MODE_CLOSE: int = 1
const STRATEGIC_BG: Color = Color("#07111b")
const GRASS: Color = Color("#24452f")
const TRACK_EDGE: Color = Color("#687783")
const ASPHALT: Color = Color("#33383e")
const ASPHALT_INNER: Color = Color("#45494e")
const SECTOR_COLORS: Array[Color] = [Color("#ff5063"), Color("#35beff"), Color("#f3ca47")]

var base_points: Array[Vector2] = []
var route: PackedVector2Array = PackedVector2Array()
var cumulative: PackedFloat32Array = PackedFloat32Array()
var route_length: float = 1.0
var cars: Array = []
var focus_id: int = -1
var show_names: bool = true
var view_mode: int = MODE_MAP
var track_title: String = "Spa-Francorchamps"
var track_subtitle: String = "Belgica"
var pit_lane_hint: float = 0.985
var historical_geometry: bool = false
var static_layer: Node2D = null
var dynamic_draw_count: int = 0

func _ready() -> void:
	# A permanent CanvasItem behind mobile dots. Its draw commands survive
	# every cars-only queue_redraw() on this parent, even at 32x.
	static_layer = StaticLayer.new()
	static_layer.name = "CachedCircuit"
	static_layer.show_behind_parent = true
	add_child(static_layer)
	static_layer.track_map = self
	static_layer.queue_redraw()
	if route.is_empty() and FileAccess.file_exists("res://data/spa_track.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/spa_track.json"))
		if typeof(parsed) == TYPE_DICTIONARY:
			var fallback: Dictionary = parsed
			set_track_data({"name": "Spa-Francorchamps", "country": "Belgica", "points": fallback.get("points", [])})

func set_track_data(payload: Dictionary) -> void:
	base_points.clear()
	track_title = str(payload.get("name", "Spa-Francorchamps"))
	track_subtitle = str(payload.get("country", ""))
	historical_geometry = str(payload.get("geometry_quality", "")) == "licensed_geojson_reference"
	var points: Array = payload.get("points", [])
	for item in points:
		if item is Array and item.size() >= 2:
			var x := float(item[0]) * 1100.0
			var y := float(item[1]) * 900.0
			base_points.append(Vector2(x, y))
	_create_route()
	if static_layer != null:
		static_layer.queue_redraw()
	queue_redraw()

func _create_route() -> void:
	# Closed Chaikin corner cutting: rounds the outline without overshoot.
	# Unlike Catmull-Rom it does not invent sharp hairpins or long loops.
	# We keep the licensed geographical points as the base.
	route.clear()
	cumulative.clear()
	route_length = 1.0
	if base_points.size() < 4:
		geometry_sampler.build(route,cumulative,route_length)
		return
	var control: Array[Vector2] = base_points.duplicate()
	if control[0].distance_to(control[-1]) < 0.001:
		control.pop_back()
	for iteration in range(3):
		var next_pass: Array[Vector2] = []
		for i in range(control.size()):
			var first: Vector2 = control[i]
			var second: Vector2 = control[(i + 1) % control.size()]
			next_pass.append(first.lerp(second, 0.25))
			next_pass.append(first.lerp(second, 0.75))
		control = next_pass
	for point in control:
		route.append(point)
	route.append(control[0])
	cumulative.clear()
	cumulative.append(0.0)
	for k in range(1, route.size()):
		cumulative.append(cumulative[k - 1] + route[k - 1].distance_to(route[k]))
	route_length = maxf(cumulative[-1], 1.0)
	geometry_sampler.build(route,cumulative,route_length)

func point_on_track(progress: float) -> Vector2:
	var started := Perf.begin() if Perf.enabled else 0
	var result := geometry_sampler.point(progress)
	if Perf.enabled: Perf.end(&"route.2d_position",started)
	return result

func direction_on_track(progress: float) -> Vector2:
	var started := Perf.begin() if Perf.enabled else 0
	var result := geometry_sampler.direction(progress)
	if Perf.enabled: Perf.end(&"route.2d_direction",started)
	return result

func geometry_revision() -> int:
	return geometry_sampler.revision

func sample_on_track(progress: float) -> Dictionary:
	return geometry_sampler.sample(progress)

func set_view_mode(mode: int) -> void:
	var new_mode: int = clampi(mode, MODE_MAP, MODE_CLOSE)
	if view_mode == new_mode:
		return
	view_mode = new_mode
	if static_layer != null:
		static_layer.queue_redraw()
	queue_redraw()

func set_race_cars(race_cars: Array, selected: int) -> void:
	if not is_visible_in_tree(): return
	if focus_id == selected and cars == race_cars: return
	cars = race_cars
	focus_id = selected
	queue_redraw()

func _draw() -> void:
	if route.is_empty():
		return
	dynamic_draw_count += 1
	for car in cars:
		var progress: float = float(car.get("progress", 0.0))
		var p: Vector2 = car.route_point if car.has("route_point") else point_on_track(progress)
		var focused: bool = int(car.get("id", -1)) == focus_id
		var ours: bool = bool(car.get("player", false))
		var team_color: Color = Color.from_string(str(car.get("color", "#ffffff")), Color.WHITE)
		if view_mode == MODE_CLOSE:
			_draw_small_car(p, car.route_direction if car.has("route_direction") else direction_on_track(progress), team_color, focused, ours)
		else:
			_draw_dot(p, team_color, focused, ours)
		if float(car.get("pit_left", 0.0)) > 0.0:
			draw_arc(p, 18.0 if view_mode == MODE_CLOSE else 11.5, 0.0, TAU, 24, Color("#ffaf57"), 2.0, true)
		if focused and show_names:
			_draw_text(p + Vector2(18, -18), "%s  P%d" % [str(car.get("name", "Piloto")), int(car.get("position", 0))], 13, Color.WHITE)

# Called only by the static child during its own CanvasItem draw pass.
func render_static(canvas: Node2D) -> void:
	if route.is_empty():
		return
	if view_mode == MODE_CLOSE:
		_draw_close_circuit(canvas)
	else:
		_draw_strategic_circuit(canvas)

func _draw_strategic_circuit(canvas: Node2D) -> void:
	# Full-circuit, top-down tactical view: road, green infield and ONLY dots
	# for race cars. No coloured sector ribbons, analytical grid or mini-cars.
	# The geometric route and timing engine remain unchanged.
	canvas.draw_rect(Rect2(Vector2(-2500, -2500), Vector2(6500, 6500)), GRASS)
	# Very subtle grass texture; visually subordinate to circuit and dots.
	for y in range(-1200, 2200, 210):
		canvas.draw_line(Vector2(-1500, y), Vector2(2600, y + 90), Color(0.06, 0.11, 0.07, 0.10), 24.0)
	canvas.draw_polyline(route, Color("#70948b"), 52.0, true)
	canvas.draw_polyline(route, Color("#b6bfba"), 44.0, true)
	canvas.draw_polyline(route, Color("#333b41"), 36.0, true)
	canvas.draw_polyline(route, Color("#40484b"), 30.0, true)
	# Alternating red/white kerbs along the circuit, not separate 3D assets.
	for k in range(0, route.size() - 7, 14):
		var p: Vector2 = route[k]
		var q: Vector2 = route[k + 6]
		var tangent: Vector2 = (q - p).normalized()
		var side: Vector2 = Vector2(-tangent.y, tangent.x)
		var kerb_color: Color = Color("#b93539") if int(k / 14) % 2 == 0 else Color("#ecefeb")
		canvas.draw_line(p + side * 19.0, q + side * 19.0, kerb_color, 3.5, true)
	_draw_finish_and_pits(false, canvas)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(90, 44), "%s • MAPA AÉREO 2D" % track_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f1f7f2"))

func _draw_close_circuit(canvas: Node2D) -> void:
	canvas.draw_rect(Rect2(Vector2(-2500, -2500), Vector2(6500, 6500)), GRASS)
	for x in range(-1500, 2600, 140):
		canvas.draw_line(Vector2(x, -1000), Vector2(x + 700, 2200), Color(0.05, 0.10, 0.05, 0.085), 28.0)
	for y in range(-1000, 1800, 110):
		canvas.draw_line(Vector2(-1300, y), Vector2(2300, y), Color(0.09, 0.16, 0.10, 0.10), 12.0)
	canvas.draw_polyline(route, Color("#638278"), 51.0, true)
	canvas.draw_polyline(route, Color("#adb1ac"), 43.0, true)
	canvas.draw_polyline(route, ASPHALT, 37.0, true)
	canvas.draw_polyline(route, ASPHALT_INNER, 31.0, true)
	canvas.draw_polyline(route, Color("#dee3dc"), 1.2, true)
	for k in range(0, route.size() - 10, 10):
		var p: Vector2 = route[k]
		var q: Vector2 = route[k + 6]
		var tangent: Vector2 = (q - p).normalized()
		var side: Vector2 = Vector2(-tangent.y, tangent.x)
		var stripe_color: Color = Color("#e64949") if int(k / 10) % 2 == 0 else Color("#e9f2ea")
		canvas.draw_line(p + side * 19.0, q + side * 19.0, stripe_color, 5.0, true)
	_draw_finish_and_pits(true, canvas)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(88, 45), "%s  /  CAMERA PROXIMA" % track_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f0fff4"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(88, 65), "%s • %s" % [track_subtitle.to_upper(), "TRAÇADO BASE GEOJSON" if historical_geometry else "TRAÇADO PROVISÓRIO"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d9e8d8"))

func _draw_finish_and_pits(close_view: bool, canvas: Node2D) -> void:
	var finish: Vector2 = point_on_track(0.0)
	var tangent: Vector2 = direction_on_track(0.0)
	var side: Vector2 = Vector2(-tangent.y, tangent.x)
	var half_width: float = 21.0 if close_view else 12.0
	canvas.draw_line(finish - side * half_width, finish + side * half_width, Color.WHITE, 3.0, true)
	# Short schematic pit entry next to the finish; never connects across the
	# circuit. It is NOT a geographically exact pit lane for every 2012 GP.
	var pit_points := PackedVector2Array()
	for step in range(15):
		var ref: float = 0.986 + float(step) / 14.0 * 0.028
		var p: Vector2 = point_on_track(ref)
		var t: Vector2 = direction_on_track(ref)
		pit_points.append(p + Vector2(-t.y, t.x) * (34.0 if close_view else 23.0))
	canvas.draw_polyline(pit_points, Color("#dbdcd5") if close_view else Color("#ffce70"), 7.0 if close_view else 2.8, true)
	if close_view:
		canvas.draw_polyline(pit_points, Color("#2e3535"), 4.5, true)

func _draw_dot(p: Vector2, team_color: Color, focused: bool, ours: bool) -> void:
	if focused:
		draw_circle(p, 12.0, Color("#ffd966"))
		draw_circle(p, 9.5, ASPHALT)
	draw_circle(p, 6.8 if ours else 5.4, team_color)
	if ours:
		draw_arc(p, 10.1, 0.0, TAU, 24, Color.WHITE, 1.6, true)

func _draw_small_car(p: Vector2, heading: Vector2, color: Color, focused: bool, ours: bool) -> void:
	var side: Vector2 = Vector2(-heading.y, heading.x)
	if focused:
		draw_arc(p, 18.0, 0.0, TAU, 28, Color("#ffe173"), 2.3, true)
	var body := PackedVector2Array([
		p + heading * 13.0, p + heading * 6.0 + side * 3.3,
		p - heading * 9.0 + side * 4.1, p - heading * 12.0,
		p - heading * 9.0 - side * 4.1, p + heading * 6.0 - side * 3.3
	])
	draw_colored_polygon(body, color)
	for offset in [-1.0, 1.0]:
		var sign: float = offset
		draw_line(p + heading * 6.0 + side * sign * 6.1, p + heading * 0.5 + side * sign * 6.1, Color("#141719"), 4.3, true)
		draw_line(p - heading * 5.0 + side * sign * 6.1, p - heading * 9.0 + side * sign * 6.1, Color("#141719"), 4.3, true)
	draw_line(p + heading * 10.7 - side * 7.6, p + heading * 10.7 + side * 7.6, Color("#eceded"), 2.8, true)
	draw_line(p - heading * 11.0 - side * 7.0, p - heading * 11.0 + side * 7.0, Color("#20242a"), 3.2, true)
	draw_circle(p + heading * 1.0, 2.7, Color("#0d1720"))
	if ours:
		draw_arc(p, 14.0, 0.0, TAU, 24, Color.WHITE, 1.25, true)

func _draw_text(pos: Vector2, value: String, size_px: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
