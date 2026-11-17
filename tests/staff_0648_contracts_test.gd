extends SceneTree
const Garage = preload("res://scripts/garage.gd")
const StaffMarket = preload("res://scripts/core/staff_market_0648.gd")
var faults: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func expect(yes: bool, note: String) -> void:
    if not yes:
        faults.append(note)
        printerr("STAFF_0648_FAIL " + note)

func _run() -> void:
    var store = Garage.new()
    var team := "Staff_0648_Unit"
    var initial: int = int(store.get_team(team)["budget"])
    expect(initial == 12000000, "caixa base")
    expect(store.effective_staff_levels(team).get("Estrategista", -1) == 0, "sem candidatos presumidos")
    var wrong: String = store.staff_hire_candidate(team, "Invalido", "x")
    expect(wrong.contains("desconhecido"), "candidato inexistente")
    var event: String = store.staff_hire_candidate(team, "Estrategista", "est_b", 1, 3)
    expect(event.contains("Miguel"), "contratacao estrategista")
    expect(int(store.get_team(team)["budget"]) == initial - 420000, "pagamento bonus")
    expect(int(store.effective_staff_levels(team)["Estrategista"]) == 2, "habilidade impacta estrategia")
    expect(store.staff_hire_candidate(team, "Estrategista", "est_c").contains("já tem"), "impedir sobrecontratacao")
    var previous_total: int = int(store.get_team(team)["budget"])
    expect(int(store.staff_settle_round(team, 1, 3)["paid"]) == 0, "sem cobrar etapa anterior a contratacao")
    expect(int(store.get_team(team)["budget"]) == previous_total, "sem retroativos")
    expect(int(store.staff_settle_round(team, 1, 4)["paid"]) == 95000, "debito salario primeiro GP")
    expect(int(store.staff_settle_round(team, 1, 4)["paid"]) == 0, "folha idempotente")
    expect(int(store.get_team(team)["staff_roster"]["Estrategista"]["remaining_gps"]) == 7, "duracao de contrato")
    expect(store.staff_hire_candidate(team, "Chefe de Mecânica", "mec_c").contains("Nina"), "contratar chefe da mecanica")
    var effective: Dictionary = store.effective_crew_levels(team)
    expect(int(effective["Agilidade"]) == 2 and int(effective["Precisão"]) == 2 and int(effective["Coordenação"]) == 2, "efeito real nos boxes")
    expect(int(store.get_team(team)["crew_levels"]["Agilidade"]) == 0, "treino original preservado")
    expect(store.staff_hire_candidate(team, "Chefe de Aerodinâmica", "aero_c").contains("André"), "contratar chefe aerodinamica")
    expect(store.research_next_cost(team, "Asa") == int(round(1600000.0 * 0.85 * 0.92)), "p&d asa desconto limitado")
    expect(store.research_next_cost(team, "Motor") == 1700000, "motor sem desconto")
    var money_before_save: int = int(store.get_team(team)["budget"])
    var reloaded = Garage.new()
    expect(int(reloaded.get_team(team)["budget"]) == money_before_save, "persistencia orcamento")
    expect(reloaded.get_team(team)["staff_roster"].has("Chefe de Aerodinâmica"), "persistencia contratos")
    # Testar pagamentos sem repetir salario e encerrar titular apos 8 GPs.
    var fresh = Garage.new()
    var roster: Dictionary = fresh.get_team(team)["staff_roster"]
    roster.erase("Chefe de Aerodinâmica")
    roster.erase("Chefe de Mecânica")
    fresh.save()
    for round_n in range(5, 12):
        var settled: Dictionary = fresh.staff_settle_round(team, 1, round_n)
        expect(int(settled["paid"]) == 95000, "folha estrategista ronda %d" % round_n)
    expect(not fresh.get_team(team)["staff_roster"].has("Estrategista"), "contrato termina apos 8 corridas")
    expect(int(fresh.staff_settle_round(team, 1, 11)["paid"]) == 0, "expiracao idempotente")
    var high: String = fresh.staff_hire_candidate(team, "Engenheiro", "eng_c")
    expect(high.contains("Davi"), "contratar engenheiro")
    expect(int(fresh.effective_staff_levels(team)["Engenheiro"]) == 3, "nivel engenharia maximo")
    var salary: int = int(fresh.get_team(team)["staff_roster"]["Engenheiro"]["salary"])
    var after_hire: int = int(fresh.get_team(team)["budget"])
    var release_msg: String = fresh.staff_release(team, "Engenheiro")
    expect(release_msg.contains("rescindido"), "rescisao")
    expect(int(fresh.get_team(team)["budget"]) == after_hire - salary * 2, "multa rescisoria")
    expect(fresh.get_team(team)["staff_log"].size() > 0, "historico de eventos")
    if faults.is_empty():
        print("STAFF_0648_PASS contracts, levels, crew, aero R&D, salary idempotency, no backcharge, expiry, release, persistence")
    quit(0 if faults.is_empty() else 1)
