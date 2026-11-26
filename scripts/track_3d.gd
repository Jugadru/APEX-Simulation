extends Node3D
const ProjectionIndex = preload("res://scripts/track_projection_index_0659.gd")
var projection_index := ProjectionIndex.new()
var projection_hints: Dictionary = {}
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")

const BattleMotion = preload("res://scripts/apex_racecraft_0654.gd")
var occupation: Dictionary = {}
var previous_nominal: Dictionary = {}
var grid_slots: Dictionary = {}
var pose_anchors: Dictionary = {}
var visual_lanes: Dictionary = {}

const CarModelScript = preload("res://scripts/car_model_3d.gd")
const PitComplexScript = preload("res://scripts/pit_complex_3d.gd")
const CircuitSceneryScript = preload("res://scripts/apex_circuit_scenery_0628.gd")
const CircuitDetailScript = preload("res://scripts/apex_circuit_detail_0629.gd")
## True Godot 3D view, rendered inside a separate SubViewport.
## Uses the same rounded route. Racecraft may delay the visual pose to keep
## occupied bodies separate; authoritative race timing remains in the engine.

# The 2D centerline is unchanged. Only its 3D world scale and road mesh change.
# v0.5.1.27 drew very broad quads using a *different* tangent for every
# little segment: the corners tore open into long, thin triangles.
const WORLD_SCALE: float = 0.60
# Monaco's compressed visual centerline produces hairpins narrower than
# the actual car footprint. Only the 3D display scale changes; the 2D map,
# sporting arc, circuit length, classification and model dimensions stay.
const MONACO_VISUAL_WORLD_SCALE: float = 0.90
const MONACO_MIN_ASPHALT_HALF_WIDTH: float = CarModelScript.OCCUPATION_HALF_WIDTH + 0.20
var visual_world_scale: float = WORLD_SCALE
const ROAD_HALF: float = 4.40
const SHOULDER_MULTIPLIER: float = 1.18
const RUNOFF_MULTIPLIER: float = 1.38
const CURB_BLOCK_METERS: float = 1.3

# Shared cross-sections prevent adjacent quads from having separate edges.
var road_centers: Array[Vector3] = []
var road_normals: Array[Vector3] = []
var road_widths: Array[float] = []
var road_outer_widths: Array[float] = []
var road_distances: Array[float] = []

var world_environment_3d: WorldEnvironment
var camera_3d: Camera3D
var course_root: Node3D
var car_root: Node3D
var live_cars: Dictionary = {}
# Presentation-only references: nodes stay stable for the lifetime of a car model.
var marker_cache: Dictionary = {}
var last_positions: Dictionary = {}
var models_created: int = 0
var route: PackedVector2Array = PackedVector2Array()
var focus_point: Vector3 = Vector3.ZERO
var magnification: float = 2.1
var course_name: String = "Spa-Francorchamps"
var pit_complex: Node3D
var pit_visual_phase: Dictionary = {}
var camera_mode_3d: String = "overview"
var broadcast_focus_id: int = -1
var camera_look_target: Vector3 = Vector3.ZERO
var free_camera_offset: Vector3 = Vector3(0.0, 110.0, 90.0)

func _ready() -> void:
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		get_viewport().use_taa = true
	# Separate sub-viewport world with its own ambient and directional light.
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#b3c6d2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color("#dce8df")
	env.ambient_light_energy = 0.65
	env.ambient_light_sky_contribution = 0.65
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("#527eaa")
	atmosphere.sky_horizon_color = Color("#c6d7de")
	atmosphere.ground_bottom_color = Color("#29352e")
	atmosphere.ground_horizon_color = Color("#b4c4bd")
	atmosphere.sky_energy_multiplier = 0.6
	atmosphere.ground_energy_multiplier = 0.3
	sky.sky_material = atmosphere
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.1
	world_env.environment = env
	world_environment_3d = world_env
	add_child(world_env)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.15
	light.light_color = Color("#fff7ed")
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = 240.0
	# Rendering-only profile, selected at launch; no engine/physics changes.
	if OS.get_environment("APEX_GRAPHICS_PROFILE") == "gtx1650":
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		light.directional_shadow_max_distance = 160.0
		env.ssao_enabled = false
	light.shadow_bias = 0.015
	light.shadow_normal_bias = 0.7
	light.light_angular_distance = 0.5
	light.rotation_degrees = Vector3(-57, -30, 0)
	add_child(light)
	course_root = Node3D.new()
	course_root.name = "Circuit3D"
	add_child(course_root)
	car_root = Node3D.new()
	car_root.name = "Carros3D"
	add_child(car_root)
	camera_3d = Camera3D.new()
	camera_3d.current = true
	camera_3d.fov = 56.0
	camera_3d.near = 2.0 # Reduce distant asphalt z-fighting in aerial camera
	camera_3d.far = 1800.0
	add_child(camera_3d)
	_apply_camera()

func set_track_data(track: PackedVector2Array, title: String, teams: Array = [],
		entry_ref: Vector2 = Vector2.ZERO, entry_dir: Vector2 = Vector2.ZERO,
		exit_ref: Vector2 = Vector2.ZERO, exit_dir: Vector2 = Vector2.ZERO) -> void:
	# Used for the whole 2012 calendar, including Suzuka's genuine crossing.
	# The road geometry and 2D route are the approved v0.5.2.1 versions.
	last_positions.clear()
	pose_anchors.clear()
	projection_hints.clear()
	visual_lanes.clear()
	occupation.clear()
	previous_nominal.clear()
	grid_slots.clear()
	live_cars.clear()
	marker_cache.clear()
	pit_visual_phase.clear()
	if car_root != null:
		for old_car in car_root.get_children():
			car_root.remove_child(old_car)
			old_car.queue_free()
	route = track.duplicate()
	course_name = title
	visual_world_scale = MONACO_VISUAL_WORLD_SCALE if title == "Circuit de Monaco" else WORLD_SCALE
	var palette: Dictionary = CircuitSceneryScript.palette_for(title)
	if world_environment_3d != null and world_environment_3d.environment != null:
		world_environment_3d.environment.background_color = Color(str(palette["sky"]))
	if course_root == null:
		return
	for old_node in course_root.get_children():
		course_root.remove_child(old_node)
		old_node.queue_free()
	_build_scenery()
	_build_road()
	projection_index.build(road_centers)
	_build_environment_details()
	preload("res://scripts/circuit_life_0660.gd").install(self)
	pit_complex = PitComplexScript.new()
	pit_complex.name = "PitComplex"
	course_root.add_child(pit_complex)
	# Exact endpoints from the map's ARC-LENGTH parameterization. Never use
	# the world viewport's index-based approximation for pit entry/exit.
	if entry_ref == Vector2.ZERO:
		entry_ref = _point_on_route(0.950)
	if exit_ref == Vector2.ZERO:
		exit_ref = _point_on_route(0.025)
	if entry_dir.length_squared() < 0.0001:
		entry_dir = _direction_on_route(0.950)
	if exit_dir.length_squared() < 0.0001:
		exit_dir = _direction_on_route(0.025)
	pit_complex.prepare(_to_world(entry_ref), Vector3(entry_dir.x, 0.0, entry_dir.y),
		_to_world(exit_ref), Vector3(exit_dir.x, 0.0, exit_dir.y), teams)
	focus_point = Vector3.ZERO
	camera_mode_3d = "overview"
	broadcast_focus_id = -1
	_apply_camera()

func set_race_cars(cars: Array, selected_id: int, motion_delta: float = -1.0) -> void:
	if car_root == null:
		return
	var active: Dictionary = {}
	var pitting_teams: Array = []
	var servicing_cars: Array = []
	var delta: float = maxf(0.0, get_process_delta_time() if motion_delta < 0.0 else motion_delta)
	pose_anchors.clear()
	var perf_occupation := Perf.begin() if Perf.enabled else 0
	var prior_occupation: Dictionary = occupation if Perf.enabled else {}
	var prior_nominal: Dictionary = previous_nominal if Perf.enabled else {}
	occupation = BattleMotion.solve_interval(cars,occupation,delta,_sample_occupied_pose,previous_nominal)
	previous_nominal = BattleMotion.nominal_history(cars)
	if Perf.enabled:
		Perf.end(&"visual.occupancy",perf_occupation)
		for id in occupation:
			var pose: Dictionary = occupation[id]
			if delta>0.0 and prior_occupation.has(id) and prior_nominal.has(id) and previous_nominal.has(id):
				var before: Dictionary = prior_nominal[id]
				var after: Dictionary = previous_nominal[id]
				if before.stage==after.stage:
					var arc_step: float = (float(after.progress)-float(before.progress))*float(pose.get("route_length",0.0))
					if arc_step>=0.015 and Vector2(pose.position).distance_squared_to(Vector2(prior_occupation[id].position))<0.015*0.015:
						Perf.count(&"visual.traffic_nominal_advancing_stalled")
					elif arc_step>=0.0 and arc_step<0.015:
						Perf.count(&"visual.traffic_nominal_low_advance")
			if int(pose.get("hold_frames",0)) > 0:
				Perf.count(&"visual.occupancy_stalled_car_frames")
			if bool(pose.get("resynced",false)):
				Perf.count(&"visual.occupancy_recovered_car_frames")
	for car in cars:
		var id: int = int(car.get("id", -1))
		active[id] = true
		if not live_cars.has(id):
			live_cars[id] = _create_car(str(car.get("color", "#dddddd")), str(car.get("team", "")), id + 1)
		var model: Node3D = live_cars[id]
		# Resolve scene nodes once per model, not four times on every frame.
		# The cache contains no sporting state and is cleared with the models.
		if not marker_cache.has(id):
			var tag := Label3D.new()
			tag.name = "QueueTag"
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.font_size = 25
			tag.pixel_size = 0.012
			tag.position = Vector3(0.0, 2.6, 0.0)
			tag.modulate = Color("#ffce75")
			tag.outline_modulate = Color("#151b20")
			tag.outline_size = 4
			model.add_child(tag)
			marker_cache[id] = {
				"queue": tag,
				"focus": model.get_node("FocusDisc"),
				"player": model.get_node("PlayerRing"),
				"number": model.get_node("NumberTag")
			}
		var markers: Dictionary = marker_cache[id]
		var queue_tag: Label3D = markers["queue"]
		var stage: String = str(car.get("pit_stage", "none"))
		queue_tag.visible = stage in ["queue", "repair", "safety_hold"]
		if stage == "queue":
			queue_tag.text = "FILA +%.1fs" % float(car.get("pit_wait", 0.0))
			queue_tag.modulate = Color("#ffce75")
		elif stage == "repair":
			queue_tag.text = "FALHA MECÂNICA +%.1fs" % maxf(0.0, float(car.get("pit_service_delay", 0.0)) - float(car.get("pit_stage_elapsed", 0.0)))
			queue_tag.modulate = Color("#ff806c")
		elif stage == "safety_hold":
			queue_tag.text = "RETIDO +%.1fs" % maxf(0.0, float(car.get("pit_release_delay", 0.0)) - float(car.get("pit_stage_elapsed", 0.0)))
			queue_tag.modulate = Color("#ff806c")
		var progress: float = float(car.get("progress", 0.0))
		var position_2d: Vector2 = car.route_point if car.has("route_point") else _point_on_route(progress)
		var direction_2d: Vector2 = car.route_direction if car.has("route_direction") else _direction_on_route(progress)
		var target_world: Vector3 = _to_world(position_2d) + Vector3(0.0, 0.055, 0.0)
		var movement_direction := Vector3(direction_2d.x, 0.0, direction_2d.y)
		var in_pit: bool = float(car.get("pit_left", 0.0)) > 0.001 and pit_complex != null
		if in_pit:
			model.visible = true
			var phase: float = clampf(float(car.get("pit_phase", 0.0)), 0.0, 1.0)
			var team: String = str(car.get("team", ""))
			target_world = pit_complex.position_for_stop(team, phase)
			movement_direction = pit_complex.tangent_for_stop(team, phase)
			pitting_teams.append(team)
			servicing_cars.append({
				"team": team,
				"stage": stage,
				"phase": phase,
				"service_elapsed": float(car.get("pit_service_elapsed", 0.0)),
				"service_total": float(car.get("pit_service_total", 0.0)),
				"hold_left": maxf(0.0, (float(car.get("pit_service_delay", 0.0)) if stage == "repair" else float(car.get("pit_release_delay", 0.0))) - float(car.get("pit_stage_elapsed", 0.0))),
				"tire": str(car.get("pit_target", car.get("tire", "Médio")))
			})
			pit_visual_phase[id] = phase
		else:
			pit_visual_phase.erase(id)
			if occupation.has(id):
				var pose: Dictionary = occupation[id]
				target_world = Vector3(pose.position.x,0.055,pose.position.y)
				movement_direction = Vector3(pose.direction.x,0,pose.direction.y)
				visual_lanes[id] = float(pose.lane)
				model.visible = bool(pose.get("visible",true))
			else:
				model.visible = true

		var distance: float = 0.0
		if last_positions.has(id):
			distance = minf(target_world.distance_to(last_positions[id]), 5.0)
		last_positions[id] = target_world
		var newly_created: bool = not model.has_meta("placed")
		model.position = target_world
		model.set_meta("placed",true)
		if movement_direction.length_squared() > 0.0000001:
			var heading: float = atan2(-movement_direction.x, -movement_direction.z)
			model.rotation.y = heading if not in_pit or newly_created else lerp_angle(model.rotation.y, heading, 1.0-exp(-12.0*delta))
		var steering: float = 0.0
		if not in_pit:
			var prior: Vector2 = _direction_on_route(progress - 0.0018)
			var future: Vector2 = _direction_on_route(progress + 0.0018)
			steering = clampf(prior.cross(future) * 0.60, -0.24, 0.24)
		model.call("update_motion", distance, steering, delta)
		model.call("set_race_animation", bool(car.get("drs_active",false)) and not in_pit, delta)
		model.call("set_tire_compound", str(car.get("tire", "Médio")))
		var wheel_visual_phase: float = float(car.get("pit_phase", 0.0)) if in_pit else -1.0
		if stage == "repair":
			wheel_visual_phase = 0.52  # tyre still being serviced, visual state only
		model.call("set_pit_wheel_swap", wheel_visual_phase,
			PitComplexScript.STOP_START, PitComplexScript.STOP_END)
		(markers["focus"] as MeshInstance3D).visible = id == selected_id
		(markers["player"] as MeshInstance3D).visible = bool(car.get("player", false)) and id != selected_id
		(markers["number"] as Label3D).visible = id == selected_id
	if pit_complex != null:
		pit_complex.update_pit_services(servicing_cars, float(Time.get_ticks_msec()) * 0.001)
	for existing in live_cars.keys():
		if not active.has(existing):
			var old: Node3D = live_cars[existing]
			car_root.remove_child(old)
			old.queue_free()
			live_cars.erase(existing)
			marker_cache.erase(existing)
			last_positions.erase(existing)
			visual_lanes.erase(existing)
			pit_visual_phase.erase(existing)
			projection_hints.erase(existing)

# Mark the actual sporting grid, not a second independently spaced grid.
# Position and heading use precisely the same sampler as live occupation.
func build_start_grid(cars: Array, map: Object) -> void:
	grid_slots.clear()
	pose_anchors.clear()
	var prior := course_root.get_node_or_null("StartingGrid")
	if prior != null:
		course_root.remove_child(prior)
		prior.queue_free()
	var marks := Node3D.new()
	marks.name = "StartingGrid"
	course_root.add_child(marks)
	var paint := _material("#f2f0e8")
	for source in cars:
		var car: Dictionary = source.duplicate()
		car.route_point = map.point_on_track(float(car.progress))
		car.route_direction = map.direction_on_track(float(car.progress))
		var pose := _sample_occupied_pose(car,float(car.get("race_lane",0.0)),0.0)
		var slot := int(car.grid)
		grid_slots[slot] = pose.duplicate()
		if slot == 1:
			# The sporting timing origin remains progress=0 (car centre).
			# Paint the visible start stripe just beyond the pole stop box;
			# it is a presentation marker, not an engine timing trigger.
			var stripe := course_root.get_node_or_null("StartFinishLine") as MeshInstance3D
			if stripe != null:
				var start_pose := _sample_occupied_pose(car,0.0,-3.5)
				stripe.position = Vector3(start_pose.position.x,0.103,start_pose.position.y)
				stripe.rotation.y = atan2(-float(start_pose.direction.x),-float(start_pose.direction.y))
				var stripe_mesh := stripe.mesh as BoxMesh
				stripe_mesh.size.x = float(start_pose.road_half_width)*1.8
		var mark := Node3D.new()
		mark.name = "P%02d" % slot
		marks.add_child(mark)
		mark.position = Vector3(pose.position.x,0.112,pose.position.y)
		mark.rotation.y = atan2(-float(pose.direction.x),-float(pose.direction.y))
		var half_width := CarModelScript.OCCUPATION_HALF_WIDTH+0.08
		var half_length := CarModelScript.OCCUPATION_HALF_LENGTH+0.08
		# U-shaped starting box, with a transverse front stop line.
		_box(mark,Vector3(half_width*2,0.012,0.10),Vector3(0,0,-half_length),paint)
		for side in [-1.0,1.0]:
			_box(mark,Vector3(0.10,0.012,half_length*2),Vector3(side*half_width,0,0),paint)
		var number := Label3D.new()
		number.text = "P%d" % slot
		number.font_size = 32
		number.pixel_size = 0.018
		number.outline_size = 4
		number.rotation.x = -PI/2.0
		number.position = Vector3(0,0.015,half_length+0.35)
		mark.add_child(number)
	pose_anchors.clear()

func _sample_occupied_pose_legacy(car: Dictionary, requested_lane: float, retreat: float) -> Dictionary:
	var pose := _sample_occupied_pose(car,requested_lane,retreat)
	pose.erase("half_length")
	pose.erase("half_width")
	pose.erase("route_length")
	pose.erase("road_half_width")
	return pose

func _sample_occupied_pose(car: Dictionary, requested_lane: float, retreat: float) -> Dictionary:
	var perf_started := Perf.begin() if Perf.enabled else 0
	var id := int(car.id)
	if not pose_anchors.has(id):
		var origin := _to_world(car.route_point)
		var anchor := projection_index.project(origin,int(projection_hints.get(id,-1)))
		pose_anchors[id] = anchor
		projection_hints[id] = anchor.nearest

	var nearest: int = pose_anchors[id].nearest
	var along: float = pose_anchors[id].along
	var total := projection_index.total_length
	var distance := fposmod(road_distances[nearest]+along-retreat,total)
	var index := road_distances.bsearch(distance,true)-1
	index = clampi(index,0,road_centers.size()-1)
	var next := (index+1)%road_centers.size()
	var length: float = projection_index.lengths[index]
	var t := clampf((distance-road_distances[index])/maxf(.000001,length),0,1)
	var center := road_centers[index].lerp(road_centers[next],t)
	var side := road_normals[index].lerp(road_normals[next],t).normalized()
	var direction := Vector3(side.z,0,-side.x)
	var width := lerpf(road_widths[index],road_widths[next],t)
	var lane := clampf(requested_lane,-maxf(0,width-1.45),maxf(0,width-1.45))
	var position := center+side*lane
	var perf_result_32 = {"position":Vector2(position.x,position.z),"direction":Vector2(direction.x,direction.z),"lane":lane,"progress":float(car.progress)-retreat/maxf(total,1)}
	perf_result_32["road_half_width"] = width
	perf_result_32["route_length"] = total
	perf_result_32["arc_distance"] = distance
	if not road_outer_widths.is_empty():
		perf_result_32["arc_sweep_max_steps"] = 64
	perf_result_32["half_length"] = CarModelScript.OCCUPATION_HALF_LENGTH
	perf_result_32["half_width"] = CarModelScript.OCCUPATION_HALF_WIDTH
	if Perf.enabled: Perf.end(&"route.3d_occupied_pose",perf_started)
	return perf_result_32

func get_pit_camera_target(car_id: int) -> Vector3:
	if live_cars.has(car_id):
		var car_model: Node3D = live_cars[car_id]
		if is_instance_valid(car_model):
			return car_model.global_position
	return _to_world(_point_on_route(0.0))

func track_point_to_world(pos: Vector2) -> Vector3:
	return _to_world(pos)

func set_zoom(zoom_level: float) -> void:
	magnification = clampf(zoom_level, 0.65, 4.5)
	# Important: broadcast views own their world-space camera transform.
	# Resetting _apply_camera() here used to teleport every TV / follow shot
	# back to the circuit centre on EVERY FRAME.
	if camera_mode_3d == "overview":
		_apply_camera()

func set_follow(target: Vector2, delta: float) -> void:
	camera_mode_3d = "overview"
	focus_point = focus_point.lerp(_to_world(target), clampf(delta * 2.2, 0.0, 1.0))
	_apply_camera()

func set_broadcast_view(primary: Vector2, direction: Vector2, secondary: Variant, style: String, delta: float, focused_car_id: int = -1) -> void:
	# 0.6.2.6: every tracking view frames the *racing situation*, not only
	# a point of asphalt. The director supplies an actual neighbor when possible.
	if camera_3d == null:
		return
	var valid_style: String = style
	if not (valid_style in ["chase", "battle", "corner", "helicopter", "aerial", "trackside", "pit"]):
		valid_style = "aerial"
	var previous_mode: String = camera_mode_3d
	var switching: bool = camera_mode_3d != valid_style
	var changed_subject: bool = focused_car_id >= 0 and focused_car_id != broadcast_focus_id
	camera_mode_3d = valid_style
	var p: Vector3 = _to_world(primary)
	var dir3: Vector3 = Vector3(direction.x, 0.0, direction.y)
	if dir3.length_squared() < 0.000001:
		dir3 = Vector3.FORWARD
	else:
		dir3 = dir3.normalized()
	var right: Vector3 = Vector3(-dir3.z, 0.0, dir3.x)
	var companion: Vector3 = p
	var have_companion: bool = typeof(secondary) == TYPE_VECTOR2
	if have_companion:
		companion = _to_world(secondary)
	var spread: float = p.distance_to(companion) if have_companion else 0.0
	# Cars on distant sections or on a crossing can be geographically close;
	# the view-controller only supplies opponents from the same race segment.
	if spread > 84.0:
		have_companion = false
		spread = 0.0
	var midpoint: Vector3 = p.lerp(companion, 0.5) if have_companion else p
	var distance_scale: float = clampf((1.72 if valid_style == "aerial" else 2.10) / magnification, 0.66, 1.63)
	# A duel tens of metres apart cannot use the same tight lens as a side-by-
	# side attack. Gently expand the camera rather than clipping a rival.
	if have_companion and valid_style in ["battle", "corner", "trackside"]:
		distance_scale *= lerpf(1.0, 1.50, clampf((spread - 28.0) / 48.0, 0.0, 1.0))
	var look_at_point: Vector3 = midpoint + dir3 * 4.0 + Vector3.UP * 0.9
	var camera_offset: Vector3 = -dir3 * 9.0 + Vector3.UP * 23.0
	var target_fov: float = 56.0
	if valid_style == "aerial":
		# Primary high strategic view: moderate angle + space ahead of the cars;
		# spread expands the shot only when there is a second nearby car.
		look_at_point = midpoint + dir3 * 7.0 + Vector3.UP * 0.7
		camera_offset = -dir3 * (15.0 + spread * 0.14) + right * 4.0 + Vector3.UP * (34.0 + spread * 0.32)
	elif valid_style == "chase":
		camera_offset = -dir3 * (16.0 + spread * 0.18) + right * (2.5 + spread * 0.05) + Vector3.UP * (13.0 + spread * 0.36)
		look_at_point = midpoint + dir3 * 2.5 + Vector3.UP * 0.9
	elif valid_style == "battle":
		# Broadcast duel: centred on the actual pair, lower than the original
		# overhead view without cutting off the chasing car.
		look_at_point = midpoint + dir3 * 1.0 + Vector3.UP * 0.85
		camera_offset = -dir3 * (19.0 + spread * 0.50) + right * (11.0 + spread * 0.14) + Vector3.UP * (13.0 + spread * 0.50)
		target_fov = 51.0
	elif valid_style == "corner":
		# Camera on the outside of a corner, aimed towards the cars rather
		# than looking vertically down at a patch of grass.
		look_at_point = midpoint + dir3 * 1.0 + Vector3.UP * 0.85
		camera_offset = right * (19.0 + spread * 0.30) - dir3 * (13.0 + spread * 0.36) + Vector3.UP * (10.0 + spread * 0.53)
		target_fov = 50.0
	elif valid_style == "trackside":
		look_at_point = midpoint + dir3 * 1.0 + Vector3.UP * 0.85
		camera_offset = -right * (21.0 + spread * 0.32) - dir3 * (13.0 + spread * 0.34) + Vector3.UP * (10.0 + spread * 0.53)
		target_fov = 50.0
	elif valid_style == "helicopter":
		look_at_point = midpoint + dir3 * 0.8 + Vector3.UP * 0.8
		camera_offset = right * 4.0 - dir3 * (22.0 + spread * 0.60) + Vector3.UP * (36.0 + spread * 0.70)
	elif valid_style == "pit":
		if focused_car_id >= 0 and live_cars.has(focused_car_id):
			look_at_point = get_pit_camera_target(focused_car_id) + Vector3.UP * 1.0
		camera_offset = right * 13.0 - dir3 * 14.0 + Vector3.UP * 10.0
	var desired_position: Vector3 = look_at_point + camera_offset * distance_scale
	# TV cameras CUT between remote sectors instead of visibly flying over
	# empty terrain. Within a scene, ease camera movement/angle/FOV together.
	var remote_cut: bool = changed_subject and camera_3d.position.distance_to(desired_position) > 105.0
	if previous_mode == "overview" or remote_cut:
		camera_3d.position = desired_position
		camera_look_target = look_at_point
		camera_3d.fov = target_fov
	else:
		var movement_rate: float = 2.8 if switching else 4.2
		var alpha: float = clampf(1.0 - exp(-maxf(delta, 0.0) * movement_rate), 0.0, 1.0)
		camera_3d.position = camera_3d.position.lerp(desired_position, alpha)
		camera_look_target = camera_look_target.lerp(look_at_point, alpha)
		camera_3d.fov = lerpf(camera_3d.fov, target_fov, alpha)
	broadcast_focus_id = focused_car_id
	if camera_3d.position.distance_squared_to(camera_look_target) > 0.1:
		camera_3d.look_at(camera_look_target, Vector3.UP)

func enter_free_view() -> void:
	# Switch from a live TV tracking shot into a movable overview without
	# jumping back to the middle of the circuit.
	if camera_mode_3d != "overview":
		focus_point = Vector3(camera_look_target.x, 0.0, camera_look_target.z)
	camera_mode_3d = "overview"
	broadcast_focus_id = -1
	_apply_camera()

func pan_by(delta_pixels: Vector2) -> void:
	# Pan follows the camera's projected horizontal frame; used in Free mode.
	camera_mode_3d = "overview"
	focus_point.x -= delta_pixels.x * 0.18 / magnification
	focus_point.z -= delta_pixels.y * 0.27 / magnification
	_apply_camera()

func center_track() -> void:
	camera_mode_3d = "overview"
	focus_point = Vector3.ZERO
	_apply_camera()

func _apply_camera() -> void:
	if camera_3d == null:
		return
	# The free camera keeps the original overview field of view.
	camera_3d.fov = 56.0
	var height: float = clampf(220.0 / magnification, 32.0, 310.0)
	free_camera_offset = Vector3(0.0, height, height * 0.82)
	var target_pos := focus_point + free_camera_offset
	camera_3d.position = target_pos
	camera_look_target = focus_point
	camera_3d.look_at(camera_look_target, Vector3.UP)

func _to_world(p: Vector2) -> Vector3:
	return Vector3((p.x - 550.0) * visual_world_scale, 0.0, (p.y - 450.0) * visual_world_scale)

func _point_on_route(progress: float) -> Vector2:
	var perf_started := Perf.begin() if Perf.enabled else 0
	if route.size() < 2:
		var perf_result_1 = Vector2.ZERO
		if Perf.enabled: Perf.end(&"route.3d_position",perf_started)
		return perf_result_1
	var idx: float = fposmod(progress, 1.0) * float(route.size() - 1)
	var a: int = int(floor(idx))
	var b: int = mini(a + 1, route.size() - 1)
	var perf_result_5 = route[a].lerp(route[b], idx - float(a))
	if Perf.enabled: Perf.end(&"route.3d_position",perf_started)
	return perf_result_5

func _direction_on_route(progress: float) -> Vector2:
	var perf_started := Perf.begin() if Perf.enabled else 0
	var diff: Vector2 = _point_on_route(progress + 0.0007) - _point_on_route(progress - 0.0007)
	var perf_result_1 = diff.normalized() if diff.length_squared() > 0.00001 else Vector2.RIGHT
	if Perf.enabled: Perf.end(&"route.3d_direction",perf_started)
	return perf_result_1

func _material(color_hex: String, rough: float = 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color_hex)
	material.roughness = rough
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _build_scenery() -> void:
	var grass_plane := MeshInstance3D.new()
	var grass := PlaneMesh.new()
	grass.size = Vector2(2200, 2200) # Fill wide free-camera panoramas
	grass_plane.mesh = grass
	grass_plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var palette: Dictionary = CircuitSceneryScript.palette_for(course_name)
	var ground := ShaderMaterial.new()
	ground.shader = preload("res://assets/shaders/terrain_0652.gdshader")
	ground.set_shader_parameter("base_color",Color(str(palette["ground"])).darkened(0.18))
	grass_plane.material_override = ground
	grass_plane.position = Vector3(0.0, -0.16, 0.0)
	course_root.add_child(grass_plane)

func _build_environment_details() -> void:
	# The approved asphalt mesh and centreline remain unchanged. All props
	# stay outside the road; no collision or physics is added.
	if road_centers.size() < 30:
		return
	_add_safety_barriers()
	if bool(CircuitSceneryScript.palette_for(course_name)["trees"]):
		_add_trees_multimesh()
	CircuitSceneryScript.add_details(course_root, course_name, road_centers, road_normals, road_widths)
	CircuitDetailScript.install(course_root, course_name, road_centers, road_normals, road_widths)

func _add_safety_barriers() -> void:
	# Corrugated steel and wire mesh are batched, independent of race physics.
	var steel := _material("#8a969c")
	steel.metallic = 0.65
	steel.roughness = 0.42
	var fence := ShaderMaterial.new()
	fence.shader = preload("res://assets/shaders/fence_0653.gdshader")
	for edge in [-1.0,1.0]:
		var rail_tool := SurfaceTool.new()
		var wire_tool := SurfaceTool.new()
		rail_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		wire_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var posts: Array[Transform3D] = []
		for i in range(road_centers.size()):
			var t := float(i)/road_centers.size()
			if not ((t > .12 and t < .22) or (t > .49 and t < .60) or (t > .80 and t < .94)): continue
			var j := (i+1)%road_centers.size()
			var a := _edge_at(i,edge*1.50,0,0)
			var b := _edge_at(j,edge*1.50,0,0)
			var normal := (b-a).cross(Vector3.UP).normalized()
			for band in range(8):
				var low := .14+float(band)*.095
				var high := low+.095
				var da := .04 if band%2 == 0 else -.04
				var db := -da
				for v in [a+Vector3.UP*low+normal*da,b+Vector3.UP*low+normal*da,a+Vector3.UP*high+normal*db,a+Vector3.UP*high+normal*db,b+Vector3.UP*low+normal*da,b+Vector3.UP*high+normal*db]:
					rail_tool.add_vertex(v)
			var length := a.distance_to(b)
			var vertices := [a+Vector3.UP*.95,b+Vector3.UP*.95,a+Vector3.UP*2.9,a+Vector3.UP*2.9,b+Vector3.UP*.95,b+Vector3.UP*2.9]
			var uv := [Vector2(road_distances[i],0),Vector2(road_distances[i]+length,0),Vector2(road_distances[i],1.95),Vector2(road_distances[i],1.95),Vector2(road_distances[i]+length,0),Vector2(road_distances[i]+length,1.95)]
			for k in range(6):
				wire_tool.set_uv(uv[k])
				wire_tool.set_normal(normal)
				wire_tool.add_vertex(vertices[k])
			if i%4 == 0: posts.append(Transform3D(Basis(),a+Vector3.UP*1.45))
		rail_tool.generate_normals()
		for item in [[rail_tool,steel,"CorrugatedArmco"],[wire_tool,fence,"SafetyMesh"]]:
			var node := MeshInstance3D.new()
			node.name = item[2]
			node.mesh = item[0].commit()
			node.material_override = item[1]
			course_root.add_child(node)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(.065,2.9,.065)
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = mesh
		instances.instance_count = posts.size()
		for i in range(posts.size()): instances.set_instance_transform(i,posts[i])
		var poles := MultiMeshInstance3D.new()
		poles.multimesh = instances
		poles.material_override = steel
		course_root.add_child(poles)

func _add_trees_multimesh() -> void:
	# Lightweight instancing for scenery; reproducible and no imported assets.
	var spots: Array[Vector3] = []
	var n: int = road_centers.size()
	var rng_local := RandomNumberGenerator.new()
	rng_local.seed = 27051
	for i in range(20, n - 10, 23):
		for sign in [-1.0, 1.0]:
			var distance := rng_local.randf_range(18.0, 35.0)
			var location: Vector3 = road_centers[i] + road_normals[i].normalized() * sign * distance
			var safe := true
			for j in range(0, n, 8):
				if location.distance_squared_to(road_centers[j]) < 13.0 * 13.0:
					safe = false
					break
			if safe:
				spots.append(location)
	if spots.is_empty():
		return
	var wood := CylinderMesh.new()
	wood.top_radius = 0.22
	wood.bottom_radius = 0.29
	wood.height = 2.25
	wood.radial_segments = 5
	var crown := SphereMesh.new()
	crown.radius = 1.5
	crown.height = 3.2
	crown.radial_segments = 14
	crown.rings = 8
	_add_instanced_props("TreeTrunks", wood, "#67513a", spots, 1.1)
	# Overlapping asymmetric crowns avoid identical spherical tree silhouettes.
	for cluster in range(4):
		var branches: Array[Vector3] = []
		for i in range(spots.size()):
			var angle := float(i)*2.399+float(cluster)*1.7
			branches.append(spots[i]+Vector3(cos(angle)*.85,float(cluster)*.28,sin(angle)*.85))
		_add_instanced_props("TreeCanopies",crown,["#263c25","#32482a","#3a502c","#2e4225"][cluster],branches,2.9)

func _add_instanced_props(label: String, part_mesh: Mesh, color: String, spots: Array[Vector3], height: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = part_mesh
	mm.instance_count = spots.size()
	for i in range(spots.size()):
		mm.set_instance_transform(i, Transform3D(Basis(), spots[i] + Vector3.UP * height))
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = mm
	node.material_override = _material(color)
	if label == "TreeCanopies":
		var foliage := ShaderMaterial.new()
		foliage.shader = preload("res://assets/shaders/foliage_0653.gdshader")
		foliage.set_shader_parameter("tint",Color(color))
		node.material_override = foliage
	course_root.add_child(node)

func _add_grandstands() -> void:
	# Simple tiered stands: visible landmarks for the low-angle TV shots.
	var painted := _material("#7e8992")
	var canopy := _material("#d4d8d6")
	var seat := _material(str(CircuitSceneryScript.palette_for(course_name)["stand"]))
	for progress in [0.16, 0.62, 0.87]:
		var idx := int(float(road_centers.size()) * progress)
		var p: Vector3 = road_centers[idx] + road_normals[idx].normalized() * 24.0
		var stand := Node3D.new()
		stand.name = "Grandstand"
		stand.position = p
		var tangent: Vector3 = (road_centers[(idx + 1) % road_centers.size()] - road_centers[(idx + road_centers.size() - 1) % road_centers.size()]).normalized()
		stand.rotation.y = atan2(-tangent.x, -tangent.z)
		course_root.add_child(stand)
		for tier in range(4):
			_box(stand, Vector3(3.7, 0.44, 9.0), Vector3(float(tier) * 1.45, 0.27 + float(tier) * 0.72, 0.0), painted)
			_box(stand, Vector3(3.6, 0.12, 8.7), Vector3(float(tier) * 1.45, 0.51 + float(tier) * 0.72, 0.0), seat)
		_box(stand, Vector3(9.0, 0.32, 11.0), Vector3(2.1, 4.2, 0.0), canopy)

func _build_road() -> void:
	if route.size() < 4:
		return
	# Build one closed ring of shared edge vectors. Every layer (runoff,
	# shoulder, asphalt, kerbs) reuses exactly the same cross-sections.
	_build_road_sections()
	_add_band(-RUNOFF_MULTIPLIER, 0.0, RUNOFF_MULTIPLIER, 0.0, 0.004, _material("#557461"))
	_add_band(-SHOULDER_MULTIPLIER, 0.0, SHOULDER_MULTIPLIER, 0.0, 0.030, _material("#8a9495"))
	var asphalt := ShaderMaterial.new()
	asphalt.shader = preload("res://assets/shaders/asphalt_0652.gdshader")
	_add_band(-1.0, 0.0, 1.0, 0.0, 0.061, asphalt, -1, "Asphalt")

	# A short and *continuous* kerb on each edge, with red/white blocks
	# alternating by distance traveled instead of by raw vertex index.
	var curb := ShaderMaterial.new()
	curb.shader = preload("res://assets/shaders/curb_0653.gdshader")
	for edge in [-1.0,1.0]:
		_add_band(edge*.91,0.0,edge*1.10,0.0,.082,curb,-1,"PaintedKerb")

	# Continuous thin white boundary line inside each kerb; purely visual.
	for edge in [-1.0, 1.0]:
		_add_band(edge * 0.883, 0.0, edge * 0.908, 0.0, 0.097,
			_material("#f3f2e8"), -1, "RoadEdgeLineL" if edge < 0.0 else "RoadEdgeLineR")

	# This finish-line mesh is independent of the long road strips.
	var start: Vector3 = road_centers[0]
	var forward: Vector3 = (road_centers[1] - road_centers[0]).normalized()
	var finish_line := MeshInstance3D.new()
	finish_line.name = "StartFinishLine"
	var finish_mesh := BoxMesh.new()
	finish_mesh.size = Vector3(ROAD_HALF * 1.9, 0.018, 0.46)
	finish_line.mesh = finish_mesh
	finish_line.material_override = _material("#f0f4f2")
	finish_line.position = start + Vector3.UP * 0.103
	course_root.add_child(finish_line)
	# Node3D.look_at requires a node already attached to the SceneTree.
	finish_line.look_at(start + forward, Vector3.UP)

func _build_road_sections() -> void:
	road_centers.clear()
	road_normals.clear()
	road_widths.clear()
	road_outer_widths.clear()
	road_distances.clear()
	# route ends with a duplicate of the first point: ignore the extra one
	# here and connect the last useful section to section zero.
	var count: int = route.size() - 1
	for i in range(count):
		road_centers.append(_to_world(route[i]))
	var unfiltered: Array[float] = []
	var travelled := 0.0
	for i in range(count):
		var p: Vector3 = road_centers[i]
		var p_prev: Vector3 = road_centers[(i + count - 1) % count]
		var p_next: Vector3 = road_centers[(i + 1) % count]
		var incoming: Vector3 = (p - p_prev).normalized()
		var outgoing: Vector3 = (p_next - p).normalized()
		var bisector: Vector3 = incoming + outgoing
		if bisector.length_squared() < 0.00001:
			bisector = outgoing
		bisector = bisector.normalized()
		# Project the shared tangent onto its perpendicular; a tightly
		# clamped miter prevents huge spikes at hairpins.
		var outgoing_side := Vector3(-outgoing.z, 0.0, outgoing.x)
		var side := Vector3(-bisector.z, 0.0, bisector.x)
		var miter: float = 1.0 / maxf(0.82, side.dot(outgoing_side))
		road_normals.append(side * minf(miter, 1.12))
		var angle: float = acos(clampf(incoming.dot(outgoing), -1.0, 1.0))
		var adjacent: float = (p.distance_to(p_prev) + p.distance_to(p_next)) * 0.5
		var local_radius: float = adjacent / maxf(angle, 0.001)
		# The licensed centerline contains very tight curves at this scale.
		# Gently narrow the strip where otherwise the inside edge would fold
		# back across itself. Preserve room for our small F1 cars.
		unfiltered.append(clampf(local_radius * 0.45 + 0.35, 1.00, ROAD_HALF))
		road_distances.append(travelled)
		travelled += p.distance_to(p_next)
	# Smooth the widths, not the centerline. This prevents sudden pinches.
	for i in range(count):
		var acc := 0.0
		var weights := 0.0
		for offset in range(-4, 5):
			var weight: float = 5.0 - float(abs(offset))
			acc += unfiltered[(i + offset + count) % count] * weight
			weights += weight
		road_widths.append(acc / weights)
	# A few extreme hairpins (especially Monaco) need a shorter inside edge.
	# Check both triangles of the widest runoff quad, and locally shrink only a
	# cross-section that would fold over itself. This never edits the route
	# that the 2D map, TV director and simulator share.
	for pass_idx in range(15):
		var bad: Array[int] = []
		for i in range(count):
			var j: int = (i + 1) % count
			var left_a: Vector3 = _edge_at(i, -RUNOFF_MULTIPLIER, 0.0, 0.0)
			var right_a: Vector3 = _edge_at(i, RUNOFF_MULTIPLIER, 0.0, 0.0)
			var left_b: Vector3 = _edge_at(j, -RUNOFF_MULTIPLIER, 0.0, 0.0)
			var right_b: Vector3 = _edge_at(j, RUNOFF_MULTIPLIER, 0.0, 0.0)
			var a1: float = Vector2(left_b.x - left_a.x, left_b.z - left_a.z).cross(Vector2(right_a.x - left_a.x, right_a.z - left_a.z))
			var a2: float = Vector2(left_b.x - right_a.x, left_b.z - right_a.z).cross(Vector2(right_b.x - right_a.x, right_b.z - right_a.z))
			if a1 <= 0.0000001 or a2 <= 0.0000001:
				bad.append(i)
		if bad.is_empty():
			break
		for i in bad:
			road_widths[i] *= 0.83
			road_widths[(i + 1) % count] *= 0.83

	# Keep the lane sampler and asphalt on the same minimum width. At a
	# compressed hairpin the outside layers need not grow by the same ratio.
	# Use the pre-floor widths for runoff, and blend a small edge margin.
	if course_name == "Circuit de Monaco" and is_equal_approx(visual_world_scale, MONACO_VISUAL_WORLD_SCALE):
		road_outer_widths.assign(road_widths)
		for i in range(count):
			road_widths[i] = maxf(road_widths[i], MONACO_MIN_ASPHALT_HALF_WIDTH)

func _edge_at(i: int, factor: float, addition: float, height: float) -> Vector3:
	var offset: float = road_widths[i] * factor
	if not road_outer_widths.is_empty() and absf(factor) > 1.0:
		# Barriers follow the safe runoff edge in Monaco instead of
		# extending into a folded inner corner at the 1.50 rail factor.
		var outer_factor: float = minf(absf(factor), RUNOFF_MULTIPLIER)
		var magnitude: float = maxf(road_widths[i] + (outer_factor-1.0)*0.20, road_outer_widths[i]*outer_factor)
		offset = signf(factor)*magnitude
	return road_centers[i] + road_normals[i] * (offset + addition) + Vector3.UP * height

func _add_band(left_factor: float, left_extension: float,
		right_factor: float, right_extension: float, height: float,
		material: Material, alternating: int = -1, label: String = "") -> void:
	if road_centers.size() < 3:
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var n := road_centers.size()
	for i in range(n):
		if alternating >= 0 and int(floor(road_distances[i] / CURB_BLOCK_METERS)) % 2 != alternating:
			continue
		var j: int = (i + 1) % n
		var a := _edge_at(i, left_factor, left_extension, height)
		var b := _edge_at(i, right_factor, right_extension, height)
		var c := _edge_at(j, left_factor, left_extension, height)
		var d := _edge_at(j, right_factor, right_extension, height)
		# Skip zero-area triangles when a licensed map has a duplicate point.
		if (c - a).cross(b - a).length_squared() < 0.00000001:
			continue
		var next_distance := road_distances[i] + road_centers[i].distance_to(road_centers[j])
		uvs.append_array(PackedVector2Array([Vector2(0,road_distances[i]),Vector2(0,next_distance),Vector2(1,road_distances[i]),Vector2(1,road_distances[i]),Vector2(0,next_distance),Vector2(1,next_distance)]))
		for v in [a, c, b, b, c, d]:
			vertices.append(v)
			normals.append(Vector3.UP)
	if vertices.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface := MeshInstance3D.new()
	if not label.is_empty():
		surface.name = label
	surface.mesh = mesh
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.material_override = material
	course_root.add_child(surface)

func _box(parent: Node3D, dims: Vector3, offset: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = dims
	m.mesh = b
	m.material_override = material
	m.position = offset
	parent.add_child(m)
	return m

func _create_car(color_hex: String, team: String, number: int) -> Node3D:
	var model: Node3D = CarModelScript.new(color_hex, team, number)
	model.scale = Vector3.ONE * CarModelScript.PRESENTATION_SCALE
	car_root.add_child(model)
	models_created += 1
	return model
