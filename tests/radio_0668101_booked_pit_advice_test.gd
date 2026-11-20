extends SceneTree
## v0.6.6.8.10.1 — Booking-first radio advice, without sporting side effects.
const Engineer = preload("res://scripts/core/race_engineer_interactive.gd")
const Race = preload("res://scripts/race_engine.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func verify(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        printerr("RADIO_0668101_BOOKED_PIT_FAIL: " + description)

func _run() -> void:
    var car: Dictionary = {
        "id": 17, "name": "Piloto de teste", "position": 4,
        "laps_done": 4, "stint_laps": 4, "pit_scheduled_lap": 21,
        "pit_control_mode": "Manual", "pit_request": false,
        "pit_left": 0.0, "finished": false,
        "tire": "Médio", "wear": 86.0
    }
    var snap: Dictionary = {
        "cars": [car], "lap_count": 53,
        "weather": {"wetness_factor": 0.74}
    }
    var advice: Dictionary = {
        "pit_now": true, "compound": "Chuva", "planned_pit_lap": 4
    }
    var untouched: PackedByteArray = var_to_bytes([snap, advice])
    var response: Dictionary = Engineer.answer("box", 17, snap, advice)
    var text_line: String = str(response.get("reply", ""))
    verify(text_line.contains("BOX V21") and text_line.contains("agendado"),
        "Scheduled lap must be the primary engineer response")
    verify(text_line.contains("não antecipa nem cancela"),
        "Radio explicitly refuses to change the scheduled stop")
    verify(text_line.contains("reavaliar") and text_line.contains("nova ordem explícita"),
        "Urgent tactical data only recommends a manual review")
    verify(text_line.contains("74%") and text_line.contains("Médio"),
        "Wet-track grip risk is grounded in observed snapshot")
    verify(not text_line.contains("vale avaliar o box agora"),
        "Must not suggest executing an immediate pit while V21 is protected")
    verify(var_to_bytes([snap, advice]) == untouched,
        "Answer must not mutate input, race state, or advice")

    snap["weather"] = {"wetness_factor": 0.0}
    advice["pit_now"] = false
    response = Engineer.answer("box", 17, snap, advice)
    text_line = str(response.get("reply", ""))
    verify(text_line.contains("BOX V21") and not text_line.contains("reavaliar"),
        "Dry low-risk radio keeps booking without inventing urgency")

    advice["pit_now"] = true
    car["pit_request"] = true
    response = Engineer.answer("box", 17, snap, advice)
    verify(str(response.get("reply", "")).contains("chamada de box já foi feita"),
        "An already-issued pit call remains the primary truth")
    car["pit_request"] = false
    car["pit_left"] = 5.0
    response = Engineer.answer("box", 17, snap, advice)
    verify(str(response.get("reply", "")).contains("procedimento de boxes"),
        "An ongoing stop remains the primary truth")
    car["pit_left"] = 0.0

    car["pit_scheduled_lap"] = 0
    response = Engineer.answer("box", 17, snap, advice)
    verify(str(response.get("reply", "")).contains("vale avaliar o box agora"),
        "Without a booking, the old urgent advice remains available")
    advice["pit_now"] = false
    advice["planned_pit_lap"] = 13
    response = Engineer.answer("box", 17, snap, advice)
    verify(str(response.get("reply", "")).contains("janela estimada é na volta 13"),
        "Forecast remains an estimate, not an order")

    car["pit_scheduled_lap"] = 4
    response = Engineer.answer("box", 17, snap, advice)
    verify(not str(response.get("reply", "")).contains("BOX V4"),
        "Expired booking is not presented as a future order")
    car["finished"] = true
    response = Engineer.answer("box", 17, snap, advice)
    verify(str(response.get("reply", "")).contains("Corrida concluída"),
        "Finished car receives no new pit recommendation")
    verify(Engineer.answer("box", -99, snap, advice).is_empty(),
        "Unknown driver cannot receive invented advice")

    var season: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/season_2012.json"))
    verify(season is Dictionary, "2012 season data loads")
    if season is Dictionary:
        var track: Dictionary = {}
        for entry in season["tracks"]:
            if str(entry.get("code", "")) == "ITA":
                track = entry
                break
        verify(not track.is_empty(), "Monza 2012 exists")
        if not track.is_empty():
            var race = Race.new(season["teams"], "Ferrari", 8101, {}, track, {})
            race.configure_weather("Seco")
            var player: Dictionary = race.player_cars()[0]
            var driver_id: int = int(player.get("id", -1))
            var tire: String = str(race.available_pit_compounds()[0])
            verify(race.schedule_pit(driver_id, tire, 21), "Actual RaceEngine books V21")
            var before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
            var actual: Dictionary = Engineer.answer("box", driver_id,
                race.get_state_snapshot(), {"pit_now": true, "compound": tire})
            verify(str(actual.get("reply", "")).contains("BOX V21"),
                "Actual sporting snapshot exposes the protected booking")
            verify(var_to_bytes(race.get_state_snapshot()) == before,
                "Consulting radio leaves complete RaceEngine state unchanged")
            verify(int(player.get("pit_scheduled_lap", 0)) == 21
                and not bool(player.get("pit_request", false)),
                "No premature pit request caused by consultation")
    if failures == 0:
        print("RADIO_0668101_BOOKED_PIT_PASS checks=%d" % checks)
    quit(0 if failures == 0 else 1)
