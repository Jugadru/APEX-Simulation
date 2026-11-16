extends Node2D
## APEX 0.6.6.7.2.2: fixed route cached independently from moving race dots.
## Only set_track_data() / set_view_mode() invalidates this CanvasItem.
var track_map: Node2D = null
var draw_count: int = 0

func _draw() -> void:
	if track_map == null or not is_instance_valid(track_map):
		return
	draw_count += 1
	track_map.render_static(self)
