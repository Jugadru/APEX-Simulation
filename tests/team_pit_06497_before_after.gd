extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for t in season["tracks"]:
        if str(t.get("code",""))=="GBR":track=t
    var sim = Race.new(season["teams"],"Ferrari",6403,{},track,{})
    sim.configure_weather("Seco")
    var cars: Array = sim.player_cars()
    for i in range(2):
        var car: Dictionary = cars[i]
        car["pit_control_mode"]="IA"
        car["position"]=2 + i*2
        car["tire"]="Macio"
        car["used_tires"]=["Macio"]
        car["wear"]=55.0
        car["progress"]=14.0
        car["laps_done"]=14
        car["stint_laps"]=14
        car["track_wear_factor"]=1.8
        car["last_pit_exit_lap"]=-100
    sim._request_ai_pit(cars[0])
    sim._request_ai_pit(cars[1])
    print("COMPARE_06497 alpha_pit=",cars[0]["pit_request"],
        " beta_pit=",cars[1]["pit_request"],
        " original_lap=",sim._build_strategy_plan(cars[0],false).get("planned_pit_lap",0),
        " coordination=",cars[1].get("team_pit_coord_06497",{}).get("decision","NA"))
    quit(0)
