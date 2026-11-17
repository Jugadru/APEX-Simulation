extends SceneTree
## 066724: presentation-only pitwall location and honest 32x effective-speed meter.
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var app=load("res://scenes/main.tscn").instantiate()
    root.add_child(app)
    for n in range(5): await process_frame
    app.set_process(false)
    app._start_race()
    var pit=app.world_view.pit_complex
    assert(pit != null)
    var details=pit.get_node("PitDetails0660")
    var station_x:float=float(details.get_meta("engineer_station_x",0.0))
    assert(station_x>pit.STALL_X+2.0 and station_x<pit.GARAGE_FRONT_X)
    var source:String=FileAccess.get_file_as_string("res://scripts/circuit_life_0660.gd")
    assert(source.contains("desks.append(transform(Vector3(apron_x"))
    assert(not source.contains("desks.append(transform(Vector3(2.5"))
    for name in ["EngineeringDesks","MonitorFrames","EngineerUniforms"]:
        var mesh: MultiMeshInstance3D = details.get_node(name)
        assert(mesh != null and mesh.multimesh.instance_count>0)
    app._change_speed(5)
    assert(app.sim_speed==32.0 and app.render_mode==0)
    app.race.running=true
    var before_tick:int=app.replay_session.tick
    for f in range(90): app._process(1.0/60.0)
    assert(app.replay_session.tick>before_tick)
    assert(app.effective_speed_x>0.0)
    assert(app.effective_speed_x<=32.5)
    assert(app.render_mode==0)
    assert(app.race_hud_0620.session_label.text.contains("real") or app.race_hud_0620.session_label.text.contains("CPU"))
    print("PITLANE_066724_PASS ", JSON.stringify({"pit_station_side":"garages", "measured_effective_x":app.effective_speed_x,"requested_x":app.sim_speed,"processed_ticks":app.replay_session.tick-before_tick,"speed_label":app.race_hud_0620.session_label.text,"cpu_limited":app.replay_session.cpu_limited}))
    quit(0)
