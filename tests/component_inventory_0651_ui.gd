extends SceneTree
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		printerr("UI_FAIL " + text)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in range(15): await process_frame
func run() -> void:
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await settle()
	host._open_garage()
	var hub = host.garage_root.get_node("ManagementHub")
	hub.show_page("factory")
	hub.workshop.show_tab("Componentes")
	var workshop = hub.workshop.legacy
	var state: Dictionary = host.garage.get_team(host.selected_team)
	var id: String = host.garage.Inventory.installed(state.component_inventory,1,"Motor")
	workshop.switch_view("car2")
	check(int(state.component_inventory.parts[workshop.selected].car) == 2,"car 2 navigation")
	workshop.switch_view("car1")
	workshop.select_part(id)
	workshop.act("remove",0)
	check(state.component_inventory.parts[id].status == "available","remove button")
	host._show_menu()
	host._start_race()
	check(host.race == null and host.garage_root.visible and hub.current_page == "factory","empty slot blocks race and opens workshop")
	workshop.switch_view("inventory")
	workshop.select_part(id)
	host.garage.component_action(host.selected_team,id,"install",1)
	hub.workshop.show_tab("Componentes")
	check(state.component_inventory.parts[id].car == 1,"install button")
	workshop.switch_view("car1")
	for resolution in [Vector2i(1600,900),Vector2i(1920,1080)]:
		root.mode = Window.MODE_FULLSCREEN if resolution.x == 1920 else Window.MODE_WINDOWED
		root.size = resolution
		await settle()
		check(workshop.details.get_global_rect().end.x <= host.get_viewport_rect().size.x,"horizontal fit")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var im := root.get_texture().get_image()
			check(im.get_size()==resolution,"capture size")
			im.save_png("res://qa/living_factory/living_factory_%dx%d.png" % [resolution.x,resolution.y])
	host._show_menu()
	host._start_race()
	check(host.race != null,"race begins with complete inventory")
	host._open_garage()
	hub.show_page("factory")
	var before := JSON.stringify(state.component_inventory)
	workshop.select_part(id)
	workshop.act("remove",0)
	check(before==JSON.stringify(state.component_inventory),"UI cannot alter active session")
	check(workshop.notice.text.contains("bloqueada"),"lock explanation")
	if failures == 0: print("INVENTORY_UI_PASS navigation / actions / session guard / viewport fit")
	quit(0 if failures==0 else 1)
