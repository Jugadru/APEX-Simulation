extends SceneTree
## 0635: strategy disagreement is advisory only, radio is filtered and memory scoped.
const RaceScript = preload("res://scripts/race_engine.gd")
const Dialogue = preload("res://scripts/core/race_stint_dialogue_0635.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")
func _initialize() -> void:
    call_deferred("_run")
func check(condition: bool, message: String) -> bool:
    if not condition:
        printerr("FAIL 0635: " + message)
    return condition
func _run() -> void:
    var good: bool = true
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for t in season["tracks"]:
        if str(t.get("code", "")) == "BEL":
            track = t
            break
    var race = RaceScript.new(season["teams"], "Red Bull Racing Renault", 635, {}, track, {})
    var drivers: Array = race.player_cars()
    var id_a: int = int(drivers[0]["id"])
    var id_b: int = int(drivers[1]["id"])
    good = check(race.schedule_pit(id_a, "Médio", 21), "V21 booking failed") and good
    var original: String = JSON.stringify(race.get_state_snapshot())
    var state: Dictionary = race.get_state_snapshot()
    var advice: Dictionary = race.get_engineer_advice(id_a)
    var first: Dictionary = Dialogue.evaluate(id_a, state, advice)
    good = check(not first.is_empty() and bool(first.get("read_only", false)) and bool(first.get("fictional", false)), "Basic dialogue") and good
    good = check(str(first["engineer"]).contains("volta 21"), "Keep explicit booking") and good
    good = check(not bool(first.get("repeat", true)), "First attempt") and good
    var second: Dictionary = Dialogue.evaluate(id_a, state, advice, first["memory"])
    good = check(bool(second.get("repeat", false)), "Repeated unchanged request") and good
    var moderate: Dictionary = state.duplicate(true)
    moderate["time"] = 124.0
    for entry in moderate["cars"]:
        if int(entry.get("id", -1)) == id_a:
            entry["wear"] = 67.0
            entry["tyre_heat"] = 0.70
    var debate: Dictionary = Dialogue.evaluate(id_a, moderate, {"planned_pit_lap": 9, "pit_now": false})
    good = check(bool(debate.get("disagreement", false)) and bool(debate.get("wants_extend", false)) and str(debate["engineer"]).contains("67%"), "Driver wants extend, engineer cautions") and good
    var outdated: Dictionary = moderate.duplicate(true)
    for entry in outdated["cars"]:
        if int(entry.get("id", -1)) == id_a:
            entry["laps_done"] = 11
            entry["pit_scheduled_lap"] = 0
    var past: Dictionary = Dialogue.evaluate(id_a, outdated, {"planned_pit_lap": 9, "pit_now": false})
    good = check(not str(past["engineer"]).contains("volta 9"), "Past plan cannot be future") and good
    var unsuitable: Dictionary = moderate.duplicate(true)
    unsuitable["weather"]["wetness_factor"] = 0.60
    var wet: Dictionary = Dialogue.evaluate(id_a, unsuitable, advice)
    good = check(not bool(wet.get("wants_extend", true)) and str(wet["driver"]).contains("aderência"), "Wet conditions prioritised") and good
    var cast = Commentary.new()
    cast.reset(635)
    cast.add_stint_discussion(12.0, str(drivers[0]["name"]), str(debate["driver"]), str(debate["engineer"]), id_a)
    cast.add_stint_discussion(14.0, str(drivers[1]["name"]), "Segundo piloto", "Análise segundo piloto", id_b)
    good = check(not cast.formatted(1).contains("stint") and not cast.formatted(1).contains("RÁDIO FICTÍCIO"), "Private dialogue excluded from broadcast") and good
    good = check(cast.formatted(3, id_a).contains(str(drivers[0]["name"])) and not cast.formatted(3, id_a).contains("ENGENHEIRO"), "Pilot filter keeps driver") and good
    good = check(not cast.formatted(2, id_a).contains("Segundo piloto"), "No teammate leak") and good
    good = check(JSON.stringify(race.get_state_snapshot()) == original, "Dialogue changed physical race or booked pit") and good
    var packed: PackedScene = load("res://scenes/main.tscn")
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    good = check(hud != null and hud.visible, "HUD active") and good
    if hud != null:
        hud._open_window("radio")
        var before: String = JSON.stringify(game.race.get_state_snapshot())
        hud._discuss_stint()
        good = check(hud.radio_history.text.contains("PILOTO") and hud.radio_history.text.contains("ENGENHEIRO"), "Dialogue accessible on team radio") and good
        var num_lines: int = game.commentary.lines.size()
        hud._discuss_stint()
        good = check(game.commentary.lines.size() == num_lines, "Repeated stint discussion didn't spam") and good
        hud._set_radio_category(3)
        good = check(not hud.radio_history.text.contains("ENGENHEIRO"), "Pilot category isn't engineer") and good
        hud._set_radio_category(1)
        good = check(not hud.radio_history.text.contains("RÁDIO FICTÍCIO"), "Broadcast privacy") and good
        good = check(JSON.stringify(game.race.get_state_snapshot()) == before, "HUD dialogue mutated game state") and good
        hud.begin_race()
        good = check(hud.radio_stint_memory.is_empty(), "Memory resets for next GP") and good
    if good:
        print("APEX 0635 PASS: subjective pilot strategy, engineer divergence, no commands, filter, cooldown, reset, HUD")
    quit(0 if good else 1)
