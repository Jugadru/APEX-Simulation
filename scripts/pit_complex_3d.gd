extends Node3D
## Apex Motorsport Manager v0.5.2.6: independent, continuous pit-lane spline.
## The 12 garages and service positions share exactly the same team-slot map.
## No teleport, reverse movement, or arbitrary blend back to the racing line.
## Generic 2012 pit-lane placement is illustrative, NOT an exact historical layout.

const MAX_SLOTS: int = 12
const LANE_X: float = 6.6
const STALL_X: float = 9.3
const GARAGE_FRONT_X: float = 13.0
const SLOT_START_Z: float = 16.0
const SLOT_SPACING: float = 3.45
const STOP_START: float = 0.43
const STOP_END: float = 0.57

var team_slots: Dictionary = {}
var team_paint: Dictionary = {}
var team_paths: Dictionary = {}
var crew_by_slot: Dictionary = {}
var crew_rigs: Dictionary = {}
var service_labels: Dictionary = {}
var service_frames: Dictionary = {}
var active_teams: Dictionary = {}
var lane_length: float = 75.0
var entry_heading: Vector3 = Vector3.BACK
var exit_heading: Vector3 = Vector3.BACK
var exit_local: Vector3 = Vector3(0.0, 0.08, 75.0)
var paint_white: StandardMaterial3D
var paint_asphalt: StandardMaterial3D
var paint_yellow: StandardMaterial3D

func _material(hex_color: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex_color)
	mat.roughness = 0.88
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _box(parent: Node3D, dims: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dims
	model.mesh = mesh
	model.material_override = mat
	model.position = at
	parent.add_child(model)
	return model

func prepare(entry_world: Vector3, forward: Vector3, exit_world: Vector3, exit_forward: Vector3, teams: Array) -> void:
	position = entry_world
	# The row of garages follows the chord between the precise track entry
	# and exit points; the end tangents stay aligned with the main circuit.
	var chord: Vector3 = exit_world - entry_world
	chord.y = 0.0
	if chord.length_squared() < 1.0:
		chord = forward
	chord = chord.normalized()
	var right := Vector3(chord.z, 0.0, -chord.x)
	basis = Basis(right, Vector3.UP, chord)
	lane_length = maxf(60.0, entry_world.distance_to(exit_world))
	exit_local = to_local(exit_world)
	exit_local.y = 0.08
	entry_heading = (basis.inverse() * forward).normalized()
	exit_heading = (basis.inverse() * exit_forward).normalized()
	if entry_heading.length_squared() < 0.01:
		entry_heading = Vector3.BACK
	if exit_heading.length_squared() < 0.01:
		exit_heading = Vector3.BACK

	paint_white = _material("#e0e8e1")
	paint_asphalt = _material("#323b45")
	paint_yellow = _material("#f4c55b")
	team_slots.clear()
	team_paint.clear()
	team_paths.clear()
	crew_by_slot.clear()
	crew_rigs.clear()
	service_labels.clear()
	service_frames.clear()
	active_teams.clear()
	for i in range(teams.size()):
		var t: Dictionary = teams[i]
		var team_name: String = str(t["name"])
		team_slots[team_name] = i
		team_paint[team_name] = _material(str(t.get("color", "#889fb0")))
		team_paths[team_name] = _make_team_path(i)
	_build_lane()
	_build_garages(teams)

func slot_for(team: String) -> int:
	return int(team_slots.get(team, -1))

func _slot_z(slot: int) -> float:
	return SLOT_START_Z + float(slot) * SLOT_SPACING

func local_stop_position(team: String, phase: float) -> Vector3:
	var data: Dictionary = team_paths.get(team, {})
	if data.is_empty():
		return Vector3.ZERO
	var p := clampf(phase, 0.0, 1.0)
	if p < STOP_START:
		return _sample_arc(data["entry"], p / STOP_START)
	if p <= STOP_END:
		return data["stall"]
	return _sample_arc(data["exit"], (p - STOP_END) / (1.0 - STOP_END))

func position_for_stop(team: String, phase: float) -> Vector3:
	return to_global(local_stop_position(team, phase))

func tangent_for_stop(team: String, phase: float) -> Vector3:
	var p := clampf(phase, 0.0, 1.0)
	var before: Vector3 = local_stop_position(team, maxf(0.0, p - 0.001))
	var after: Vector3 = local_stop_position(team, minf(1.0, p + 0.001))
	var movement: Vector3 = after - before
	# While stationary, keep the car pointing towards the pit exit (+Z).
	if movement.length_squared() < 0.00000001:
		movement = Vector3.BACK
	movement.y = 0.0
	return (basis * movement).normalized()

func stop_position(team: String) -> Vector3:
	return position_for_stop(team, 0.50)

func _bezier(a: Vector3, b: Vector3, c: Vector3, d: Vector3, steps: int = 28) -> PackedVector3Array:
	var output := PackedVector3Array()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var u: float = 1.0 - t
		output.append(a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)
	return output

func _append_curve(path: PackedVector3Array, curve: PackedVector3Array) -> void:
	for i in range(curve.size()):
		if path.size() == 0 or i > 0:
			path.append(curve[i])

func _with_length(points: PackedVector3Array) -> Dictionary:
	var lengths := PackedFloat32Array([0.0])
	for i in range(1, points.size()):
		lengths.append(lengths[i - 1] + points[i].distance_to(points[i - 1]))
	return {"points": points, "lengths": lengths, "total": maxf(0.0001, lengths[-1])}

func _sample_arc(data: Dictionary, t: float) -> Vector3:
	var points: PackedVector3Array = data["points"]
	var distances: PackedFloat32Array = data["lengths"]
	if t <= 0.0:
		return points[0]
	if t >= 1.0:
		return points[-1]
	var destination: float = t * float(data["total"])
	var lo: int = 0
	var hi: int = distances.size() - 1
	while hi - lo > 1:
		var mid: int = (lo + hi) / 2
		if distances[mid] < destination:
			lo = mid
		else:
			hi = mid
	var mix: float = (destination - distances[lo]) / maxf(0.00001, distances[hi] - distances[lo])
	return points[lo].lerp(points[hi], mix)

func _make_team_path(slot: int) -> Dictionary:
	var stall_z: float = _slot_z(slot)
	var entry := Vector3(0.0, 0.08, 0.0)
	var entry_lane := Vector3(LANE_X, 0.08, 10.0)
	var before_stall := Vector3(LANE_X, 0.08, stall_z - 3.3)
	var stall := Vector3(STALL_X, 0.08, stall_z)
	var after_stall := Vector3(LANE_X, 0.08, stall_z + 3.3)
	var exit_lane := Vector3(LANE_X, 0.08, maxf(stall_z + 7.0, exit_local.z - 8.0))
	# The last stall cannot be placed behind its service lane's exit.
	exit_lane.z = minf(exit_lane.z, exit_local.z - 5.0)
	var entry_path := PackedVector3Array()
	_append_curve(entry_path, _bezier(entry, entry + entry_heading * 4.2, entry_lane - Vector3(0.0, 0.0, 3.5), entry_lane))
	_append_curve(entry_path, _bezier(entry_lane, entry_lane + Vector3(0.0, 0.0, 1.2), before_stall - Vector3(0.0, 0.0, 1.2), before_stall))
	_append_curve(entry_path, _bezier(before_stall, before_stall + Vector3(0.0, 0.0, 1.2), stall - Vector3(0.0, 0.0, 1.2), stall))
	var exit_path := PackedVector3Array()
	_append_curve(exit_path, _bezier(stall, stall + Vector3(0.0, 0.0, 1.2), after_stall - Vector3(0.0, 0.0, 1.2), after_stall))
	_append_curve(exit_path, _bezier(after_stall, after_stall + Vector3(0.0, 0.0, 1.5), exit_lane - Vector3(0.0, 0.0, 1.5), exit_lane))
	_append_curve(exit_path, _bezier(exit_lane, exit_lane + Vector3(0.0, 0.0, 3.0), exit_local - exit_heading * 4.2, exit_local))
	return {"entry": _with_length(entry_path), "exit": _with_length(exit_path), "stall": stall}

func _ribbon(points: PackedVector3Array, width: float, material: Material) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var sides: Array[Vector3] = []
	for i in range(points.size()):
		var incoming: Vector3 = (points[i] - points[maxi(0,i-1)]).normalized()
		var outgoing: Vector3 = (points[mini(points.size()-1,i+1)] - points[i]).normalized()
		var tangent: Vector3 = (incoming + outgoing).normalized()
		if tangent.length_squared() < 0.00001: tangent = outgoing
		var side := Vector3(tangent.z,0,-tangent.x)
		var reference := Vector3(outgoing.z,0,-outgoing.x)
		var miter: float = 1.0 / maxf(.9,side.dot(reference)) if reference.length_squared()>.1 else 1.0
		sides.append(side * width * .5 * miter)
	for i in range(points.size() - 1):
		if points[i].distance_squared_to(points[i+1]) < 0.00001: continue
		# Shared cross sections remove the old radial gaps/overlaps. Clockwise
		# front faces agree with the upward normals (Godot convention).
		var quad := [points[i]-sides[i], points[i]+sides[i], points[i+1]-sides[i+1], points[i+1]+sides[i+1]]
		for ix in [0,1,2,1,3,2]:
			vertices.append(quad[ix] + Vector3.UP * 0.010)
			normals.append(Vector3.UP)
	if vertices.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface := MeshInstance3D.new()
	surface.name = "PitAccessRibbon"
	surface.mesh = mesh
	# Road ribbons are ground surfaces, not shadow-casting walls.
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.material_override = material
	add_child(surface)

func _build_lane() -> void:
	# Parallel service lane, joined to the actual circuit at BOTH ends.
	var z_center: float = exit_local.z * 0.5
	var length: float = exit_local.z - 12.0
	_box(self, Vector3(7.1, 0.025, length), Vector3(LANE_X + 1.0, 0.055, z_center), paint_asphalt)
	_box(self, Vector3(0.13, 0.04, length), Vector3(LANE_X - 2.45, 0.082, z_center), paint_yellow)
	_box(self, Vector3(0.13, 0.04, length), Vector3(LANE_X + 4.25, 0.082, z_center), paint_white)
	_box(self, Vector3(2.7, 0.035, length - 5.0), Vector3(GARAGE_FRONT_X - 1.35, 0.05, z_center), _material("#919d99"))
	# Meshes under the animated merging trajectories prevent floating cars.
	for path in [
		_bezier(Vector3(0.0, 0.077, 0.0), entry_heading * 4.2 + Vector3(0.0, 0.077, 0.0), Vector3(LANE_X, 0.077, 6.0), Vector3(LANE_X, 0.077, 10.0), 30),
		_bezier(Vector3(LANE_X, 0.077, exit_local.z - 8.0), Vector3(LANE_X, 0.077, exit_local.z - 4.5), exit_local - exit_heading * 3.8, exit_local, 30)
	]:
		_ribbon(path, 5.0, paint_asphalt)

func _build_garages(teams: Array) -> void:
	preload("res://scripts/circuit_life_0660.gd").pit_details(self,teams)
	var wall := _material("#74858d")
	var roof := _material("#b1c0c0")
	var shutter := _material("#1b2935")
	var crew_dark := _material("#17232c")
	var z_start: float = _slot_z(0) - 2.25
	var z_end: float = _slot_z(MAX_SLOTS - 1) + 2.25
	var z_mid: float = (z_start + z_end) * 0.5
	_box(self, Vector3(9.3, 4.25, z_end - z_start), Vector3(GARAGE_FRONT_X + 4.5, 2.17, z_mid), wall)
	_box(self, Vector3(10.7, 0.30, z_end - z_start + 1.6), Vector3(GARAGE_FRONT_X + 4.3, 4.41, z_mid), roof)
	for slot in range(mini(MAX_SLOTS, teams.size())):
		var team: Dictionary = teams[slot]
		var name_team: String = str(team["name"])
		var z: float = _slot_z(slot)
		var team_mat: Material = team_paint[name_team]
		_box(self, Vector3(0.13, 3.0, 2.85), Vector3(GARAGE_FRONT_X - 0.01, 1.86, z), shutter)
		_box(self, Vector3(0.17, 0.38, 2.88), Vector3(GARAGE_FRONT_X - 0.02, 3.74, z), team_mat)
		_box(self, Vector3(2.25, 0.022, 2.6), Vector3(STALL_X, 0.085, z), team_mat)
		var sign := Label3D.new()
		sign.text = "%02d %s" % [slot + 1, name_team]
		sign.font_size = 22
		sign.pixel_size = 0.018
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign.position = Vector3(GARAGE_FRONT_X - 0.10, 3.95, z)
		add_child(sign)
		var crew := Node3D.new()
		crew.name = "Equipe_%02d" % slot
		crew.position = Vector3(STALL_X, 0.0, z)
		add_child(crew)
		var rigs: Array = []
		for i in range(4):
			var side: float = -1.0 if i % 2 == 0 else 1.0
			var axle: float = 1.0 if i < 2 else -1.0
			var person := Node3D.new()
			person.name = "Mecanico_%d" % (i + 1)
			crew.add_child(person)
			# Simple team-colour overalls, gloves, helmet and articulated tool arm.
			_box(person, Vector3(0.42, 0.82, 0.37), Vector3(0.0, 0.69, 0.0), team_mat)
			var helmet := MeshInstance3D.new()
			var shell := SphereMesh.new();shell.radius=.21;shell.height=.43;shell.radial_segments=12;shell.rings=6
			helmet.mesh=shell;helmet.material_override=team_mat;helmet.position=Vector3(0,1.25,0);person.add_child(helmet)
			_box(person,Vector3(.31,.1,.08),Vector3(0,1.27,-.18),crew_dark)
			_box(person, Vector3(0.15, 0.38, 0.17), Vector3(-0.11, 0.24, 0.0), crew_dark)
			_box(person, Vector3(0.15, 0.38, 0.17), Vector3(0.11, 0.24, 0.0), crew_dark)
			var arm := Node3D.new()
			arm.name = "ToolArm"
			arm.position = Vector3(-side * 0.10, 1.0, 0.0)
			person.add_child(arm)
			_box(arm, Vector3(0.12, 0.48, 0.13), Vector3(-side * 0.09, -0.20, 0.0), team_mat)
			# Wheel gun is visible beside the tyre being serviced.
			_box(arm, Vector3(0.27, 0.14, 0.17), Vector3(-side * 0.18, -0.43, 0.0), crew_dark)
			var spare := MeshInstance3D.new()
			spare.name = "PneuNovo"
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.34
			mesh.bottom_radius = 0.34
			mesh.height = 0.28
			mesh.radial_segments = 14
			spare.mesh = mesh
			spare.rotation_degrees.z = 90.0
			spare.material_override = _material("#181d20")
			crew.add_child(spare)
			rigs.append({"person": person, "arm": arm, "wheel": spare, "side": side, "axle": axle})
		crew.visible = false
		crew_by_slot[slot] = crew
		crew_rigs[slot] = rigs
		var clock_label := Label3D.new()
		clock_label.name = "Cronometro_%02d" % slot
		clock_label.font_size = 25
		clock_label.pixel_size = 0.015
		clock_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		clock_label.position = Vector3(STALL_X, 2.1, z)
		clock_label.modulate = Color("#fff1aa")
		clock_label.outline_modulate = Color("#101a21")
		clock_label.outline_size = 5
		clock_label.visible = false
		add_child(clock_label)
		service_labels[slot] = clock_label

func update_active_teams(team_names: Array, simulation_clock: float) -> void:
	# Compatibility with the older 0.5.2.4 test interface.
	var frames: Array = []
	for team in team_names:
		frames.append({"team": str(team), "phase": 0.50, "service_elapsed": 0.0, "service_total": 3.5, "tire": "Médio"})
	update_pit_services(frames, simulation_clock)

func update_pit_services(services: Array, simulation_clock: float) -> void:
	# Four wheel crew members are animated only while their own car is at
	# its own stall. Every team's service uses the approved team-slot mapping.
	active_teams.clear()
	service_frames.clear()
	for service in services:
		var team: String = str(service.get("team", ""))
		var slot: int = slot_for(team)
		if slot < 0 or not crew_by_slot.has(slot):
			continue
		var stage: String = str(service.get("stage", "service"))
		var priorities: Dictionary = {"queue": 0, "approach": 1, "exit": 1, "dock": 2, "service": 3, "repair": 4, "safety_hold": 4}
		var old_stage: String = str(service_frames[slot].get("stage", "queue")) if service_frames.has(slot) else "queue"
		if not service_frames.has(slot) or int(priorities.get(stage, 0)) > int(priorities.get(old_stage, 0)):
			active_teams[team] = true
			service_frames[slot] = service
	for key in crew_by_slot.keys():
		var slot: int = int(key)
		var group: Node3D = crew_by_slot[slot]
		var text_label: Label3D = service_labels[slot]
		if not service_frames.has(slot):
			group.visible = false
			text_label.visible = false
			continue
		var state: Dictionary = service_frames[slot]
		var phase: float = clampf(float(state.get("phase", 0.0)), 0.0, 1.0)
		var service_stage: String = str(state.get("stage", "service"))
		var in_service: bool = service_stage in ["service", "dock", "repair", "safety_hold"] or (service_stage == "exit" and phase <= STOP_END + 0.05)
		group.visible = in_service
		text_label.visible = in_service
		if not in_service:
			continue
		var t: float = clampf((phase - STOP_START) / (STOP_END - STOP_START), 0.0, 1.0)
		var approach: float = smoothstep(0.0, 0.22, t)
		var retreat: float = smoothstep(0.75, 1.0, t)
		for item in crew_rigs[slot]:
			var side: float = float(item["side"])
			var axle: float = float(item["axle"])
			var person: Node3D = item["person"]
			var arm: Node3D = item["arm"]
			var spare: MeshInstance3D = item["wheel"]
			var active_distance: float = 3.0 - 1.55 * approach + 1.55 * retreat
			person.position = Vector3(side * active_distance, 0.0, axle * 1.18)
			arm.rotation.z = side * (-0.30 + sin(t * TAU * 4.0 + axle) * 0.20) * approach * (1.0 - retreat)
			spare.visible = t > 0.18 and t < 0.84
			var wheel_place: float = 1.5 - 0.67 * smoothstep(0.22, 0.65, t)
			spare.position = Vector3(side * wheel_place, 0.44, axle * 1.15)
			spare.rotation.x = t * TAU * 0.45
		var elapsed: float = float(state.get("service_elapsed", 0.0))
		var total: float = maxf(0.01, float(state.get("service_total", 3.5)))
		var caption := "PREPARANDO"
		if phase >= STOP_START and phase <= STOP_END:
			caption = "TROCA  %.2f / %.2f s" % [elapsed, total]
		elif phase > STOP_END:
			caption = "LIBERADO  %.2f s" % total
		if service_stage == "repair":
			caption = "FALHA NO BOX  +%.1fs" % float(state.get("hold_left", 0.0))
		elif service_stage == "safety_hold":
			caption = "SEGURANÇA  RETIDO +%.1fs" % float(state.get("hold_left", 0.0))
		text_label.text = caption
