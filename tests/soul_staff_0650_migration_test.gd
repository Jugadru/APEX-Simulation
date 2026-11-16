extends SceneTree
const Garage = preload("res://scripts/garage.gd")
const Championship = preload("res://scripts/championship_2012.gd")
const Market = preload("res://scripts/core/staff_market_0648.gd")
var failures: Array[String] = []
func check(ok: bool, name: String) -> void:
    if not ok:
        failures.append(name)
        printerr("SOUL_0650_MIGRATION_FAIL " + name)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var folder: String = OS.get_environment("XDG_DATA_HOME").path_join("APEX_06499_STRATEGY_SIMULATOR")
    DirAccess.make_dir_recursive_absolute(folder)
    var old_garage: String = folder.path_join("apex_garage_050.json")
    var old_season: String = folder.path_join("apex_championship_2012_v060.json")
    var staff: Dictionary = Market.candidate("Estrategista", "est_b")
    staff.merge({"remaining_gps":5,"hired_serial":1,"hired_round":0},true)
    var old_data: Dictionary = {"Ferrari":{"budget":8844000,"levels":{"Motor":1,"Asa":0,"Chassi":0},
        "staff_roster":{"Estrategista":staff},"staff_log":["registro legado 9.9"]}}
    var file := FileAccess.open(old_garage, FileAccess.WRITE)
    file.store_string(JSON.stringify(old_data))
    file.close()
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var previous_season = Championship.new(old_season)
    check(previous_season.start_new("Ferrari", 42, data["tracks"], data["teams"]), "fixture campanha 9.9")
    var old_garage_bytes: String = FileAccess.get_file_as_string(old_garage)
    var old_season_bytes: String = FileAccess.get_file_as_string(old_season)
    var new_garage = Garage.new()
    var new_season = Championship.new()
    check(int(new_garage.get_team("Ferrari")["budget"]) == 8844000, "caixa legado importado")
    check(int(new_garage.get_team("Ferrari")["levels"]["Motor"]) == 1, "oficina 9.9 preservada")
    check(int(new_garage.get_team("Ferrari")["staff_roster"]["Estrategista"]["remaining_gps"]) == 5,
        "contrato 9.9 preservado")
    check(new_garage.get_team("Ferrari")["staff_roster"]["Estrategista"].has("personality"),
        "personalidade criada sem nova contratação")
    check(new_season.has_season() and int(new_season.state.get("seed",0)) == 42,
        "campeonato 9.9 importado")
    check(FileAccess.file_exists("user://apex_championship_2012_v060.json"),
        "campeonato gravado no diretório 9.0")
    new_garage.save()
    check(FileAccess.file_exists("user://apex_garage_050.json"), "oficina gravada no diretório 9.0")
    check(FileAccess.get_file_as_string(old_garage) == old_garage_bytes,
        "save da oficina 9.9 preservado sem alterações")
    check(FileAccess.get_file_as_string(old_season) == old_season_bytes,
        "save do campeonato 9.9 preservado sem alterações")
    if failures.is_empty():
        print("SOUL_0650_MIGRATION_PASS true 9.9 custom-dir -> 6.5.0, garage/season read-only/contract")
    quit(0 if failures.is_empty() else 1)
