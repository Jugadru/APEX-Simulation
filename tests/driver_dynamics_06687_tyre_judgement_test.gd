extends SceneTree
## Version 0.6.6.8.7 — deterministic, read-only driver dialogue integration.
const Judgement = preload("res://scripts/core/race_driver_tyre_judgement_06687.gd")
const Dialogue = preload("res://scripts/core/race_stint_dialogue_0635.gd")
const Race = preload("res://scripts/race_engine.gd")
var checks: int = 0
func _initialize() -> void:
    call_deferred("run")
func verify(value: bool, reason: String) -> void:
    checks += 1
    if not value:
        printerr("DRIVER_06687_FAIL: " + reason)
        quit(1)
        assert(value, reason)
func make_car() -> Dictionary:
    return {"id": 3, "name": "Piloto de teste", "laps_done": 9,
        "stint_laps": 8, "last_pit_exit_lap": 0, "best_lap": 100.0,
        "last_lap": 103.0, "wear": 52.0, "tyre_heat": 0.20,
        "risk_tolerance": 55.0, "tire": "Médio", "pit_scheduled_lap": 21,
        "pit_request": false, "pit_left": 0.0, "finished": false}
func run() -> void:
    var car := make_car()
    var soul: Dictionary = {"perceived_wear": 45.0, "initiative": 0.6}
    var before: PackedByteArray = var_to_bytes([car, soul])
    var loss: Dictionary = Judgement.assess(car, soul)
    verify(loss.valid and loss.state == "perda_ritmo", "Recent loss must be reported")
    verify(is_equal_approx(float(loss.delta_s), 3.0), "Difference is measured, not invented")
    verify(var_to_bytes([car, soul]) == before, "Calculator must be pure")
    verify(var_to_bytes(Judgement.assess(car, soul)) == var_to_bytes(loss), "Deterministic output")

    var low_risk: Dictionary = car.duplicate(true)
    low_risk["risk_tolerance"] = 20.0
    low_risk["last_lap"] = 101.43
    var high_risk: Dictionary = low_risk.duplicate(true)
    high_risk["risk_tolerance"] = 90.0
    verify(Judgement.assess(low_risk, soul).state == "perda_ritmo", "Cautious driver reports smaller loss")
    verify(Judgement.assess(high_risk, soul).state != "perda_ritmo", "Risk-tolerant driver waits longer")
    var stable: Dictionary = car.duplicate(true)
    stable["last_lap"] = 100.20
    stable["wear"] = 40.0
    verify(Judgement.assess(stable, soul).state == "stint_estavel", "Healthy stint requests extension")
    stable["tyre_heat"] = 0.85
    verify(Judgement.assess(stable, soul).state != "stint_estavel", "Overheated tyre cannot be called stable")
    stable["tyre_heat"] = 0.20
    stable["last_lap"] = 0.0
    verify(not Judgement.assess(stable, soul).valid, "Invalid timing cannot yield claims")
    stable["last_lap"] = 100.20
    stable["stint_laps"] = 1
    verify(not Judgement.assess(stable, soul).valid, "Out lap cannot be a comparison")

    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for item in season.tracks:
        if str(item.code) == "BEL":
            track = item
    verify(not track.is_empty(), "Spa fixture")
    var race = Race.new(season.teams, "Ferrari", 6687, {}, track, {})
    var player: Dictionary = race.player_cars()[0]
    var id: int = int(player.id)
    verify(race.schedule_pit(id, race.available_pit_compounds()[0], 21), "Protect V21 schedule")
    var snapshot: Dictionary = race.get_state_snapshot()
    snapshot["time"] = 1900.0
    for item in snapshot.cars:
        if int(item.id) == id:
            item["wear"] = 52.0
            item["last_lap"] = 103.0
            item["best_lap"] = 100.0
            item["stint_laps"] = 8
            item["laps_done"] = 9
            item["last_pit_exit_lap"] = 0
            item["tyre_heat"] = 0.2
            item["risk_tolerance"] = 55.0
    var race_before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
    var snapshot_before: PackedByteArray = var_to_bytes(snapshot)
    var advice: Dictionary = {"planned_pit_lap": 21, "pit_now": false}
    var dialogue: Dictionary = Dialogue.evaluate(id, snapshot, advice, {}, soul)
    verify(str(dialogue.timing.state) == "perda_ritmo", "Dialogue integrates measured pace loss")
    verify(str(dialogue.driver).contains("3.00s"), "Driver mentions real delta")
    verify(str(dialogue.engineer).contains("Tráfego") and str(dialogue.engineer).contains("volta 21"), "Engineer contextualizes and protects V21")
    verify(bool(dialogue.read_only) and bool(dialogue.fictional), "Advice is explicitly simulated")
    verify(bool(Dialogue.evaluate(id, snapshot, advice, dialogue.memory, soul).repeat), "Same condition is throttled")
    var improved: Dictionary = snapshot.duplicate(true)
    for item in improved.cars:
        if int(item.id) == id:
            item["last_lap"] = 100.18
            item["wear"] = 39.0
    var fresh: Dictionary = Dialogue.evaluate(id, improved, advice, dialogue.memory, soul)
    verify(not bool(fresh.repeat) and bool(fresh.wants_extend), "Material pace improvement revives dialogue")
    verify(str(fresh.engineer).contains("volta 21"), "Stable tyres never cancel V21")
    var wet: Dictionary = snapshot.duplicate(true)
    wet.weather["wetness_factor"] = 0.85
    var wet_dialogue: Dictionary = Dialogue.evaluate(id, wet, advice, {}, soul)
    verify(not bool(wet_dialogue.wants_extend), "Wrong compound overrides pace confidence")
    verify(var_to_bytes(snapshot) == snapshot_before, "Input snapshot untouched")
    verify(var_to_bytes(race.get_state_snapshot()) == race_before, "Race engine state untouched")
    verify(int(player.pit_scheduled_lap) == 21 and not bool(player.pit_request), "No unintended pit command")
    print("DRIVER_DYNAMICS_06687_PASS ", {"checks": checks, "pure": true, "protected_box": 21})
    quit(0)
