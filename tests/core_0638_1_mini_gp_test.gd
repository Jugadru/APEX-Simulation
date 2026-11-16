extends SceneTree
## Fast self-contained dry and wet 4-lap regressions with pit-lane crossing.
const RaceScript = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    var team_subset: Array = []
    for item in season["tracks"]:
        if str(item["code"]) == "BRA":
            track = item.duplicate(true)
    track["laps"] = 4
    track["race_km"] = float(track["lap_km"]) * 4.0
    for item in season["teams"]:
        if str(item["name"]) in ["Ferrari", "Red Bull Racing Renault"]:
            team_subset.append(item.duplicate(true))
    if team_subset.size() < 2:
        # Reuse Ferrari and the first independent rival, whatever its label.
        team_subset.clear()
        for item in season["teams"]:
            if str(item["name"]) == "Ferrari" or (team_subset.size() < 2 and str(item["name"]) != "Ferrari"):
                team_subset.append(item.duplicate(true))
    var passed: bool = true
    for mode in ["Seco", "Chuva intensa"]:
        var race = RaceScript.new(team_subset, "Ferrari", 321, {}, track, {})
        race.configure_weather(mode)
        var own: Array = race.player_cars()
        if own.size() != 2:
            printerr("APEX MINI FAIL: Ferrari pilots missing")
            quit(1)
            return
        var compounds: Array = race.available_pit_compounds()
        race.schedule_pit(int(own[0]["id"]), str(compounds[1]), 2)
        race.schedule_pit(int(own[1]["id"]), str(compounds[1]), 3)
        race.running = true
        var steps: int = 0
        while not race.finished and steps < 1200:
            race.step(4.0)
            steps += 1
        var invalid: int = 0
        for car in race.cars:
            invalid += int(car.get("invalid_lap_count", 0))
            if float(car.get("best_lap", 9999.0)) < race.base_lap * 0.70:
                passed = false
        var own_pits: Array = race.get_pit_history("Ferrari")
        var pit_laps: Array = []
        for item in own_pits:
            pit_laps.append(int(item["lap"]))
        pit_laps.sort()
        var good: bool = race.finished and race.finish_results_validated and invalid == 0 and pit_laps == [2,3]
        print("APEX 0638.1 MINI GP ", mode, " steps=", steps, " finished=", race.finished, " pit_laps=", pit_laps, " invalid_laps=", invalid, " result=", "PASS" if good else "FAIL")
        if not good:
            passed = false
    quit(0 if passed else 1)
