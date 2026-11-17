extends SceneTree
## One round per OS process: real scene, career callbacks and persisted saves.
const Garage = preload("res://scripts/garage.gd")
const Championship = preload("res://scripts/championship_2012.gd")
const POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
const CODES := ["AUS", "MAL", "CHN", "BHR", "ESP", "MON", "CAN", "EUR"]
var failures: Array[String] = []
var checks: int = 0
var evidence: Dictionary = {}
var output: String
var index: int

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)
        printerr("CAREER_FAIL round=%d %s" % [index + 1, message])

func signature(value: Variant) -> String:
    # JSON reload represents numbers as floats; compare canonical persisted values.
    return JSON.stringify(JSON.parse_string(JSON.stringify(value)))

func store_json(path: String, value: Variant) -> void:
    var f = FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        failures.append("cannot write " + path)
        return
    f.store_string(JSON.stringify(value, "  "))
    f.close()

func finish(game = null) -> void:
    evidence["checks"] = checks
    evidence["errors"] = failures
    evidence["status"] = "PASS" if failures.is_empty() else "FAIL"
    store_json(output.path_join("round_%02d.json" % (index + 1)), evidence)
    print("CAREER_%s round=%d code=%s checks=%d" % ["PASS" if failures.is_empty() else "FAIL", index + 1, CODES[index], checks])
    if game != null:
        game.free()
    quit(0 if failures.is_empty() else 1)

func run() -> void:
    var args = OS.get_cmdline_user_args()
    if args.size() != 1 or not str(args[0]).is_valid_int():
        printerr("Usage: -- round_index (0..7)")
        quit(2)
        return
    index = int(args[0])
    if index < 0 or index >= 8:
        quit(2)
        return
    output = OS.get_environment("APEX_CAREER_QA_DIR")
    if output.is_empty():
        printerr("APEX_CAREER_QA_DIR and an isolated XDG_DATA_HOME are required")
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(output)
    var began: int = Time.get_ticks_msec()
    evidence = {"round": index + 1, "code": CODES[index], "step_seconds": 0.20, "engine": Engine.get_version_info()["string"]}
    # Never initialize over an existing career. Shell runner owns the fresh data dir.
    if index == 0:
        check(not FileAccess.file_exists(Championship.SAVE_PATH), "fresh career directory")
        check(not FileAccess.file_exists(Garage.SAVE_PATH), "fresh garage directory")
        if not failures.is_empty():
            finish()
            return
        store_json(Garage.SAVE_PATH, {})
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false) # manual native ticks; never mix wall-clock advancement
    if index == 0:
        game.selected_team = "Ferrari"
        game.seed_picker.value = 321
        game._new_championship()
    check(game.championship_mode and game.championship.has_season(), "career resumes through real scene")
    check(int(game.championship.state.get("round_index", -1)) == index, "saved round sequence")
    check(str(game.championship.next_round().get("code", "")) == CODES[index], "calendar continuity")
    check(game.selected_team == "Ferrari", "saved player team")
    var loaded_garage: Dictionary = game.garage.get_team("Ferrari").duplicate(true)
    if index > 0:
        var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("round_%02d.json" % index)))
        check(signature(game.championship.state) == signature(previous["season_after"]), "championship survives OS process restart")
        check(signature(loaded_garage) == signature(previous["garage_after"]), "garage survives OS process restart")
    evidence["loaded_garage"] = loaded_garage
    evidence["season_before"] = game.championship.state.duplicate(true)
    var budget_before: int = int(loaded_garage["budget"])
    var expense: int = 0
    game._open_garage()
    if index == 0:
        game._buy_part("Motor")
        game._buy_crew("Agilidade")
        game._hire_staff("Engenheiro")
        game._start_garage_research("Asa")
        expense = 2000000 + 240000 + 300000 + 1360000
    elif index == 1:
        var locked: String = signature(game.garage.get_team("Ferrari"))
        game._buy_part("Asa")
        game._start_garage_research("Chassi")
        check(signature(game.garage.get_team("Ferrari")) == locked, "active project prevents duplicate purchase/research")
    elif index == 2:
        game._start_garage_research("Chassi")
        expense = 1190000
    elif index == 4:
        game._start_garage_research("Motor")
        game._cancel_garage_research()
        check(int(game.garage.get_team("Ferrari")["budget"]) == budget_before - 850000, "cancel returns exactly 75 percent")
        game._start_garage_research("Motor")
        expense = 4250000
    elif index == 6:
        game._start_garage_research("Asa")
        expense = 2720000
    var garage_before: Dictionary = game.garage.get_team("Ferrari").duplicate(true)
    check(int(garage_before["budget"]) == budget_before - expense, "workshop budget ledger")
    check(int(garage_before["crew_levels"]["Agilidade"]) == 1 and int(garage_before["staff_levels"]["Engenheiro"]) == 1, "crew and staff persist")
    var expected_levels: Dictionary = {"Motor": 2 if index >= 6 else 1, "Asa": 1 if index >= 2 else 0, "Chassi": 1 if index >= 4 else 0}
    check(signature(garage_before["levels"]) == signature(expected_levels), "research available only after due rounds")
    check(game.garage_rivals_summary.text.contains("Red Bull"), "actual workshop rival display")
    evidence["workshop_expense"] = expense
    evidence["garage_before_race"] = garage_before
    if not failures.is_empty():
        finish(game)
        return
    game.team_control_mode = "Automático"
    game.weather_mode_picker.select(0)
    game._start_race()
    var race = game.race
    check(game.championship_race_active, "real session enters career")
    check(str(race.track["code"]) == CODES[index], "real race follows calendar")
    check(int(race.rng.seed) == 321 + index * 7919, "career seed continuity")
    check(signature(race.team_upgrades) == signature(expected_levels), "workshop levels reach race engine")
    check(signature(race.rival_upgrades) == signature(game.championship.get_rival_levels()), "rival investments reach race engine")
    for c in race.player_cars():
        check(c["pit_control_mode"] == "IA" and game._engineer_mode_for(int(c["id"])) == "Automático", "full automatic player control")
    evidence["seed"] = 321 + index * 7919
    evidence["race_upgrades"] = race.team_upgrades.duplicate(true)
    evidence["race_rival_upgrades"] = race.rival_upgrades.duplicate(true)
    var championship_before: String = FileAccess.get_file_as_string(Championship.SAVE_PATH)
    race.running = true
    var ticks: int = 0
    print("CAREER_START round=%d code=%s laps=%d native_step=0.20" % [index + 1, CODES[index], race.lap_count])
    while not race.finished and ticks < 100000:
        game._autonomy_tick()
        var before: float = race.clock
        race.step(0.20)
        ticks += 1
        if not is_finite(race.clock) or absf(race.clock - before - 0.20) > 0.000001:
            check(false, "native step clock")
            break
        if ticks % 3000 == 0:
            print("CAREER_PROGRESS round=%d lap=%d/%d simulated_s=%.1f" % [index + 1, race.lap, race.lap_count, race.clock])
        if ticks % 100 == 0:
            for c in race.cars:
                for field in ["wear", "tyre_surface_c", "tyre_core_c", "progress"]:
                    if not is_finite(float(c[field])):
                        check(false, "non-finite " + field)
            if not failures.is_empty(): break
    check(race.finished and race.finish_results_validated, "full GP finished and classified")
    check(FileAccess.get_file_as_string(Championship.SAVE_PATH) == championship_before, "unfinished GP never changes career save")
    var order: Array = race.get_sorted()
    check(order.size() == 24, "24 car grid")
    var expected_drivers: Dictionary = game.championship.state["drivers"].duplicate(true)
    var expected_teams: Dictionary = game.championship.state["constructors"].duplicate(true)
    var best_player: int = 99
    var stops: int = 0
    for i in range(order.size()):
        var c: Dictionary = order[i]
        check(c["finished"] and not c.get("disqualified", false), "valid finisher " + str(c["name"]))
        check(int(c.get("invalid_lap_count", 0)) == 0 and float(c["best_lap"]) >= race.base_lap * 0.70, "timing " + str(c["name"]))
        check(int(c["position"]) == i + 1, "classified position")
        var points: int = POINTS[i] if i < 10 else 0
        expected_drivers[c["name"]] += points
        expected_teams[c["team"]] += points
        stops += int(c["stops"])
        if c["team"] == "Ferrari": best_player = mini(best_player, i + 1)
    var reward: int = 500000 + maxi(0, 11 - best_player) * 70000
    evidence.merge({"ticks": ticks, "clock": race.clock, "laps": race.lap_count, "stops": stops,
        "positions": order.duplicate(true), "pit_history": race.get_pit_history(),
        "winner": order[0]["name"], "expected_reward": reward}, true)
    if not failures.is_empty():
        finish(game)
        return
    game._commit_championship_result()
    check(game.championship_result_saved, "real UI commits result")
    check(int(game.championship.state["round_index"]) == index + 1, "career advances exactly once")
    check(signature(game.championship.state["drivers"]) == signature(expected_drivers), "independent driver points ledger")
    check(signature(game.championship.state["constructors"]) == signature(expected_teams), "independent constructor points ledger")
    var garage_after: Dictionary = game.garage.get_team("Ferrari").duplicate(true)
    check(int(garage_after["budget"]) == int(garage_before["budget"]) + reward, "one correct cash prize")
    check(garage_after["championship_awards"].size() == index + 1, "one reward entry per GP")
    var expected_after: Dictionary = {"Motor": 2 if index >= 5 else 1, "Asa": 2 if index == 7 else (1 if index >= 1 else 0), "Chassi": 1 if index >= 3 else 0}
    check(signature(garage_after["levels"]) == signature(expected_after), "P&D delivery at exact round")
    var before_rivals: Dictionary = evidence["season_before"]["rival_development"]
    var after_rivals: Dictionary = game.championship.get_rival_development()
    check(after_rivals.size() == 11 and not after_rivals.has("Ferrari"), "11 independent rival teams")
    for name in after_rivals:
        var account: Dictionary = after_rivals[name]
        var prev: Dictionary = before_rivals[name]
        var history: Array = account["history"]
        check(history.size() == index + 1, "rival history once per round " + name)
        var entry: Dictionary = history[-1]
        check(int(entry["round"]) == index + 1, "rival round " + name)
        check(int(account["budget"]) == int(prev["budget"]) + int(entry["revenue"]) - int(entry["cost"]) and int(account["budget"]) >= 0, "rival budget " + name)
        check(int(account["invested"]) == int(prev["invested"]) + int(entry["cost"]), "rival investment " + name)
        for part in ["Motor", "Asa", "Chassi"]:
            var increment: int = 1 if entry["action"] == "melhoria" and entry["part"] == part else 0
            check(int(account["levels"][part]) == int(prev["levels"][part]) + increment and int(account["levels"][part]) <= 3, "rival levels " + name + " " + part)
    var season_saved: String = signature(game.championship.state)
    var garage_saved: String = signature(game.garage.get_team("Ferrari"))
    game._commit_championship_result()
    game._reconcile_championship_rewards()
    game._reconcile_championship_rewards()
    check(signature(game.championship.state) == season_saved and signature(game.garage.get_team("Ferrari")) == garage_saved, "duplicate commit/reconcile is idempotent")
    var duplicate: Dictionary = game.championship.record_result(race.track, order, race.clock)
    check(not duplicate.get("ok", true) and signature(game.championship.state) == season_saved, "old GP cannot score twice")
    var loaded = Championship.new()
    var restored = Garage.new()
    check(signature(loaded.state) == season_saved, "championship disk roundtrip")
    check(signature(restored.get_team("Ferrari")) == garage_saved, "garage disk roundtrip")
    game._end_to_menu()
    game._resume_championship()
    check(game.selected_track_index == index + 1, "next GP selected by real menu")
    evidence["season_after"] = game.championship.state.duplicate(true)
    evidence["garage_after"] = garage_after
    evidence["wall_seconds"] = (Time.get_ticks_msec() - began) / 1000.0
    store_json(output.path_join("championship_after_%02d.json" % (index + 1)), loaded.state)
    store_json(output.path_join("garage_after_%02d.json" % (index + 1)), restored.team_data)
    finish(game)
