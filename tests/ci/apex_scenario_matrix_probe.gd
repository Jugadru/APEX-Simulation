extends SceneTree
## Scenario Matrix 1.0: real 24-car Core 2, fixed seed, ten laps per case.
## No writes to gameplay scripts or persisted career files.
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const TeamAutonomy = preload("res://scripts/core/race_team_autonomy.gd")

const LAPS := 10
const MAX_STEPS := 1500
const STEP_SECONDS := 4.0
const WEATHER_MODES := ["Seco", "Variável", "Chuva intensa"]
const STRATEGY_MODES := ["Manual", "Assistido", "IA"]

func _initialize() -> void:
    call_deferred("_run")

func _fatal(message: String) -> void:
    printerr("APEX_MATRIX_PROBE_FAIL " + message)
    quit(1)

func _run() -> void:
    var case_id: String = OS.get_environment("APEX_MATRIX_ID")
    var track_code: String = OS.get_environment("APEX_MATRIX_TRACK")
    var weather: String = OS.get_environment("APEX_MATRIX_WEATHER")
    var mode: String = OS.get_environment("APEX_MATRIX_MODE")
    var seed_text: String = OS.get_environment("APEX_MATRIX_SEED")
    if case_id.is_empty() or not case_id.is_valid_identifier() or track_code.is_empty() \
            or not WEATHER_MODES.has(weather) or not STRATEGY_MODES.has(mode) \
            or not seed_text.is_valid_int() or int(seed_text) < 1:
        _fatal("Missing or invalid scenario environment")
        return
    var seed: int = int(seed_text)
    # Diagnostic-only trace for the reproducible Monaco assisted case.
    # Never changes race state, random draws, physics, AI decisions or reports.
    var trace_monaco: bool = case_id == "mon_1_1_1764457695"
    if trace_monaco:
        print("APEX_MATRIX_DIAG phase=env_validated id=", case_id, " seed=", seed)
    var season: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/season_2012.json"))
    if not (season is Dictionary):
        _fatal("Missing 2012 season")
        return
    if season["teams"].size() != 12 or season["tracks"].size() != 20:
        _fatal("2012 season must contain 12 teams and 20 tracks")
        return
    var track: Dictionary = {}
    for candidate in season["tracks"]:
        if str(candidate.get("code", "")) == track_code:
            track = candidate.duplicate(true)
            break
    if track.is_empty():
        _fatal("Unknown 2012 circuit: " + track_code)
        return
    track["laps"] = LAPS
    track["race_km"] = float(track["lap_km"]) * float(LAPS)
    var race = Race.new(season["teams"], "Ferrari", seed, {}, track, {})
    race.configure_weather(weather)
    if trace_monaco:
        print("APEX_MATRIX_DIAG phase=race_created cars=", race.cars.size())
    if race.cars.size() != 24 or race.player_cars().size() != 2:
        _fatal("Invalid 24-car starting grid")
        return

    var player_ids: Array[int] = []
    var errors: Array[String] = []
    var warnings: Array[String] = []
    var manual_mode: bool = mode != "IA"
    for player in race.player_cars():
        var driver_id: int = int(player.get("id", -1))
        player_ids.append(driver_id)
        if not race.set_pit_control_mode(driver_id, "Manual" if manual_mode else "IA"):
            errors.append("Failed to select pit control mode")
    if manual_mode:
        # Each player's scheduled dry stop must change to the *other* nominated
        # slick. The old single target for both Ferrari cars caused artificial
        # 2012 tyre-rule DQs when a driver already started on that compound.
        var nominated: Array = race.available_pit_compounds()
        for i in range(player_ids.size()):
            var target_lap: int = 6 + i
            var initial: String = str(race.player_cars()[i].get("tire", ""))
            var target: String = "Chuva" if weather == "Chuva intensa" else (
                str(nominated[0]) if initial == str(nominated[1]) else str(nominated[1])
            )
            if not race.schedule_pit(player_ids[i], target, target_lap):
                errors.append("Manual schedule V%d rejected" % target_lap)

    race.running = true
    var steps: int = 0
    var max_stops_observed: int = 0
    var wetness_peak: float = 0.0
    while not race.finished and steps < MAX_STEPS:
        if mode == "Assistido" and steps % 40 == 0:
            # Delegates actual TeamAutonomy pace/KERS decisions, while keeping
            # the player's pit authority manual. Does not emulate full HUD/staff.
            for player in race.player_cars():
                var driver_id: int = int(player.get("id", -1))
                var advice: Dictionary = race.get_engineer_advice(driver_id)
                var decision: Dictionary = TeamAutonomy.decide(
                    player, advice, race.weather_snapshot(),
                    {"Engenheiro": 2, "Estrategista": 2}, race.lap_count)
                race.set_pace(driver_id, str(decision.get("pace", "Normal")))
                race.set_kers_mode(driver_id, str(decision.get("kers", "Equilibrado")))
        race.step(STEP_SECONDS)
        steps += 1
        # Read-only diagnostic snapshots, without modifying the race, AI, RNG,
        # step budget, finish criteria or sporting report.
        if trace_monaco and (steps == 1 or steps % 100 == 0 or race.finished):
            var cars_state: Array[Dictionary] = []
            for diag_car in race.cars:
                cars_state.append({
                    "id": int(diag_car.get("id", -1)),
                    "progress": snappedf(float(diag_car.get("progress", 0.0)), 0.0001),
                    "laps_done": int(diag_car.get("laps_done", 0)),
                    "finished": bool(diag_car.get("finished", false)),
                    "pit_stage": str(diag_car.get("pit_stage", "none")),
                    "pit_left": snappedf(float(diag_car.get("pit_left", 0.0)), 0.001),
                    "pit_wait": snappedf(float(diag_car.get("pit_wait", 0.0)), 0.001),
                    "pit_request": bool(diag_car.get("pit_request", false)),
                    "pit_scheduled_lap": int(diag_car.get("pit_scheduled_lap", 0)),
                    "pace": str(diag_car.get("pace", "")),
                    "race_space_blocked": bool(diag_car.get("race_space_blocked", false)),
                    "lane": snappedf(float(diag_car.get("race_lane", 0.0)), 0.001),
                })
            print("APEX_MATRIX_DIAG_SNAPSHOT ", JSON.stringify({
                "step": steps, "clock": snappedf(float(race.clock), 0.001),
                "lap": race.lap, "first_finish_at": race.first_finish_at,
                "finished": race.finished, "cars": cars_state,
            }))
        wetness_peak = maxf(wetness_peak,
            float(race.weather_snapshot().get("wetness_factor", 0.0)))
        for car in race.cars:
            max_stops_observed = maxi(max_stops_observed, int(car.get("stops", 0)))
            if max_stops_observed > LAPS:
                errors.append("More than one stop per lap on a car")
                break
        if not errors.is_empty():
            break

    if trace_monaco:
        print("APEX_MATRIX_DIAG phase=loop_exit steps=", steps, " finished=", race.finished)
    var finished_cars: int = 0
    var disqualified: int = 0
    var dq_evidence: Array[Dictionary] = []
    var positions: Array[int] = []
    var tyres: Array = race.available_pit_compounds()
    var ranked: Array = race.get_sorted()
    if ranked.size() != 24:
        errors.append("Grid size changed during racing")
    for car in ranked:
        if bool(car.get("finished", false)):
            finished_cars += 1
        if bool(car.get("disqualified", false)):
            disqualified += 1
            # Read-only evidence: identify regulated car, used compounds and stops.
            dq_evidence.append({
                "car_id": int(car.get("id", -1)),
                "driver": str(car.get("name", car.get("driver", ""))),
                "team": str(car.get("team", "")),
                "used_tires": car.get("used_tires", []).duplicate(true),
                "tyre_rule_violation": bool(car.get("tyre_rule_violation", false)),
                "tire": str(car.get("tire", "")),
                "stops": int(car.get("stops", 0)),
            })
        positions.append(int(car.get("position", -1)))
        var wear: float = float(car.get("wear", -1.0))
        var best: float = float(car.get("best_lap", 0.0))
        var progress: float = float(car.get("progress", -1.0))
        if not is_finite(wear) or wear < -0.01 or wear > 100.01:
            errors.append("Invalid tyre wear for car " + str(car.get("id", -1)))
        if not is_finite(best) or best <= 0.0:
            errors.append("Invalid best lap for car " + str(car.get("id", -1)))
        if not is_finite(progress) or progress < 0.0:
            errors.append("Invalid car progress")
        if str(car.get("tire", "")) not in tyres:
            errors.append("Compound is not allowed for this 2012 circuit")

    positions.sort()
    dq_evidence.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["car_id"]) < int(b["car_id"]))
    if not race.finished or not race.finish_results_validated:
        errors.append("Race did not finish or validate before bounded timeout")
    if finished_cars != 24 or positions != range(1, 25):
        errors.append("Inconsistent 24-car finishing classification")

    var pit_history: Array = race.get_pit_history()
    var pit_laps_by_player: Array = [[], []]
    for stop in pit_history:
        var lap: int = int(stop.get("lap", -1))
        if lap < 1 or lap > LAPS:
            errors.append("Pit stop outside valid lap range")
        for i in range(player_ids.size()):
            if int(stop.get("car_id", -1)) == player_ids[i]:
                pit_laps_by_player[i].append(lap)
    if manual_mode and pit_laps_by_player != [[6], [7]]:
        errors.append("Manual scheduled stop was early, late or duplicated")
    if manual_mode and weather == "Seco":
        for car in ranked:
            if player_ids.has(int(car.get("id", -1))) and bool(car.get("disqualified", false)):
                errors.append("Manual/assisted fixture violated 2012 dry tyre rule for car " + str(car.get("id", -1)))
    if max_stops_observed >= 4 or pit_history.size() > 30:
        warnings.append("Unusually many stops for ten laps; inspect tyre/weather traces")
    if disqualified > 0:
        warnings.append("%d cars were disqualified; inspect tyre regulations" % disqualified)
    if weather == "Chuva intensa" and wetness_peak < 0.15:
        errors.append("Configured heavy-rain fixture was not wet")

    var pass_events: int = 0
    for event in race.telemetry.event_history:
        if str(event.get("type", "")) == "pass":
            pass_events += 1

    var report: Dictionary = {
        "id": case_id, "track": track_code, "weather": weather,
        "mode": mode, "seed": seed, "laps": LAPS, "steps": steps,
        "finished": race.finished,
        "finish_results_validated": race.finish_results_validated,
        "finished_cars": finished_cars, "classified_positions": positions,
        "race_hash": Codec.sporting_hash(race, {}),
        "pits_total": pit_history.size(), "max_stops": max_stops_observed,
        "pit_laps_by_player": pit_laps_by_player, "disqualified": disqualified,
        "disqualification_evidence": dq_evidence,
        "wetness_peak": snappedf(wetness_peak, 0.000001),
        "on_track_pass_events": pass_events,
        "errors": errors, "warnings": warnings,
        "status": "PASS" if errors.is_empty() else "FAIL",
    }
    print("APEX_MATRIX_RESULT ", JSON.stringify(report))
    quit(0 if errors.is_empty() else 1)
