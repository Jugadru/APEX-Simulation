extends SceneTree
## Integração temporada nativa: GP concluído, resultado salvo, folha e Soul Staff.
var failures: Array[String] = []
func verify(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        printerr("SOUL_0650_SEASON_FAIL: " + label)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var host = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(host)
    await process_frame
    host._new_championship()
    verify(host.championship_mode and host.championship.has_season(), "campeonato começa")
    var team: String = host.selected_team
    host._hire_staff_candidate("Engenheiro", "eng_c")
    host._hire_staff_candidate("Chefe de Mecânica", "mec_a")
    verify(host.garage.staff_soul_summary(team)["count"] == 2, "dois titulares contratados")
    var crew_before: String = JSON.stringify(host.garage.effective_crew_levels(team))
    var levels_before: String = JSON.stringify(host.garage.effective_staff_levels(team))
    host._staff_soul_action("integration")
    verify(JSON.stringify(host.garage.effective_crew_levels(team)) == crew_before,
        "integração não modifica níveis da equipe de boxes")
    verify(JSON.stringify(host.garage.effective_staff_levels(team)) == levels_before,
        "integração não modifica níveis da IA")
    verify(host.garage.staff_soul_summary(team)["relations"] == 1,
        "vínculo criado pelos dois departamentos")
    var energy_before: int = int(host.garage.get_team(team)["staff_roster"]["Engenheiro"]["energy"])
    host._start_race()
    verify(host.race != null and host.championship_race_active, "corrida de campeonato construída")
    var original_state: String = JSON.stringify(host.race.get_state_snapshot())
    host.garage.staff_soul_summary(team)
    verify(JSON.stringify(host.race.get_state_snapshot()) == original_state,
        "consulta Soul Staff não altera estado da corrida")
    host.race.running = true
    var ticks: int = 0
    while not host.race.finished and ticks < 9000:
        host.race.step(4.0)
        ticks += 1
    verify(host.race.finished and host.race.finish_results_validated, "GP completo com classificação validada")
    var round_number: int = 1
    var serial: int = int(host.championship.state.get("serial", 1))
    var prior_round: int = int(host.championship.state.get("round_index", 0))
    host._commit_championship_result()
    verify(host.championship_result_saved, "resultado gravado uma vez")
    verify(int(host.championship.state.get("round_index", 0)) == prior_round + 1, "etapa incrementada")
    var state: Dictionary = host.garage.get_team(team)
    verify(state["staff_soul"]["round_keys"].has("%d_r%02d" % [serial, round_number]),
        "Soul Staff calculado após resultado real")
    verify(state["staff_payroll_keys"].has("%d_r01_Engenheiro" % serial),
        "salário cobrado pelo campeonato")
    verify(int(state["staff_roster"]["Engenheiro"]["energy"]) < energy_before,
        "cansaço observado após corrida")
    var snapshot: String = JSON.stringify([state["staff_soul"],state["staff_roster"],state["staff_log"]])
    var budget_after: int = int(state["budget"])
    host._reconcile_championship_rewards()
    verify(JSON.stringify([state["staff_soul"],state["staff_roster"],state["staff_log"]]) == snapshot,
        "reconciliação não repete alterações Soul Staff")
    verify(int(state["budget"]) == budget_after, "sem duplicar custos, salários ou premiação")
    host._resume_championship()
    host._open_staff()
    verify(not host.staff_soul_action_buttons["briefing"].disabled,
        "nova reunião liberada antes da próxima etapa")
    if failures.is_empty():
        print("SOUL_0650_SEASON_PASS GP=%d ticks=%d result/salary/soul/idempotence/next-action" % [int(host.race.lap_count),ticks])
    quit(0 if failures.is_empty() else 1)
