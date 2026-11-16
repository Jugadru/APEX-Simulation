extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for t in season["tracks"]:
        if str(t.get("code", "")) == "GBR":
            track = t
            break
    var sim = Race.new(season["teams"], "Ferrari", 6403, {"Motor":1,"Asa":1,"Chassi":1}, track, {})
    sim.configure_weather("Seco")
    sim.pit_incidents_enabled = false
    var pair: Array = sim.player_cars()
    for car in pair:
        car["pit_control_mode"] = "IA"
        car["wear"] = 35.0
        car["laps_done"] = 0
        car["stint_laps"] = 8
        car["pit_request"] = true
        car["pit_order_source"] = "ia_estrategia"
        car["pit_target"] = "Duro" if str(car.get("tire", "")) != "Duro" else "Médio"
        car["ai_plan"] = {"pit_now":true, "compound":car["pit_target"], "critical":false, "life_laps":5.0}
    pair[0]["progress"] = 0.949
    pair[1]["progress"] = 0.947
    sim.running = true
    for i in range(150):
        sim.step(0.20)
    print("DOUBLESTACK_COMPARE first_stops=%d second_stops=%d second_hold=%s second_pit_stage=%s second_wait=%.1f" % [int(pair[0]["stops"]),int(pair[1]["stops"]),str(pair[1].get("pitwall49_held",false)),str(pair[1].get("pit_stage","none")),float(pair[1].get("pit_wait",0.0))])
    quit(0)
