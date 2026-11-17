extends SceneTree
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        printerr("HUD04_FAIL: "+label)
func _initialize() -> void:
    call_deferred("run")
func frames() -> void:
    for i in range(10): await process_frame
func run() -> void:
    var host = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(host)
    await frames()
    host._open_garage()
    var hub = host.garage_root.get_node("ManagementHub")
    check(hub.visible and hub.current_page == "research", "P&D entry")
    check(host.garage_project_buttons["Asa"].disabled, "research requires active championship")
    host._new_championship()
    host._hire_staff_candidate("Chefe de Aerodinâmica","aero_b")
    host._open_garage()
    var state: Dictionary = host.garage.get_team(host.selected_team)
    var before: int = int(state["budget"])
    var cost: int = host.garage.research_next_cost(host.selected_team,"Asa")
    hub.show_research_tab("research")
    check(not host.garage_project_buttons["Asa"].disabled,"research enabled in season")
    host.garage_project_buttons["Asa"].pressed.emit()
    check(int(state["budget"]) == before-cost,"real research cost")
    check(state["development_project"]["part"] == "Asa","research persisted")
    check(host.garage_project_buttons["Motor"].disabled,"one project limit")
    check(hub.project_progress.value == 0,"initial progress zero")
    hub.show_research_tab("active")
    if DisplayServer.get_name() != "headless":
        root.size = Vector2i(1600,900)
        await frames()
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://qa/hud04/pd_1600.png")
        root.mode = Window.MODE_FULLSCREEN
        await frames()
        await RenderingServer.frame_post_draw
        var screen: Image = root.get_texture().get_image()
        screen.save_png("res://qa/hud04/pd_fullscreen.png")
        print("HUD04_CAPTURE ", screen.get_size())
    host.championship.state["round_index"] = 1
    host._update_garage()
    check(hub.project_progress.value == 50,"progress based on completed rounds")
    var current_budget: int = int(state["budget"])
    host.garage_cancel_project.pressed.emit()
    check(state["development_project"].is_empty(),"cancel action")
    check(int(state["budget"]) == current_budget+int(round(cost*0.75)),"cancel refund")
    check(hub.history_text.text.contains("cancelado"),"history updated")
    hub.show_research_tab("development")
    before = int(state["budget"])
    cost = host.garage.next_cost(host.selected_team,"Motor")
    host.upgrade_buttons["Motor"].pressed.emit()
    check(int(state["levels"]["Motor"]) == 1 and int(state["budget"]) == before-cost,"immediate purchase")
    check(hub.area_bars["Motor"].value == 1,"level refresh")
    for page in hub.pages:
        hub.show_page(page)
        check(hub.pages[page].visible,"page " + str(page))
        var visible_count := 0
        for candidate in hub.pages.values():
            if candidate.visible: visible_count += 1
        check(visible_count == 1,"single visible page")
    check(hub.driver_text.text.contains("Fernando Alonso"),"real selected team drivers")
    check(hub.team_text.text.contains("Bianca Leal"),"real staff")
    check(hub.finance_text.text.contains(hub.money(int(state["budget"]))),"real budget")
    hub.open_configuration()
    check(host.menu_root.visible and not host.garage_root.visible,"return preparation")
    host._open_garage()
    hub.show_page("research")
    hub.show_research_tab("research")
    host.garage_project_buttons["Chassi"].pressed.emit()
    var serial: int = int(host.championship.state["serial"])
    check(host.garage.deliver_research(host.selected_team,serial,3),"deliver project")
    host._update_garage()
    check(hub.history_text.text.contains("entregue"),"delivered history")
    if failures.is_empty(): print("HUD04_PASS real data / research / refund / purchase / navigation / progress / delivery")
    quit(0 if failures.is_empty() else 1)
