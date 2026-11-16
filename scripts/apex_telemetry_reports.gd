extends RefCounted
## APEX 0.6.2.3 — extracted responsibility; main.gd remains the scene host.
## The wrapper preserves legacy signals and callbacks.
static func _refresh_car_diagnostics(host) -> void:
	if host.race == null or host.diagnostic_primary == null:
		return
	var owned: Array = host.race.player_cars()
	var ratings: Array = []
	for item in host.race.cars:
		ratings.append(float(item.get("car_rating", 80)))
	var average_rating := 0.0
	for rating in ratings:
		average_rating += float(rating)
	average_rating /= maxf(1.0, float(ratings.size()))
	for i in range(mini(2, owned.size())):
		var car: Dictionary = owned[i]
		var diagnostic: Label = host.diagnostic_primary if i == 0 else host.diagnostic_secondary
		var rating: float = float(car.get("car_rating", 80))
		var rel: float = rating - average_rating
		var wear: float = float(car.get("wear", 0.0))
		diagnostic.text = "CARRO %d • %s\nBase: %.0f  |  Grid: %.1f (%+.1f)\nPneu %s • desgaste %.0f%%\nRitmo %s • melhor volta %s" % [i + 1, str(car.get("name", "Piloto")), rating, average_rating, rel, str(car.get("tire", "Médio")), wear, str(car.get("pace", "Normal")), host._format_lap(float(car.get("best_lap", 9999.0)))]


static func _refresh_telemetry_panel(host) -> void:
	if host.race == null or host.race.telemetry == null or host.telemetry_summary_label == null:
		return
	var ledger = host.race.telemetry
	var counts: Dictionary = ledger.summary()
	host.telemetry_summary_label.text = "Voltas: %d • Setores: %d\nPosições: %d • Clima: %d amostras\nEventos: %d • Boxes: %d • Amostragem: %.0fs" % [int(counts["laps"]), int(counts["sectors"]), int(counts["position_samples"]), int(counts["weather_samples"]), int(counts["events"]), int(counts["pits"]), 10.0]
	var owned: Array = host.race.player_cars()
	for index in range(mini(host.telemetry_player_labels.size(), owned.size())):
		var driver: Dictionary = owned[index]
		var logs: Array = ledger.recent_laps(int(driver["id"]), 3)
		var summary_lines: Array[String] = []
		for lap_record in logs:
			summary_lines.append("V%d %s | S1 %s • S2 %s • S3 %s%s" % [int(lap_record["lap"]), host._format_lap(float(lap_record["seconds"])), host._format_lap(float(lap_record["s1"])), host._format_lap(float(lap_record["s2"])), host._format_lap(float(lap_record["s3"])), " • BOX" if bool(lap_record["pit_on_lap"]) else ""])
		var recent: String = "Sem volta completa registrada." if summary_lines.is_empty() else "\n".join(summary_lines)
		host.telemetry_player_labels[index].text = "%s • P%d • %s (%d%% desgaste)\n%s" % [str(driver["name"]), int(driver["position"]), str(driver["tire"]), int(round(float(driver["wear"]))), recent]


static func _export_telemetry(host) -> void:
	if host.race == null or host.race.telemetry == null or host.telemetry_export_label == null:
		return
	var folder: String = OS.get_user_data_dir().path_join("telemetria")
	var result: Dictionary = host.race.telemetry.export_files(folder, {"team": host.selected_team, "race_clock": host.race.clock, "finished": host.race.finished})
	if bool(result.get("ok", false)):
		var counts: Dictionary = result["counts"]
		host.telemetry_export_label.text = "Exportação concluída: %d arquivos em\n%s\n%d voltas e %d eventos registrados." % [result["files"].size(), str(result["folder"]), int(counts["laps"]), int(counts["events"])]
	else:
		host.telemetry_export_label.text = "Erro: %s" % str(result.get("error", "falha desconhecida"))

