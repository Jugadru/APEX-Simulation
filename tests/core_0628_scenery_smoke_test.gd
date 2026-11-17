extends SceneTree
## Native check: create 3D circuit in four environments without changing route.
const Track3D = preload("res://scripts/track_3d.gd")
const Scenery = preload("res://scripts/apex_circuit_scenery_0628.gd")
const Car = preload("res://scripts/car_model_3d.gd")

func _initialize() -> void:
	call_deferred("run_smoke")

func fail_test(message: String) -> void:
	printerr("APEX 0628: " + message)
	quit(1)

func run_smoke() -> void:
	var expected: Dictionary = {
		"Bahrain International Circuit": "desert",
		"Sepang — Kuala Lumpur": "tropical",
		"Circuit de Monaco": "urban",
		"Silverstone": "temperate"
	}
	var path := PackedVector2Array()
	for i in range(160):
		var angle: float = TAU * float(i) / 160.0
		path.append(Vector2(550.0 + 315.0 * cos(angle), 450.0 + 230.0 * sin(angle)))
	path.append(path[0])
	var track := Track3D.new()
	root.add_child(track)
	for title in expected:
		var palette: Dictionary = Scenery.palette_for(title)
		if str(palette.get("kind", "")) != expected[title]:
			fail_test("paleta incorreta: " + title)
			return
		track.set_track_data(path, title)
		var scenery: Node = track.course_root.get_node_or_null("CircuitScenery0628")
		if scenery == null:
			fail_test("cenario nao criado: " + title)
			return
		if track.road_centers.size() != path.size() - 1:
			fail_test("traçado alterado: " + title)
			return
		if track.world_environment_3d == null:
			fail_test("WorldEnvironment ausente")
			return
	var car := Car.new("#165ab5", "Apex Test", 14)
	root.add_child(car)
	if car.get_node_or_null("ChassisVisual/MirrorCase") == null:
		fail_test("retrovisores visuais ausentes")
		return
	if car.get_node_or_null("ChassisVisual/RainLightVisual") == null:
		fail_test("lanterna visual ausente")
		return
	print("APEX 0.6.2.8 SCENERY SMOKE OK")
	quit(0)
