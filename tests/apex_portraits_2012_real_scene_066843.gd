extends SceneTree
## Teste da cena e HUD REAIS no Godot (não é mock de UI).
## Usa retratos temporários gerados por fixture; NÃO valida aparência das fotos originais.
var failures: Array[String] = []
var checks := 0
func ck(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures.append(reason)
        printerr("APEX_REAL_PORTRAITS_FAIL: ",reason)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    if packed == null:
        printerr("APEX_REAL_PORTRAITS_FAIL: main scene not loaded")
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/portraits_ci"))
    for size in [Vector2i(1600,900),Vector2i(1920,1080)]:
        root.mode = Window.MODE_WINDOWED
        root.size = size
        var game: Node = packed.instantiate()
        root.add_child(game)
        for t in range(4): await process_frame
        game.set_process(false)
        game._start_race()
        for t in range(4): await process_frame
        var hud = game.race_hud_0620
        ck(hud != null and hud.visible,"real HUD visible " + str(size))
        ck(game.race.cars.size() == 24,"24 cars in simulation")
        if hud == null:
            game.queue_free()
            quit(3)
            return
        hud._change_hud_mode(1)
        hud.refresh_hud()
        ck(hud.standing_rows.size() == 24,"24 ranking rows")
        var visible_photos := 0
        for row in hud.standing_rows:
            var tile: TextureRect = row.get("portrait")
            if tile != null and tile.visible and tile.texture != null:
                visible_photos += 1
        ck(visible_photos == 24,"24 textures actually bound to leaderboard, got " + str(visible_photos))
        var pilot: String = str(game.race.player_cars()[0].get("name",""))
        ck(game.portrait_manager.get_profile_photo(pilot) != null,"real manager loads profile")
        var state_before: PackedByteArray = var_to_bytes(game.race.get_state_snapshot())
        hud._open_window("radio")
        if not hud.radio_driver_ids.is_empty():
            hud.radio_driver_picker.select(0)
            hud._radio_driver_changed(0)
        ck(hud.radio_portrait_texture != null and hud.radio_portrait_texture.visible,"radio portrait bound")
        hud._close_window()
        ck(state_before == var_to_bytes(game.race.get_state_snapshot()),"no sporting mutations from UI")
        for i in range(100):
            game.race.step(0.2)
            if i % 10 == 0:
                hud.refresh_hud()
            await process_frame
        ck(game.race.clock >= 19.9,"race advanced 20 in-game seconds")
        await RenderingServer.frame_post_draw
        var screenshot := root.get_texture().get_image()
        var found: Vector2i = screenshot.get_size()
        ck(found.x >= size.x - 1 and found.y >= size.y - 1,"actual render dimensions " + str(found))
        var path := "res://qa/portraits_ci/real_hud_%dx%d.png" % [size.x,size.y]
        ck(screenshot.save_png(path) == OK,"actual rendering saved " + path)
        game.queue_free()
        await process_frame
    if failures.is_empty():
        print("APEX_PORTRAITS_REAL_SCENE_PASS checks=%d viewport=1600x900,1920x1080 fixture_only=true" % checks)
    else:
        printerr("APEX_PORTRAITS_REAL_SCENE_FAIL ", failures)
    quit(0 if failures.is_empty() else 1)
