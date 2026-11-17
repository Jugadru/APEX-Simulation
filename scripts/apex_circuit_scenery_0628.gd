extends RefCounted
## APEX 0.6.2.8 — circuit scenery only; no racing physics or track changes.
## Static helpers create original, low-poly visual landmarks outside the road.

static func palette_for(circuit_name: String) -> Dictionary:
	var name: String = circuit_name.to_lower()
	if "bahrain" in name or "yas marina" in name or "buddh" in name:
		return {
			"kind": "desert", "ground": "#bba882", "patch_a": "#c7b38d",
			"patch_b": "#a99672", "sky": "#cbdce2", "trees": false,
			"accent": "#328c94", "stand": "#567884"
		}
	if "monaco" in name or "valencia" in name or "marina bay" in name:
		return {
			"kind": "urban", "ground": "#68776f", "patch_a": "#74857e",
			"patch_b": "#5d6d68", "sky": "#b9ccd9", "trees": false,
			"accent": "#d8a14d", "stand": "#536373"
		}
	if "sepang" in name or "interlagos" in name:
		return {
			"kind": "tropical", "ground": "#315c42", "patch_a": "#3b694b",
			"patch_b": "#2d563f", "sky": "#b5d5dd", "trees": true,
			"accent": "#35abb0", "stand": "#326f7b"
		}
	return {
		"kind": "temperate", "ground": "#45684a", "patch_a": "#4f7654",
		"patch_b": "#3e6046", "sky": "#b9d0dc", "trees": true,
		"accent": "#4089af", "stand": "#3c687e"
	}

static func _mat(hex_color: String, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex_color)
	material.roughness = 0.84 if metallic < 0.01 else 0.58
	material.metallic = metallic
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func _block(parent: Node3D, block_name: String, dimensions: Vector3, location: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = block_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.position = location
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance

static func _is_outside_other_sections(location: Vector3, centers: Array[Vector3], clearance: float) -> bool:
	var limit: float = clearance * clearance
	for j in range(0, centers.size(), 5):
		if location.distance_squared_to(centers[j]) < limit:
			return false
	return true

static func add_details(root: Node3D, circuit_name: String, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	if root == null or centers.size() < 30 or centers.size() != normals.size() or centers.size() != widths.size():
		return
	var visual_root := Node3D.new()
	visual_root.name = "CircuitScenery0628"
	root.add_child(visual_root)
	var palette: Dictionary = palette_for(circuit_name)
	_add_branding(visual_root, palette, centers, normals, widths)
	_add_fence_posts(visual_root, centers, normals, widths)
	_add_landmarks(visual_root, palette, centers, normals, widths)

static func _add_branding(root: Node3D, palette: Dictionary, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var accent: StandardMaterial3D = _mat(str(palette["accent"]))
	var navy: StandardMaterial3D = _mat("#172c3c")
	var pole: StandardMaterial3D = _mat("#7f8990", 0.22)
	var count: int = centers.size()
	for slot in range(18):
		var i: int = mini(int((float(slot) + 0.45) / 18.0 * float(count)), count - 1)
		var side: float = 1.0 if slot % 2 == 0 else -1.0
		var right: Vector3 = normals[i].normalized() * side
		var world_pos: Vector3 = centers[i] + right * (widths[i] * 1.50 + 7.0)
		if not _is_outside_other_sections(world_pos, centers, 10.0):
			continue
		var prev: Vector3 = centers[(i + count - 1) % count]
		var next: Vector3 = centers[(i + 1) % count]
		var tangent: Vector3 = (next - prev).normalized()
		if tangent.length_squared() < 0.1:
			continue
		var board := Node3D.new()
		board.name = "TracksideBoard_%02d" % slot
		board.position = world_pos
		board.rotation.y = atan2(-tangent.z, tangent.x)
		root.add_child(board)
		_block(board, "Panel", Vector3(5.8, 1.9, 0.20), Vector3(0.0, 1.75, 0.0), navy if slot % 3 != 0 else accent)
		for x in [-2.55, 2.55]:
			_block(board, "Post", Vector3(0.13, 2.0, 0.13), Vector3(x, 0.94, 0.0), pole)
		var text := Label3D.new()
		text.name = "APEXSign"
		text.text = "APEX" if slot % 3 != 1 else "MOTORSPORT"
		text.font_size = 64 if slot % 3 != 1 else 46
		text.pixel_size = 0.009
		text.outline_size = 5
		text.outline_modulate = Color("#0a1d27")
		text.modulate = Color("#ecf5f2")
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		text.position = Vector3(0.0, 1.75, 0.20)
		board.add_child(text)

static func _add_fence_posts(root: Node3D, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	# One instanced fence-post batch per circuit rather than hundreds of Nodes.
	var positions: Array[Vector3] = []
	for i in range(0, centers.size(), 8):
		var progress: float = float(i) / float(centers.size())
		if not ((progress > 0.12 and progress < 0.22) or (progress > 0.49 and progress < 0.60) or (progress > 0.80 and progress < 0.94)):
			continue
		for side in [-1.0, 1.0]:
			positions.append(centers[i] + normals[i] * side * (widths[i] * 1.50 + 0.10))
	if positions.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.09, 1.85, 0.09)
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = positions.size()
	for i in range(positions.size()):
		instances.set_instance_transform(i, Transform3D(Basis(), positions[i] + Vector3.UP * 0.92))
	var fence := MultiMeshInstance3D.new()
	fence.name = "FencePosts"
	fence.multimesh = instances
	fence.material_override = _mat("#a6b6b7", 0.20)
	root.add_child(fence)

static func _add_landmarks(root: Node3D, palette: Dictionary, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var kind: String = str(palette["kind"])
	if kind == "tropical" or kind == "temperate":
		return  # These circuits already have the instanced tree scenery.
	var count: int = centers.size()
	var shell := _mat("#9ca8ad" if kind == "urban" else "#ede4d2")
	var roof := _mat("#384e5e" if kind == "urban" else "#4a96a1")
	var glass := _mat("#537b8b" if kind == "urban" else "#6c8e99", 0.12)
	for slot in range(12):
		var i: int = mini(int((float(slot) + 0.3) / 12.0 * float(count)), count - 1)
		var sign: float = -1.0 if slot % 2 == 0 else 1.0
		var offset: float = 45.0 + float(slot % 3) * 8.0
		var spot: Vector3 = centers[i] + normals[i].normalized() * sign * offset
		if not _is_outside_other_sections(spot, centers, 25.0):
			continue
		var building := Node3D.new()
		building.name = "DistantFacility_%02d" % slot
		building.position = spot
		root.add_child(building)
		if kind == "urban":
			var height: float = 7.0 + float(slot % 4) * 3.0
			_block(building, "Building", Vector3(6.5, height, 7.5), Vector3(0.0, height * 0.5, 0.0), shell)
			for floor_id in range(2, int(height / 2.0)):
				_block(building, "Windows", Vector3(6.6, 0.34, 0.13), Vector3(0.0, 1.4 + floor_id * 1.8, 3.83), glass)
		else:
			var height_desert: float = 3.1 + float(slot % 2) * 1.2
			_block(building, "DesertFacility", Vector3(10.0, height_desert, 6.4), Vector3(0.0, height_desert * 0.5, 0.0), shell)
			_block(building, "RoofBand", Vector3(10.5, 0.30, 6.8), Vector3(0.0, height_desert + 0.06, 0.0), roof)
			_block(building, "FrontWindows", Vector3(7.0, 0.75, 0.14), Vector3(0.0, 1.45, 3.28), glass)
