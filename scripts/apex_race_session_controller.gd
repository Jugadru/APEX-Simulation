extends RefCounted
## APEX 0.6.2.3 — extracted responsibility; main.gd remains the scene host.
## The wrapper preserves legacy signals and callbacks.

const DirectorScript = preload("res://scripts/tv_director.gd")
const RaceScript = preload("res://scripts/race_engine.gd")
const StrategyStaff066910 = preload("res://scripts/core/race_strategy_staff_intelligence_066910.gd")
static func _start_race(host) -> void:
	if host.replay_ui != null: host.replay_ui.leave()
	host.replay_session = null
	# 066721: every new GP starts in 1x, regardless of last session speed.
	host._change_speed(0)
	host.garage.inventory_observe(host.race, true)
	var team_state: Dictionary = host.garage.get_team(host.selected_team)
	for task in team_state.workshop.tasks:
		if task.status == "em execução":
			host._open_garage()
			var hub = host.garage_root.get_node("ManagementHub")
			hub.show_page("factory")
			hub.workshop.show_tab("Fila de tarefas")
			hub.workshop.notice.text = "Conclua ou cancele os serviços em execução antes de enviar os carros à pista."
			return
	var inventory: Dictionary = team_state.component_inventory
	if not host.garage.Inventory.ready(inventory, host.garage.PARTS):
		host._open_garage()
		host.garage_root.get_node("ManagementHub").show_page("factory")
		return
	if host.championship_mode and host.championship.is_complete():
		return
	if host.championship_mode:
		host._resume_championship()
	var track: Dictionary = host.season_tracks[host.selected_track_index]
	# Guardrail: never launch a different circuit from the current season round.
	if host.championship_mode and str(track.get("code", "")) != str(host.championship.next_round().get("code", "")):
		push_error("APEX: circuito do GP diferente da etapa agendada; corrida não iniciada.")
		host.championship_status.text = "ERRO: circuito diferente do calendário. Clique em CONTINUAR para sincronizar."
		return
	host.championship_race_active = host.championship_mode
	host.championship_result_saved = false
	host.race = RaceScript.new(host.teams, host.selected_team, host.championship.round_seed() if host.championship_race_active else int(host.seed_picker.value), host.garage.get_team(host.selected_team)["levels"], track, host.garage.effective_crew_levels(host.selected_team))
	# Prediction Ledger keeps its historic observer-only staff levels.
	host.race.prediction_staff = host.garage.effective_staff_levels(host.selected_team).duplicate(true)
	# Independent, immutable race-session snapshot for staff decisions and replays.
	host.race.strategy_staff_profile = StrategyStaff066910.profile(team_state)
	host.garage.inventory_begin(host.selected_team, {"season": int(host.championship.state.get("serial", 0)), "round": int(host.championship.state.get("round_index", 0)) + 1, "mode": "championship" if host.championship_mode else "single"})
	if host.championship_race_active:
		host.race.set_championship_round(int(host.championship.state.get("round_index", 0)))
		host.race.set_rival_development(host.championship.get_rival_levels())
	if host.weather_mode_picker != null:
		host.race.configure_weather(host.weather_mode_picker.get_item_text(host.weather_mode_picker.selected))
	# Only the explicit demo option forces failures. Ordinary races use low,
	# seeded incident probabilities defined in race_engine.gd.
	if host.pit_test_picker != null and host.pit_test_picker.selected > 0:
		var player: Dictionary = host.race.player_cars()[0]
		var demo: Dictionary = {"service_fault": "", "service_delay": 0.0, "release_delay": 0.0}
		if host.pit_test_picker.selected == 1 or host.pit_test_picker.selected == 3:
			demo["service_fault"] = "Porca travada"
			demo["service_delay"] = 4.0
		if host.pit_test_picker.selected == 2 or host.pit_test_picker.selected == 3:
			demo["release_delay"] = 4.5
		host.race.pit_incident_test_overrides[int(player["id"])] = demo
	host.director = DirectorScript.new()
	# Each GP opens with a live race-oriented camera, even if the previous
	# session ended in free-pan. Free mode remains available during the GP.
	host.camera_mode = "Diretor TV"
	if host.mode_picker != null:
		host.mode_picker.select(2)
	host.tv_shot_override = "Automático"
	host.camera_zoom_multiplier = 1.0
	host.director.mode = host.camera_mode
	host.next_ui = 0.0
	host.next_tv = 0.0
	host.focused_id = -1
	host.manual_driver = int(host.race.player_cars()[0]["id"])
	# Prevent policy from the previous Grand Prix leaking into this session.
	host.engineer_driver_modes.clear()
	host._apply_team_control(host.team_control_mode)
	# Explicitly approved first-stop plan only. Auto mode remains fully autonomous.
	host.PreRaceStrategy06495.apply_pending(host)
	host.pitwall_focus_driver = host.manual_driver
	host.last_radio_count = 0
	host.analytics_seen_count = -1
	host.analytics_final_rendered = false
	if host.analytics_export_label != null:
		host.analytics_export_label.text = "Exportação disponível após uma parada."
	if host.telemetry_export_label != null:
		host.telemetry_export_label.text = "Exportação disponível a partir do grid. Arquivos salvos na pasta de dados do Apex."
	host.run_button.disabled = false
	host.run_button.text = "▶ INICIAR"
	if host.pre_race_strategy_dialog != null and is_instance_valid(host.pre_race_strategy_dialog):
		host.pre_race_strategy_dialog.hide()
	host.menu_root.hide()
	host.garage_root.hide()
	host.staff_root.hide()
	host.game_root.show()
	host.commentary.reset(int(host.seed_picker.value))
	host.commentary.ingest(host.race, host.selected_team)
	host._render_commentary()
	host._rebuild_player_cards()
	host.driver_picker.clear()
	host.driver_picker.add_item("Líder")
	for driver in host.race.get_sorted():
		host.driver_picker.add_item(str(driver["name"]))
	host.map_view.set_track_data(track)
	host.mini_map.set_track(host.map_view.route)
	if host.tactical_mini_map != null:
		host.tactical_mini_map.set_track(host.map_view.route)
	host.world_view.set_track_data(host.map_view.route, str(track["name"]), host.teams,
		host.map_view.point_on_track(RaceScript.PIT_ENTRY_FRACTION),
		host.map_view.direction_on_track(RaceScript.PIT_ENTRY_FRACTION),
		host.map_view.point_on_track(RaceScript.PIT_EXIT_FRACTION),
		host.map_view.direction_on_track(RaceScript.PIT_EXIT_FRACTION))
	# Auto starts in 3D at 1x and switches to cached 2D at 10x+.
	# Changing view manually afterwards has priority over automatic changes.
	host.visual_setting = 0
	host.visual_picker.select(0)
	host._apply_visual_from_setting()
	if host.race_hud_0620 != null:
		host.race_hud_0620.begin_race()
	host.heading_label.text = "TEMPORADA %s  /  %s  /  %s" % [host.season_title, str(track["country"]), str(track["name"])]
	if host.championship_race_active:
		host.heading_label.text += "  •  CAMPEONATO ETAPA %d/20" % (int(host.championship.state["round_index"]) + 1)
	host.heading_label.text += "  •  CORE 2 / CLIMA + KERS + DRS 2012"
	if str(track.get("geometry_quality", "")) == "schematic_not_historical":
		host.heading_label.text += " | TRAÇADO PROVISÓRIO"
	host.cam.position = Vector2(520, 430)
	host.cam.zoom = Vector2(1.25, 1.25)
	host.target_zoom = 1.25
	host.pit_wall_header.text = "PIT WALL / ESTRATÉGIA  /  %s" % host.selected_team.to_upper()
	host.race_progress.max_value = float(host.race.lap_count)
	host.replay_session = preload("res://scripts/core/race_replay_0660.gd").new()
	host.replay_session.attach(host.race, host.engineer_driver_modes, host.garage.effective_staff_levels(host.selected_team))
	host._update_game_ui()
	host._layout_ui()


static func _end_to_menu(host) -> void:
	if host.race != null:
		host.race.running = false
	host._show_menu()

