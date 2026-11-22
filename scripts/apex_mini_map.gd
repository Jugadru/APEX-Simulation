extends Control
## Tiny live track map. Uses the EXACT route and car positions from track_map.gd.
## No game simulation/geometry changes.

const ROAD := Color("#c5e0eb")
const DARK := Color("#111c28")
const AQUA := Color("#ff7a00")

var route: PackedVector2Array = PackedVector2Array()
var cars: Array = []
var focus_id: int = -1
var min_point: Vector2 = Vector2.ZERO
var scale_factor: float = 1.0
var offset_point: Vector2 = Vector2.ZERO
var show_background: bool = true

func _ready() -> void:
	custom_minimum_size = Vector2(170, 133)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func set_track(new_route: PackedVector2Array) -> void:
	route = new_route
	queue_redraw()

func set_cars(new_cars: Array, focus: int) -> void:
	if not is_visible_in_tree(): return
	if focus_id == focus and cars == new_cars: return
	cars = new_cars
	focus_id = focus
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	if show_background:
		draw_rect(bounds, DARK)
	if route.size() < 3:
		return
	var mn := route[0]
	var mx := route[0]
	for point in route:
		mn = mn.min(point)
		mx = mx.max(point)
	var extents := mx - mn
	var sx: float = (size.x - 24.0) / maxf(extents.x, 1.0)
	var sy: float = (size.y - 22.0) / maxf(extents.y, 1.0)
	scale_factor = minf(sx, sy)
	min_point = mn
	offset_point = Vector2(12.0 + (size.x - 24.0 - extents.x * scale_factor) * 0.5,
		11.0 + (size.y - 22.0 - extents.y * scale_factor) * 0.5)
	var transformed := PackedVector2Array()
	var step: int = maxi(1, int(route.size() / 500))
	for i in range(0, route.size(), step):
		transformed.append(_map_point(route[i]))
	transformed.append(_map_point(route[0]))
	draw_polyline(transformed, Color("#324d60"), 6.0, true)
	draw_polyline(transformed, ROAD, 2.7, true)
	for item in cars:
		var pos: Vector2 = item.get("route_point", Vector2.ZERO)
		var driver_id: int = int(item.get("id", -1))
		var mine: bool = bool(item.get("player", false))
		var selected: bool = driver_id == focus_id
		var color: Color = Color.from_string(str(item.get("color", "#ffffff")), Color.WHITE)
		var dot: Vector2 = _map_point(pos)
		if selected:
			draw_circle(dot, 5.3, Color("#ffffff"))
		draw_circle(dot, 3.6 if selected else (2.8 if mine else 2.1), AQUA if mine else color)
	if cars.size() == 0:
		draw_string(ThemeDB.fallback_font, Vector2(8, 20), "MAPA AO VIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, AQUA)

func _map_point(p: Vector2) -> Vector2:
	return (p - min_point) * scale_factor + offset_point
