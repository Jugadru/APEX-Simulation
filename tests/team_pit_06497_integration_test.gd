extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
var fails: Array[String] = []
func ck(ok: bool, message: String) -> void:
    if not ok:
        fails.append(message)
        printerr("INTEGRATION_06497_FAIL " + message)

func make_sim() -> Dictionary:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for t in season["tracks"]:
        if str(t.get("code","")) == "GBR": track=t
    var sim = Race.new(season["teams"],"Ferrari",6403,{},track,{})
    sim.configure_weather("Seco")
    var pair: Array = sim.player_cars()
    for i in range(2):
        var c: Dictionary = pair[i]
        c["pit_control_mode"]="IA"
        c["position"]=2 + 2 * i
        c["tire"]="Macio"
        c["used_tires"]=["Macio"]
        c["wear"]=55.0
        c["progress"]=14.0
        c["laps_done"]=14
        c["stint_laps"]=14
        c["track_wear_factor"]=1.8
        c["last_pit_exit_lap"]=-100
    return {"sim":sim,"pair":pair}

func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var ctx: Dictionary = make_sim()
    var sim = ctx["sim"]
    var pair: Array = ctx["pair"]
    var a: Dictionary = sim._build_strategy_plan(pair[0],false)
    var b: Dictionary = sim._build_strategy_plan(pair[1],false)
    ck(int(a.get("planned_pit_lap",0))==16 and int(b.get("planned_pit_lap",0))==16, "both forecast V16")
    sim._request_ai_pit(pair[0])
    ck(not bool(pair[0]["pit_request"]),"priority car should wait until planned V16")
    sim._request_ai_pit(pair[1])
    ck(bool(pair[1]["pit_request"]),"secondary car anticipates to V15")
    ck(str(pair[1].get("pit_order_source",""))=="ia_estrategia","AI authority preserved")
    ck(int(pair[1].get("team_pit_adjusted_stint_06497",-99))==0,"single shift recorded in stint")
    ck(str(pair[1].get("team_pit_coord_06497",{}).get("decision",""))=="ANTECIPAR","coordination rationale stored")
    var again: int = 0
    for ev in sim.events:
        if str(ev.get("type",""))=="team_coordination": again+=1
    ck(again==1,"single coordination event")
    sim._request_ai_pit(pair[1])
    var after_count: int = 0
    for ev in sim.events:
        if str(ev.get("type",""))=="team_coordination": after_count+=1
    ck(after_count==1,"no repeated early order")
    var manual_ctx: Dictionary = make_sim()
    var manual_pair: Array = manual_ctx["pair"]
    manual_pair[1]["pit_control_mode"]="Manual"
    manual_ctx["sim"]._request_ai_pit(manual_pair[1])
    ck(not bool(manual_pair[1]["pit_request"]),"manual cannot be overridden")
    var booked_ctx: Dictionary = make_sim()
    var booked_pair: Array = booked_ctx["pair"]
    ck(booked_ctx["sim"].schedule_pit(int(booked_pair[1]["id"]),"Duro",21),"V21 accepted")
    booked_ctx["sim"]._request_ai_pit(booked_pair[1])
    ck(int(booked_pair[1]["pit_scheduled_lap"])==21 and not bool(booked_pair[1]["pit_request"]),"V21 protected")
    var wet_ctx: Dictionary = make_sim()
    wet_ctx["sim"].configure_weather("Chuva intensa")
    wet_ctx["sim"]._request_ai_pit(wet_ctx["pair"][1])
    ck(int(wet_ctx["pair"][1].get("team_pit_adjusted_stint_06497",-999))==-999,"wet stops not pre-staggered")
    if fails.is_empty():
        print("INTEGRATION_06497_PASS Silverstone V16-V15 AI, manual, V21, wet, one-shot")
    quit(0 if fails.is_empty() else 1)
