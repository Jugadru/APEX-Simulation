extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks := 0
var failures: Array[String] = []
var graphics := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		printerr("NAVIGATION_09176_FAIL ", msg)
func settle(n: int = 3) -> void:
	for i in range(n): await process_frame
func count_button(node: Node, label: String) -> int:
	var count := 1 if node is Button and node.text == label else 0
	for child in node.get_children(): count += count_button(child, label)
	return count
func only(host, screen: Control) -> bool:
	return screen.visible and [host.menu_root, host.garage_root, host.staff_root, host.game_root].filter(func(n): return n.visible).size() == 1
func capture(label: String) -> void:
	if not graphics: return
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(not image.is_empty() and image.save_png("res://qa/navigation_09176/" + label + ".png") == OK, "capture " + label)
func run() -> void:
	graphics = DisplayServer.get_name() != "headless"
	if graphics: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/navigation_09176"))
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await settle(6)
	host.set_process(false)
	var front = host.menu_root.get_node("FrontDoor")
	front.open_sandbox()
	host.seed_picker.value = 99176
	host._open_garage()
	var hub = host.garage_root.get_node("ManagementHub")
	hub.show_development()
	hub.show_development()
	check(count_button(hub.pages.settings,"Performance Profiler 1.0 (F8)") == 1, "profiler not duplicated")
	hub.show_page("factory")
	hub.workshop.show_tab("Fila de tarefas")
	await settle()
	var workshop = hub.workshop
	workshop.car_select.select(1)
	workshop.part_select.select(2)
	workshop.service_select.select(2)
	workshop.priority_select.select(2)
	var part_id: String = str(workshop.part_ids[2])
	host._open_staff()
	host._open_staff()
	await settle()
	var staff_scroll: ScrollContainer = host.staff_root.find_child("StaffScroll",true,false)
	staff_scroll.scroll_vertical = 160
	var staff_position: int = staff_scroll.scroll_vertical
	check(only(host, host.staff_root), "staff is sole visible root")
	host._navigate_back()
	await settle()
	check(only(host, host.garage_root), "staff returns to garage")
	check(hub.current_page == "factory" and hub.workshop.tab == "Fila de tarefas", "page and tab preserved")
	check(workshop.car_select.selected == 1 and str(workshop.part_ids[workshop.part_select.selected]) == part_id and workshop.service_select.selected == 2 and workshop.priority_select.selected == 2, "workshop draft retained")
	host._navigate_back()
	check(only(host, host.menu_root) and not front.visible and host.menu_root.get_node("MenuCard").visible, "back to original GP configuration")
	check(int(host.seed_picker.value) == 99176, "seed selection preserved")
	host._open_staff()
	await settle()
	check(staff_position > 0 and staff_scroll.scroll_vertical == staff_position, "staff scroll restored")
	host._navigate_back()
	check(only(host, host.menu_root), "staff opened from menu returns to menu")
	# Bounded repeated navigation using the real roots, including the existing tab callbacks.
	host._open_garage()
	hub.show_page("research")
	hub.show_research_tab("development")
	host._navigate_back()
	await settle(6)
	var before_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var before_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var before_memory: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var started: int = Time.get_ticks_msec()
	for i in range(100):
		host._open_garage()
		host._open_staff()
		host._navigate_back()
		host._navigate_back()
		await settle(1)
		check(only(host, host.menu_root) and host.navigation.history.is_empty(), "cycle %d returns without history growth" % i)
	await settle(8)
	var after_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var after_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var after_memory: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	check(after_nodes == before_nodes, "node count stable")
	check(after_orphans == before_orphans, "orphan count stable")
	check(count_button(hub.pages.settings,"Performance Profiler 1.0 (F8)") == 1, "profiler still single")
	check(host.start_button.pressed.get_connections().size() == 1, "start signal single")
	print("NAVIGATION_09176_BENCH ", JSON.stringify({"cycles":100,"elapsed_ms":Time.get_ticks_msec()-started,"nodes_before":before_nodes,"nodes_after":after_nodes,"orphans_before":before_orphans,"orphans_after":after_orphans,"memory_before":before_memory,"memory_after":after_memory}))
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size = resolution
		host._layout_ui()
		host._open_garage()
		await settle()
		check(only(host, host.garage_root), "garage at " + str(resolution))
		await capture("garage_%dx%d" % [resolution.x,resolution.y])
		host._open_staff()
		await settle()
		await capture("staff_%dx%d" % [resolution.x,resolution.y])
		host._navigate_back()
		host._navigate_back()
		await settle()
		check(only(host, host.menu_root), "return at " + str(resolution))
	front.open_sandbox()
	host.start_button.pressed.emit()
	await settle()
	var race = host.race
	check(race != null and only(host, host.game_root), "new race starts")
	if race == null:
		quit(1)
		return
	host.start_button.pressed.emit()
	check(host.race == race, "duplicate start signal cannot replace race")
	race.running = false
	var hash_before: String = Codec.sporting_hash(race,host.replay_session.policy)
	var team: String = host.selected_team
	var mode: String = host.team_control_mode
	var track: int = host.selected_track_index
	host._show_menu()
	front.open_sandbox()
	var other: int = (host.team_picker.selected+1) % host.teams.size()
	host.team_picker.select(other)
	host._on_team_selected(other)
	host._select_pre_race_team_mode(1)
	front.resume_race()
	check(only(host,host.game_root) and host.race == race and not race.running,"resume same paused race")
	check(host.selected_team == team and host.team_control_mode == mode and host.selected_track_index == track,"original live session bindings restored")
	check(Codec.sporting_hash(race,host.replay_session.policy) == hash_before,"navigation keeps sporting hash")
	await settle()
	await capture("race_resume")
	print("NAVIGATION_09176_REPORT ", JSON.stringify({"checks":checks,"failures":failures,"graphical":graphics,"sporting_hash":hash_before}))
	if failures.is_empty(): print("NAVIGATION_09176_PASS")
	quit(0 if failures.is_empty() else 1)
