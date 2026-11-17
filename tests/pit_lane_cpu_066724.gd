extends SceneTree
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize():
    call_deferred("run")
func run():
    var app=load("res://scenes/main.tscn").instantiate()
    root.add_child(app)
    for i in range(5): await process_frame
    app.set_process(false)
    app.seed_picker.value=660
    for index in range(app.season_tracks.size()):
        if str(app.season_tracks[index].get("code",""))=="ITA": app.selected_track_index=index;break
    app._start_race()
    app._change_speed(5)
    assert(app.render_mode==0)
    var a=app.race.player_cars()[0]
    var b=app.race.player_cars()[1]
    a["progress"]=0.948
    b["progress"]=0.947
    var tyre: String = "Duro" if str(a.tire)!="Duro" else "Macio"
    app.race.order_pit(int(a.id),tyre)
    app.race.order_pit(int(b.id),tyre)
    app.race.running=true
    Perf.set_enabled(true)
    Perf.reset({"task":"pit_sprint"})
    var ms:Array=[]
    var pit:Array=[]
    var max_frame:float=0.0
    var active:int=0
    var start_tick:int=app.replay_session.tick
    for frame in range(180):
        var st:int=Time.get_ticks_usec()
        app._process(1.0/60.0)
        var elapsed:float=float(Time.get_ticks_usec()-st)/1000.0
        max_frame=maxf(max_frame,elapsed)
        ms.append(elapsed)
        if float(a.pit_left)>0.0 or float(b.pit_left)>0.0: active+=1
        if frame%30==0:
            pit.append({"frame":frame,"ms":elapsed,"t":app.replay_session.tick,"pit_a":float(a.pit_left),"pit_b":float(b.pit_left),"stage_a":str(a.pit_stage),"stage_b":str(b.pit_stage)})
    ms.sort()
    var snap=Perf.snapshot()
    print("PIT_SPRINT ",JSON.stringify({"ticks":app.replay_session.tick-start_tick,"active_frames":active,"max_ms":max_frame,"p95_ms":ms[int(float(ms.size()-1)*.95)],"median_ms":ms[ms.size()/2],"sample":pit,"sections":snap.sections,"cpu_limited":app.replay_session.cpu_limited}))
    quit(0)
