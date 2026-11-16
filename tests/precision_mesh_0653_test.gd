extends SceneTree
const Car = preload("res://scripts/car_model_3d.gd")
var checked := 0
func _initialize() -> void:
	var car = Car.new()
	check_nodes(car)
	assert(car.wheel_spins.size()==4 and car.steering_pivots.size()==2)
	assert(car.chassis.get_node("OpenCockpitCoaming") != null)
	assert(checked > 10)
	car.free()
	print("PRECISION_MESH_PASS ",checked," indexed meshes: finite/unit normals, valid indices, four wheels, open cockpit")
	quit()
func check_nodes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		var arrays = node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		assert(vertices.size()==normals.size())
		for v in vertices: assert(v.is_finite())
		for n in normals: assert(n.is_finite() and absf(n.length()-1)<.01)
		for index in arrays[Mesh.ARRAY_INDEX]: assert(index>=0 and index<vertices.size())
		checked += 1
	for child in node.get_children(): check_nodes(child)
