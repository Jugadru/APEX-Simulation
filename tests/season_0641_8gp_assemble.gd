extends SceneTree
## Usa o ChampionshipScript REAL, com save/load real, somando oito GPs
## completos 100% automaticos na ordem oficial do calendario.
const ChampionshipScript = preload("res://scripts/championship_2012.gd")
const GarageScript = preload("res://scripts/garage.gd")
const SAVE := "user://apex_8gp_0641_weather_balance.json"
const SEED := 321
const TEAM := "Ferrari"
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func verify(ok: bool, why: String) -> void:
    if not ok:
        failures.append(why)
        printerr("APEX_8GP_CAMP_FAIL: ",why)

func _run() -> void:
    var argv: PackedStringArray = OS.get_cmdline_user_args()
    if argv.size() < 1:
        quit(5)
        return
    var output_folder: String = str(argv[0])
    var season_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var tracks: Array = season_data["tracks"]
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
    var season = ChampionshipScript.new(SAVE)
    verify(season.start_new(TEAM, SEED, tracks, season_data["teams"]), "start_new da temporada")
    verify(season.has_season(), "temporada ativa")
    # Isolated test data: never inherit reward claims from a previous test run.
    DirAccess.remove_absolute(ProjectSettings.globalize_path(GarageScript.SAVE_PATH))
    var garage = GarageScript.new()
    var budget_start: int = int(garage.get_team(TEAM)["budget"])
    var income_sum: int = 0
    var round_summaries: Array = []
    for i in range(8):
        var json_path: String = output_folder.path_join("GP_%02d.json" % (i+1))
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
        if typeof(parsed) != TYPE_DICTIONARY:
            verify(false,"resultado faltando para GP %d: %s" % [i + 1, json_path])
            break
        var report: Dictionary = parsed
        var track: Dictionary = tracks[i]
        verify(str(report.get("code", "")) == str(track.get("code", "")), "ordem do calendário GP %d" % (i + 1))
        verify(int(report.get("seed", -1)) == season.round_seed(), "seed da temporada GP %d" % (i+1))
        verify(str(report.get("team_control", "")) == "Automático" and str(report.get("weather_mode", "")) == "Automático", "controles auto GP %d" % (i+1))
        verify(int(report.get("error_count",-1)) == 0 and bool(report.get("finished", false)), "simulação válida GP %d" % (i+1))
        verify(int(report.get("invalid_laps",-1)) == 0, "voltas impossíveis GP %d" % (i+1))
        var rows: Array = report.get("positions",[])
        verify(rows.size() == 24, "24 classificados GP %d" % (i+1))
        var outcome: Dictionary = season.record_result(track, rows, float(report["clock_s"]))
        verify(bool(outcome.get("ok", false)), "record_result GP %d: %s" % [i+1,str(outcome)])
        if not bool(outcome.get("ok", false)):
            break
        verify(int(season.state.get("round_index",-1)) == i+1, "round_index após GP %d" % (i+1))
        var best_pos: int = 99
        for row in rows:
            if str(row["team"]) == TEAM:
                best_pos = mini(best_pos,int(row["position"]))
        var bonus: int = 500000 + maxi(0, 11 - best_pos) * 70000
        verify(garage.credit_championship_prize(TEAM,"2012_c%d_r%02d" % [int(season.state["serial"]),i+1],bonus), "premiação GP %d" % (i+1))
        income_sum += bonus
        var same_again: Dictionary = season.record_result(track, rows, float(report["clock_s"]))
        verify(not bool(same_again.get("ok", false)), "resultado duplicado bloqueado GP %d" % (i+1))
        var restored = ChampionshipScript.new(SAVE)
        verify(int(restored.state.get("round_index",-1)) == i+1, "save/load GP %d" % (i+1))
        verify(int(restored.state.get("seed",0)) == SEED, "persistência seed GP %d" % (i+1))
        season = restored
        var snapshot_path: String = output_folder.path_join("CAMPEONATO_APOS_GP_%02d.json" % (i+1))
        var snapshot_file: FileAccess = FileAccess.open(snapshot_path,FileAccess.WRITE)
        if snapshot_file != null:
            snapshot_file.store_string(JSON.stringify(season.state,"  "))
            snapshot_file.close()
        var podium: Array = []
        for n in range(3):
            podium.append(str(rows[n]["name"]))
        round_summaries.append({"round":i+1,"code":str(track["code"]),"podium":podium,
            "ferrari_best":best_pos,"ferrari_bonus":bonus,"season_round_index":int(season.state["round_index"]),
            "driver_leader":season.standings("drivers")[0],
            "constructor_leader":season.standings("constructors")[0]})
        print("CHAMPIONSHIP_COMMITTED: ",i+1,"/20 ",str(track["code"])," leader=",str(season.standings("drivers")[0]["name"])," pts=",int(season.standings("drivers")[0]["points"]))
    verify(round_summaries.size() == 8,"8 GPs registrados")
    verify(int(season.state.get("round_index",-1)) == 8,"etapa atual 8 de 20")
    verify((season.state.get("results",[]) as Array).size() == 8,"historico de oito GPs")
    verify(not season.is_complete(),"temporada continua após GP8")
    verify(str(season.next_round().get("code","")) == str(tracks[8]["code"]),"proxima etapa Silverstone")
    var drivers: Dictionary = {}
    var constructors: Dictionary = {}
    for item in season.state.get("results",[]):
        for entry in item.get("positions",[]):
            drivers[str(entry["name"])] = int(drivers.get(str(entry["name"]),0)) + int(entry["points"])
            constructors[str(entry["team"])] = int(constructors.get(str(entry["team"]),0)) + int(entry["points"])
    # Dicionários do campeonato mantêm pilotos/equipes ainda com zero ponto.
    # Completar explicitamente os zeros antes da comparação, sem mascarar pontuação.
    for k in (season.state.get("drivers",{}) as Dictionary).keys():
        if not drivers.has(str(k)):
            drivers[str(k)] = 0
    for k in (season.state.get("constructors",{}) as Dictionary).keys():
        if not constructors.has(str(k)):
            constructors[str(k)] = 0
    var stored_drivers: Dictionary = season.state.get("drivers",{})
    var stored_teams: Dictionary = season.state.get("constructors",{})
    verify(drivers.size() == stored_drivers.size(), "tamanho pontuação pilotos")
    verify(constructors.size() == stored_teams.size(), "tamanho pontuação construtores")
    for key in stored_drivers.keys():
        verify(int(drivers.get(key,-1)) == int(stored_drivers[key]), "pontuação piloto: %s" % str(key))
    for key in stored_teams.keys():
        verify(int(constructors.get(key,-1)) == int(stored_teams[key]), "pontuação equipe: %s" % str(key))
    verify(int(garage.get_team(TEAM)["budget"]) == budget_start + income_sum,"bônus campeonato acumulado")
    var result: Dictionary = {"version":"0.6.4.1","scenario":"8 primeiras etapas 2012; temporada real; 100% AUTO",
        "seed":SEED,"team":TEAM,"weather":"Automático","mode":"Automático",
        "round_index":int(season.state.get("round_index",-1)),"next_round":season.next_round(),
        "races":round_summaries,"driver_standings":season.standings("drivers"),
        "constructor_standings":season.standings("constructors"),
        "budget_initial":budget_start,"awarded_income":income_sum,
        "budget_final":int(garage.get_team(TEAM)["budget"]),
        "valid":failures.is_empty(),"failures":failures}
    var output: FileAccess = FileAccess.open(output_folder.path_join("CAMPEONATO_CONSOLIDADO.json"),FileAccess.WRITE)
    if output != null:
        output.store_string(JSON.stringify(result,"  "))
        output.close()
    print("APEX_8GP_CHAMPIONSHIP_RESULT ",JSON.stringify({"rounds":round_summaries.size(),
        "leader":str(season.standings("drivers")[0]["name"]),"points":int(season.standings("drivers")[0]["points"]),
        "next":str(season.next_round().get("code","")),"failures":failures.size()}))
    quit(0 if failures.is_empty() else 1)
