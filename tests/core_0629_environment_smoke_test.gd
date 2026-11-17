extends SceneTree
## Native smoke — visuals across distinct 2012 circuits, unchanged route.
const Track3D = preload("res://scripts/track_3d.gd")

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var route := PackedVector2Array()
	for i in range(180):
		var a: float = TAU * float(i) / 180.0
		route.append(Vector2(550.0 + 300.0 * cos(a), 450.0 + 230.0 * sin(a)))
	route.append(route[0])
	var track := Track3D.new()
	root.add_child(track)
	var cases: Dictionary = {
		"Bahrain International Circuit": "DesertPaddock_",
		"Sepang — Kuala Lumpur": "TropicalPalm_",
		"Circuit de Monaco": "UrbanBlock_",
		"Silverstone": "CircuitService_"
	}
	for title in cases.keys():
		track.set_track_data(route, title)
		var details: Node = track.course_root.get_node_or_null("CircuitDetail0629")
		assert(details != null, "Layer 0629 missing: " + title)
		var road_edges: int = 0
		for child in track.course_root.get_children():
			if str(child.name).begins_with("RoadEdgeLine"):
				road_edges += 1
		if road_edges != 2:
			printerr("Road lines count %s: %d" % [title, road_edges])
			quit(1)
			return
		assert(track.road_centers.size() == route.size() - 1, "Route modified: " + title)
		var themed: int = 0
		for prop in details.get_children():
			if str(prop.name).begins_with(str(cases[title])):
				themed += 1
		assert(themed > 0, "Biome theme missing: " + title)
		assert(track.camera_3d.near >= 2.0, "Prior near plane regression")
		print("APEX_0629 ", title, " themed props=", themed, " layer props=", details.get_child_count())
	print("APEX 0.6.2.9 NATIVE SCENERY SMOKE OK")
	quit(0)
