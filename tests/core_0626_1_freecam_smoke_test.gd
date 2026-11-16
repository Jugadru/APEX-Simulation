extends SceneTree
## Godot-only smoke: check that actual 3D free camera pan moves world camera.
## A GUI mouse routing test still requires using the actual game viewport.
const Track3D = preload("res://scripts/track_3d.gd")
const CameraControl = preload("res://scripts/apex_race_view_controller.gd")

func _initialize() -> void:
	call_deferred("_check_pan")

func _check_pan() -> void:
	var world = Track3D.new()
	root.add_child(world)
	if world.camera_3d == null:
		printerr("Free cam: Camera3D not initialized")
		quit(1)
		return
	world.enter_free_view()
	var before: Vector3 = world.camera_3d.position
	world.pan_by(Vector2(110.0, -75.0))
	if world.camera_3d.position.distance_to(before) < 0.01:
		printerr("Free cam: drag pan did not change camera position")
		quit(2)
		return
	if world.camera_mode_3d != "overview":
		printerr("Free cam: input did not preserve overview state")
		quit(3)
		return
	print("APEX FREECAM 0.6.2.6.1 SMOKE OK")
	quit(0)
