extends RefCounted
## APEX 0.6.2.9 — decorative environment layer. No collision, lap logic or route edits.
## All assets are original low-poly primitives assembled at runtime.

const PriorStyle = preload("res://scripts/apex_circuit_scenery_0628.gd")

static func _mat(colour: String, roughness: float = 0.83) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(colour)
	mat.roughness = roughness
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

static func _box(parent: Node3D, label: String, dims: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	var mesh := BoxMesh.new()
	mesh.size = dims
	item.mesh = mesh
	item.position = pos
	item.material_override = mat
	parent.add_child(item)
	return item

static func _site_clear(site: Vector3, centers: Array[Vector3], clearance: float) -> bool:
	# Track can fold back within a few metres; test the entire route, not just
	# the centreline segment used to place a prop.
	var limit := clearance * clearance
	for i in range(0, centers.size(), 4):
		if centers[i].distance_squared_to(site) < limit:
			return false
	return true

static func _anchor(centers: Array[Vector3], normals: Array[Vector3], widths: Array[float], fraction: float, side: float, clearance: float) -> Dictionary:
	var count: int = centers.size()
	var i: int = clampi(int(fraction * float(count)), 0, count - 1)
	var tangent: Vector3 = (centers[(i + 4) % count] - centers[(i + count - 4) % count]).normalized()
	if tangent.length_squared() < 0.2:
		return {}
	var position: Vector3 = centers[i] + normals[i].normalized() * side * (maxf(4.4, widths[i]) + clearance)
	if not _site_clear(position, centers, clearance * 0.76):
		return {}
	return {"pos": position, "rotation": atan2(-tangent.z, tangent.x), "index": i}

static func install(parent: Node3D, title: String, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	if parent == null or centers.size() < 40 or centers.size() != normals.size() or centers.size() != widths.size():
		return
	var layer := Node3D.new()
	layer.name = "CircuitDetail0629"
	parent.add_child(layer)
	var style: Dictionary = PriorStyle.palette_for(title)
	_add_runoff(layer, style, centers, normals, widths)
	# Corrugated guardrails are supplied by track_3d in v0.6.5.3.
	_add_stands(layer, style, centers, normals, widths)
	_add_architecture(layer, title, style, centers, normals, widths)

static func _add_runoff(layer: Node3D, style: Dictionary, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	# Small *outside-the-road* paved runoff patches at selected camera sectors.
	# Roads are y=0.061; these triangles are y=0.018, above terrain and
	# below the asphalt/kerbs. Skip bends with nearby returning sections.
	var kind: String = str(style["kind"])
	var primary: String = "#baac8f" if kind == "desert" else "#687d79" if kind == "urban" else "#637d72" if kind == "tropical" else "#6f8177"
	var secondary: String = "#6e9ca3" if kind == "desert" else "#9aaca9" if kind == "urban" else "#3f8d7c" if kind == "tropical" else "#8a9b90"
	var n: int = centers.size()
	for patch_id in range(6):
		var center_fraction: float = [0.10, 0.29, 0.44, 0.61, 0.76, 0.91][patch_id]
		var midpoint: int = int(center_fraction * float(n))
		var start: int = maxi(0, midpoint - 14)
		var end: int = mini(n - 2, midpoint + 14)
		var vertices := PackedVector3Array()
		var side: float = 1.0 if patch_id % 2 == 0 else -1.0
		for i in range(start, end):
			var j: int = i + 1
			var outer: Vector3 = centers[i] + normals[i].normalized() * side * (maxf(4.4, widths[i]) * 1.50 + 8.5)
			if not _site_clear(outer, centers, 7.5):
				continue
			var outer_j: Vector3 = centers[j] + normals[j].normalized() * side * (maxf(4.4, widths[j]) * 1.50 + 8.5)
			if not _site_clear(outer_j, centers, 7.5):
				continue
			var a: Vector3 = centers[i] + normals[i].normalized() * side * (widths[i] * 1.45 + 1.5) + Vector3.UP * 0.018
			var b: Vector3 = outer + Vector3.UP * 0.018
			var c: Vector3 = centers[j] + normals[j].normalized() * side * (widths[j] * 1.45 + 1.5) + Vector3.UP * 0.018
			var d: Vector3 = outer_j + Vector3.UP * 0.018
			vertices.append_array(PackedVector3Array([a, c, b, b, c, d]))
		if vertices.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var surface_normals := PackedVector3Array()
		surface_normals.resize(vertices.size())
		surface_normals.fill(Vector3.UP)
		arrays[Mesh.ARRAY_NORMAL] = surface_normals
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var zone := MeshInstance3D.new()
		zone.name = "RunoffZone_%02d" % patch_id
		zone.mesh = mesh
		zone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		zone.material_override = _mat(primary if patch_id % 2 == 0 else secondary)
		layer.add_child(zone)

static func _add_guardrails(layer: Node3D, style: Dictionary, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	# Single triangle-batch mesh per side, not hundreds of Nodes or colliders.
	var n: int = centers.size()
	for side in [-1.0, 1.0]:
		var vertices := PackedVector3Array()
		for i in range(0, n - 2, 3):
			var fraction: float = float(i) / float(n)
			if not ((fraction > 0.08 and fraction < 0.25) or (fraction > 0.52 and fraction < 0.69) or (fraction > 0.79 and fraction < 0.93)):
				continue
			var j: int = mini(i + 3, n - 1)
			var a: Vector3 = centers[i] + normals[i].normalized() * side * (maxf(4.4, widths[i]) * 1.53 + 1.9)
			var b: Vector3 = centers[j] + normals[j].normalized() * side * (maxf(4.4, widths[j]) * 1.53 + 1.9)
			if not _site_clear(a, centers, 6.1) or not _site_clear(b, centers, 6.1):
				continue
			var bottom: Vector3 = Vector3.UP * 0.55
			var top: Vector3 = Vector3.UP * 1.12
			vertices.append_array(PackedVector3Array([a + bottom, b + bottom, a + top, a + top, b + bottom, b + top]))
		if vertices.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var panel := MeshInstance3D.new()
		panel.name = "ArmcoGuard_%s" % ("L" if side < 0.0 else "R")
		panel.mesh = mesh
		panel.material_override = _mat("#b9c9c5" if str(style["kind"]) != "urban" else "#a2b2bb", 0.52)
		layer.add_child(panel)

static func _add_stands(layer: Node3D, style: Dictionary, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var concrete := _mat("#788589" if str(style["kind"]) != "desert" else "#9d9585")
	var seat := _mat(str(style["stand"]))
	var roof := _mat("#d7dedb" if str(style["kind"]) != "desert" else "#e4dfd1")
	var crowd := [_mat("#ecb35d"), _mat("#3ba5ab"), _mat("#d5dad4"), _mat("#40566c")]
	for stand_id in range(4):
		var frac: float = [0.15, 0.36, 0.63, 0.84][stand_id]
		var side: float = -1.0 if stand_id % 2 == 0 else 1.0
		var place: Dictionary = _anchor(centers, normals, widths, frac, side, 31.0)
		if place.is_empty():
			continue
		var stand := Node3D.new()
		stand.name = "Grandstand_%02d" % stand_id
		stand.position = place["pos"]
		stand.rotation.y = float(place["rotation"])
		layer.add_child(stand)
		_box(stand, "StandBase", Vector3(22.0, 0.65, 11.0), Vector3(0.0, 0.32, 0.0), concrete)
		for tier in range(5):
			var depth: float = -3.8 + float(tier) * 1.65
			_box(stand, "Riser", Vector3(21.2, 0.7 + float(tier) * 0.67, 1.55), Vector3(0.0, 0.38 + float(tier) * 0.32, depth), concrete)
			_box(stand, "Seating", Vector3(20.8, 0.14, 1.40), Vector3(0.0, 0.8 + float(tier) * 0.68, depth), seat)
			for crowd_idx in range(13):
				var colour: Material = crowd[(crowd_idx + stand_id + tier) % crowd.size()]
				_box(stand, "Spectator", Vector3(0.39, 0.38, 0.32), Vector3(-9.1 + float(crowd_idx) * 1.49, 1.09 + float(tier) * 0.68, depth), colour)
		for x in [-10.1, 10.1]:
			_box(stand, "CanopySupport", Vector3(0.27, 5.4, 0.27), Vector3(x, 2.7, 3.8), concrete)
		_box(stand, "Roof", Vector3(24.5, 0.28, 12.4), Vector3(0.0, 5.52, 0.0), roof)
		_box(stand, "ApexCanopyBand", Vector3(24.5, 0.42, 0.4), Vector3(0.0, 5.30, -6.0), _mat(str(style["accent"])))

static func _add_architecture(layer: Node3D, title: String, style: Dictionary, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var kind: String = str(style["kind"])
	if kind == "desert":
		_add_desert(layer, centers, normals, widths)
	elif kind == "tropical":
		_add_tropical(layer, centers, normals, widths)
	elif kind == "urban":
		_add_city(layer, title, centers, normals, widths)
	else:
		_add_temperate(layer, centers, normals, widths)

static func _add_desert(layer: Node3D, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var white := _mat("#dfd7c6")
	var turquoise := _mat("#3c98a4")
	var glazing := _mat("#536d77", 0.42)
	for n in range(5):
		var site: Dictionary = _anchor(centers, normals, widths, [0.07, 0.27, 0.48, 0.74, 0.90][n], -1.0 if n % 2 else 1.0, 45.0)
		if site.is_empty():
			continue
		var building := Node3D.new()
		building.name = "DesertPaddock_%02d" % n
		building.position = site["pos"]
		building.rotation.y = float(site["rotation"])
		layer.add_child(building)
		_box(building, "MainBuilding", Vector3(17.0, 5.1, 11.0), Vector3.ZERO + Vector3.UP * 2.55, white)
		_box(building, "Roof", Vector3(19.5, 0.45, 13.0), Vector3(0.0, 5.35, 0.0), turquoise)
		_box(building, "GlazedFront", Vector3(15.5, 2.2, 0.18), Vector3(0.0, 2.65, 5.63), glazing)
		for x in [-6.4, -2.1, 2.1, 6.4]:
			_box(building, "FacadeFin", Vector3(0.28, 4.0, 0.48), Vector3(x, 2.0, 5.93), white)

static func _add_tropical(layer: Node3D, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var trunk := _mat("#806348")
	var frond := _mat("#24563c")
	for k in range(17):
		var fraction: float = 0.035 + float(k) * 0.057
		var place: Dictionary = _anchor(centers, normals, widths, fraction, 1.0 if k % 2 else -1.0, 27.0 + float(k % 3) * 7.0)
		if place.is_empty():
			continue
		var palm := Node3D.new()
		palm.name = "TropicalPalm_%02d" % k
		palm.position = place["pos"]
		layer.add_child(palm)
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.16
		trunk_mesh.bottom_radius = 0.28
		trunk_mesh.height = 5.4
		trunk_mesh.radial_segments = 6
		var trunk_node := MeshInstance3D.new()
		trunk_node.name = "PalmTrunk"
		trunk_node.mesh = trunk_mesh
		trunk_node.material_override = trunk
		trunk_node.position = Vector3.UP * 2.7
		palm.add_child(trunk_node)
		for blade in range(6):
			var angle: float = TAU * float(blade) / 6.0
			var leaf := _box(palm, "PalmLeaf", Vector3(0.9, 0.13, 4.6), Vector3(sin(angle) * 1.25, 5.50, cos(angle) * 1.25), frond)
			leaf.rotation = Vector3(0.27, angle, 0.0)

static func _add_city(layer: Node3D, title: String, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var white := _mat("#acb6b9")
	var steel := _mat("#5a6b76")
	var glass := _mat("#426675", 0.38)
	for k in range(11):
		var fraction: float = 0.04 + float(k) * 0.085
		var dist: float = 35.0 + float(k % 4) * 6.0
		var place: Dictionary = _anchor(centers, normals, widths, fraction, 1.0 if k % 2 else -1.0, dist)
		if place.is_empty():
			continue
		var building := Node3D.new()
		building.name = "UrbanBlock_%02d" % k
		building.position = place["pos"]
		building.rotation.y = float(place["rotation"])
		layer.add_child(building)
		var height: float = 14.0 + float(k % 5) * 4.0
		_box(building, "Facade", Vector3(12.0, height, 11.0), Vector3(0.0, height * 0.5, 0.0), white if k % 3 == 0 else steel)
		for floor_idx in range(1, int(height / 3.0)):
			_box(building, "Windows", Vector3(10.7, 1.2, 0.18), Vector3(0.0, float(floor_idx) * 2.75, 5.59), glass)
		_box(building, "Cornice", Vector3(13.0, 0.45, 11.7), Vector3(0.0, height + 0.2, 0.0), white)

static func _add_temperate(layer: Node3D, centers: Array[Vector3], normals: Array[Vector3], widths: Array[float]) -> void:
	var shell := _mat("#9ba8a5")
	var roof := _mat("#364d5c")
	for k in range(5):
		var place: Dictionary = _anchor(centers, normals, widths, [0.06, 0.26, 0.46, 0.71, 0.92][k], 1.0 if k % 2 else -1.0, 41.0)
		if place.is_empty():
			continue
		var lodge := Node3D.new()
		lodge.name = "CircuitService_%02d" % k
		lodge.position = place["pos"]
		lodge.rotation.y = float(place["rotation"])
		layer.add_child(lodge)
		_box(lodge, "ServiceBlock", Vector3(13.0, 4.6, 8.0), Vector3(0.0, 2.3, 0.0), shell)
		_box(lodge, "ServiceRoof", Vector3(14.5, 0.35, 9.4), Vector3(0.0, 4.7, 0.0), roof)
