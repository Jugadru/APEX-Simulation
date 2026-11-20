extends SceneTree
## APEX Pit Wall Intelligence Analyzer 1.0 — evidence-only Core 2 fixture.
## It never changes the sporting engine, staff ability or error probability.
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

const LAPS := 10
const MAX_STEPS := 1200
const SCENARIOS := {
    "ita_dry_auto": {"track": "ITA", "weather": "Seco", "seed": 13660, "control": "IA"},
    "gbr_wet_auto": {"track": "GBR", "weather": "Chuva intensa", "seed": 13661, "control": "IA"},
    "bra_variable_auto": {"track": "BRA", "weather": "Variável", "seed": 13662, "control": "IA"},
    "ita_manual_v7": {"track": "ITA", "weather": "Seco", "seed": 13663, "control": "Manual"},
}

func _initialize() -> void:
    call_deferred("_run")

func _fatal(message: String) -> void:
    printerr("APEX_PITWALL_ANALYZER_FAIL " + message)
    quit(1)

func _sample(race, step_number: int, pilot_ids: Array[int]) -> Array:
    var rows: Array = []
    var wet: float = float(race.weather_snapshot().get("wetness_factor", 0.0))
    for car in race.cars:
        # Two player drivers plus one independently controlled rival.
        var car_id: int = int(car.get("id", -1))
        if not pilot_ids.has(car_id) and str(car.get("team", "")) == "Ferrari":
            continue
        if not pilot_ids.has(car_id) and rows.size() >= 3:
            continue
        if not pilot_ids.has(car_id) and rows.size() < 2:
            continue
        var ai_plan: Dictionary = car.get("ai_plan", {})
        var coordination: Dictionary = car.get("team_pit_coord_06497", {})
        rows.append({
            "step": step_number, "lap": int(car.get("laps_done", 0)),
            "clock": snappedf(float(race.clock), 0.000001),
            "car_id": car_id, "driver": str(car.get("name", "")),
            "team": str(car.get("team", "")), "position": int(car.get("position", -1)),
            "control": str(car.get("pit_control_mode", "IA")) if pilot_ids.has(car_id) else "IA",
            "tire": str(car.get("tire", "")),
            "wear": snappedf(float(car.get("wear", 0.0)), 0.0001),
            "wetness": snappedf(wet, 0.000001), "pace": str(car.get("pace", "")),
            "stops": int(car.get("stops", 0)),
            "pit_request": bool(car.get("pit_request", false)),
            "pit_scheduled_lap": int(car.get("pit_scheduled_lap", 0)),
            "pit_left": snappedf(float(car.get("pit_left", 0.0)), 0.0001),
            "pit_order_source": str(car.get("pit_order_source", "")),
            "ai_has_plan": not ai_plan.is_empty(),
            "ai_pit_now": bool(ai_plan.get("pit_now", false)),
            "ai_plan_compound": str(ai_plan.get("compound", "")),
            "ai_plan_reason": str(ai_plan.get("reason", "")),
            "ai_plan_lap": int(ai_plan.get("planned_pit_lap", 0)),
            "coordination": str(coordination.get("decision", "")),
        })
        if rows.size() >= 3:
            break
    return rows

func _run() -> void:
    var scenario_name: String = OS.get_environment("APEX_PITWALL_SCENARIO")
    if not SCENARIOS.has(scenario_name):
        _fatal("Unknown APEX_PITWALL_SCENARIO")
        return
    var config: Dictionary = SCENARIOS[scenario_name]
    var source: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    if not (source is Dictionary):
        _fatal("No real season_2012.json")
        return
    var track: Dictionary = {}
    for entry in source.get("tracks", []):
        if str(entry.get("code", "")) == str(config["track"]):
            track = entry.duplicate(true)
            break
    if track.is_empty():
        _fatal("Scenario circuit not found")
        return
    track["laps"] = LAPS
    track["race_km"] = float(track["lap_km"]) * float(LAPS)
    var race = Race.new(source["teams"], "Ferrari", int(config["seed"]), {}, track, {})
    race.configure_weather(str(config["weather"]))
    if race.cars.size() != 24 or race.player_cars().size() != 2:
        _fatal("Expected 24 cars and 2 player cars")
        return

    var pilot_ids: Array[int] = []
    for car in race.player_cars():
        var driver_id: int = int(car.get("id", -1))
        pilot_ids.append(driver_id)
        if not race.set_pit_control_mode(driver_id, str(config["control"])):
            _fatal("Cannot set player pit control")
            return
    var scheduled_id: int = -1
    if scenario_name == "ita_manual_v7":
        scheduled_id = pilot_ids[0]
        if not race.schedule_pit(scheduled_id, str(race.available_pit_compounds()[1]), 7):
            _fatal("Cannot book V7")
            return

    var errors: Array[String] = []
    var rows: Array = []
    var last_leader_lap: int = -1
    var steps: int = 0
    var premature_manual: bool = false
    race.running = true
    # Initial observation is before the green flag and is NOT an AI recommendation.
    rows.append_array(_sample(race, 0, pilot_ids))
    while not race.finished and steps < MAX_STEPS:
        race.step(4.0)
        steps += 1
        if scheduled_id >= 0 and not race.finished:
            var manual: Dictionary = race.player_cars()[0]
            if int(manual.get("laps_done", 0)) < 5 and (bool(manual.get("pit_request", false)) or float(manual.get("pit_left", 0.0)) > 0.0):
                premature_manual = true
        if race.lap != last_leader_lap or race.finished:
            rows.append_array(_sample(race, steps, pilot_ids))
            last_leader_lap = race.lap

    var finishes: int = 0
    var positions: Array[int] = []
    for car in race.get_sorted():
        if bool(car.get("finished", false)):
            finishes += 1
        positions.append(int(car.get("position", -1)))
        if not is_finite(float(car.get("wear", 0.0))):
            errors.append("Non-finite tyre wear")
    positions.sort()
    if not race.finished or not race.finish_results_validated or finishes != 24 or positions != range(1, 25):
        errors.append("Race failed to finish with 24 valid classified positions")
    var stops: Array = []
    var manual_laps: Array[int] = []
    for item in race.get_pit_history():
        var lap: int = int(item.get("lap", -1))
        if lap < 1 or lap > LAPS:
            errors.append("Pit history lap out of bounds")
        if int(item.get("car_id", -1)) == scheduled_id:
            manual_laps.append(lap)
        stops.append({
            "car_id": int(item.get("car_id", -1)),
            "driver": str(item.get("driver", "")), "team": str(item.get("team", "")),
            "lap": lap, "order_origin": str(item.get("order_origin", "")),
            "old_tire": str(item.get("old_tire", "")),
            "new_tire": str(item.get("new_tire", "")),
            "wait": snappedf(float(item.get("wait", 0.0)), 0.0001),
            "incident_delay": snappedf(float(item.get("incident_delay", 0.0)), 0.0001),
            "position_before": int(item.get("position_before", -1)),
            "position_after": int(item.get("position_after", -1)),
        })
    if scheduled_id >= 0 and (premature_manual or manual_laps != [7]):
        errors.append("Manual V7 order was anticipated, lost or duplicated")
    var radio: Array = []
    var event_counts: Dictionary = {}
    for event in race.events:
        var kind: String = str(event.get("type", ""))
        event_counts[kind] = int(event_counts.get(kind, 0)) + 1
        if kind in ["driver_radio", "engineer_reply", "radio", "strategy", "team_coordination", "double_stack"]:
            radio.append({
                "type": kind, "car_id": int(event.get("driver_id", -1)),
                "time": snappedf(float(event.get("time", 0.0)), 0.000001),
                "message": str(event.get("message", "")),
            })

    var result: Dictionary = {
        "scenario": scenario_name, "track": str(config["track"]),
        "weather": str(config["weather"]), "control": str(config["control"]),
        "seed": int(config["seed"]), "lap_count": LAPS,
        "finished": race.finished, "classified": finishes, "steps": steps,
        "race_hash": Codec.sporting_hash(race, {}),
        "manual_v7_laps": manual_laps, "player_ids": pilot_ids,
        "decisions": rows, "pits": stops, "radio": radio,
        "event_counts": event_counts, "errors": errors,
        "status": "PASS" if errors.is_empty() else "FAIL",
        "limits": "Samples when the race leader changes lap; not every decision or hidden staff intent.",
    }
    print("APEX_PITWALL_ANALYZER_RESULT ", JSON.stringify(result))
    quit(0 if errors.is_empty() else 1)
