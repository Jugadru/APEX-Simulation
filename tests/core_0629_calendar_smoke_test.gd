extends SceneTree
## Test full licensed 2012 calendar, not only synthetic circles.
const Track3D = preload("res://scripts/track_3d.gd")
const Map2D = preload("res://scripts/track_map.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("APEX 0629 CALENDAR FAILURE: " + message)
	quit(1)

func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not (data is Dictionary):
		_fail("Season JSON not available")
		return
	var races: Array = data["tracks"]
	var map2d := Map2D.new()
	root.add_child(map2d)
	var visual := Track3D.new()
	root.add_child(visual)
	var successes: int = 0
	for event in races:
		var name: String = str(event["name"])
		map2d.set_track_data(event)
		visual.set_track_data(map2d.route, name)
		var layer: Node = visual.course_root.get_node_or_null("CircuitDetail0629")
		if layer == null or visual.road_centers.size() < 20:
			_fail("No road or scenery for " + name)
			return
		var invalid_prop: String = ""
		for prop in layer.get_children():
			if prop is Node3D:
				if absf((prop as Node3D).position.x) > 1500.0 or absf((prop as Node3D).position.z) > 1500.0:
					invalid_prop = str(prop.name)
		if not invalid_prop.is_empty():
			_fail("Bad prop " + invalid_prop + " in " + name)
			return
		successes += 1
		print("APEX_0629_TRACK ", successes, " ", name, " props=", layer.get_child_count())
	if successes != 20:
		_fail("Expected 20 tracks")
		return
	print("APEX 0.6.2.9 FULL CALENDAR OK: 20/20")
	quit(0)
