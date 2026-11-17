extends SceneTree
## Godot 4 smoke test. Runs a camera shot, enters free mode, and verifies
## that the auto-director picks two real competitors. No UI or GPU required.
const Track3D = preload("res://scripts/track_3d.gd")
const Director = preload("res://scripts/tv_director.gd")

class FakeRace:
	extends RefCounted
	var team_name: String = "Red Bull Racing Renault"
	var events: Array = []
	func get_sorted() -> Array:
		return [
			{"id": 4, "team": "Ferrari", "interval": 0.0},
			{"id": 9, "team": "Red Bull Racing Renault", "interval": 0.42},
			{"id": 10, "team": "Mercedes", "interval": 3.5},
		]

func _initialize() -> void:
	call_deferred("run_smoke")

func run_smoke() -> void:
	var test_race := FakeRace.new()
	var tv := Director.new()
	var chosen: int = tv.select(test_race, 9, 0.0)
	if chosen != 9 or tv.secondary_focus_id != 4 or tv.camera_style != "battle":
		printerr("0626: TV did not select battle with both competitors")
		quit(1)
		return
	var world := Track3D.new()
	root.add_child(world)
	world.magnification = 1.35
	world.set_broadcast_view(Vector2(540.0, 450.0), Vector2.RIGHT, Vector2(590.0, 450.0), "aerial", 1.0)
	if world.camera_mode_3d != "aerial" or world.camera_3d == null:
		printerr("0626: aerial camera did not activate")
		quit(2)
		return
	var before: Vector3 = world.camera_look_target
	world.enter_free_view()
	if world.camera_mode_3d != "overview" or world.focus_point.distance_to(Vector3(before.x, 0.0, before.z)) > 0.1:
		printerr("0626: free camera did not preserve focus")
		quit(3)
		return
	world.set_broadcast_view(Vector2(540.0, 450.0), Vector2.RIGHT, Vector2(590.0, 450.0), "battle", 1.0)
	if world.camera_mode_3d != "battle":
		printerr("0626: battle camera did not activate")
		quit(4)
		return
	print("APEX 0.6.2.6 CAMERA SMOKE OK")
	quit(0)
