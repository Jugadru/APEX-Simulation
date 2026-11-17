extends SceneTree
## Executa GP real da v0.6.4.0 com regras de temporada, ambos pilotos e STAFF 100% auto.
## Script de auditoria; não modifica RaceEngine ou pontos oficiais.
const RaceScript = preload("res://scripts/race_engine.gd")
const RaceEngineer = preload("res://scripts/core/race_engineer_0639.gd")
const TEAM := "Ferrari"
const SEED := 321
const MAX_STEPS := 16000
const STAFF := {"Engenheiro": 0, "Estrategista": 0}
const UPGRADES := {"Motor": 0, "Asa": 0, "Chassi": 0}
const CREW := {"Agilidade": 0, "Precisão": 0, "Coordenação": 0}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var argv: PackedStringArray = OS.get_cmdline_user_args()
    if argv.size() < 2:
        printerr("USO: -- <round_index 0..7> <output_json_abs_path>")
        quit(2)
        return
    var round_index: int = int(argv[0])
    var save_path: String = str(argv[1])
    var season_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    if typeof(season_data) != TYPE_DICTIONARY:
        printerr("ERRO: dados 2012 inválidos")
        quit(3)
        return
    var season: Dictionary = season_data
    var tracks: Array = season["tracks"]
    if round_index < 0 or round_index >= 8 or round_index >= tracks.size():
        printerr("ERRO: etapa inválida ", round_index)
        quit(4)
        return
    var track: Dictionary = tracks[round_index]
    var seed: int = SEED + round_index * 7919
    var race = RaceScript.new(season["teams"], TEAM, seed, UPGRADES, track, CREW)
    race.set_championship_round(round_index)
    race.configure_weather("Automático")
    var player_ids: Array[int] = []
    var fingerprints: Dictionary = {}
    var auto_updates: Dictionary = {}
    var changed_pace: int = 0
    var changed_kers: int = 0
    for car in race.player_cars():
        var cid: int = int(car["id"])
        player_ids.append(cid)
        auto_updates[str(cid)] = 0
        race.set_pit_control_mode(cid, "IA")
    race.running = true
    var ticks: int = 0
    var max_kers_kj: float = 0.0
    var min_kers_kj: float = 400.0
    var max_progress_backwards: float = 0.0
    var previous_progress: Dictionary = {}
    for car in race.cars:
        previous_progress[int(car["id"])] = float(car["progress"])
    var errors: Array[String] = []
    var pit_event_rows: Array = []
    var previous_event_id: int = 0
    var weather_samples: Array = []
    var next_lap_sample: int = -1
    while not race.finished and ticks < MAX_STEPS:
        var conditions: Dictionary = race.weather_snapshot()
        var wet_bucket: int = int(float(conditions.get("wetness_factor", 0.0)) * 5.0)
        # Replica o _autonomy_tick de apex_race_commands.gd (v0.6.4.0).
        for car in race.player_cars():
            if bool(car.get("finished", false)):
                continue
            var id: int = int(car["id"])
            var fp: String = "%d/%d/%s/%d" % [int(car.get("laps_done",0)), wet_bucket,
                str(car.get("tire","")), int(float(car.get("wear",0.0)) / 15.0)]
            if str(fingerprints.get(id, "")) == fp:
                continue
            fingerprints[id] = fp
            var advice: Dictionary = race.get_engineer_advice(id)
            var decision: Dictionary = RaceEngineer.evaluate(car, advice, conditions, STAFF, race.lap_count)
            var old_pace: String = str(car.get("pace", "Normal"))
            var old_kers: String = str(car.get("kers_mode", "Equilibrado"))
            race.set_pace(id, str(decision.get("pace", "Normal")))
            race.set_kers_mode(id, str(decision.get("kers", "Equilibrado")))
            if old_pace != str(car.get("pace", "Normal")):
                changed_pace += 1
            if old_kers != str(car.get("kers_mode", "Equilibrado")):
                changed_kers += 1
            auto_updates[str(id)] = int(auto_updates[str(id)]) + 1
        race.step(4.0)
        ticks += 1
        if race.lap != next_lap_sample:
            next_lap_sample = race.lap
            weather_samples.append({"lap":race.lap,"wetness":float(race.weather_snapshot().get("wetness_factor",0.0)),"rain":float(race.weather_snapshot().get("rain_intensity",0.0))})
        for e in race.events:
            var event_id: int = int(e.get("event_id",0))
            if event_id <= previous_event_id:
                continue
            previous_event_id = event_id
            if str(e.get("type","")) == "strategy" and str(e.get("message","")) .begins_with("IA BOX"):
                var driver: Dictionary = {}
                for entry in race.cars:
                    if int(entry.get("id",-1)) == int(e.get("driver_id",-100)):
                        driver = entry
                        break
                pit_event_rows.append({"lap":int(driver.get("laps_done",0)),"driver":str(driver.get("name","")),"compound_before":str(driver.get("tire","")),"wear":float(driver.get("wear",0.0)),"stint":int(driver.get("stint_laps",0)),"wetness":float(race.weather_snapshot().get("wetness_factor",0.0)),"message":str(e.get("message",""))})
        if ticks % 800 == 0:
            print("GP_PROGRESS round=",round_index + 1," code=",track["code"]," lap=",race.lap,"/",race.lap_count," tick=",ticks," clock=",int(race.clock))
        for car in race.cars:
            var id: int = int(car["id"])
            var prog: float = float(car["progress"])
            var back: float = float(previous_progress[id]) - prog
            max_progress_backwards = maxf(max_progress_backwards, back)
            previous_progress[id] = prog
            if bool(car.get("kers_equipped", false)):
                max_kers_kj = maxf(max_kers_kj, float(car.get("kers_used_lap_kj", 0.0)))
                min_kers_kj = minf(min_kers_kj, float(car.get("kers_remaining_kj", 400.0)))
    if not race.finished:
        errors.append("GP não terminou: limite de passos")
    if not race.finish_results_validated:
        errors.append("Classificação final não validada")
    if max_progress_backwards > 0.000001:
        errors.append("Progresso retrocedeu %.4f" % max_progress_backwards)
    if max_kers_kj > 400.01 or min_kers_kj < -0.01:
        errors.append("KERS fora dos limites 0-400 kJ")
    var order: Array = race.get_sorted()
    if order.size() != 24:
        errors.append("Grid incompleto: %d carros" % order.size())
    var positions: Array = []
    var invalid_laps: int = 0
    var best_lap_min: float = 9999.0
    var cars_with_pits: int = 0
    var total_stops: int = 0
    var disqualified: int = 0
    var finishers: int = 0
    var distinct: Dictionary = {}
    for i in range(order.size()):
        var car: Dictionary = order[i]
        var name: String = str(car.get("name", ""))
        distinct[name] = true
        var best: float = float(car.get("best_lap", 9999.0))
        best_lap_min = minf(best_lap_min, best)
        invalid_laps += int(car.get("invalid_lap_count", 0))
        total_stops += int(car.get("stops", 0))
        if int(car.get("stops", 0)) > 0:
            cars_with_pits += 1
        if bool(car.get("disqualified", false)):
            disqualified += 1
        if bool(car.get("finished", false)):
            finishers += 1
        if best < float(track.get("base_lap", 90.0)) * 0.70 or best >= 500.0:
            errors.append("Melhor volta implausível: %s %.3f" % [name,best])
        if int(car.get("finish_laps", 0)) > race.lap_count or int(car.get("finish_laps", 0)) < 1:
            errors.append("Voltas de chegada incorretas: %s %d" % [name, int(car.get("finish_laps",0))])
        positions.append({"position":i + 1,"name":name,"team":str(car["team"]),
            "best_lap":best,"stops":int(car.get("stops",0)),
            "disqualified":bool(car.get("disqualified", false)),
            "finish_laps":int(car.get("finish_laps",0)),
            "finish_time":float(car.get("finish_time",-1.0)),
            "gap_label":str(car.get("gap_label",""))})
    if distinct.size() != 24:
        errors.append("Pilotos repetidos na classificação")
    if invalid_laps != 0:
        errors.append("Voltas invalidadas pelo filtro de segurança: %d" % invalid_laps)
    var player_details: Array = []
    for car in race.player_cars():
        var cid: int = int(car["id"])
        var scheduled: int = int(car.get("pit_scheduled_lap",0))
        if str(car.get("pit_control_mode","")) != "IA":
            errors.append("Piloto da equipe fora do modo IA: %s" % str(car["name"]))
        if int(auto_updates.get(str(cid),0)) < 4:
            errors.append("Autonomia não processada: %s" % str(car["name"]))
        player_details.append({"id": cid,"name":str(car["name"]),"position":int(car.get("position",0)),
            "stops":int(car.get("stops",0)),"pace":str(car.get("pace","")),
            "kers":str(car.get("kers_mode","")),"mode":str(car.get("pit_control_mode","")),
            "auto_updates":int(auto_updates.get(str(cid),0)), "scheduled_at_end":scheduled})
    var pit_counts: Dictionary = {}
    var total_extra_pit_s: float = 0.0
    for entry in race.pit_history:
        var owner: String = str(entry.get("name", "?"))
        pit_counts[owner] = int(pit_counts.get(owner,0)) + 1
        total_extra_pit_s += float(entry.get("pit_last_extra",0.0))
    var output: Dictionary = {"round":round_index + 1,"code":str(track["code"]),
        "name":str(track["name"]),"laps":int(track["laps"]),"seed":seed,
        "weather_mode":"Automático","team_control":"Automático", "player_team":TEAM,
        "upgrades":UPGRADES,"crew":CREW,"staff":STAFF,"full_race":true,
        "finished":race.finished,"finish_results_validated":race.finish_results_validated,
        "clock_s":race.clock,"steps":ticks,"weather_final":race.weather_snapshot(),
        "positions":positions,"player":player_details,"pit_counts":pit_counts,
        "pit_history_len":race.pit_history.size(),"pit_extra_s":total_extra_pit_s,
        "total_stops":total_stops,"cars_with_pits":cars_with_pits,
        "disqualified":disqualified,"finishers":finishers,"invalid_laps":invalid_laps,
        "best_lap_min":best_lap_min,"max_progress_backwards":max_progress_backwards,
        "kers_max_used_kj":max_kers_kj,"kers_min_remaining_kj":min_kers_kj,
        "staff_pace_changes":changed_pace,"staff_kers_changes":changed_kers,
        "error_count":errors.size(),"errors":errors, "pit_history":race.get_pit_history(),"pit_events":pit_event_rows,"weather_samples":weather_samples}
    var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        printerr("FALHA: não gravou JSON em ",save_path)
        quit(5)
        return
    file.store_string(JSON.stringify(output,"  "))
    file.close()
    print("APEX_8GP_ROUND ",JSON.stringify({"round":round_index + 1,"code":track["code"],
        "winner":str(positions[0]["name"]),"laps":race.lap_count,
        "clock_s":race.clock,"pits":total_stops,"invalid":invalid_laps,
        "dnfs":24 - finishers,"dq":disqualified,
        "staff_pace_changes":changed_pace,"errors":errors.size()}))
    quit(0 if errors.is_empty() else 1)
