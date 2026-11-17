extends SceneTree
# 20 isolated *administrative* championships x 20 recorded rounds.
# This DOES NOT claim 400 fully simulated GPs or a multi-year career UI.
const Championship = preload("res://scripts/championship_2012.gd")
const SAVE = "user://apex_0667_20_season_stress.json"
const SEASONS := 20
var failures: Array[String] = []
var checks: int = 0
func ck(ok: bool, description: String) -> void:
    checks += 1
    if not ok:
        failures.append(description)
        printerr("CAREER_STRESS_FAIL ", description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var season_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    ck(season_data is Dictionary,"2012 data loads")
    if not season_data is Dictionary: quit(2);return
    var tracks: Array = season_data["tracks"]
    var teams: Array = season_data["teams"]
    var all_drivers: Array = []
    for team in teams:
        for driver in team.drivers:
            all_drivers.append({"name":str(driver.name),"team":str(team.name),"stops":1,"best_lap":90.0,"disqualified":false})
    ck(tracks.size()==20,"20 historical tracks")
    ck(all_drivers.size()==24,"24 drivers")
    var file := ProjectSettings.globalize_path(SAVE)
    if FileAccess.file_exists(SAVE): DirAccess.remove_absolute(file)
    var championship = Championship.new(SAVE)
    ck(not championship.has_season(),"no inherited save")
    var start_time: int = Time.get_ticks_msec()
    var recorded: int = 0
    var saved_bytes: int = 0
    for season in range(SEASONS):
        var start_ok: bool = championship.start_new("Ferrari",321+season,tracks,teams)
        ck(start_ok,"season %d starts" % (season+1))
        ck(int(championship.state.get("serial",-1))==season+1,"season serial %d" % (season+1))
        ck(int(championship.state.get("round_index",-1))==0,"season reset %d" % (season+1))
        if not start_ok: break
        for round_index in range(tracks.size()):
            var order: Array = []
            for i in range(all_drivers.size()):
                order.append(all_drivers[(i+season+round_index)%all_drivers.size()].duplicate(true))
            var result: Dictionary = championship.record_result(tracks[round_index],order,5000.0+round_index)
            ck(bool(result.get("ok",false)),"season %d round %d saved" % [season+1,round_index+1])
            ck(int(championship.state.get("round_index",-1))==round_index+1,"round advances exactly once")
            if not bool(result.get("ok",false)): break
            recorded += 1
            if round_index in [0,9,19]:
                var reloaded = Championship.new(SAVE)
                ck(reloaded.has_season(),"disk reload valid")
                ck(int(reloaded.state.get("round_index",-1))==round_index+1,"disk round position valid")
                ck(int(reloaded.state.get("serial",-1))==season+1,"disk season serial valid")
                ck(reloaded.get_rival_levels().size()==teams.size()-1,"rival levels survive reload")
                championship = reloaded
        ck(championship.is_complete(),"season %d complete" % (season+1))
        ck((championship.state.get("results",[]) as Array).size()==tracks.size(),"season includes 20 distinct results")
        var duplicate: Dictionary = championship.record_result(tracks[-1],all_drivers,6000.0)
        ck(not bool(duplicate.get("ok",true)),"completed championship refuses duplicate result")
        saved_bytes = FileAccess.get_file_as_bytes(SAVE).size()
        ck(saved_bytes > 1000 and saved_bytes < 2*1024*1024,"bounded save size")
    var seconds: float = float(Time.get_ticks_msec()-start_time)/1000.0
    var result: Dictionary = {"test":"20_championships_data_layer_stress","seasons":SEASONS,"races_committed":recorded,"checks":checks,"pass":failures.is_empty(),"errors":failures,"elapsed_seconds":seconds,"last_save_bytes":saved_bytes,"not_covered":"No simulated race physics; historical year remains 2012; does not test multi-year career UI"}
    print("CAREER_20_SEASON_STRESS ",JSON.stringify(result))
    quit(0 if failures.is_empty() else 1)
