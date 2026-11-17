extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize(): call_deferred("run")
func run():
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for t in data.tracks:
        if str(t.code)=="ITA": track=t.duplicate(true)
    var e = Race.new(data.teams,"Ferrari",660,{},track,{})
    e.configure_weather("Seco")
    var s = Replay.new()
    s.attach(e)
    var total:int = int(OS.get_environment("APEX_TICKS"))
    if total < 1: total=3000
    Perf.set_enabled(true)
    Perf.reset({"task":"growth_benchmark"})
    var last: int = Time.get_ticks_usec()
    var rows: Array = []
    var chunk_size: int = 250
    for n in range(total):
        assert(s.step_tick(),s.error)
        if s.tick % chunk_size == 0:
            var now: int = Time.get_ticks_usec()
            var snap:Dictionary=Perf.snapshot()
            var section:Dictionary=snap.sections
            var line:Dictionary={"tick":s.tick,"block_ms":(now-last)/1000.0,"ms_tick":float(now-last)/1000.0/chunk_size,"race_step_ms_per_tick":section.get("race.step",{}).get("mean_ms",0.0),"events":e.events.size(),"telemetry_events":e.telemetry.event_history.size(),"telemetry_positions":e.telemetry.position_history.size(),"checkpoints":s.checkpoints.size(),"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)}
            line["sections"]=section
            print("GROWTH ",JSON.stringify(line))
            rows.append(line)
            Perf.reset({"part":s.tick})
            last=Time.get_ticks_usec()
    print("GROWTH_DONE ",JSON.stringify({"rows":rows,"hash":s.hashes[-1],"ticks":s.tick}))
    quit(0)
