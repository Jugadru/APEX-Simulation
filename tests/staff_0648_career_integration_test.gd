extends SceneTree
const TeamAutonomy = preload("res://scripts/core/race_team_autonomy.gd")
var errs: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")
func chk(ok: bool, message: String) -> void:
    if not ok:
        errs.append(message)
        printerr("STAFF_CAREER_FAIL "+message)
func _run() -> void:
    var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    await process_frame
    var team: String = game.selected_team
    var init: int = int(game.garage.get_team(team)["budget"])
    chk(game.championship.start_new(team, 41, game.season_tracks, game.teams), "temporada inicia")
    game._resume_championship()
    chk(game.championship_mode, "carreira ativa")
    game._hire_staff_candidate("Estrategista", "est_b")
    var serial: int = int(game.championship.state["serial"])
    var after_signing: int = init - 420000
    chk(int(game.garage.get_team(team)["budget"]) == after_signing, "assinatura")
    var weak = TeamAutonomy.decide({"wear":68.0,"tire":"Médio","interval":6.0,"laps_done":12}, 
        {"pit_now":false,"window_start":32,"forecast_3":0.35},{"wetness_factor":0.01}, {"Estrategista":0,"Engenheiro":0},70)
    var strong = TeamAutonomy.decide({"wear":68.0,"tire":"Médio","interval":6.0,"laps_done":12},
        {"pit_now":false,"window_start":32,"forecast_3":0.35},{"wetness_factor":0.01}, game.garage.effective_staff_levels(team),70)
    chk(str(weak["pace"]) == "Normal" and str(strong["pace"]) == "Conservar", "staff muda realmente estrategia")
    game.championship.state["results"] = [{
        "round":1,"positions":[{"team":team,"position":2}]}]
    game._reconcile_championship_rewards()
    var expected: int = after_signing + 500000 + 9*70000 - 95000
    chk(int(game.garage.get_team(team)["budget"]) == expected, "premio e folha pagos no mesmo fluxo real")
    var first_key_count: int = game.garage.get_team(team)["staff_payroll_keys"].size()
    game._reconcile_championship_rewards()
    chk(int(game.garage.get_team(team)["budget"]) == expected, "reconcile sem pagamento duplo")
    chk(game.garage.get_team(team)["staff_payroll_keys"].size() == first_key_count, "reconcile idempotente")
    game._start_race()
    await process_frame
    chk(game.race != null, "GP após contratação inicia")
    if game.race != null:
        chk(game.race.crew_levels is Dictionary, "motor de box preservado")
    if errs.is_empty():
        print("STAFF_CAREER_0648_PASS championship reward/payroll idempotent, autodelegation real effect, next race")
    quit(0 if errs.is_empty() else 1)
