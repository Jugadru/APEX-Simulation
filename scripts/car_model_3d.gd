extends Node3D
## APEX v0.5.2.3 — original, procedural Formula-style car for the 2012 grid.
## No external assets or other games' models, textures, or logos.
## All dimensions are in our simplified in-game world units.

const Precision = preload("res://scripts/apex_precision_mesh_0653.gd")

const WHEEL_RADIUS: float = 0.37
const CAR_HALF_LENGTH: float = 2.65
# Presentation contract: scaled mesh plus a conservative clearance margin.
# Validated against mesh AABB corners, including steering/DRS/body animation.
const PRESENTATION_SCALE := 0.78
const OCCUPATION_HALF_LENGTH := 2.40
const OCCUPATION_HALF_WIDTH := 1.25

var team_color: Color = Color.WHITE
var accent_color: Color = Color("#dae2ea")
var dark_material: StandardMaterial3D
var wheel_spins: Array[Node3D] = []
var wheel_sidewalls: Array[MeshInstance3D] = []
var tire_display_name: String = ""
var service_fraction: float = -1.0
var steering_pivots: Array[Node3D] = []
var chassis: Node3D
var steer_value: float = 0.0
var driven_meters: float = 0.0
var motion_speed := 0.0
var drs_flap: Node3D
var drs_angle := 0.0
# Visual-only switch: avoid setting four identical wheel visibilities every frame.
var pit_wheels_visible: bool = true

func _init(color_code: String = "#e74d4d", team: String = "", number: int = 1) -> void:
	team_color = Color.from_string(color_code, Color("#e74d4d"))
	# Distinctive, original accent colours; not copies of historical liveries.
	var team_lower: String = team.to_lower()
	if "ferrari" in team_lower:
		accent_color = Color("#fff2bd")
	elif "red bull" in team_lower:
		accent_color = Color("#edbe54")
	elif "mclaren" in team_lower:
		accent_color = Color("#f5aa5c")
	elif "lotus" in team_lower:
		accent_color = Color("#e1c766")
	elif "mercedes" in team_lower:
		accent_color = Color("#49e8de")
	else:
		accent_color = Color("#eaf2f2")
	name = "Car_%02d" % number
	_build_model(number)

func _mat(col: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = 0.30 if metal > 0.0 else 0.72
	m.clearcoat_enabled = metal > 0.0
	m.clearcoat = 0.65 if metal > 0.0 else 0.0
	m.clearcoat_roughness = 0.22
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _box(parent: Node3D, name_text: String, size: Vector3, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name_text
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _sphere(parent: Node3D, name_text: String, size: Vector3, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name_text
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 24
	mesh.rings = 12
	instance.mesh = mesh
	instance.scale = size
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: StandardMaterial3D) -> void:
	var between: Vector3 = b - a
	if between.length_squared() < 0.00001:
		return
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = between.length()
	cylinder.radial_segments = 6
	var instance := MeshInstance3D.new()
	instance.mesh = cylinder
	instance.material_override = material
	instance.position = (a + b) * 0.5
	instance.quaternion = Quaternion(Vector3.UP, between.normalized())
	parent.add_child(instance)

func _hull(parent: Node3D, paint: StandardMaterial3D) -> void:
	Precision.loft(parent,"SculptedNose",[Vector4(-2.48,.10,.44,.53),Vector4(-1.8,.17,.43,.64),Vector4(-1.05,.32,.35,.79),Vector4(-.65,.36,.35,.87)],paint)
	# Separate cockpit walls leave a real opening around the driver.
	for side in [-1.0,1.0]:
		Precision.loft(parent,"CockpitShoulder",[Vector4(-.70,.09,.35,.79),Vector4(-.3,.075,.38,.89),Vector4(.30,.09,.39,.92),Vector4(.65,.12,.40,.91)],paint,Vector3(side*.35,0,0))
	Precision.loft(parent,"EngineCover",[Vector4(.32,.27,.36,1.05),Vector4(.57,.23,.39,1.38),Vector4(.95,.19,.35,1.09),Vector4(1.6,.10,.34,.56),Vector4(1.86,.05,.35,.43)],paint)
	Precision.cockpit_rim(parent,_mat(Color("#101319")))
	_sphere(parent,"RecessedSeat",Vector3(.58,.22,.88),Vector3(0,.59,-.13),_mat(Color("#101217")))

func _loft(parent: Node3D, label: String, sections: Array[Vector4], paint: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(sections.size() - 1):
		var a: Vector4 = sections[i]
		var b: Vector4 = sections[i + 1]
		# top with sloped shoulders + underside + two side panels
		_quad(tool, Vector3(-a.y, a.w, a.x), Vector3(a.y, a.w, a.x), Vector3(b.y, b.w, b.x), Vector3(-b.y, b.w, b.x))
		_quad(tool, Vector3(a.y, a.z, a.x), Vector3(-a.y, a.z, a.x), Vector3(-b.y, b.z, b.x), Vector3(b.y, b.z, b.x))
		_quad(tool, Vector3(-a.y, a.z, a.x), Vector3(-a.y, a.w, a.x), Vector3(-b.y, b.w, b.x), Vector3(-b.y, b.z, b.x))
		_quad(tool, Vector3(a.y, a.w, a.x), Vector3(a.y, a.z, a.x), Vector3(b.y, b.z, b.x), Vector3(b.y, b.w, b.x))
	tool.generate_normals()
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = tool.commit()
	part.material_override = paint
	parent.add_child(part)

func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		tool.add_vertex(v)

func _wheel_mount(parent: Node3D, side: float, front: bool, tire: StandardMaterial3D, hub: StandardMaterial3D) -> void:
	var point := Vector3(side * 0.98, 0.39, -1.47 if front else 1.20)
	var pivot := Node3D.new()
	pivot.name = ("Front" if front else "Rear") + ("Right" if side > 0.0 else "Left")
	pivot.position = point
	parent.add_child(pivot)
	if front:
		steering_pivots.append(pivot)
	var spin := Node3D.new()
	spin.name = "WheelSpin"
	pivot.add_child(spin)
	wheel_spins.append(spin)
	Precision.tire(spin,0.33 if front else 0.40,tire)
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.205
	rim_mesh.bottom_radius = 0.205
	rim_mesh.height = 0.23 if front else 0.30
	rim_mesh.radial_segments = 24
	rim.mesh = rim_mesh
	rim.rotation_degrees.z = 90.0
	rim.material_override = _mat(Color("#191c20"),0.55)
	spin.add_child(rim)
	var hubcap := MeshInstance3D.new()
	hubcap.name = "HubCenter"
	var cap := CylinderMesh.new()
	cap.top_radius = 0.085
	cap.bottom_radius = 0.085
	cap.height = 0.35 if front else 0.42
	cap.radial_segments = 10
	hubcap.mesh = cap
	hubcap.rotation_degrees.z = 90.0
	hubcap.material_override = _mat(Color("#273440"), 0.22)
	spin.add_child(hubcap)
	# Sidewall stripe can be updated when a fresh tyre is fitted.
	var stripe := MeshInstance3D.new()
	stripe.name = "CompoundStripe"
	var disk := TorusMesh.new()
	disk.inner_radius = 0.285
	disk.outer_radius = 0.295
	disk.rings = 32
	disk.ring_segments = 8
	stripe.mesh = disk
	stripe.rotation_degrees.z = 90.0
	stripe.position.x = side * (0.175 if front else 0.210)
	stripe.material_override = _mat(Color("#f0f1e9"))
	spin.add_child(stripe)
	wheel_sidewalls.append(stripe)
	# Visible spokes give wheel rotation an actual reference, unlike a solid cylinder.
	for spoke in range(8):
		var angle := TAU * float(spoke) / 8.0
		var x := side * (0.178 if front else 0.213)
		_rod(spin, Vector3(x,cos(angle)*0.08,sin(angle)*0.08), Vector3(x,cos(angle)*0.20,sin(angle)*0.20),0.018,hub)

func _build_model(number: int) -> void:
	var paint := _mat(team_color, 0.48)
	paint.roughness = 0.23
	var accent := _mat(accent_color)
	var carbon := _mat(Color("#11161b"), 0.18)
	carbon.roughness = 0.48
	var tire := _mat(Color("#202123"))
	tire.roughness = 0.88
	var rims := _mat(Color("#8c98a0"), 0.4)
	var visor := _mat(Color("#243746"), 0.22)
	var suspension := _mat(Color("#474f59"), 0.45)

	chassis = Node3D.new()
	chassis.name = "ChassisVisual"
	add_child(chassis)
	_hull(chassis, paint)
	# 2012-era stepped nose, front wing layers and horizontal endplates.
	_box(chassis, "NoseStep", Vector3(0.29, 0.075, 0.53), Vector3(0.0, 0.665, -1.66), accent)
	Precision.foil(chassis,"FrontWingMain",2.53,.43,.055,Vector3(0,.22,-2.44),carbon)
	Precision.foil(chassis,"FrontWingFlap",2.17,.24,.035,Vector3(0,.32,-2.19),accent)
	Precision.foil(chassis,"FrontWingCascade",2.05,.16,.025,Vector3(0,.39,-2.07),carbon)
	for side in [-1.0, 1.0]:
		_box(chassis, "FrontWingEndplate", Vector3(0.065, 0.23, 0.58), Vector3(side * 1.29, 0.31, -2.38), paint)
		var pod := Node3D.new()
		pod.position.x = side * 0.60
		chassis.add_child(pod)
		Precision.loft(pod,"SculptedSidepod",[Vector4(-0.43,0.14,0.32,0.60),Vector4(-0.15,0.25,0.30,0.74),Vector4(0.65,0.22,0.29,0.66),Vector4(1.26,0.055,0.30,0.46)],paint)
		Precision.loft(pod,"PodLivery",[Vector4(-.05,.025,.737,.75),Vector4(.4,.025,.715,.728),Vector4(.8,.018,.59,.602)],accent,Vector3(side*.08,0,0))
		# 2012-style functional silhouettes: radiator intake, mirrors and winglet.
		_box(chassis, "SidepodInlet", Vector3(0.11, 0.22, 0.30), Vector3(side * 0.79, 0.70, -0.34), carbon)
		_box(chassis, "MirrorStalk", Vector3(0.055, 0.24, 0.06), Vector3(side * 0.72, 0.97, -0.39), suspension)
		_sphere(chassis, "MirrorCase", Vector3(0.25, 0.13, 0.16), Vector3(side * 0.79, 1.12, -0.40), paint)
		_box(chassis, "FrontWingOutboardFlap", Vector3(0.35, 0.054, 0.17), Vector3(side * 1.07, 0.40, -2.31), accent)
		_box(chassis, "RearWingEndplate", Vector3(0.07, 0.73, 0.42), Vector3(side * 0.77, 1.10, 1.86), carbon)
		for z in [-1.63, 1.17]:
			_rod(chassis, Vector3(side * 0.32, 0.48, z), Vector3(side * 0.93, 0.36, z), 0.029, suspension)
			_rod(chassis, Vector3(side * 0.38, 0.63, z + 0.18), Vector3(side * 0.94, 0.37, z), 0.026, suspension)
	Precision.foil(chassis,"RearWingPrimary",1.65,.39,.055,Vector3(0,1.40,1.85),paint)
	drs_flap = Node3D.new()
	drs_flap.name = "DRSHinge"
	drs_flap.position = Vector3(0.0,1.51,1.88)
	chassis.add_child(drs_flap)
	Precision.foil(drs_flap,"RearWingAccent",1.47,.25,.038,Vector3(0,0,-.12),accent)
	_box(chassis, "RearWingSupport", Vector3(0.17, 0.62, 0.25), Vector3(0.0, 1.0, 1.76), carbon)
	_box(chassis, "Floor",Vector3(1.65,0.055,2.7),Vector3(0,0.26,0.35),carbon)
	for fin in range(5):
		_box(chassis,"DiffuserFin",Vector3(0.035,0.22,0.55),Vector3((fin-2)*0.22,0.25,1.65),carbon)
	_box(chassis, "Diffuser", Vector3(1.02, 0.13, 0.45), Vector3(0.0, 0.33, 1.75), carbon)
	var rear_lamp := _mat(Color("#f44b4a"))
	rear_lamp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_box(chassis, "RainLightVisual", Vector3(0.17, 0.12, 0.09), Vector3(0.0, 0.38, 1.97), rear_lamp)
	_sphere(chassis, "DriverHelmet", Vector3(0.39, 0.43, 0.39), Vector3(0.0, 1.10, -0.15), accent)
	_sphere(chassis, "Visor", Vector3(0.35, 0.13, 0.14), Vector3(0.0, 1.11, -0.32), visor)
	_sphere(chassis,"AirIntake",Vector3(.24,.24,.06),Vector3(0,1.25,.36),carbon)
	_rod(chassis,Vector3(-.12,1.12,.43),Vector3(0,1.47,.49),.035,suspension)
	_rod(chassis,Vector3(.12,1.12,.43),Vector3(0,1.47,.49),.035,suspension)
	# Four independent wheel assemblies: turn fronts, rotate every wheel.
	for side in [-1.0, 1.0]:
		_wheel_mount(self, side, true, tire, rims)
		_wheel_mount(self, side, false, tire, rims)

	var disc := MeshInstance3D.new()
	disc.name = "FocusDisc"
	var ring := CylinderMesh.new()
	ring.top_radius = 2.05
	ring.bottom_radius = 2.05
	ring.height = 0.018
	disc.mesh = ring
	var golden := _mat(Color("#ffdb72"))
	golden.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	golden.albedo_color.a = 0.14
	golden.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = golden
	disc.position.y = 0.048
	add_child(disc)
	var player_ring := MeshInstance3D.new()
	player_ring.name = "PlayerRing"
	var pmesh := CylinderMesh.new()
	pmesh.top_radius = 1.78
	pmesh.bottom_radius = 1.78
	pmesh.height = 0.012
	player_ring.mesh = pmesh
	var white_ring := _mat(Color.WHITE)
	white_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white_ring.albedo_color.a = 0.08
	white_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	player_ring.material_override = white_ring
	player_ring.position.y = 0.041
	add_child(player_ring)

	# Only the focused car gets a small driver number tag.
	var tag := Label3D.new()
	tag.name = "NumberTag"
	tag.text = str(number)
	tag.font_size = 30
	tag.pixel_size = 0.014
	tag.position = Vector3(0.0, 1.96, 0.0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color.WHITE
	tag.outline_modulate = Color("#111820")
	tag.outline_size = 5
	add_child(tag)

func update_motion(traveled_distance: float, steering: float, delta: float) -> void:
	if delta <= 0.0: return
	var rate := 1.0-exp(-8.0*delta)
	steer_value = lerpf(steer_value, clampf(steering, -0.27, 0.27), rate)
	for front in steering_pivots:
		front.rotation.y = steer_value
	var distance := maxf(0.0,traveled_distance)
	for wheel in wheel_spins:
		wheel.rotation.x = fposmod(wheel.rotation.x + distance / WHEEL_RADIUS, TAU)
	driven_meters += distance
	var speed := distance / maxf(delta,0.001)
	var acceleration := clampf((speed-motion_speed)/maxf(delta,0.001),-15,15)
	motion_speed = lerpf(motion_speed,speed,rate)
	var vibration := 0.009 * sin(driven_meters*3.5) * clampf(speed/6.0,0,1)
	chassis.position.y = lerpf(chassis.position.y,vibration,rate)
	chassis.rotation.z = lerpf(chassis.rotation.z,-steer_value*0.11,rate)
	chassis.rotation.x = lerpf(chassis.rotation.x,-acceleration*0.0015,rate)

func set_race_animation(drs_open: bool, delta: float) -> void:
	drs_angle = lerpf(drs_angle, -0.48 if drs_open else 0.0, 1.0-exp(-9.0*maxf(delta,0.0)))
	drs_flap.rotation.x = drs_angle


func set_tire_compound(compound: String) -> void:
	if tire_display_name == compound:
		return
	tire_display_name = compound
	var color := Color("#f0eee2")  # 2012-style white medium
	if compound == "Macio":
		color = Color("#ffdb48")
	elif compound == "Duro":
		color = Color("#d1d6d9")
	elif compound == "Intermediário":
		color = Color("#48cf74")
	elif compound == "Chuva":
		color = Color("#4c8eff")
	for sidewall in wheel_sidewalls:
		sidewall.material_override = _mat(color)

func set_pit_wheel_swap(phase: float, begin_phase: float, end_phase: float) -> void:
	# A pit-service visual can hide wheels briefly; normal racing does not.
	# Reapply only on a state change (4 visibility setters avoided per car/frame).
	# Racing position, tyre physics and actual pit commands are not touched.
	var target_visible: bool = true
	if phase >= begin_phase and phase < end_phase:
		var t: float = clampf((phase - begin_phase) / maxf(0.001, end_phase - begin_phase), 0.0, 1.0)
		target_visible = not (t > 0.32 and t < 0.55)
	if target_visible == pit_wheels_visible:
		return
	pit_wheels_visible = target_visible
	for spin in wheel_spins:
		spin.visible = target_visible
