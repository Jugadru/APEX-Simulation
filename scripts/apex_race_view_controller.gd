extends RefCounted
## APEX 0.6.2.6.1 — free camera mouse/input hotfix; 0.6.2.6 tracking preserved.
## The wrapper preserves legacy signals and callbacks.

const VISUAL_OPTIONS := ["Auto F1M", "Mapa estratégico", "Câmera 3D", "Aérea estratégica"]
static func _change_speed(host, index: int) -> void:
	var previous_speed: float = host.sim_speed
	var was_fast: bool = previous_speed >= 10.0
	host.sim_speed = [1.0, 2.0, 5.0, 10.0, 16.0, 32.0][clampi(index, 0, 5)]
	if host.replay_session != null and host.replay_session.race == host.race:
		host.replay_session.rebase_interactive_speed(previous_speed, host.sim_speed)
	# Do not label a newly selected 32x with the prior 16x rolling average.
	host.effective_speed_x = 0.0
	host.effective_speed_elapsed = 0.0
	host.effective_speed_ticks = 0
	# The Auto preset selects the cheap strategic map at 10x+ only.
	# An explicit player choice of 2D, 3D or aerial is never overwritten.
	if host.visual_setting == 0 and was_fast != (host.sim_speed >= 10.0):
		host._apply_visual_from_setting()
	if host.speed_picker != null and host.speed_picker.selected != index:
		host.speed_picker.select(index)


static func _change_visual_setting(host, index: int) -> void:
	host.visual_setting = clampi(index, 0, 3)
	host.camera_zoom_multiplier = 1.0
	host._apply_visual_from_setting()


static func _apply_visual_from_setting(host) -> void:
	if host.visual_setting == 0:
		host.render_mode = 0 if host.sim_speed >= 10.0 else 1
	elif host.visual_setting == 1:
		host.render_mode = 0
	else:
		host.render_mode = 1
	# Aerial is a dedicated helicopter shot of the same 3D scene.
	# Auto: 1x/2x/5x = 3D; 10x/16x/32x = cached tactical 2D.
	if host.map_view != null:
		host.map_view.set_view_mode(0)
		host.map_view.visible = host.render_mode == 0
	if host.world_container != null:
		host.world_container.visible = host.render_mode == 1
	if host.render_mode == 1:
		host.target_zoom = 1.20 if host.visual_setting == 3 else maxf(host.target_zoom, 2.1)
	else:
		host._frame_strategic_circuit()
	if host.world_view != null and host.render_mode == 1 and host.visual_setting == 3:
		host.world_view.set_zoom(host.target_zoom)
	host._apply_hud_visibility()


static func _frame_strategic_circuit(host) -> void:
	# Strategic 2D starts with the whole circuit inside the free central area.
	# Zoom/drag remain manual after this initial framing.
	if host.map_view == null or host.map_view.route.is_empty() or host.cam == null:
		return
	var smallest: Vector2 = host.map_view.route[0]
	var largest: Vector2 = host.map_view.route[0]
	for point in host.map_view.route:
		smallest = smallest.min(point)
		largest = largest.max(point)
	var dims: Vector2 = largest - smallest
	var view_size: Vector2 = host.get_viewport_rect().size
	var available_x: float = view_size.x - 520.0 if view_size.x >= 1500.0 else view_size.x - 475.0
	var available_y: float = view_size.y - 225.0
	host.target_zoom = clampf(minf(available_x / maxf(1.0, dims.x), available_y / maxf(1.0, dims.y)) * 0.92, 0.45, 1.5)
	host.cam.position = (smallest + largest) * 0.5
	host.cam.zoom = Vector2.ONE * host.target_zoom


static func _change_camera_mode(host, index: int) -> void:
	var next_mode: String = ["Livre", "Seguir piloto", "Diretor TV"][clampi(index, 0, 2)]
	if next_mode == "Livre" and host.camera_mode != "Livre" and host.render_mode == 1 and host.world_view != null:
		host.world_view.enter_free_view()
	host.camera_mode = next_mode
	if host.director != null:
		host.director.mode = host.camera_mode
	host.next_tv = 0.0


static func _enter_free_camera(host) -> void:
	if host.camera_mode == "Livre":
		return
	if host.mode_picker != null:
		host.mode_picker.select(0)
	_change_camera_mode(host, 0)

static func _change_director_preset(host, index: int) -> void:
	if host.director != null:
		host.director.preset = ["Ação", "Transmissão"][index]


static func _change_tv_shot(host, index: int) -> void:
	host.tv_shot_override = ["Automático", "chase", "corner", "trackside", "helicopter", "battle"][index]
	# A selected camera angle needs a subject. Keep the game in follow mode
	# when the player comes from the free-map camera.
	if host.camera_mode == "Livre" and host.tv_shot_override != "Automático":
		host.mode_picker.select(1)
		host._change_camera_mode(1)


static func _nearest_rival(host, car_id: int) -> Variant:
	# Prefer a close car along the *same lap segment*. Looking only at the
	# timing tower can put the camera between unrelated corners at Sepang.
	if host.race == null or host.map_view == null:
		return null
	var focus_car: Dictionary = host._car_by_id(car_id)
	if focus_car.is_empty() or float(focus_car.get("pit_left", 0.0)) > 0.0:
		return null
	var progress: float = float(focus_car.get("progress", 0.0))
	var origin: Vector2 = host.map_view.point_on_track(progress)
	var best_distance: float = INF
	var best_position: Variant = null
	for rival in host.race.cars:
		if int(rival.get("id", -1)) == car_id or float(rival.get("pit_left", 0.0)) > 0.0:
			continue
		var other_progress: float = float(rival.get("progress", 0.0))
		var phase: float = absf(fposmod(other_progress - progress + 0.5, 1.0) - 0.5)
		if phase > 0.038:
			continue
		var position: Vector2 = host.map_view.point_on_track(other_progress)
		var distance: float = origin.distance_to(position)
		# 84 m in the 3D scene: approximately 140 map units.
		if distance < best_distance and distance < 140.0:
			best_distance = distance
			best_position = position
	return best_position

static func _select_pilot_option(host, index: int) -> void:
	if host.race == null:
		return
	if index == 0:
		host.manual_driver = int(host.race.get_sorted()[0]["id"])
	else:
		var target = host.driver_picker.get_item_text(index)
		for driver in host.race.cars:
			if driver["name"] == target:
				host.manual_driver = int(driver["id"])
				break
	if host.camera_mode == "Diretor TV":
		host.director.override_focus(host.manual_driver, host.race.clock)


static func _on_position_pressed(host, row_index: int) -> void:
	if host.race == null:
		return
	var ordered: Array = host.race.get_sorted()
	if row_index >= 0 and row_index < ordered.size():
		host.manual_driver = int(ordered[row_index]["id"])
		for j in range(1, host.driver_picker.item_count):
			if host.driver_picker.get_item_text(j) == str(ordered[row_index]["name"]):
				host.driver_picker.select(j)
				break
		host.mode_picker.select(1)
		host._change_camera_mode(1)
		host.context_enabled = true
		host._layout_ui()
		host._save_hud_prefs()


static func _zoom_by(host, factor: float) -> void:
	if host.camera_mode != "Livre":
		host.camera_zoom_multiplier = clampf(host.camera_zoom_multiplier * factor, 0.65, 1.75)
	host.target_zoom = clampf(host.target_zoom * factor, 0.65, 4.5)
	host.cam.zoom = Vector2.ONE * host.target_zoom
	if host.world_view != null:
		host.world_view.set_zoom(host.target_zoom)


static func _reset_camera(host) -> void:
	host.camera_zoom_multiplier = 1.0
	host.camera_mode = "Livre"
	host.mode_picker.select(0)
	if host.director != null:
		host.director.mode = host.camera_mode
	host.target_zoom = 1.25 if host.render_mode == 0 else 2.1
	host.cam.position = Vector2(520, 430)
	host.cam.zoom = Vector2.ONE * host.target_zoom
	if host.world_view != null:
		host.world_view.center_track()
		host.world_view.set_zoom(host.target_zoom)


static func _pointer_over_race_ui(host, pointer_pos: Vector2) -> bool:
	# Do not pan when starting over any of the actual buttons/cards/windows.
	# This explicit check also works on the *first click*, before GUI hover
	# information has necessarily been updated by Godot's Control dispatch.
	var hud = host.race_hud_0620
	if hud != null:
		if hud.background_dimmer.visible:
			return true
		for control in [hud.ranking, hud.weather_box, hud.map_box, hud.bottom_bar, hud.tiny_top, hud.actions_top]:
			if control != null and control.is_visible_in_tree() and control.get_global_rect().has_point(pointer_pos):
				return true
		for card in hud.race_card_panels:
			for name in ["base", "expanded"]:
				var part: Control = card.get(name, null)
				if part != null and part.is_visible_in_tree() and part.get_global_rect().has_point(pointer_pos):
					return true
	# The HUD uses full-screen Controls for layout; those alone are not UI
	# controls to block drags. Actual nested panels still block the camera.
	var hovered: Control = host.get_viewport().gui_get_hovered_control()
	return hovered != null and hovered != host.screen and hovered != host.game_root and hovered != host.world_container and hovered != hud


static func _camera_mouse_input(host, event: InputEvent) -> void:
	# `_input` runs before the UI dispatch: `_unhandled_input` never received
	# mouse drags over the full-screen HUD container on some systems.
	if host.race == null or host.game_root == null or not host.game_root.visible:
		host.dragging = false
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if not event.pressed:
				host.dragging = false
			elif not _pointer_over_race_ui(host, event.position):
				host.dragging = true
				_enter_free_camera(host)
			else:
				host.dragging = false
		elif event.pressed and not _pointer_over_race_ui(host, event.position):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_enter_free_camera(host)
				host._zoom_by(1.12)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_enter_free_camera(host)
				host._zoom_by(1.0 / 1.12)
	elif event is InputEventMouseMotion and host.dragging:
		# Do not turn a click in a pilot card or menu into a camera drag.
		if host.camera_mode != "Livre":
			_enter_free_camera(host)
		if host.render_mode == 1 and host.world_view != null:
			host.world_view.pan_by(event.relative)
		elif host.cam != null:
			host.cam.position -= event.relative / host.cam.zoom


static func update_free_navigation(host, delta: float) -> void:
	# Optional strategy-game controls, without holding the mouse button:
	# WASD/arrows and cursor near an unobstructed screen edge.
	if host.race == null or host.game_root == null or not host.game_root.visible or host.camera_mode != "Livre" or host.dragging:
		return
	var movement := Vector2.ZERO
	var focused: Control = host.get_viewport().gui_get_focus_owner()
	var editing_text: bool = focused is LineEdit or focused is TextEdit or focused is SpinBox
	if not editing_text:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			movement.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			movement.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			movement.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			movement.y += 1.0
	var mouse_pos: Vector2 = host.get_viewport().get_mouse_position()
	if movement == Vector2.ZERO and not _pointer_over_race_ui(host, mouse_pos):
		var screen_size: Vector2 = host.get_viewport_rect().size
		var margin: float = 18.0
		if mouse_pos.x >= 0.0 and mouse_pos.y >= 0.0 and mouse_pos.x <= screen_size.x and mouse_pos.y <= screen_size.y:
			if mouse_pos.x < margin:
				movement.x -= 1.0
			elif mouse_pos.x > screen_size.x - margin:
				movement.x += 1.0
			if mouse_pos.y < margin:
				movement.y -= 1.0
			elif mouse_pos.y > screen_size.y - margin:
				movement.y += 1.0
	if movement == Vector2.ZERO:
		return
	movement = movement.normalized() * 460.0 * maxf(delta, 0.0)
	if host.render_mode == 1 and host.world_view != null:
		host.world_view.pan_by(-movement)
	elif host.cam != null:
		host.cam.position += movement / host.cam.zoom


static func _unhandled_input(host, event: InputEvent) -> void:
	# Keyboard shortcuts only: leave text fields, lists and buttons unaffected.
	if host.race == null or not host.game_root.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			host._toggle_race()
		elif event.keycode == KEY_TAB:
			host._toggle_hud()
		elif event.keycode == KEY_R:
			host._reset_camera()
		elif event.keycode == KEY_M:
			if host.race_hud_0620 != null:
				host.race_hud_0620._set_view((host.race_hud_0620.view_picker.selected + 1) % 3)
			else:
				host.visual_setting = (host.visual_setting + 1) % VISUAL_OPTIONS.size()
				host.visual_picker.select(host.visual_setting)
				host._apply_visual_from_setting()
		elif event.keycode == KEY_I:
			host._cycle_info_mode()
		elif event.keycode == KEY_C:
			if host.race_hud_0620 != null:
				host.race_hud_0620._open_window("corrida")
		elif event.keycode == KEY_V:
			if host.race_hud_0620 != null:
				for slot in range(host.race_hud_0620.race_card_panels.size()):
					host.race_hud_0620._collapse_driver(slot)
		elif event.keycode == KEY_F:
			host.mode_picker.select(1)
			host._change_camera_mode(1)


static func update_tracking(host, delta: float) -> void:
	var target_car_id = host.manual_driver
	if host.camera_mode == "Diretor TV":
		# Hold a TV shot for real viewer seconds, regardless of race speed.
		if host.race.running:
			host.director.screen_clock += maxf(delta, 0.0)
		host.next_tv -= delta
		if host.next_tv <= 0.0:
			target_car_id = host.director.select(host.race, host.manual_driver, host.race.clock)
			host.next_tv = 0.8
		else:
			target_car_id = host.director.focus_id
	elif host.camera_mode == "Seguir piloto":
		target_car_id = host.manual_driver
	elif host.camera_mode == "Livre":
		target_car_id = -1
	# Strategic mode is an overview by default, not a zoomed TV close-up.
	# Explicit "Seguir piloto" continues to follow the selected car.
	if host.render_mode == 0 and host.camera_mode != "Seguir piloto":
		target_car_id = -1
	host.focused_id = target_car_id if target_car_id >= 0 else host.manual_driver
	if target_car_id >= 0:
		var focus_car: Dictionary = host._car_by_id(target_car_id)
		if not focus_car.is_empty():
			var desired: Vector2 = host.map_view.point_on_track(float(focus_car["progress"]))
			var desired_dir: Vector2 = host.map_view.direction_on_track(float(focus_car["progress"]))
			host.cam.position = host.cam.position.lerp(desired, clampf(delta * 2.2, 0.0, 1.0))
			if host.render_mode == 1:
				var shot_style: String = "chase"
				var secondary_pos: Variant = null
				if host.camera_mode == "Diretor TV":
					shot_style = str(host.director.camera_style)
					if host.director.secondary_focus_id >= 0:
						var secondary_car: Dictionary = host._car_by_id(host.director.secondary_focus_id)
						if not secondary_car.is_empty() and float(secondary_car.get("pit_left", 0.0)) <= 0.0 and float(focus_car.get("pit_left", 0.0)) <= 0.0:
							var phase_gap: float = absf(float(secondary_car["progress"]) - float(focus_car["progress"]))
							if phase_gap <= 0.045:
								secondary_pos = host.map_view.point_on_track(float(secondary_car["progress"]))
				if host.visual_setting == 3:
					shot_style = "pit" if shot_style == "pit" else "aerial"
				elif host.tv_shot_override != "Automático":
					shot_style = host.tv_shot_override
				elif float(focus_car.get("pit_left", 0.0)) > 0.0:
					# Follow/TV uses the REAL 3D pit position, not the virtual
					# racing-line progress while this driver is at the garage.
					shot_style = "pit"
				if secondary_pos == null and shot_style in ["aerial", "battle", "helicopter", "corner", "trackside", "chase"]:
					secondary_pos = host._nearest_rival(target_car_id)
				if shot_style == "battle" and secondary_pos == null:
					# Don't pretend a battle is in the frame if no rival is nearby.
					shot_style = "chase"
				host.world_view.set_broadcast_view(desired, desired_dir, secondary_pos, shot_style, delta, target_car_id)
		var intended: float = float(host.director.camera_zoom) if host.camera_mode == "Diretor TV" else 1.95
		if host.render_mode == 0:
			intended = minf(intended, 1.55)
		else:
			intended = 1.35 if host.visual_setting == 3 else maxf(intended, 2.10)
		intended = clampf(intended * host.camera_zoom_multiplier, 0.65, 4.5)
		host.target_zoom = lerpf(host.target_zoom, intended, clampf(delta * 1.2, 0.0, 1.0))
		host.cam.zoom = host.cam.zoom.lerp(Vector2.ONE * host.target_zoom, clampf(delta * 1.9, 0.0, 1.0))
		if host.render_mode == 1:
			host.world_view.set_zoom(host.target_zoom)
