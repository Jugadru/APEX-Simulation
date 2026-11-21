extends SceneTree
## v0.6.4.7 — Soul Driver 2.0 runs on lap crossing, produces radio requests
## and keeps pit/pace/physical state immutable.
const Soul = preload("res://scripts/core/race_driver_soul_0647.gd")
const Race = preload("res://scripts/race_engine.gd")
var errors: Array[String] = []

func require(value: bool, message: String) -> void:
    if not value:
        errors.append(message)
        printerr("SOUL2_FAIL: " + message)

func setup_car(id: int = 4) -> Dictionary:
    return {"id": id, "name": "Piloto Exemplo", "team": "Equipe A",
        "laps_done": 0, "position": 5, "interval": 1.0, "last_lap": 0.0,
        "best_lap": 9999.0, "wear": 0.0, "tire": "Médio",
        "pit_scheduled_lap": 0, "pit_request": false, "pit_left": 0.0,
        "pace": "Normal", "finished": false, "stint_laps": 0}

func lap_update(car: Dictionary, next: int, wear: float, wet: float, lap: float = 92.0) -> void:
    car["laps_done"] = next
    car["wear"] = wear
    car["last_lap"] = lap
    car["best_lap"] = 90.0
    Soul.update(car, {"wetness_factor": wet})

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var a: Dictionary = setup_car()
    var first: Dictionary = Soul.initial(a)
    require(first == Soul.initial(a), "deterministic personality")
    require(first != Soul.initial(setup_car(5)), "independent drivers")
    a["driver_soul"] = first
    var copy_before: Dictionary = a.duplicate(true)
    lap_update(a, 1, 4.0, 0.1)
    require(a["driver_soul"]["last_lap"] == 1, "updates on completed lap")
    require(int((a["driver_soul"] as Dictionary).get("request_seq", 0)) == 0, "no fake request on first lap")
    var once: String = JSON.stringify(a["driver_soul"])
    Soul.update(a, {"wetness_factor": 0.1})
    require(JSON.stringify(a["driver_soul"]) == once, "no multiple changes in one lap")
    require(str(a.get("pace", "")) == str(copy_before.get("pace", "")), "pace untouched")

    # A protected pit booking stays V21 in severe rain, even if the pilot protests.
    var manual: Dictionary = setup_car(10)
    manual["pit_scheduled_lap"] = 21
    manual["driver_soul"] = Soul.initial(manual)
    lap_update(manual, 4, 72.0, 0.83)
    var req: Dictionary = Soul.latest(manual)
    require(str(req.get("kind", "")) == "revisar_plano", "booked stop produces discussion, not new pit")
    require(int(manual.get("pit_scheduled_lap", -1)) == 21, "V21 preserved")
    require(not bool(manual.get("pit_request", true)), "no immediate pit")
    require(str(req.get("message", "")).contains("V21"), "pilot acknowledges booking")
    var first_id: int = int(req.get("id", 0))
    var before_commands: Dictionary = manual.duplicate(true)
    var response: Dictionary = Soul.respond(manual, first_id, "ouvir")
    require(bool(response.get("applied", false)), "pitwall can answer radio request")
    require(float(manual["driver_soul"]["trust"]) > float(before_commands["driver_soul"]["trust"]), "response affects trust")
    require(not bool(Soul.respond(manual, first_id, "ouvir").get("applied", true)), "single response to request")
    require(manual["pit_scheduled_lap"] == before_commands["pit_scheduled_lap"] and
        manual["pit_request"] == before_commands["pit_request"] and
        manual["pace"] == before_commands["pace"], "response cannot execute pit or pace")
    require(not bool(Soul.respond(manual, 999, "ouvir").get("applied", true)), "stale request rejected")

    # Sustained teammate pace advantage can request review of a team-order swap.
    var chasing: Dictionary = setup_car(14)
    var mate: Dictionary = setup_car(15)
    chasing["position"] = 6
    mate["position"] = 5
    mate["last_lap"] = 93.3
    chasing["driver_soul"] = Soul.initial(chasing)
    for lap in range(1, 4):
        chasing["laps_done"] = lap
        chasing["wear"] = 14.0 + float(lap)
        chasing["last_lap"] = 91.0
        chasing["best_lap"] = 90.0
        Soul.update(chasing, {"wetness_factor": 0.0}, mate)
    require(str(Soul.latest(chasing).get("kind", "")) == "troca_equipe", "faster teammate request")
    require(mate["position"] == 5 and chasing["position"] == 6, "no automatic overtaking")

    # A driver with bad pace asks for strategy review, not a pit order.
    var slow: Dictionary = setup_car(22)
    slow["driver_soul"] = Soul.initial(slow)
    for lap in range(1, 5):
        lap_update(slow, lap, 56.0, 0.05, 95.0)
    require(str(Soul.latest(slow).get("kind", "")) == "perda_ritmo", "slow driver request")
    require(not bool(slow.get("pit_request", true)), "request does not call pit")
    var high_wear: Dictionary = setup_car(30)
    high_wear["driver_soul"] = Soul.initial(high_wear)
    lap_update(high_wear, 3, 92.0, 0.76)
    require(str(Soul.latest(high_wear).get("kind", "")) == "avaliar_box", "wet worn slick requests review")
    require(not bool(high_wear["pit_request"]), "weather warning remains consultative")

    # Integrated engine uses 2.0 after a real lap crossing without running any HUD.
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = (season.get("tracks", []) as Array)[0]
    var race = Race.new(season["teams"], "Red Bull Racing Renault", 647, {}, track, {})
    race.running = true
    var pilot: Dictionary = race.player_cars()[0]
    require(str(pilot["driver_soul"].get("version", "")) == "3.0", "engine initializes Soul 3.0 while Soul 2.0 module stays testable")
    var initial_time: float = float(race.clock)
    for i in range(1800):
        race.step(0.20)
        if int(pilot.get("laps_done", 0)) > 0:
            break
    require(race.clock >= initial_time, "native sim time advances")
    require(int(pilot.get("laps_done", 0)) > 0, "engine completed first lap")
    require(int((pilot.get("driver_soul", {}) as Dictionary).get("last_lap", -1)) == int(pilot.get("laps_done", 0)), "soul updated with native crossing")
    require(race.player_cars().size() == 2, "team preserved")
    if errors.is_empty():
        print("SOUL2_PASS deterministic, radio requests, protected V21, team-order request, morale, engine native lap")
        quit(0)
    else:
        quit(1)
