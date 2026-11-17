extends SceneTree
## APEX Core 2 0.6.6.8.3: verifies the sport remains unchanged after optimizing
## the frozen start-of-tick view used exclusively by pace and racecraft.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
const REFERENCE = "res://qa/core2_06683/fixtures_reference.json"
const SCENARIOS = [
    {"code":"GBR", "weather":"Seco", "seed":660},
    {"code":"BEL", "weather":"Chuva intensa", "seed":661},
    {"code":"ITA", "weather":"Seco", "seed":662},
    {"code":"SIN", "weather":"Chuva intensa", "seed":663}
]

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var expected: Dictionary = {}
    if FileAccess.file_exists(REFERENCE):
        expected = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))
    var baseline: bool = OS.get_environment("APEX_BASELINE") == "1"
    var results: Dictionary = {}
    var failures: Array[String] = []
    var count: int = 0
    for scenario in SCENARIOS:
        var track: Dictionary = {}
        for entry in data.tracks:
            if str(entry.code) == str(scenario.code):
                track = entry.duplicate(true)
                break
        if track.is_empty():
            failures.append("Circuito ausente: " + str(scenario.code))
            continue
        var race = Race.new(data.teams, "Ferrari", int(scenario.seed), {}, track, {})
        race.configure_weather(str(scenario.weather))
        var session = Replay.new()
        session.attach(race)
        var car_id: int = int(race.player_cars()[0].id)
        var wettyre: String = "Chuva" if str(scenario.weather) == "Chuva intensa" else str(race.available_pit_compounds()[0])
        if str(scenario.code) == "BEL":
            if not session.enqueue("schedule_pit", [car_id, wettyre, 21], 2):
                failures.append("Agendamento manual V21 rejeitado")
        Perf.set_enabled(true)
        Perf.reset({"version":"06683", "scenario":scenario.code})
        var t0: int = Time.get_ticks_usec()
        var sampled_hashes: Dictionary = {}
        for tick in range(750):
            if not session.step_tick():
                failures.append("step_tick falhou em " + str(scenario.code) + " tick=" + str(tick))
                break
            if session.tick in [1, 250, 500, 750]:
                sampled_hashes[str(session.tick)] = session.hashes[-1]
            if str(scenario.code) == "BEL" and session.tick == 750:
                var car: Dictionary = race.player_cars()[0]
                if int(car.get("pit_scheduled_lap", -1)) != 21 or bool(car.get("pit_request", false)) or int(car.get("stops", 0)) > 0:
                    failures.append("V21 foi alterada ou executada antes da hora")
        var t1: int = Time.get_ticks_usec()
        var sections: Dictionary = Perf.snapshot().get("sections", {})
        var snapshot_stats: Dictionary = sections.get("race.snapshot", {})
        var test_value: Dictionary = {"hashes":sampled_hashes, "event_count":race.events.size(), "tick_count":session.tick,
            "snapshot_total_ms":snapshot_stats.get("total_ms",0.0),"snapshot_mean_ms":snapshot_stats.get("mean_ms",0.0),"wall_ms":float(t1-t0)/1000.0,
            "position_checksum":_position_checksum(race.cars)}
        results[str(scenario.code)] = test_value
        if not baseline:
            var reference: Dictionary = expected.get(str(scenario.code), {})
            if reference.is_empty():
                failures.append("Sem referencia do circuito " + str(scenario.code))
            else:
                for key in ["hashes", "event_count", "tick_count"]:
                    if test_value[key] != reference.get(key):
                        failures.append("Divergencia em " + str(scenario.code) + ":" + key)
                if not _same_positions(test_value.position_checksum, reference.get("position_checksum", [])):
                    failures.append("Divergencia nas posicoes em " + str(scenario.code))
        count += 1
        print("CORE2_06683_SCENARIO ",JSON.stringify({"scenario":scenario.code,"result":test_value}))
    Perf.set_enabled(false)
    if baseline:
        var file = FileAccess.open(REFERENCE, FileAccess.WRITE)
        if file == null:
            failures.append("Falha ao gravar referencia no pacote")
        else:
            file.store_string(JSON.stringify(results,"\t"))
    var status: String = "PASS" if failures.is_empty() and count == SCENARIOS.size() else "FAIL"
    print("CORE2_06683_RESULT ",JSON.stringify({"status":status,"scenarios":count,"failures":failures}))
    quit(0 if status == "PASS" else 1)

func _position_checksum(cars: Array) -> Array:
    var rows: Array = []
    for car in cars:
        rows.append({"id":int(car.id), "progress":float(car.progress), "position":int(car.position),
            "wear":float(car.wear),"tire":str(car.tire), "stops":int(car.stops)})
    rows.sort_custom(func(a,b): return int(a.id) < int(b.id))
    return rows

func _same_positions(current: Array, reference: Array) -> bool:
    if current.size() != reference.size():
        return false
    for i in range(current.size()):
        var left: Dictionary = current[i]
        var right: Dictionary = reference[i]
        for key in ["id", "position", "stops"]:
            if int(left.get(key, -1)) != int(right.get(key, -1)):
                return false
        if str(left.get("tire", "")) != str(right.get("tire", "")):
            return false
        for key in ["progress", "wear"]:
            if absf(float(left.get(key, 0.0)) - float(right.get(key, 0.0))) > 0.00000000001:
                return false
    return true
