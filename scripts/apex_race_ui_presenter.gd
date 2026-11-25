extends RefCounted
## Apex 0.6.2.4: legacy UI responsibility extracted from main.gd.
## New 0.6.2.2 race HUD and physics are independent of this compatibility layer.

const GREEN := Color("#46dcc0")
const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")
const PitWallStrategy3 = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const MUTED := Color("#9eb8c8")
const TABLE_MODES := ["Para o líder", "Intervalo frente", "Intervalo atrás", "Pneus", "Melhor volta"]
const VISUAL_OPTIONS := ["Auto F1M", "Mapa estratégico", "Câmera 3D", "Aérea estratégica"]
const WHITE := Color("#e9f4fd")
const YELLOW := Color("#ffce76")
static func _update_game_ui(host) -> void:
	if host.race == null:
		return
	var clock: int = int(host.race.clock)
	var order: Array = host.race.get_sorted()
	host.header_label.text = "VOLTA %02d/%02d     %02d:%02d:%02d" % [host.race.lap, host.race.lap_count, int(clock / 3600), int(clock / 60) % 60, clock % 60]
	host.status_label.text = "FINALIZADA" if host.race.finished else ("● AO VIVO  %d×" % int(host.sim_speed) if host.race.running else "Ⅱ PAUSADA")
	if host.tactical_map_caption != null:
		host.tactical_map_caption.text = "MAPA 2D • VOLTA %02d/%02d" % [host.race.lap, host.race.lap_count]
	host.status_label.text += " • %s" % ("EQUIPE AUTO" if host.team_control_mode == "Automático" else "EQUIPE MANUAL")
	if host.replay_session != null and host.replay_session.playback:
		host.status_label.text = "REPLAY • tick %d/%d • F9 controles" % [host.replay_session.tick, host.replay_session.end_tick]
	host.status_label.add_theme_color_override("font_color", GREEN if host.race.running else YELLOW)
	if host.race_progress != null and not order.is_empty():
		host.race_progress.max_value = float(host.race.lap_count)
		host.race_progress.value = clampf(float(order[0].get("progress", 0.0)), 0.0, float(host.race.lap_count))
	if host.live_event_label != null and not host.race.events.is_empty():
		var recent: Dictionary = host.race.events[-1]
		host.live_event_label.text = "RÁDIO  |  %s" % str(recent.get("message", ""))
	# 06684: ReBroadcast replaces the old left/table and telemetry widgets.
	# Keep sporting/event updates below unchanged; skip rendering invisible controls.
	if host.left_panel != null and host.left_panel.is_visible_in_tree():
		var fastest: float = host._best_lap(order)
		for idx in range(host.main_rows.size()):
			var row: Dictionary = host.main_rows[idx]
			var is_visible: bool = idx < order.size()
			row["container"].visible = is_visible
			if not is_visible:
				continue
			var car: Dictionary = order[idx]
			var is_mine: bool = str(car["team"]) == host.selected_team
			var is_filmed: bool = int(car["id"]) == host.focused_id
			var is_selected: bool = int(car["id"]) == host.manual_driver
			var team_color: Color = Color.from_string(str(car.get("color", "#e8f5ff")), WHITE)
			row["pos"].text = "%02d" % (idx + 1)
			row["icon"].text = host._icon_for_car(car, order, idx)
			row["button"].text = str(car["name"])
			row["button"].add_theme_color_override("font_color", GREEN if is_mine else WHITE)
			row["color_bar"].color = team_color
			row["tire"].text = host._compound_code(str(car["tire"]))
			row["tire"].add_theme_color_override("font_color", host._tyre_color(str(car["tire"])))
			row["wear"].text = "%d%%" % int(round(float(car["wear"])))
			row["wear"].add_theme_color_override("font_color", host._wear_color(float(car["wear"])))
			row["pit"].text = str(int(car.get("stops", 0)))
			row["detail"].text = host._row_detail(order, idx)
			var is_fastest: bool = fastest < 9999.0 and absf(float(car.get("best_lap", 9999.0)) - fastest) < 0.001
			row["detail"].add_theme_color_override("font_color", Color("#d8a2ff") if is_fastest and host.table_mode == 4 else MUTED)
			# Recreate the row background only when its state changes.
			var row_style: int = 2 if is_selected else (1 if is_mine else (3 if is_filmed else 0))
			if int(row.get("style_id", -1)) != row_style:
				var bg: Color = Color(0.08, 0.13, 0.20, 0.68)
				var stroke: Color = Color("#263d50")
				if row_style == 1:
					bg = Color(0.09, 0.22, 0.22, 0.84)
					stroke = Color("#317a70")
				elif row_style == 2:
					bg = Color(0.11, 0.26, 0.29, 0.91)
					stroke = GREEN
				elif row_style == 3:
					bg = Color(0.17, 0.20, 0.30, 0.8)
					stroke = YELLOW
				row["container"].add_theme_stylebox_override("panel", HudThemeScript.panel(bg, 5, stroke, 3))
				row["style_id"] = row_style
		host._update_telemetry(order)
	if host.player_card_strip != null and host.player_card_strip.is_visible_in_tree():
		host._refresh_player_cards()
	if host.right_panel != null and host.right_panel.is_visible_in_tree():
		host._refresh_strategy_blocks()
	if host.telemetry_panel != null and host.telemetry_panel.is_visible_in_tree():
		host._refresh_car_diagnostics()
	if host.weather_label != null:
		var conditions_now: Dictionary = host.race.weather_snapshot()
		host.weather_header.text = "☀ CONDIÇÕES" if str(conditions_now["sky"]) == "Céu limpo" else "☁ CONDIÇÕES"
		host.weather_label.text = "Ar %.0f°C  Pista %.0f°C\n%s • Chuva %d%%\n%s • Água %d%%\nAderência %s • DRS %s\nBorracha %d%%" % [float(conditions_now["air_c"]), float(conditions_now["track_c"]), str(conditions_now["sky"]), int(round(float(conditions_now["rain_intensity"]) * 100.0)), str(conditions_now["track_state"]), int(conditions_now["wetness"]), str(conditions_now["grip"]), "liberado" if bool(conditions_now["drs_allowed"]) else "suspenso", int(conditions_now["rubber"])]
	var pitting_names: Array[String] = []
	for car in host.race.cars:
		if float(car["pit_left"]) > 0.0:
			var pit_stage: String = str(car.get("pit_stage", ""))
			if pit_stage == "queue":
				pitting_names.append("%s  NA FILA %.1fs" % [str(car["name"]), float(car.get("pit_wait", 0.0))])
			elif pit_stage == "repair":
				pitting_names.append("%s  FALHA +%.1fs" % [str(car["name"]), maxf(0.0, float(car.get("pit_service_delay", 0.0)) - float(car.get("pit_stage_elapsed", 0.0)))])
			elif pit_stage == "safety_hold":
				pitting_names.append("%s  SEGURANÇA +%.1fs" % [str(car["name"]), maxf(0.0, float(car.get("pit_release_delay", 0.0)) - float(car.get("pit_stage_elapsed", 0.0)))])
			else:
				pitting_names.append("%s  %.1fs" % [str(car["name"]), float(car["pit_left"])])
	if host.pit_status_label != null:
		var pit_short: String = ""
		for i in range(mini(2, pitting_names.size())):
			if i > 0:
				pit_short += ", "
			pit_short += pitting_names[i]
		host.pit_status_label.text = "PIT LANE: livre" if pitting_names.is_empty() else "BOX: " + pit_short
	if host.pit_timer_label != null:
		var chosen: Dictionary = {}
		var service_car: Dictionary = {}
		var queued_car: Dictionary = {}
		var last_done: Dictionary = {}
		for car in host.race.cars:
			if float(car.get("pit_last_service", -1.0)) > 0.0:
				last_done = car
			if float(car["pit_left"]) <= 0.0:
				continue
			var car_stage: String = str(car.get("pit_stage", ""))
			if chosen.is_empty() or str(car["team"]) == host.selected_team:
				chosen = car
			if str(car["team"]) == host.selected_team:
				if car_stage in ["service", "repair", "safety_hold"]:
					service_car = car
				elif car_stage == "queue":
					queued_car = car
		if not service_car.is_empty():
			chosen = service_car
		elif not queued_car.is_empty() and chosen.is_empty():
			chosen = queued_car
		if not chosen.is_empty():
			var elapsed: float = float(chosen.get("pit_service_elapsed", 0.0))
			var duration: float = float(chosen.get("pit_service_total", 0.0))
			var stage: String = str(chosen.get("pit_stage", "approach"))
			if stage == "queue":
				host.pit_timer_label.text = "DOUBLE STACK • %s NA FILA: +%.2fs" % [str(chosen["name"]), float(chosen.get("pit_wait", 0.0))]
			else:
				var stage_caption := "ENTRADA"
				if stage == "dock":
					stage_caption = "ALINHANDO"
				elif stage == "service":
					stage_caption = "4 PNEUS"
				elif stage == "repair":
					stage_caption = "FALHA MECÂNICA"
				elif stage == "safety_hold":
					stage_caption = "LIBERAÇÃO BLOQUEADA"
				elif stage == "exit":
					stage_caption = "SAÍDA"
				host.pit_timer_label.text = "BOX %s | %s %.2f / %.2f s" % [str(chosen["name"]), stage_caption, elapsed, duration]
				if stage == "repair":
					host.pit_timer_label.text += "\nPistola/porca: atraso extra +%.1fs" % float(chosen.get("pit_service_delay", 0.0))
				elif stage == "safety_hold":
					host.pit_timer_label.text += "\nSegurança: retenção extra +%.1fs" % float(chosen.get("pit_release_delay", 0.0))
				if not queued_car.is_empty() and int(queued_car["id"]) != int(chosen["id"]):
					host.pit_timer_label.text += "\nDOUBLE STACK: %s na fila +%.1fs" % [str(queued_car["name"]), float(queued_car.get("pit_wait", 0.0))]
		elif not last_done.is_empty():
			host.pit_timer_label.text = "ÚLTIMA TROCA: %s %.2fs | FILA +%.1fs | INCIDENTE +%.1fs" % [str(last_done["name"]), float(last_done["pit_last_service"]), float(last_done.get("pit_last_wait", 0.0)), float(last_done.get("pit_last_extra", 0.0))]
		else:
			host.pit_timer_label.text = "CRONÔMETRO BOX: aguardando parada"
	var state: Dictionary = host.garage.get_team(host.selected_team)
	var track: Dictionary = host.season_tracks[host.selected_track_index]
	host.garage_readout.text = "%s\n\nMotor N%d • Asa N%d • Chassi N%d\n\nEQUIPE BOXES\nAgilidade N%d • Precisão N%d • Coordenação N%d\nServiço estimado: -%.2fs • Dock -%.2fs\n\nSaldo: R$ %.2f milhões\n\n%s\n%d voltas • %.3f km por volta\nBase IA: ~%s" % [host.selected_team, state["levels"]["Motor"], state["levels"]["Asa"], state["levels"]["Chassi"], state["crew_levels"]["Agilidade"], state["crew_levels"]["Precisão"], state["crew_levels"]["Coordenação"], float(host.race.get_pit_crew_effects()["service_saving"]), float(host.race.get_pit_crew_effects()["dock_saving"]), float(state["budget"]) / 1000000.0, str(track["name"]), int(track["laps"]), float(track["lap_km"]), host._format_lap(float(track["base_lap"]))]
	host.commentary.radio_speed = float(host.sim_speed)
	if host.commentary.ingest(host.race, host.selected_team):
		host._render_commentary()
	host.info_label.text = "%s\n\nVisual: %s\nModo efetivo: %s\nÂngulo: %s\nTecla M alterna visual; mouse move a câmera em modo Livre." % [host.director.reason, VISUAL_OPTIONS[host.visual_setting], "Câmera 3D" if host.render_mode == 1 else "Mapa estratégico", str(host.director.camera_style) if host.tv_shot_override == "Automático" else host.tv_shot_override]
	if host.analytics_seen_count != host.race.pit_history.size() or (host.race.finished and not host.analytics_final_rendered):
		host._refresh_pit_analytics()
	# Legacy telemetry detail has no consumers while its panel is hidden.
	if host.telemetry_panel != null and host.telemetry_panel.is_visible_in_tree():
		host._refresh_telemetry_panel()
	if host.race_hud_0620 != null:
		host.race_hud_0620.refresh_hud()


static func _set_pitwall_mode(host, index: int) -> void:
	host.pitwall_mode = clampi(index, 0, 2)
	for i in range(host.pitwall_mode_buttons.size()):
		var button: Button = host.pitwall_mode_buttons[i]
		var active: bool = i == host.pitwall_mode
		button.text = ["CHUVA", "PNEUS", "ESTRATÉGIA"][i]
		button.add_theme_stylebox_override("normal", HudThemeScript.panel(Color("#16324a") if active else Color("#0d1824"), 7, GREEN if active else Color("#365270"), 4))
		button.add_theme_stylebox_override("hover", HudThemeScript.panel(Color("#1b3b57") if active else Color("#14293b"), 7, GREEN if active else Color("#4a6b84"), 4))
	host._refresh_pitwall_summary()


static func _refresh_strategy_blocks(host) -> void:
	if host.race == null:
		return
	var player_cars: Array = host.race.player_cars()
	for idx in range(mini(2, player_cars.size())):
		var car: Dictionary = player_cars[idx]
		var tyre: String = str(car.get("tire", "Médio"))
		var wear: float = float(car.get("wear", 0.0))
		var pit_order: String = "BOX CHAMADO (%s)" % str(car.get("pit_target", "Duro")) if bool(car.get("pit_request", false)) else "Sem pit agendado"
		if int(car.get("pit_scheduled_lap", 0)) > 0:
			pit_order = "BOX AGENDADO V%d (%s)" % [int(car["pit_scheduled_lap"]), str(car.get("pit_target", "Médio"))]
		if float(car.get("pit_left", 0.0)) > 0.0:
			pit_order = "Em atendimento"
		var label: Label = host.strategy_primary if idx == 0 else host.strategy_secondary
		var engineer: Dictionary = host.race.get_engineer_advice(int(car["id"]))
		var next_stop: String = str(engineer.get("message", "Aguardando dados"))
		label.text = "%s  P%d • %s %d%% • %d parada(s)\n%s\nENG: %s" % [str(car.get("name", "Piloto")), int(car.get("position", 0)), tyre, int(round(wear)), int(car.get("stops", 0)), pit_order, next_stop]
	if host.strategy_stints != null:
		host.strategy_stints.update_cars(player_cars, int(host.race.lap_count), host.race.pit_history)
	host._refresh_pitwall_summary()


static func _refresh_pitwall_summary(host) -> void:
	if host.pitwall_summary_title == null or host.race == null:
		return
	var focus: Dictionary = host._pitwall_focus_car()
	if focus.is_empty():
		host.pitwall_summary_title.text = "PAINEL RÁPIDO"
		host.pitwall_summary_body.text = "Aguardando dados da corrida."
		return
	var conditions_now: Dictionary = host.race.weather_snapshot()
	var tyre_name: String = str(focus.get("tire", "Médio"))
	var wear_value: float = float(focus.get("wear", 0.0))
	if host.pitwall_mode == 0:
		host.pitwall_summary_title.text = "CHUVA / CONDIÇÕES • %s" % str(host.track_picker.get_item_text(host.selected_track_index))
		host.pitwall_summary_body.text = "Previsão móvel (próx. 15 min): %d%%\nCéu: %s\nAr %.0f°C • Pista %.0f°C\nÁgua %d%% • Vento %.0f km/h\nAderência %s • Borracha %d%%\nClima ativo: ritmo, pneus, IA e DRS." % [int(conditions_now.get("rain_probability", 0)), str(conditions_now.get("sky", "Céu limpo")), float(conditions_now.get("air_c", 0.0)), float(conditions_now.get("track_c", 0.0)), int(conditions_now.get("wetness", 0)), float(conditions_now.get("wind", 0.0)), str(conditions_now.get("grip", "Normal")), int(conditions_now.get("rubber", 0))]
	elif host.pitwall_mode == 1:
		host.pitwall_summary_title.text = "PNEUS / DEGRADAÇÃO • %s" % str(focus.get("name", "Piloto"))
		var compound_info: Dictionary = host.race.tyre_spec(tyre_name)
		var to_cliff: float = maxf(0.0, float(compound_info.get("cliff", 70.0)) - wear_value)
		host.pitwall_summary_body.text = "Composto atual: %s (%s)\nDegradação: %d%%\nSuperfície %.1f°C • Carcaça %.1f°C\nGraining %d%% • Blister %d%%\nMargem até queda forte: %.0f pontos\nÚltima volta: %s\nMelhor volta: %s" % [tyre_name, host._compound_code(tyre_name), int(round(wear_value)), float(focus.get("tyre_surface_c", 0.0)), float(focus.get("tyre_core_c", 0.0)), int(round(100.0 * float(focus.get("tyre_graining", 0.0)))), int(round(100.0 * float(focus.get("tyre_blistering", 0.0)))), to_cliff, host._format_lap(float(focus.get("last_lap", 9999.0))), host._format_lap(float(focus.get("best_lap", 9999.0)))]
	else:
		host.pitwall_summary_title.text = "ESTRATÉGIA • %s" % str(focus.get("name", "Piloto"))
		var pit_state := "Nenhum pit solicitado"
		if bool(focus.get("pit_request", false)):
			pit_state = "Pit solicitado para %s" % str(focus.get("pit_target", "Médio"))
		elif int(focus.get("pit_scheduled_lap", 0)) > 0:
			pit_state = "Pit agendado V%d para %s" % [int(focus["pit_scheduled_lap"]), str(focus.get("pit_target", "Médio"))]
		elif float(focus.get("pit_left", 0.0)) > 0.0:
			pit_state = "Executando pit • %s" % str(focus.get("pit_stage", "service")).capitalize()
		var engineer: Dictionary = host.race.get_engineer_advice(int(focus["id"]))
		var gap_caption: String = str(focus.get("gap_label", "—")) if bool(host.race.finished) else "+%.1fs" % float(focus.get("gap", 0.0))
		host.pitwall_summary_body.text = "Posição P%d • Gap %s\nRitmo: %s • Paradas: %d\n%s\n\nENGENHEIRO: %s\nPrevisão de água em 3v: %d%% • 6v: %d%%\nVida até o limite: %.1f volta(s)" % [
			int(focus.get("position", 0)), gap_caption, str(focus.get("pace", "Normal")), int(focus.get("stops", 0)), pit_state,
			str(engineer.get("message", "Aguardando dados")), int(round(float(engineer.get("forecast_3", 0.0)) * 100.0)),
			int(round(float(engineer.get("forecast_6", 0.0)) * 100.0)), float(engineer.get("life_laps", 0.0))]
		# Pit Wall 3.0 adds tactical comparisons to the legacy compact panel.
		var partner: Dictionary = {}
		for other in host.race.player_cars():
			if int(other.get("id", -1)) != int(focus.get("id", -1)):
				partner = other
				break
		var tactical: Dictionary = PitWallStrategy3.assess(focus, partner, host.race.get_sorted(), engineer,
			conditions_now, host.race.available_pit_compounds(), int(host.race.lap_count),
			float(host.race.pit_loss), float(host.race.base_lap), int(host.race._next_pit_entry_lap(focus)))
		host.pitwall_summary_body.text += "\n\nPIT WALL 3.0: %s\nRetorno ~P%d · %s" % [
			str(tactical.get("plan", "")), int(tactical.get("now", {}).get("position", 0)),
			str(tactical.get("stack_note", ""))]


static func _cycle_info_mode(host) -> void:
	if host.race_hud_0620 != null and host.race_hud_0620.visible:
		host.race_hud_0620._move_metric(1)
	host.table_mode = (host.table_mode + 1) % TABLE_MODES.size()
	if is_instance_valid(host.table_mode_label):
		host.table_mode_label.text = "Modo da tabela: %s" % TABLE_MODES[host.table_mode]
	host._update_game_ui()

