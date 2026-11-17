extends SceneTree
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        printerr("UNIFIED_FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func settle() -> void:
    for i in range(12): await process_frame
func capture(file: String) -> void:
    await settle()
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://qa/unified/"+file+".png")
func audit_images(node: Node) -> void:
    if node is TextureRect and node.is_visible_in_tree():
        check(node.texture == null,"no visible image: "+str(node.get_path()))
    for child in node.get_children(): audit_images(child)
func run() -> void:
    root.size = Vector2i(1600,900)
    var host = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(host)
    await settle()
    check(host.portrait_manager.get_photo("Fernando Alonso") == null,"portraits disabled")
    check(not host.portrait_download_button.visible,"download hidden")
    await capture("menu")
    audit_images(host)
    host._new_championship()
    host._hire_staff_candidate("Chefe de Aerodinâmica","aero_b")
    host._open_garage()
    var hub = host.garage_root.get_node("ManagementHub")
    for key in ["team","drivers","finance","research","performance","calendar","contracts","career"]:
        hub.show_page(key)
        await capture(key)
        audit_images(host)
    check(hub.dashboards.driver_cards[0].name.text == "Fernando Alonso","Ferrari roster")
    check(hub.dashboards.roster_cards["Chefe de Aerodinâmica"].name.text == "Bianca Leal","staff data")
    var state: Dictionary = host.garage.get_team(host.selected_team)
    check(hub.dashboards.figures.balance.text == hub.money(int(state["budget"])),"finance data")
    host._open_staff()
    await capture("staff")
    check(host.staff_card.get_rect().end.y <= host.get_viewport_rect().size.y,"staff fits viewport")
    audit_images(host)
    host._show_menu()
    var menu = host.menu_root.get_node("FrontDoor")
    menu.apply_preset(1)
    host._start_race()
    await settle()
    await capture("race")
    check(host.race_hud_0620.weather_box.size.y < 200,"weather panel fits content")
    audit_images(host)
    check(host.race != null and host.game_root.visible,"race running")
    host._show_menu()
    host._on_team_selected(0)
    host._open_garage()
    hub.show_page("drivers")
    check(hub.dashboards.driver_cards[0].team.text.begins_with(host.selected_team),"team identity refresh")
    if failures.is_empty(): print("UNIFIED_PASS pages / real data / identity / no imagery / race")
    quit(0 if failures.is_empty() else 1)
