extends SceneTree
## Paridade A/B na mesma semente em GBR, ITA e SIN, com Soul Staff em leitura e gestão.
const Race = preload("res://scripts/race_engine.gd")
const Soul = preload("res://scripts/core/staff_soul_0650.gd")
var fails: Array[String] = []
func check(ok: bool, note: String) -> void:
    if not ok:
        fails.append(note)
        printerr("SOUL_0650_TRACK_FAIL " + note)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    for case in [{"code":"GBR","seed":6403,"weather":"Variável"},
        {"code":"ITA","seed":6503,"weather":"Seco"},
        {"code":"SIN","seed":6603,"weather":"Variável"}]:
        var track: Dictionary = {}
        for t in season["tracks"]:
            if str(t.get("code", "")) == str(case["code"]):
                track = t
                break
        check(not track.is_empty(), "circuito existe %s" % case["code"])
        if track.is_empty(): continue
        var normal = Race.new(season["teams"], "Ferrari", int(case["seed"]), {}, track, {})
        var observing = Race.new(season["teams"], "Ferrari", int(case["seed"]), {}, track, {})
        normal.configure_weather(str(case["weather"]))
        observing.configure_weather(str(case["weather"]))
        for car in normal.player_cars(): car["pit_control_mode"] = "IA"
        for car in observing.player_cars(): car["pit_control_mode"] = "IA"
        var staff: Dictionary = {"budget":12000000, "staff_roster":{
            "Estrategista":{"id":"est_b", "name":"Miguel Torres"},
            "Engenheiro":{"id":"eng_b", "name":"Clara Ferreira"}},
            "staff_payroll_keys":{}, "staff_log":[]}
        Soul.ensure(staff)
        var initial: String = JSON.stringify(observing.get_state_snapshot())
        Soul.summary(staff)
        Soul.apply_action(staff, "integration", 1, 1, 20)
        check(initial == JSON.stringify(observing.get_state_snapshot()), "ações não alteram corrida %s" % case["code"])
        normal.running = true
        observing.running = true
        var ticks: int = 0
        for n in range(115):
            if normal.finished or observing.finished: break
            normal.step(4.0)
            observing.step(4.0)
            ticks += 1
            Soul.summary(staff)
            if ticks % 25 == 0:
                check(JSON.stringify(normal.get_state_snapshot()) == JSON.stringify(observing.get_state_snapshot()),
                    "mesmo estado e RNG na volta %d em %s" % [int(normal.lap), case["code"]])
        check(int(normal.lap) >= 3, "pelo menos 3 voltas reais %s" % case["code"])
        print("SOUL_0650_TRACK_PASS %s laps=%d ticks=%d; pure human management" % [case["code"], int(normal.lap), ticks], true)
    if fails.is_empty():
        print("SOUL_0650_THREE_TRACKS_PASS GBR/ITA/SIN snapshots, deterministic 2x115 ticks, true engine")
    quit(0 if fails.is_empty() else 1)
