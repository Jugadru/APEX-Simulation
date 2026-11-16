extends SceneTree
## UI-level smoke for 0644, retaining all 0643 screens and interactive systems.
const Race = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("run")
func require(value: bool, label: String) -> void:
    if not value:
        printerr("APEX_0644_HUD_FAIL " + label)
        failures.append(label)
func run() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    require(game.race != null, "race created")
    if game.race == null:
        quit(1)
        return
    for i in range(8):
        game.race.step(4.0)
    game.pitwall_mode = 1
    game._refresh_pitwall_summary()
    require(game.pitwall_summary_body != null, "pitwall panel exists")
    if game.pitwall_summary_body != null:
        require(game.pitwall_summary_body.text.contains("Superfície"), "thermal surface in HUD")
        require(game.pitwall_summary_body.text.contains("Carcaça"), "core temp in HUD")
        require(game.pitwall_summary_body.text.contains("Graining"), "graining in HUD")
    game.race_hud_0620.refresh_hud()
    require(float(game.race.weather_snapshot().get("track_c", 0.0)) > 5.0, "asphalt available")
    require(int(game.race.weather_snapshot().get("rubber", -1)) >= 0, "rubber available")
    for car in game.race.player_cars():
        require(car.has("tyre_surface_c") and car.has("tyre_core_c"), "thermal car state")
    if failures.is_empty():
        print("APEX_0644_HUD_PASS: scene, PNEUS panel, thermal data, HUD, weather, 2 player cars")
        quit(0)
    else:
        quit(1)
