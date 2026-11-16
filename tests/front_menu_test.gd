extends SceneTree
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        printerr("FRONT_MENU_FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var host = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(host)
    for i in range(8): await process_frame
    var menu = host.menu_root.get_node("FrontDoor")
    check(menu.visible and not host.menu_root.get_node("MenuCard").visible, "initial landing")
    check(menu.continue_button.disabled, "no save continue disabled")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://qa/menu/menu_home.png")
    menu.open_standard()
    check(host.team_control_mode == "Manual" and not menu.visible, "standard manual configuration")
    menu.show_home()
    menu.show_simulation()
    check(menu.detail.visible and menu.detail_text.text.contains("Planejado"), "simulation roadmap clearly labelled")
    menu.open_delegated_gp()
    check(host.team_control_mode == "Automático" and not host.championship_mode, "delegation config")
    menu.show_home()
    menu.show_scenarios()
    check(menu.detail_actions.get_child_count() == 3, "three training presets")
    if DisplayServer.get_name() != "headless":
        for i in range(5): await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://qa/menu/menu_scenarios.png")
    for i in range(3):
        menu.apply_preset(i)
        var preset: Dictionary = menu.PRESETS[i]
        check(host.season_tracks[host.selected_track_index]["code"] == preset["code"], "track preset")
        check(host.weather_mode_picker.selected == preset["weather"], "weather preset")
        check(int(host.seed_picker.value) == preset["seed"], "seed preset")
        check(host.team_control_mode == "Manual", "manual scenario")
    menu.open_sandbox()
    check(not host.championship_mode and host.weather_mode_picker.selected == 0, "sandbox independent GP")
    menu.apply_preset(1)
    host._start_race()
    check(host.race != null and host.game_root.visible, "race starts")
    check(host.race.track["code"] == "ITA", "preset propagated to engine")
    var saved_race = host.race
    host._show_menu()
    check(menu.visible and not menu.resume_race_button.disabled, "return menu")
    menu.resume_race()
    check(host.race == saved_race and host.game_root.visible and not host.menu_root.visible, "resume preserves session")
    host._show_menu()
    host._open_staff()
    check(host.staff_root.visible, "staff navigation")
    host._show_menu()
    host._open_garage()
    check(host.garage_root.visible, "garage navigation")
    host._show_menu()
    if failures.is_empty(): print("FRONT_MENU_PASS navigation / presets / live race / resume / staff / garage")
    quit(0 if failures.is_empty() else 1)
