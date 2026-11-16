extends SceneTree
## Native Godot 4.7.2 smoke test for camera depth, terrain and finish line.
const Track3D = preload("res://scripts/track_3d.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var track = Track3D.new()
	root.add_child(track)
	var path := PackedVector2Array()
	for i in range(144):
		var a: float = TAU * float(i) / 144.0
		path.append(Vector2(550.0 + cos(a) * 340.0, 450.0 + sin(a) * 250.0))
	path.append(path[0])
	track.set_track_data(path, "Bahrain International Circuit")
	assert(track.camera_3d.near >= 2.0, "Camera near plane too small for aerial overview")
	var terrain: MeshInstance3D = track.course_root.get_child(0) as MeshInstance3D
	assert(terrain != null and terrain.mesh is PlaneMesh, "Terrain missing")
	assert((terrain.mesh as PlaneMesh).size.x >= 2000.0, "Terrain can expose sky when panning")
	var has_finish: bool = false
	for n in track.course_root.get_children():
		if n is MeshInstance3D and n.mesh is BoxMesh and n != terrain:
			if n.position.y > 0.10 and n.position.y < 0.11:
				has_finish = true
	assert(has_finish, "Finish line mesh missing")
	print("APEX 0.6.2.8.1 VISUAL SMOKE OK")
	quit(0)
