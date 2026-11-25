extends RefCounted
## Module extracted from main.gd v0.6.2.0. Works through the live scene host.
## Keeps existing callbacks while separating responsibilities.

static func _ask_new_championship(host) -> void:
	host.championship_new_dialog.popup_centered()

static func _new_championship(host) -> void:
	if host.championship.start_new(host.selected_team, int(host.seed_picker.value), host.season_tracks, host.teams):
		host.garage.sync_project_season(host.selected_team, int(host.championship.state.get("serial", 1)))
		host._resume_championship()
	else:
		host.championship_status.text = "ERRO: nao foi possivel salvar a nova temporada."

static func _resume_championship(host) -> void:
	if not host.championship.has_season():
		host.championship_mode = false
		host._update_championship_menu()
		return
	host.championship_mode = true
	host.selected_team = str(host.championship.state.get("team", host.selected_team))
	if host.team_picker != null:
		for i in range(host.teams.size()):
			if str(host.teams[i]["name"]) == host.selected_team:
				host.team_picker.select(i)
				break
	var next: Dictionary = host.championship.next_round()
	if not next.is_empty():
		for i in range(host.season_tracks.size()):
			if str(host.season_tracks[i].get("code", "")) == str(next.get("code", "")):
				host.selected_track_index = i
				break
		if host.track_picker != null:
			host.track_picker.select(host.selected_track_index)
		if host.seed_picker != null:
			host.seed_picker.value = float(host.championship.round_seed())
		host._update_tyre_briefing()
		host._update_weather_briefing()
	host._update_championship_menu()

static func _single_race_mode(host) -> void:
	host.championship_mode = false
	host._update_championship_menu()

static func _update_championship_menu(host) -> void:
	if host.championship_status == null:
		return
	var existing: bool = host.championship.has_season()
	host.championship_continue_button.disabled = not existing
	host.team_picker.disabled = host.championship_mode
	host.track_picker.disabled = host.championship_mode
	host.seed_picker.editable = not host.championship_mode
	if not existing:
		host.championship_status.text = "GP avulso • crie uma temporada para somar pontos de pilotos e construtores."
	elif host.championship.is_complete():
		host.championship_status.text = "CAMPEONATO CONCLUÍDO • 20/20 etapas. Consulte a classificação final."
	elif host.championship_mode:
		var next: Dictionary = host.championship.next_round()
		host.championship_status.text = "CAMPEONATO ATIVO • Etapa %d/20 • %s / %s • %s" % [int(host.championship.state["round_index"]) + 1, str(next.get("country", "")), str(next.get("name", "")), host.selected_team]
	else:
		host.championship_status.text = "GP AVULSO • campeonato salvo: %d/20 etapas concluídas." % int(host.championship.state["round_index"])
	if host.championship_mode and existing:
		host.championship_status.text += " • Caixa virtual: R$ %d" % int(host.garage.get_team(host.selected_team)["budget"])
	if host.championship_mode and host.championship.is_complete():
		host.start_button.disabled = true
		host.start_button.text = "🏁 CAMPEONATO FINALIZADO"
	else:
		host.start_button.disabled = false
		host.start_button.text = "▶  DISPUTAR ETAPA %d/20" % (int(host.championship.state["round_index"]) + 1) if host.championship_mode else "▶  INICIAR CORRIDA  /  ENTRAR NO GRID"

static func _show_championship_table(host) -> void:
	if not host.championship.has_season():
		host.championship_report_text.text = "Nenhuma temporada iniciada. Clique em NOVA TEMPORADA."
		host.championship_table_dialog.popup_centered(Vector2i(640, 270))
		return
	var lines: Array[String] = []
	lines.append("TEMPORADA 2012  •  %d/20 etapas  •  %s" % [int(host.championship.state["round_index"]), "ENCERRADA" if host.championship.is_complete() else "EM ANDAMENTO"])
	lines.append("PILOTOS")
	var rank: int = 0
	for entry in host.championship.standings("drivers"):
		rank += 1
		lines.append("%02d  %-25s %3d pts" % [rank, str(entry["name"]), int(entry["points"])])
	lines.append("\nCONSTRUTORES")
	rank = 0
	for entry in host.championship.standings("constructors"):
		rank += 1
		lines.append("%02d  %-25s %3d pts" % [rank, str(entry["name"]), int(entry["points"])])
	var results: Array = host.championship.state["results"]
	if not results.is_empty():
		var last: Dictionary = results[-1]
		lines.append("\nÚLTIMA ETAPA: %s / vencedor: %s" % [str(last["name"]), str(last["positions"][0]["name"])])
	lines.append("\nCALENDÁRIO / RESULTADOS")
	var finished_results: Array = host.championship.state["results"]
	for i in range(host.championship.state["calendar"].size()):
		var race_entry: Dictionary = host.championship.state["calendar"][i]
		var info: String = "A disputar"
		if i < finished_results.size():
			info = "Vencedor: " + str(finished_results[i]["positions"][0]["name"])
		lines.append("%02d  %s — %s | %s" % [i + 1, str(race_entry["country"]), str(race_entry["name"]), info])
	host.championship_report_text.text = "\n".join(lines)
	host.championship_table_dialog.popup_centered(Vector2i(890, 750))

static func _reconcile_championship_rewards(host) -> void:
	if host.garage == null or host.championship == null or not host.championship.has_season():
		return
	var my_team: String = str(host.championship.state.get("team", ""))
	var serial: int = int(host.championship.state.get("serial", 1))
	host.garage.sync_project_season(my_team, serial)
	host.garage.deliver_research(my_team, serial, int(host.championship.state.get("round_index", 0)))
	for finished_round in host.championship.state.get("results", []):
		var best_pos: int = 99
		for row in finished_round["positions"]:
			if str(row["team"]) == my_team:
				best_pos = mini(best_pos, int(row["position"]))
		var bonus: int = 500000 + maxi(0, 11 - best_pos) * 70000
		# Awards are game-economy balancing, NOT historic F1 payments.
		host.garage.credit_championship_prize(my_team, "2012_c%d_r%02d" % [serial, int(finished_round["round"])], bonus)
		# 0.6.5.0: registrar efeitos humanos uma vez por etapa ANTES da folha
		# (a folha pode encerrar contratos). Não reprocessa GPs salvos na 9.9.
		host.garage.staff_soul_settle_round(my_team, serial, int(finished_round["round"]), best_pos)
		# Salários por GP somente de contratos 0648, com chave por etapa.
		host.garage.staff_settle_round(my_team, serial, int(finished_round["round"]))

static func _commit_championship_result(host) -> void:
	if host.replay_session != null and host.replay_session.playback: return
	if not host.championship_race_active or host.championship_result_saved or host.race == null or not host.race.finished:
		return
	if host.commentary != null:
		host.commentary.ingest(host.race, host.selected_team)
	var outcome: Dictionary = host.championship.record_result(host.race.track, host.race.get_sorted(), host.race.clock)
	if not bool(outcome.get("ok", false)):
		push_error("APEX campeonato: " + str(outcome.get("error", "erro ao salvar")))
		host.run_button.text = "TENTAR SALVAR RESULTADO"
		host.run_button.disabled = false
		return
	host.championship_result_saved = true
	if host.commentary != null:
		var career = preload("res://scripts/core/race_engineer_career_0922.gd")
		var team: Dictionary = host.garage.get_team(host.selected_team)
		var previous: Dictionary = (team.get("staff_soul", {}) as Dictionary).duplicate(true)
		if career.settle(team, host.commentary.staff_context, host.race.player_cars(), host.commentary.communication.relationships, int(host.championship.state.get("serial", 0)), int(host.championship.state.get("round_index", 0))):
			if not host.garage.save():
				team["staff_soul"] = previous
	host._reconcile_championship_rewards()
	host.run_button.text = "▶ PRÓXIMO GP" if not host.championship.is_complete() else "🏆 CLASSIFICAÇÃO"
	host.run_button.disabled = false

