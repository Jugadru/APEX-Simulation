extends SceneTree
## UI / radio integration for Soul Driver 2.0.
const Soul = preload("res://scripts/core/race_driver_soul_0647.gd")
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func require(ok: bool, label: String) -> void:
    if not ok:
        printerr("SOUL2_UI_FAIL: " + label)
        errors.append(label)

func _run() -> void:
    root.size = Vector2i(1600, 900)
    var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    await process_frame
    var hud = game.race_hud_0620
    require(hud != null and hud.visible, "real race HUD")
    if hud == null:
        quit(2)
        return
    var players: Array = game.race.player_cars()
    var car: Dictionary = players[0]
    var other: Dictionary = players[1]
    var id: int = int(car["id"])
    game.race.schedule_pit(id, game.race.available_pit_compounds()[1], 21)
    # Seed a plausible late-race tyre alert directly in the data, not an order.
    car["wear"] = 87.0
    car["laps_done"] = 4
    Soul.update(car, game.race.weather_snapshot(), other)
    var request: Dictionary = Soul.latest(car)
    require(str(request.get("kind", "")) == "revisar_plano", "pending driver request")
    var old_state: Array = [int(car["pit_scheduled_lap"]), bool(car["pit_request"]), str(car["pace"])]
    game.race.running = true
    hud.refresh_hud()
    require(int(hud.radio_soul_notified.get(id, 0)) == int(request.get("id", -1)), "automatic radio only once")
    var total_announced: int = hud.radio_soul_notified.size()
    hud.refresh_hud()
    require(hud.radio_soul_notified.size() == total_announced, "duplicate prevention")
    hud._open_window("radio")
    require(hud.radio_soul_request_label != null and hud.radio_soul_request_label.text.contains("AGUARDANDO"), "pending request radio")
    for frame_index in range(5):
        await process_frame
    var radio_screenshot: Image = root.get_texture().get_image()
    require(radio_screenshot.save_png("res://docs/APEX_SOUL2_RADIO_REAL.png") == OK, "radio screenshot")
    hud._answer_soul_request("ouvir")
    require(Soul.latest(car).get("answered", false), "answer stored in engine soul")
    require(hud.radio_soul_request_label.text.contains("RESPONDIDO"), "radio refreshes after answer")
    require([int(car["pit_scheduled_lap"]), bool(car["pit_request"]), str(car["pace"])] == old_state, "response does not change orders")
    hud._answer_soul_request("ouvir")
    require(Soul.latest(car).get("answered", false), "duplicate answer blocked")
    hud._close_window()
    hud._open_window("engineer")
    require(hud.overlay_title.text.contains("RACE ENGINEER 3.0"), "Engineer 3 preserved")
    require(hud.engineer_cards.size() == 2, "2 engineer cards")
    require((hud.engineer_cards[0]["text"] as Label).text.contains("SOUL 2.0"), "Soul in Engineer")
    for size in [Vector2i(1600, 900), Vector2i(1920, 1080)]:
        root.size = size
        await process_frame
        game._layout_ui()
        hud.layout_hud()
        require(hud.ranking.position.x == 12.0, "ranking placement")
    root.size = Vector2i(1600, 900)
    await process_frame
    game._layout_ui()
    hud.layout_hud()
    for i in range(4):
        await process_frame
    var screenshot: Image = root.get_texture().get_image()
    require(screenshot.get_width() == 1600 and screenshot.get_height() == 900, "render dimensions")
    require(screenshot.save_png("res://docs/APEX_SOUL2_ENGENHEIRO_REAL.png") == OK, "render capture")
    if errors.is_empty():
        print("SOUL2_UI_PASS real HUD radio answered, controls unchanged, Engineer 3, resolution 1600/1920")
        quit(0)
    else:
        quit(1)
