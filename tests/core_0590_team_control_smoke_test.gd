extends SceneTree
## Run with: godot --headless --path . --script res://tests/core_0590_team_control_smoke_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")
const AutoScript = preload("res://scripts/core/race_team_autonomy.gd")
const GarageScript = preload("res://scripts/garage.gd")

func _failure(reason: String) -> void:
    push_error("0590: " + reason)
    quit(1)

func _initialize() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    if typeof(parsed) != TYPE_DICTIONARY:
        _failure("invalid 2012 season JSON")
        return
    var season: Dictionary = parsed
    var tracks: Array = season.get("tracks", [])
    if tracks.size() < 12:
        _failure("missing Spa / tracks")
        return
    var race = RaceScript.new(season["teams"], "Ferrari", 42,
        {"Motor": 0, "Asa": 0, "Chassi": 0}, tracks[11],
        {"Agilidade": 0, "Precisão": 0, "Coordenação": 0})
    var pilots: Array = race.player_cars()
    if pilots.size() != 2:
        _failure("expected two controlled drivers")
        return
    var target: Dictionary = pilots[0]
    var id: int = int(target["id"])
    if not race.schedule_pit(id, "Intermediário", 21):
        _failure("manual scheduled pit rejected")
        return
    for driver in pilots:
        if not race.set_pit_control_mode(int(driver["id"]), "IA"):
            _failure("AI pit control not enabled")
            return
    if int(target.get("pit_scheduled_lap", 0)) != 21 or bool(target.get("pit_request", false)):
        _failure("scheduled pit was wrongly advanced")
        return
    var weather: Dictionary = {"wetness_factor": 0.04}
    target["laps_done"] = 3
    target["wear"] = 84.0
    var decision: Dictionary = AutoScript.decide(target, {"forecast_3": 0.04}, weather,
        {"Engenheiro": 2, "Estrategista": 2}, int(race.lap_count))
    if decision.get("pace", "") != "Conservar" or decision.get("kers", "") != "Economizar":
        _failure("autonomy did not conserve heavily worn tyres")
        return
    target["wear"] = 15.0
    target["interval"] = 0.6
    decision = AutoScript.decide(target, {"forecast_3": 0.04}, weather,
        {"Engenheiro": 2, "Estrategista": 2}, int(race.lap_count))
    if decision.get("pace", "") != "Atacar" or decision.get("kers", "") != "Atacar":
        _failure("autonomy did not attack nearby competitor")
        return
    race.set_pace(id, str(decision["pace"]))
    race.set_kers_mode(id, str(decision["kers"]))
    if str(target.get("pace", "")) != "Atacar":
        _failure("race engine did not receive autonomous pace order")
        return
    for driver in pilots:
        if not race.set_pit_control_mode(int(driver["id"]), "Manual"):
            _failure("manual takeover failed")
            return
    if int(target.get("pit_scheduled_lap", 0)) != 21 or str(target.get("pit_control_mode", "")) != "Manual":
        _failure("manual takeover erased scheduled pit")
        return
    print("PASS 0590 runtime: manual/auto pit mode, staff pace/KERS, V21 preserved")
    quit(0)
