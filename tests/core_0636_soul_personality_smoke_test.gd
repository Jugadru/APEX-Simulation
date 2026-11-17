extends SceneTree
## Tests APEX Soul Driver v0.6.3.6: persona ficcional, memória, ações de rádio sem tocar física.
const RaceScript = preload("res://scripts/race_engine.gd")
const Soul = preload("res://scripts/core/race_soul_driver_0636.gd")
const Dialogue = preload("res://scripts/core/race_stint_dialogue_0635.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> bool:
    if not condition:
        printerr("FAIL 0636: " + message)
    return condition

func _run() -> void:
    var good: bool = true
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for item in season["tracks"]:
        if str(item.get("code", "")) == "BEL":
            track = item
            break
    var race = RaceScript.new(season["teams"], "Red Bull Racing Renault", 636, {}, track, {})
    var cars: Array = race.player_cars()
    var pilot: int = int(cars[0]["id"])
    var teammate: int = int(cars[1]["id"])
    good = check(race.schedule_pit(pilot, "Médio", 21), "V21 booked") and good
    var baseline: String = JSON.stringify(race.get_state_snapshot())
    var snapshot: Dictionary = race.get_state_snapshot()
    var original_soul: Dictionary = Soul.initial_profile(pilot)
    good = check(original_soul == Soul.initial_profile(pilot), "Profile deterministic") and good
    good = check(original_soul != Soul.initial_profile(teammate), "Not a universal personality") and good
    var perception: Dictionary = Soul.perceive(pilot, snapshot, original_soul)
    good = check(not perception.is_empty() and perception.has("perceived_wear") and perception.has("actual_wear"), "Perception created") and good
    var rejected: Dictionary = Soul.choose(original_soul, "piloto")
    good = check(not bool(rejected.get("applied", false)), "Cannot respond before discussion") and good
    var advice: Dictionary = race.get_engineer_advice(pilot)
    var exchange: Dictionary = Dialogue.evaluate(pilot, snapshot, advice, {}, perception.merged(original_soul, true))
    good = check(not exchange.is_empty() and bool(exchange.get("fictional", false)) and bool(exchange.get("read_only", false)), "Fictional read-only exchange") and good
    good = check(str(exchange["engineer"]).contains("volta 21"), "Manual pit order still explicitly acknowledged") and good
    # Different subjective wear may change a preference, not engineer telemetry.
    var high_wear: Dictionary = snapshot.duplicate(true)
    high_wear["time"] = 151.0
    for entry in high_wear["cars"]:
        if int(entry.get("id", -1)) == pilot:
            entry["wear"] = 80.0
            entry["tyre_heat"] = 0.40
    var optimistic: Dictionary = Dialogue.evaluate(pilot, high_wear, {"pit_now": true}, {}, {"perceived_wear": 45.0})
    var worried: Dictionary = Dialogue.evaluate(pilot, high_wear, {"pit_now": true}, {}, {"perceived_wear": 90.0})
    good = check(bool(optimistic.get("wants_extend", false)) and bool(optimistic.get("disagreement", false)), "Overconfident driver may contest engine data") and good
    good = check(not bool(worried.get("wants_extend", true)), "Cautious perception can recommend tyre review") and good
    good = check(str(optimistic.get("engineer", "")).contains("80%"), "Engineer still reports measured wear") and good
    var after_talk: Dictionary = Soul.begin_discussion(original_soul)
    var answer: Dictionary = Soul.choose(after_talk, "piloto")
    good = check(bool(answer.get("applied", false)), "Support pilot affects communication state") and good
    var changed: Dictionary = answer["profile"]
    good = check(float(changed["confidence"]) > float(original_soul["confidence"]), "Pilot gets more confident") and good
    good = check(float(changed["trust"]) < float(original_soul["trust"]), "Engineer confidence responds") and good
    good = check(str(answer["driver"]).contains("cockpit"), "Driver replies") and good
    good = check(not bool(Soul.choose(changed, "engenheiro").get("applied", true)), "Only one response per conversation") and good
    var repeated: Dictionary = Dialogue.evaluate(pilot, snapshot, advice, exchange["memory"], Soul.perceive(pilot, snapshot, changed).merged(changed, true))
    good = check(bool(repeated.get("repeat", false)), "Cannot farm soul by repeating immediately") and good
    var later: Dictionary = snapshot.duplicate(true)
    later["time"] = float(snapshot.get("time", 0.0)) + 75.0
    var later_dialogue: Dictionary = Dialogue.evaluate(pilot, later, advice, exchange["memory"], Soul.perceive(pilot, later, changed).merged(changed, true))
    good = check(not bool(later_dialogue.get("repeat", true)) and str(later_dialogue["driver"]).contains("Lembro"), "Driver remembers the chief's response") and good
    var second_choice: Dictionary = Soul.choose(Soul.begin_discussion(changed), "engenheiro")
    good = check(bool(second_choice.get("applied", false)) and float(second_choice["profile"]["trust"]) > float(changed["trust"]), "Engineer choice is remembered") and good
    var history: Array = second_choice["profile"]["history"]
    good = check(history.size() == 2, "Two actions in per-race memory") and good
    var cast = Commentary.new()
    cast.reset(636)
    cast.add_soul_alignment(75.0, str(cars[0]["name"]), str(answer["decision"]), str(answer["driver"]), str(answer["engineer"]), pilot)
    cast.add_soul_alignment(76.0, str(cars[1]["name"]), "Outra equipe", "Mensagem de outro piloto", "Outra resposta", teammate)
    good = check(not cast.formatted(1).contains("RÁDIO FICTÍCIO"), "Private soul radio is not broadcast") and good
    good = check(cast.formatted(3, pilot).contains(str(cars[0]["name"])) and not cast.formatted(3, pilot).contains("ENGENHEIRO"), "Pilot radio filter remains private") and good
    good = check(not cast.formatted(2, pilot).contains("Mensagem de outro piloto"), "Teammate filter") and good
    good = check(JSON.stringify(race.get_state_snapshot()) == baseline, "Consultation didn't mutate race/pit/pace") and good
    var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var hud = game.race_hud_0620
    good = check(hud != null and hud.visible, "HUD active") and good
    if hud != null:
        hud._open_window("radio")
        var race_before: String = JSON.stringify(game.race.get_state_snapshot())
        var driver_id: int = hud.radio_driver_ids[0]
        var count_before: int = game.commentary.lines.size()
        hud._answer_stint("piloto")
        good = check(not hud.radio_soul_profiles[driver_id].has("missing") and game.commentary.lines.size() == count_before, "Action blocked until discussion") and good
        hud._discuss_stint()
        good = check(hud.radio_soul_profiles.has(driver_id) and hud.radio_soul_status.text.contains("confiança"), "Soul panel integrated") and good
        var count_first: int = game.commentary.lines.size()
        hud._discuss_stint()
        good = check(game.commentary.lines.size() == count_first, "Stint repeat rate limited") and good
        hud._answer_stint("piloto")
        good = check(game.commentary.lines.size() == count_first + 3, "Chief, pilot and engineer respond") and good
        var count_answered: int = game.commentary.lines.size()
        hud._answer_stint("engenheiro")
        good = check(game.commentary.lines.size() == count_answered, "One reply per session") and good
        hud._set_radio_category(1)
        good = check(not hud.radio_history.text.contains("RÁDIO FICTÍCIO"), "Broadcast excludes dialogue") and good
        good = check(JSON.stringify(game.race.get_state_snapshot()) == race_before, "HUD soul not changing race") and good
        hud.begin_race()
        good = check(hud.radio_soul_profiles.is_empty() and hud.radio_stint_memory.is_empty(), "Soul reset for next GP") and good
    if good:
        print("APEX 0636 PASS: personality, subjective wear, trust, confidence, memory, UI, filters, immutable race")
    quit(0 if good else 1)
