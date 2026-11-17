extends SceneTree
const Soul = preload("res://scripts/core/staff_soul_0650.gd")
const Garage = preload("res://scripts/garage.gd")
const Market = preload("res://scripts/core/staff_market_0648.gd")
var failures: Array[String] = []

func verify(ok: bool, name: String) -> void:
    if not ok:
        failures.append(name)
        printerr("SOUL_0650_FAIL: " + name)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var legacy: Dictionary = {"staff_roster":{
        "Estrategista":{"id":"est_b", "name":"Miguel Torres", "skill":76, "salary":95000, "remaining_gps":8},
        "Engenheiro":{"id":"eng_b", "name":"Clara Ferreira", "skill":78, "salary":105000, "remaining_gps":8}},
        "staff_payroll_keys":{}, "staff_log":[], "budget":12000000}
    Soul.ensure(legacy)
    verify(legacy["staff_roster"]["Estrategista"].has("personality"), "migração de contrato 9.9 sem substituição")
    verify(int(legacy["staff_roster"]["Engenheiro"]["morale"]) == 70, "moral inicial determinístico")
    verify(Soul.summary(legacy)["relations"] == 1, "uma relação com dois titulares")
    var checksum: String = JSON.stringify(legacy)
    Soul.ensure(legacy)
    verify(JSON.stringify(legacy) == checksum, "migração idempotente")
    verify(Soul.action_allowed(legacy, "briefing", 0, 0, 0) != "", "GP avulso não permite ação")
    verify(Soul.action_allowed(legacy, "briefing", 1, 1, 20) == "", "ação na primeira etapa disponível")
    var initial_budget: int = int(legacy["budget"])
    var before: Dictionary = Soul.summary(legacy)
    verify(Soul.apply_action(legacy, "integration", 1, 1, 20).contains("INTEGRAÇÃO"), "integração realizada")
    verify(int(legacy["budget"]) == initial_budget - 120000, "valor descontado uma vez")
    var after: Dictionary = Soul.summary(legacy)
    verify(int(after["cohesion"]) == int(before["cohesion"]) + 9, "coesão evolui por ação")
    verify(int(after["morale"]) == int(before["morale"]) + 4, "moral evolui por ação")
    verify(Soul.apply_action(legacy, "recovery", 1, 1, 20).contains("já foi realizada"), "apenas uma ação por GP")
    verify(int(legacy["budget"]) == initial_budget - 120000, "não gasta duas vezes")
    var stat_before: Dictionary = Soul.summary(legacy)
    verify(bool(Soul.settle_round(legacy, 1, 1, 3)["updated"]), "resultado real afeta equipe")
    verify(int(Soul.summary(legacy)["energy"]) < int(stat_before["energy"]), "energia consumida pelo GP")
    var result_snapshot: String = JSON.stringify(legacy)
    verify(not bool(Soul.settle_round(legacy, 1, 1, 3)["updated"]), "resultado idempotente")
    verify(JSON.stringify(legacy) == result_snapshot, "sem segundo efeito de GP")
    verify(Soul.action_allowed(legacy, "recovery", 1, 2, 20) == "", "nova ação no GP seguinte")
    var migrated: Dictionary = {"staff_roster":{"Engenheiro":Market.candidate("Engenheiro", "eng_c")},
        "staff_payroll_keys":{"3_r04_Engenheiro":170000}, "staff_log":[], "budget":500000}
    var before_migration: String = JSON.stringify(migrated["staff_roster"])
    verify(not bool(Soul.settle_round(migrated, 3, 4, 1)["updated"]), "não recalcula GP legado")
    verify(JSON.stringify(migrated["staff_roster"]) != before_migration, "contrato legado recebe perfil")
    verify(str(migrated["staff_soul"]["round_keys"]["3_r04"]) == "migrated", "migração histórica marcada")
    var game = Garage.new()
    var team: String = "Team_Soul_0650_Validation"
    var budget: int = int(game.get_team(team)["budget"])
    verify(game.staff_hire_candidate(team, "Chefe de Mecânica", "mec_c", 11, 0).contains("Nina"), "contratação de mecânico permanece")
    verify(int(game.get_team(team)["budget"]) == budget - 710000, "contratação 9.9 mantém bônus")
    verify(game.effective_crew_levels(team).get("Precisão", 0) == 2, "bônus técnico legado inalterado")
    verify(int(game.staff_soul_summary(team)["count"]) == 1, "painel reflete contratação")
    verify(game.staff_soul_action(team, "recovery", 11, 1, 20).contains("DESCANSO"), "gestão persiste via garage")
    verify(game.staff_soul_action(team, "briefing", 11, 1, 20).contains("já foi realizada"), "garage impede duplicação")
    verify(bool(game.staff_soul_settle_round(team, 11, 1, 12)["updated"]), "garage registra classificação")
    verify(game.staff_settle_round(team, 11, 1)["paid"] == 152000, "folha preservada")
    verify(game.staff_settle_round(team, 11, 1)["paid"] == 0, "folha idempotente")
    verify(int(game.get_team(team)["staff_roster"]["Chefe de Mecânica"]["remaining_gps"]) == 7, "contrato passa 8->7 GPs")
    var saved: Dictionary = game.get_team(team).duplicate(true)
    game.save()
    var reloaded = Garage.new()
    var current: Dictionary = reloaded.get_team(team)
    verify(current["staff_roster"]["Chefe de Mecânica"]["morale"] == saved["staff_roster"]["Chefe de Mecânica"]["morale"], "moral persiste no save")
    verify(current["staff_soul"]["action_keys"].has("11_r01"), "ação persiste no save")
    verify(current["staff_soul"]["round_keys"].has("11_r01"), "pós-GP persiste no save")
    verify(current["staff_payroll_keys"].has("11_r01_Chefe de Mecânica"), "salários continuam no save")
    if failures.is_empty():
        print("SOUL_0650_MODEL_PASS migration/hire/economy/morale/energy/trust/relations/actions/cooldown/round/save")
    quit(0 if failures.is_empty() else 1)
