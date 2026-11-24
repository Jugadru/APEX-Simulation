extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)
        printerr("MAIN_MENU_09178_FAIL ", message)
func settle() -> void:
    for i in range(5): await process_frame
func capture(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa/main_menu_09178/"+label+".png")==OK, "capture "+label)
func buttons(node: Node) -> Array:
    var result: Array = [node] if node is Button and node.is_visible_in_tree() else []
    for child in node.get_children(): result.append_array(buttons(child))
    return result
func run() -> void:
    if DisplayServer.get_name() != "headless": DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/main_menu_09178"))
    var host = load("res://scenes/main.tscn").instantiate()
    root.add_child(host)
    await settle()
    host.set_process(false)
    var menu = host.menu_root.get_node("FrontDoor")
    check(menu.continue_button.disabled and menu.resume_race_button.disabled, "empty session")
    check(menu.session_info.text.contains("Nenhuma temporada"), "empty season status")
    check(menu.mode_grid.get_child_count()==4, "four modes")
    for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
        root.size=resolution
        host._layout_ui()
        await settle()
        check(menu.visible and not menu.body.vertical, "desktop layout "+str(resolution))
        var view: Rect2=menu.home_scroll.get_global_rect()
        for button in buttons(menu):
            var rect: Rect2=button.get_global_rect()
            check(rect.position.x>=view.position.x-1 and rect.end.x<=view.end.x+1, "horizontal fit "+button.text+str(resolution))
            check(rect.position.y>=view.position.y-1 and rect.end.y<=view.end.y+1, "visible without scrolling "+button.text+str(resolution))
            check(button.pressed.get_connections().size()==1, "single signal "+button.text)
        await capture("home_%dx%d" % [resolution.x,resolution.y])
    # All details retain their actual callbacks and planned status.
    menu.show_simulation()
    await settle()
    check(menu.detail.visible and not menu.landing.visible and menu.detail_text.text.contains("Planejado"), "owner planned")
    await capture("simulation")
    menu.detail_actions.get_child(0).pressed.emit()
    check(host.team_control_mode=="Automático" and not menu.visible, "delegated GP route")
    menu.show_home()
    menu.show_scenarios()
    await settle()
    check(menu.detail_actions.get_child_count()==3, "three scenarios")
    await capture("scenarios")
    menu.detail_actions.get_child(1).pressed.emit()
    check(host.season_tracks[host.selected_track_index].code=="ITA", "actual preset callback")
    host._start_race()
    await settle()
    var race = host.race
    race.running=false
    var hash_before: String=Codec.sporting_hash(race,host.replay_session.policy)
    host._show_menu()
    check(not menu.resume_race_button.disabled and menu.race_info.text.contains("sessão em memória"), "live session shown")
    await settle()
    await capture("live_session")
    menu.resume_race_button.pressed.emit()
    check(host.race==race and host.game_root.visible and Codec.sporting_hash(race,host.replay_session.policy)==hash_before, "resume same race/hash")
    host._show_menu()
    host._open_staff()
    host._navigate_back()
    check(menu.is_visible_in_tree() and menu.landing.visible, "staff returns home")
    host._open_garage()
    host._navigate_back()
    check(menu.is_visible_in_tree() and menu.landing.visible, "garage returns home")
    check(host.championship.start_new(host.selected_team,99178,host.season_tracks,host.teams), "isolated season fixture")
    menu.show_home()
    check(not menu.continue_button.disabled and menu.session_info.text.contains("0/20 etapas"), "actual saved season data")
    await settle()
    await capture("saved_season")
    host.championship.state.round_index=host.championship.state.calendar.size()
    menu.show_home()
    check(menu.continue_button.text.contains("CONCLUÍDA"), "completed season label")
    host.championship.state.clear()
    menu.show_home()
    check(menu.continue_button.disabled and menu.continue_button.text=="CONTINUAR TEMPORADA", "reset stale label")
    print("MAIN_MENU_09178_REPORT ",JSON.stringify({"checks":checks,"failures":failures,"graphical":DisplayServer.get_name()!="headless"}))
    if failures.is_empty(): print("MAIN_MENU_09178_PASS")
    quit(0 if failures.is_empty() else 1)
