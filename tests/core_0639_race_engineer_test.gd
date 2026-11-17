extends SceneTree
## v0.6.3.9: Race Engineer must observe the core without modifying physics.
const RaceScript = preload("res://scripts/race_engine.gd")
const Engineer = preload("res://scripts/core/race_engineer_0639.gd")
const Autonomy = preload("res://scripts/core/race_team_autonomy.gd")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, description: String) -> void:
    if not value:
        failures.append(description)
        printerr("APEX_0639_FAIL: ", description)

func _run() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for candidate in season["tracks"]:
        if str(candidate.get("code", "")) == "BRA":
            track = candidate
            break
    check(int(track.get("laps", 0)) == 71, "Interlagos must have 71 laps")
    var race = RaceScript.new(season["teams"], "Ferrari", 321, {}, track, {})
    race.configure_weather("Seco")
    var car: Dictionary = race.player_cars()[0]
    var id: int = int(car["id"])
    var tire: String = str(race.available_pit_compounds()[1])
    check(race.schedule_pit(id, tire, 21), "V21 manual reservation")
    var before: String = JSON.stringify(race.get_state_snapshot())
    var advice: Dictionary = race.get_engineer_advice(id)
    var weather: Dictionary = race.weather_snapshot()
    var staff: Dictionary = {"Engenheiro": 2, "Estrategista": 2}
    var plan: Dictionary = Engineer.evaluate(car, advice, weather, staff, race.lap_count)
    var previous: Dictionary = Autonomy.decide(car, advice, weather, staff, race.lap_count)
    check(str(plan.get("pace", "")) == str(previous.get("pace", "")), "existing AI pace preserved")
    check(str(plan.get("kers", "")) == str(previous.get("kers", "")), "existing KERS recommendation preserved")
    check(int(plan.get("scheduled_lap", 0)) == 21, "booked stop recognized")
    check(not bool(plan.get("can_call_pit", true)), "scheduled V21 not overwritten")
    check(str(plan.get("briefing", "")).contains("21"), "engineer explains booking")
    check(JSON.stringify(race.get_state_snapshot()) == before, "engineer doesn't mutate race data")
    race.running = true
    for n in range(24):
        race.step(4.0)
    check(int(car.get("pit_scheduled_lap", 0)) == 21, "V21 still scheduled after first lap")
    check(not bool(car.get("pit_request", false)), "no unsolicited manual box")
    check(float(car.get("progress", 0.0)) >= 0.0, "car continues along the track")
    # Real main scene + modern interactive HUD; no conceptual mockups.
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    check(hud != null and hud.visible, "real HUD available")
    hud._open_window("engineer")
    check(hud.active_window == "engineer", "engineer window opens")
    check(hud.engineer_cards.size() == 2, "two drivers represented")
    check(hud.engineer_reports.size() == 2, "both drivers have current advice")
    var player: Dictionary = game.race.player_cars()[0]
    var pid: int = int(player["id"])
    hud._engineer_accept_pace(pid)
    check(str(player.get("pace", "")) in ["Normal", "Atacar", "Conservar"], "manual accepts pace")
    # A stale button/report must not overrule a newly scheduled manual pit.
    var legal_tire: String = str(game.race.available_pit_compounds()[1])
    check(game.race.schedule_pit(pid, legal_tire, 21), "GUI V21 booked")
    hud.engineer_reports[pid] = {"can_call_pit": true, "compound": legal_tire}
    hud._engineer_accept_pit(pid)
    check(int(player.get("pit_scheduled_lap", 0)) == 21, "stale engineer advice did not erase V21")
    check(not bool(player.get("pit_request", false)), "stale engineer advice did not call early BOX")
    hud._update_engineer_reports()
    hud._engineer_change_mode(1)
    check(game.team_control_mode == "Automático", "auto mode delegated to staff")
    check(str(player.get("pit_control_mode", "")) == "IA", "automatic pit mode delegated")
    hud._engineer_change_mode(0)
    check(game.team_control_mode == "Manual", "manual mode restored")
    check(str(player.get("pit_control_mode", "")) == "Manual", "manual pit mode restored")
    hud._engineer_ask(pid)
    check(game.commentary != null, "race engineer radio uses existing commentary")
    hud._close_window()
    check(hud.active_window == "", "window closes")
    if failures.is_empty():
        print("APEX 0639 ENGINEER PASS: 71-lap setup; immutable advice; V21; STAFF AI parity; HUD/manual/auto/radio")
        quit(0)
    else:
        print("APEX 0639 ENGINEER FAILED: ", failures)
        quit(1)
