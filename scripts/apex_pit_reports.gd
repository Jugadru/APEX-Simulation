extends RefCounted
## APEX 0.6.2.3 — extracted responsibility; main.gd remains the scene host.
## The wrapper preserves legacy signals and callbacks.

const GarageScript = preload("res://scripts/garage.gd")
static func _refresh_pit_analytics(host) -> void:
	if host.race == null or host.analytics_summary_label == null:
		return
	host.analytics_seen_count = host.race.pit_history.size()
	var mine: Array = host.race.get_pit_history(host.selected_team)
	var stats: Dictionary = host.race.get_pit_summary(host.selected_team)
	var all_stats: Dictionary = host.race.get_pit_summary()
	var count: int = int(stats["stops"])
	if count == 0:
		host.analytics_summary_label.text = "Nenhum pit stop concluído pela sua equipe.\nTrocas registradas na grid: %d" % int(all_stats["stops"])
	else:
		host.analytics_summary_label.text = "%d parada(s)  •  média serviço %.2fs\nMelhor %.2fs  •  média pit lane %.2fs\nFila total +%.2fs  •  incidentes +%.2fs" % [count, float(stats["mean_service"]), float(stats["fastest_service"]), float(stats["mean_total"]), float(stats["sum_queue"]), float(stats["sum_incidents"])]
	host.analytics_chart.set_records(mine)
	var comparison: Array = host.race.get_team_pit_comparison()
	var compare_lines: Array[String] = []
	for i in range(mini(6, comparison.size())):
		var record: Dictionary = comparison[i]
		var mark := "★ " if str(record["team"]) == host.selected_team else ""
		compare_lines.append("%d. %s%s • %.2fs (%d)" % [i + 1, mark, str(record["team"]), float(record["mean_service"]), int(record["stops"])])
	host.analytics_compare_label.text = "\n".join(compare_lines) if not compare_lines.is_empty() else "Sem paradas concluídas na grid."
	var history_lines: Array[String] = []
	for i in range(mine.size() - 1, maxi(-1, mine.size() - 11), -1):
		var item: Dictionary = mine[i]
		var incident_mark := " / FALHA" if float(item["incident_delay"]) > 0.001 else ""
		history_lines.append("V%02d %s | P%d→P%d | %s→%s\n  troca %.2fs • fila +%.1fs • falha +%.1fs%s" % [int(item["lap"]), str(item["driver"]), int(item["position_before"]), int(item["position_after"]), str(item["old_tire"]), str(item["new_tire"]), float(item["service"]), float(item["wait"]), float(item["incident_delay"]), incident_mark])
	host.analytics_history_label.text = "\n".join(history_lines) if not history_lines.is_empty() else "Aguardando primeira parada."
	host.analytics_advice_label.text = host._pit_engineer_recommendation(stats)
	host.analytics_final_rendered = host.race.finished
	if host.race.finished:
		var finish_lines: Array[String] = ["%s • %s" % [host.race.track_name, host.selected_team],
			"%d paradas | pit lane total %.1fs" % [count, float(stats["sum_pit_time"])],
			"Treinamento: economia teórica nesta prova %.2fs" % float(stats["sum_training_saving"]),
			"Saldo após fila e incidentes vs referência: %+.2fs" % float(stats["sum_net_vs_untrained"])]
		for item in host.race.get_sorted():
			if str(item["team"]) == host.selected_team:
				finish_lines.append("P%d %s • %d parada(s)" % [int(item["position"]), str(item["name"]), int(item["stops"])])
		host.analytics_final_label.text = "\n".join(finish_lines)
	else:
		host.analytics_final_label.text = "Disponível na bandeirada."


static func _crew_training_cost_spent(host) -> int:
	var crew_data: Dictionary = host.garage.get_team(host.selected_team)["crew_levels"]
	var total := 0
	for part in GarageScript.CREW_PARTS:
		var level: int = int(crew_data.get(part, 0))
		for n in range(1, level + 1):
			total += int(GarageScript.CREW_BASE_COST[part]) * n
	return total


static func _pit_engineer_recommendation(host, stats: Dictionary) -> String:
	var count: int = int(stats["stops"])
	if count == 0:
		return "Faça ao menos uma parada para habilitar a análise."
	var lines: Array[String] = []
	if float(stats["sum_queue"]) > 0.3:
		lines.append("A fila custou %.2fs. Considere separar as chamadas dos dois pilotos." % float(stats["sum_queue"]))
	if float(stats["sum_incidents"]) > 0.3:
		lines.append("As falhas acrescentaram %.2fs. Treinar Precisão pode reduzir a probabilidade de novas falhas." % float(stats["sum_incidents"]))
	var crew: Dictionary = host.garage.get_team(host.selected_team)["crew_levels"]
	if int(crew.get("Agilidade", 0)) < 3:
		lines.append("Agilidade pode economizar até 0,28s por parada adicionalmente por nível, respeitando o limite mínimo.")
	if int(crew.get("Coordenação", 0)) < 3:
		lines.append("Coordenação pode economizar até 0,18s por parada adicionalmente por nível.")
	lines.append("Treinamento já adquirido: R$ %.2f mi • economia estimada nesta prova: %.2fs." % [float(host._crew_training_cost_spent()) / 1000000.0, float(stats["sum_training_saving"])])
	lines.append("Comparações usam somente paradas concluídas nesta corrida; amostras pequenas são indicativas.")
	return "\n".join(lines)


static func _export_pit_csv(host) -> void:
	if host.race == null or host.race.pit_history.is_empty():
		host.analytics_export_label.text = "Ainda não há paradas concluídas para exportar."
		return
	var folder: String = OS.get_user_data_dir().path_join("relatorios")
	var err: Error = DirAccess.make_dir_recursive_absolute(folder)
	if err != OK:
		host.analytics_export_label.text = "Falha ao criar pasta: erro %d" % err
		return
	var path: String = folder.path_join("apex_pit_2012_%s_%s.csv" % [str(host.race.track.get("code", "GP")), Time.get_datetime_string_from_system().replace(":", "-")])
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		host.analytics_export_label.text = "Não foi possível salvar o relatório CSV."
		return
	file.store_csv_line(PackedStringArray(["Circuito", "Equipe", "Piloto", "Volta", "Parada", "Pneu anterior", "Pneu novo", "Serviço (s)", "Pit lane total (s)", "Fila (s)", "Incidente (s)", "Ocorrência", "Economia treino (s)", "Saldo vs referência (s)"]), ";")
	for item in host.race.get_pit_history():
		file.store_csv_line(PackedStringArray([
			str(item["track"]), str(item["team"]), str(item["driver"]), str(item["lap"]), str(item["stop"]),
			str(item["old_tire"]), str(item["new_tire"]), str(item["service"]), str(item["total"]),
			str(item["wait"]), str(item["incident_delay"]), str(item["incident"]),
			str(item["training_saved"]), str(item["net_vs_untrained"])]), ";")
	file.close()
	host.analytics_export_label.text = "CSV salvo em: " + path

