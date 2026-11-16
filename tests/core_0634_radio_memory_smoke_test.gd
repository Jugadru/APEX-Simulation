extends SceneTree
## Apex v0.6.3.4: memory, single-driver filter, no obsolete strategy and GUI.
const RaceScript = preload("res://scripts/race_engine.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")
const Memory = preload("res://scripts/core/race_driver_memory_0634.gd")
const Interactive = preload("res://scripts/core/race_engineer_interactive.gd")

func _initialize() -> void:
    call_deferred("_run")

func expect(ok: bool, message: String) -> bool:
    if not ok:
        printerr("FAIL 0634: " + message)
    return ok

func _run() -> void:
    var good: bool = true
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for t in season["tracks"]:
        if str(t.get("code", "")) == "MON":
            track = t
            break
    var race = RaceScript.new(season["teams"], "Red Bull Racing Renault", 634, {}, track, {})
    var car_a: Dictionary = race.player_cars()[0]
    var car_b: Dictionary = race.player_cars()[1]
    var a_id: int = int(car_a["id"])
    var b_id: int = int(car_b["id"])
    var before: String = JSON.stringify(race.get_state_snapshot())
    var snapshot: Dictionary = race.get_state_snapshot()
    var first: Dictionary = Memory.observe(a_id, snapshot)
    good = expect(bool(first.get("subjective_only", false)) and not bool(first.get("repeat", true)), "First subjective report") and good
    var second: Dictionary = Memory.observe(a_id, snapshot, first.get("memory", {}))
    good = expect(bool(second.get("repeat", false)), "Duplicate contact should be rate limited") and good
    var modified: Dictionary = snapshot.duplicate(true)
    modified["time"] = float(snapshot.get("time", 0.0)) + 120.0
    for item in modified["cars"]:
        if int(item.get("id", -1)) == a_id:
            item["wear"] = 45.0
    var third: Dictionary = Memory.observe(a_id, modified, first.get("memory", {}))
    good = expect(not bool(third.get("repeat", true)) and str(third.get("message", "")).contains("aderência caiu"), "Updated perception should mention degradation") and good
    var stale: Dictionary = snapshot.duplicate(true)
    for item in stale["cars"]:
        if int(item.get("id", -1)) == a_id:
            item["laps_done"] = 11
            item["pit_scheduled_lap"] = 0
    var stale_answer: Dictionary = Interactive.answer("box", a_id, stale, {"planned_pit_lap": 9, "compound": "Supermacio", "pit_now": false})
    good = expect(not str(stale_answer.get("reply", "")).contains("volta 9") and str(stale_answer.get("reply", "")).contains("restam 67"), "Past pit window must be discarded") and good
    var future_answer: Dictionary = Interactive.answer("box", a_id, stale, {"planned_pit_lap": 20, "compound": "Supermacio", "pit_now": false})
    good = expect(str(future_answer.get("reply", "")).contains("volta 20"), "Genuine future pit window") and good
    var cast = Commentary.new()
    cast.reset(634)
    cast.add_driver_consultation(12.0, str(car_a["name"]), "mensagem carro A", "resposta A", a_id)
    cast.add_driver_consultation(13.0, str(car_b["name"]), "mensagem carro B", "resposta B", b_id)
    good = expect(cast.formatted(2, a_id).contains("mensagem carro A") and not cast.formatted(2, a_id).contains("mensagem carro B"), "Selected team driver A") and good
    good = expect(cast.formatted(3, b_id).contains("mensagem carro B") and not cast.formatted(3, b_id).contains("mensagem carro A"), "Selected radio driver B") and good
    good = expect(cast.formatted(0, a_id).contains("mensagem carro B"), "All filter must be unaffected") and good
    good = expect(not cast.formatted(1).contains("mensagem carro A"), "TV must never show private messages") and good
    good = expect(JSON.stringify(race.get_state_snapshot()) == before, "Radio computations modified race") and good
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    good = expect(hud != null and hud.visible, "HUD initialized") and good
    if hud != null:
        hud._open_window("radio")
        good = expect(hud.radio_only_button != null and hud.radio_driver_ids.size() == 2, "Single pilot control") and good
        hud._set_radio_category(3)
        hud._toggle_radio_driver_filter()
        good = expect(hud.radio_only_selected and hud._selected_radio_id() == hud.radio_driver_ids[0], "Selected car ID") and good
        var state_before: String = JSON.stringify(game.race.get_state_snapshot())
        hud._ask_driver()
        var entries: int = game.commentary.lines.size()
        hud._ask_driver()
        good = expect(entries == game.commentary.lines.size(), "Repeated pilot consultation adds no spam") and good
        hud.radio_driver_picker.select(1)
        hud._radio_driver_changed(1)
        good = expect(hud._selected_radio_id() == hud.radio_driver_ids[1], "Driver changed") and good
        hud._ask_engineer("box")
        good = expect(hud.radio_response_label.text.contains("ENGENHEIRO") and hud.radio_history.text.contains("ENGENHEIRO"), "Engineer response in selected channel") and good
        good = expect(not hud.radio_history.text.contains("Para " + hud.radio_driver_picker.get_item_text(0) + ":"), "Other pilot not leaked") and good
        good = expect(JSON.stringify(game.race.get_state_snapshot()) == state_before, "HUD consultations changed race") and good
        hud._set_radio_category(1)
        good = expect(hud.radio_only_button.disabled, "Selected filter disabled on TV") and good
        hud._set_radio_category(2)
        good = expect(not hud.radio_only_button.disabled, "Selected filter enabled on team") and good
    if good:
        print("APEX 0.6.3.4 PASS: past pit warning, memory, selected pilot, anti-spam, full HUD and unchanged race")
    quit(0 if good else 1)
