extends SceneTree
const Perf=preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize(): call_deferred("run")
func run():
    var host=load("res://scenes/main.tscn").instantiate()
    root.add_child(host)
    for i in range(5): await process_frame
    host.set_process(false)
    host.seed_picker.value = 660
    for index in range(host.season_tracks.size()):
        if str(host.season_tracks[index].get("code", "")) == "ITA":
            host.selected_track_index = index
            break
    if host.weather_mode_picker != null:
        for index in range(host.weather_mode_picker.item_count):
            if host.weather_mode_picker.get_item_text(index) == "Seco":
                host.weather_mode_picker.select(index)
                break
    host._start_race()
    host.race.running=true
    var warmup_ticks:int=int(OS.get_environment("APEX_WARMUP_TICKS"))
    if warmup_ticks > 0:
        for i in range(warmup_ticks):
            assert(host.replay_session.step_tick(), host.replay_session.error)
    var index:int=int(OS.get_environment("APEX_SPEED_INDEX"))
    if index < 3 or index > 5: index=5
    host._change_speed(index)
    assert(host.render_mode==0, "10x/16x/32x Auto should switch to 2D")
    Perf.set_enabled(true)
    Perf.reset({"index":index,"warmup":warmup_ticks})
    var total_frames:int=60
    var start_tick:int=host.replay_session.tick
    var max_ms:float=0.0
    var total_us:int=0
    var frame_ticks:Array=[]
    var frame_ms:Array=[]
    var limited_frames:int=0
    for f in range(total_frames):
        var b:int=Time.get_ticks_usec()
        var last:int=host.replay_session.tick
        host._process(1.0/60.0)
        var d:int=Time.get_ticks_usec()-b
        total_us+=d
        max_ms=maxf(max_ms,float(d)/1000.0)
        frame_ticks.append(host.replay_session.tick-last)
        frame_ms.append(float(d)/1000.0)
        if host.replay_session.cpu_limited: limited_frames+=1
    frame_ms.sort()
    assert(host.replay_session.hashes.size()==host.replay_session.tick, "No unrecorded sporting ticks")
    assert(host.replay_session.accumulator <= 1.200001, "No unbounded simulation debt")
    assert(host.replay_session.tick > 0)
    var perf_data:Dictionary=Perf.snapshot()
    var samples:Dictionary={"perf_sections":perf_data.sections,"warmup_ticks":warmup_ticks,"requested_speed":host.sim_speed,"frames":total_frames,"cpu_limited_frames":limited_frames,"p95_frame_ms":frame_ms[56],"ticks":host.replay_session.tick-start_tick,"time_ms":float(total_us)/1000.0,"mean_frame_ms":float(total_us)/1000.0/total_frames,"max_frame_ms":max_ms,"ticks_per_frame":frame_ticks,"accumulator":host.replay_session.accumulator,"fast_view_2d":host.render_mode==0,"hash":host.replay_session.hashes[-1]}
    print("HIGH_SPEED_UI ",JSON.stringify(samples))
    quit(0)
