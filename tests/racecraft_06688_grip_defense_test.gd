extends SceneTree
## Racecraft 2.0 — grip-aware defense, deterministic traffic and replay contract.
const Grip = preload("res://scripts/core/race_defense_grip_06688.gd")
const Tactics = preload("res://scripts/core/race_driver_dynamics_0661.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        printerr("RACECRAFT_06688_FAIL " + reason)
func make_car(id: int, progress: float) -> Dictionary:
    return {"id": id, "progress": progress, "race_lane": 0.0,
        "pit_left": 0.0, "finished": false, "skill": 84.0,
        "risk_tolerance": 60.0, "spatial_awareness": 90.0,
        "defense_aggression": 60.0, "attack_charge": 1.8,
        "combat_state": "closing", "combat_target_id": -1,
        "combat_attempts": 0, "combat_pass_pending": false,
        "combat_hesitation_s": 0.0, "wear": 20.0,
        "combat_cooldown": 0.0, "race_defending_against": -1,
        "race_defense_line": 0.0}
func run() -> void:
    var attacker := make_car(1, 0.350)
    var defender := make_car(2, 0.370)
    var dry := {"wetness_factor": 0.0}
    var wet := {"wetness_factor": 0.95}
    var track := {"code": "TEST", "race_width_m": 14.0, "overtake_zones": [[0.0, 1.0]]}
    check(bool(Grip.evaluate(defender, 20.0, dry).early_move), "Original dry defense preserved")
    check(is_zero_approx(float(Grip.evaluate(defender, 20.0, dry).caution)), "No dry penalty")
    check(not bool(Grip.evaluate(defender, 11.5, dry).early_move), "No late defense")
    check(not bool(Grip.evaluate(defender, 36.0, dry).early_move), "No distant defense")
    defender.wear = 82.0
    defender.spatial_awareness = 52.0
    var caution: Dictionary = Grip.evaluate(defender, 20.0, wet)
    check(not bool(caution.early_move), "Poor grip discourages early squeeze")
    check(float(caution.caution) > 0.0, "Additional wet caution is positive")
    check(bool(Grip.evaluate(defender, 20.0, dry).early_move), "Dry remains unchanged with worn tyres")
    defender.wear = 15.0
    defender.spatial_awareness = 98.0
    check(bool(Grip.evaluate(defender, 20.0, wet).early_move), "Fresh aware defender can defend")
    defender.wear = 82.0
    defender.spatial_awareness = 52.0
    var tactic: Dictionary = Tactics.choose(attacker, defender, 20.0, 3.0, 2.95, track, wet)
    check(not bool(tactic.defense), "Tactics use new early defense decision")
    check(bool(Tactics.choose(attacker, defender, 20.0, 3.0, 2.95, track, dry).defense), "Dry tactics unchanged")
    var source: PackedByteArray = var_to_bytes([attacker, defender, wet])
    check(Tactics.choose(attacker, defender, 20.0, 3.0, 2.95, track, wet) == tactic, "Pure deterministic judgement")
    check(var_to_bytes([attacker, defender, wet]) == source, "No mutation of cars/weather")
    defender.race_defending_against = 1
    defender.race_defense_line = 0.55
    defender.race_lane = 0.55
    var locked: Dictionary = Tactics.choose(attacker, defender, 8.0, 3.0, 2.95, track, wet)
    check(bool(locked.defense) and is_equal_approx(float(locked.defend_goal), 0.55), "Existing defensive line held")
    var pair: Array = [defender.duplicate(true), attacker.duplicate(true)]
    var pair_before: PackedByteArray = var_to_bytes(pair)
    var resolved: Dictionary = Space.plan(pair, {1: {"target": 87.0}, 2: {"target": 90.0}}, 0.2, track, {"length": 1000.0}, wet)
    check(resolved.has(1) and resolved.has(2), "Both cars stay in race")
    check(float(resolved[1].progress) >= float(attacker.progress), "No backward attacker teleport")
    check(float(resolved[2].progress) >= float(defender.progress), "No backward defender teleport")
    check(var_to_bytes(pair) == pair_before, "Frozen sporting state preserved")
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var spa: Dictionary = {}
    for t in data.tracks:
        if str(t.code) == "BEL": spa = t
    check(not spa.is_empty(), "Spa circuit loaded")
    var engine = Race.new(data.teams, "Ferrari", 6888, {}, spa, {})
    engine.configure_weather("Chuva intensa")
    var session = Replay.new()
    session.attach(engine)
    var car_id: int = int(engine.player_cars()[0].id)
    check(session.enqueue("schedule_pit", [car_id, str(engine.available_pit_compounds()[0]), 21], 1), "BOX V21 queued")
    for i in range(200):
        if not session.step_tick():
            check(false, "Race tick failed")
            break
    check(int(engine.player_cars()[0].get("pit_scheduled_lap", 0)) == 21, "Manual V21 preserved")
    var archive: Dictionary = session.export_data()
    check(archive.simulation_revision == Replay.SIMULATION_REVISION, "Replay revision updated")
    var replay = Replay.new()
    check(replay.load_data(archive) and replay.seek(session.tick), "New-rule replay verified")
    check(replay.hashes[-1] == session.hashes[-1], "Identical replay hash")
    archive.simulation_revision = "0661_driver_dynamics"
    check(not Replay.new().load_data(archive), "Old-rule replay explicitly rejected")
    if failures == 0:
        print("RACECRAFT_06688_GRIP_PASS checks=%d hash=%s" % [checks, session.hashes[-1]])
    quit(0 if failures == 0 else 1)
