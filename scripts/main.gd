extends Node2D

const RaceViewSnapshot = preload("res://scripts/race_view_snapshot_0658.gd")
var presentation := RaceViewSnapshot.new()
var presentation_race: RefCounted
var presented_3d_revision: int = -1
var presented_3d_focus: int = -2
var presented_3d_active: bool = false
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
## Apex Motorsport Manager — Godot 0.6.3.0
## Team control: manual or autonomous; 0.5.8.0 physics and camera preserved.
## Driver pit orders and quick controls stay on the lower driver cards.

const RaceScript = preload("res://scripts/race_engine.gd")
const Tyres2012Script = preload("res://scripts/core/race_tyres_2012.gd")
const GarageScript = preload("res://scripts/garage.gd")
const MapScript = preload("res://scripts/track_map.gd")
const Track3DScript = preload("res://scripts/track_3d.gd")
const DirectorScript = preload("res://scripts/tv_director.gd")
const AnalyticsChartScript = preload("res://scripts/pit_analytics_chart.gd")
const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")
const MiniMapScript = preload("res://scripts/apex_mini_map.gd")
const PortraitScript = preload("res://scripts/apex_portrait_manager.gd")
const CommentaryScript = preload("res://scripts/apex_commentary.gd")
const StrategyTimelineScript = preload("res://scripts/apex_stint_timeline.gd")
const TeamAutonomyScript = preload("res://scripts/core/race_team_autonomy.gd")
const ChampionshipScript = preload("res://scripts/championship_2012.gd")
const WeatherCore = preload("res://scripts/core/race_weather.gd")
const RaceHud0622 = preload("res://scripts/apex_race_hud_0622.gd")
const SessionSettings = preload("res://scripts/apex_session_settings.gd")
const ChampionshipFlow = preload("res://scripts/apex_championship_flow.gd")
const GaragePresentation = preload("res://scripts/apex_garage_presentation.gd")
const RaceFormatting = preload("res://scripts/apex_race_formatting.gd")
const RaceCommands = preload("res://scripts/apex_race_commands.gd")
const RaceViewController = preload("res://scripts/apex_race_view_controller.gd")
const TelemetryReports = preload("res://scripts/apex_telemetry_reports.gd")
const PitReports = preload("res://scripts/apex_pit_reports.gd")
const MenuScreen = preload("res://scripts/apex_menu_screen.gd")
const GarageScreen = preload("res://scripts/apex_garage_screen.gd")
const StaffScreen = preload("res://scripts/apex_staff_screen_0648.gd")
const PreRaceStrategy06495 = preload("res://scripts/apex_pre_race_screen_06495.gd")
const RaceSessionController = preload("res://scripts/apex_race_session_controller.gd")
const RadioFeed = preload("res://scripts/apex_radio_feed.gd")
const RaceUiLegacyBuilder = preload("res://scripts/apex_race_ui_legacy_builder.gd")
const RaceUiLayout = preload("res://scripts/apex_race_ui_layout.gd")
const RaceUiPresenter = preload("res://scripts/apex_race_ui_presenter.gd")
const RaceUiLegacyCards = preload("res://scripts/apex_race_ui_legacy_cards.gd")

const BLUE := Color("#091423")
const GREEN := Color("#46dcc0")
const WHITE := Color("#e9f4fd")
const MUTED := Color("#9eb8c8")
const YELLOW := Color("#ffce76")
const TRANSPARENT_PANEL := Color(0.055, 0.091, 0.139, 0.88)
const TABLE_MODES := ["Para o líder", "Intervalo frente", "Intervalo atrás", "Pneus", "Melhor volta"]
const VISUAL_OPTIONS := ["Auto F1M", "Mapa estratégico", "Câmera 3D", "Aérea estratégica"]

var season_title := "2012"
var championship
var championship_mode := false
var championship_race_active := false
var championship_result_saved := false
var championship_status: Label
var championship_continue_button: Button
var championship_table_dialog: AcceptDialog
var championship_report_text: RichTextLabel
var championship_new_dialog: ConfirmationDialog
var teams: Array = []
var season_tracks: Array = []
var garage
var race
var director
var map_view
var world_container: SubViewportContainer
var world_viewport: SubViewport
var world_view
var cam: Camera2D
var ui_layer: CanvasLayer
var screen: Control
var menu_root: Control
var menu_hero: Control
var menu_scroll: ScrollContainer
var menu_actions: VBoxContainer
var game_root: Control
var garage_root: Control
var staff_root: Control
var pre_race_strategy_dialog: Window
var pre_race_strategy_status: Label
var pre_race_strategy_pending: Dictionary = {}
var staff_card: PanelContainer
var staff_market_buttons: Dictionary = {}
var staff_release_buttons: Dictionary = {}
var staff_roster_labels: Dictionary = {}
var staff_budget_label: Label
var staff_payroll_label: Label
var staff_notice: Label
var staff_history_label: Label
var staff_culture_summary: Label
var staff_factory_summary: Label
var staff_action_hint: Label
var staff_relations_label: Label
var staff_soul_action_buttons: Dictionary = {}
var staff_soul_profile_labels: Dictionary = {}
var staff_soul_voice_labels: Dictionary = {}
var staff_soul_meters: Dictionary = {}
var heading_label: Label
var header_label: Label
var status_label: Label
var info_label: Label
var money_label: Label
var garage_title: Label
var garage_notes: Label
var upgrade_buttons: Dictionary = {}
var crew_buttons: Dictionary = {}
var staff_buttons: Dictionary = {}
var staff_summary: Label
var garage_development_summary: Label
var garage_project_status: Label
var garage_project_buttons: Dictionary = {}
var garage_cancel_project: Button
var garage_rivals_summary: Label
var team_control_mode := "Manual"
var pre_race_team_mode_picker: OptionButton
var live_team_mode_picker: OptionButton
var autonomy_fingerprints: Dictionary = {}
# v0.6.4.0: per-car policy. Bulk MANUAL/AUTO still resets both drivers.
var engineer_driver_modes: Dictionary = {}
var crew_summary: Label
var selected_team := "Ferrari"
var team_picker: OptionButton
var track_picker: OptionButton
var seed_picker: SpinBox
var pit_test_picker: OptionButton
var tyre_briefing_label: Label
var start_button: Button
var main_rows: Array = []
var tabs: TabContainer
var strategy_area: VBoxContainer
var radio_log: RichTextLabel
var garage_readout: Label
var pit_status_label: Label
var pit_timer_label: Label
var analytics_summary_label: Label
var analytics_history_label: Label
var analytics_compare_label: Label
var analytics_advice_label: Label
var analytics_final_label: Label
var analytics_export_label: Label
var analytics_chart
var analytics_seen_count := -1
var analytics_final_rendered := false
var run_button: Button
var speed_picker: OptionButton
var mode_picker: OptionButton
var visual_picker: OptionButton
var director_preset: OptionButton
var tv_shot_picker: OptionButton
var tv_shot_override := "Automático"
var driver_picker: OptionButton
var hud_button: Button
var bottom_bar: PanelContainer
var left_panel: PanelContainer
var table_mode_label: Label
var right_panel: PanelContainer
var top_panel: PanelContainer
var camera_mode := "Diretor TV"
var replay_session
var replay_ui
var sim_speed := 1.0 # 066721: start in real-time; 5x is an explicit choice
# Diagnostic only: rolling actual simulated seconds / wall-clock seconds.
var effective_speed_x: float = 0.0
var effective_speed_elapsed: float = 0.0
var effective_speed_ticks: int = 0
var manual_driver := -1
var focused_id := -1
var target_zoom := 1.25
var camera_zoom_multiplier := 1.0 # 0.6.2.6: zoom chosen during tracking persists
var next_ui := 0.0
var next_tv := 0.0
var dragging := false
var show_panels := true
var last_radio_count := 0
var visual_setting := 0 # 0 auto, 1 strategic, 2 close
var render_mode := 0
var table_mode := 0
var selected_track_index := 11
# New HUD layer; the race engine remains an independent module.
var hud_layout_mode: int = 2 # 0 Auto, 1 Completa, 2 Compacta, 3 Cinema; hotfix starts compact
var hud_layout_picker: OptionButton
var card_fold_preferences: Dictionary = {} # slot -> collapsed; no preference follows auto sizing
var cards_toggle_button: Button
var broadcast_speed_label: Label
var broadcast_camera_label: Label
var broadcast_zoom_minus: Button
var broadcast_zoom_plus: Button
var broadcast_center: Button
var broadcast_tv: Button
var broadcast_analytics: Button
var broadcast_driver_label: Label
var broadcast_hint_visible := true
var left_toggle_button: Button
var right_toggle_button: Button
var left_panel_enabled := true
var right_panel_enabled := true
var race_progress: ProgressBar
var live_event_label: Label
var telemetry_panel: PanelContainer
var telemetry_name: Label
var telemetry_subtitle: Label
var telemetry_stats: Label
var telemetry_tire: Label
var telemetry_wear: ProgressBar
var telemetry_pit: Label
var telemetry_camera: Label
var player_card_strip: Control
var player_cards: Array = []
var mini_map
var tactical_map_panel: PanelContainer
var tactical_mini_map
var tactical_map_caption: Label
var tactical_map_button: Button
var context_toggle_button: Button
var map_overlay_enabled: bool = false
var context_enabled: bool = false
var weather_briefing_label: Label
var weather_mode_picker: OptionButton
var weather_label: Label
var weather_header: Label
var portrait_manager
var portrait_status_label: Label
var portrait_download_button: Button
var portrait_download_all_button: Button
var top_shortcuts: HBoxContainer
var position_header: Label
var pit_wall_header: Label
var table_scroll: ScrollContainer
var table_legend: Label
var hud_hint: Label
var commentary
var telemetry_summary_label: Label
var telemetry_player_labels: Array[Label] = []
var telemetry_export_label: Label
var radio_filter: int = 0
var radio_filter_buttons: Array[Button] = []
var diagnostic_primary: Label
var diagnostic_secondary: Label
var strategy_primary: Label
var strategy_secondary: Label
var strategy_stints: Control
var map_panel_in_pitwall: VBoxContainer
var pitwall_mode := 2
var pitwall_focus_driver := -1
var pitwall_mode_buttons: Array = []
var pitwall_summary_panel: PanelContainer
var pitwall_summary_title: Label
var pitwall_summary_body: Label
var race_hud_0620

func _ready() -> void:
	var preview := get_node_or_null("EditorPreview")
	if preview != null:
		preview.hide()
	get_window().title = "APEX Motorsport Manager — v0.6.6.8.8 / Core 2 Racecraft 2.0 • Replay F9"
	_load_season_data()
	_load_hud_prefs()
	garage = GarageScript.new()
	championship = ChampionshipScript.new()
	_reconcile_championship_rewards()
	portrait_manager = PortraitScript.new()
	add_child(portrait_manager)
	portrait_manager.status_changed.connect(_on_portrait_status)
	portrait_manager.portraits_finished.connect(_on_portrait_finished)
	commentary = CommentaryScript.new()
	director = DirectorScript.new()
	map_view = MapScript.new()
	add_child(map_view)
	cam = Camera2D.new()
	cam.position = Vector2(520, 430)
	cam.zoom = Vector2(1.25, 1.25)
	cam.enabled = true
	add_child(cam)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	screen = Control.new()
	screen.theme = HudThemeScript.build()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(screen)
	_build_menu()
	_build_game_ui()
	_build_garage()
	StaffScreen._build_staff(self)
	if championship.has_season() and not championship.is_complete():
		_resume_championship()
	_show_menu()
	get_viewport().size_changed.connect(_layout_ui)

func _load_season_data() -> void:
	SessionSettings._load_season_data(self)

func _load_hud_prefs() -> void:
	SessionSettings._load_hud_prefs(self)

func _save_hud_prefs() -> void:
	SessionSettings._save_hud_prefs(self)

func _effective_hud_layout() -> int:
	return SessionSettings._effective_hud_layout(self)

func _card_folded(slot: int) -> bool:
	return SessionSettings._card_folded(self, slot)

func _toggle_driver_card(slot: int) -> void:
	SessionSettings._toggle_driver_card(self, slot)

func _toggle_all_driver_cards() -> void:
	SessionSettings._toggle_all_driver_cards(self)

func _style_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color("#2a4356")
	box.border_width_bottom = 1
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.corner_radius_top_left = 12
	box.corner_radius_top_right = 12
	box.corner_radius_bottom_left = 12
	box.corner_radius_bottom_right = 12
	box.content_margin_left = 11
	box.content_margin_right = 11
	box.content_margin_top = 9
	box.content_margin_bottom = 9
	return box

func _panel(parent: Control, bg: Color = TRANSPARENT_PANEL) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(bg))
	parent.add_child(panel)
	return panel

func _vbox(parent: Node, separation: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	parent.add_child(v)
	return v

func _label(parent: Node, message: String, size_px: int = 15, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = message
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _button(parent: Node, caption: String, action: Callable, min_width: int = 0) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(min_width, 38)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _option(parent: Node, choices: Array, on_selected: Callable) -> OptionButton:
	var o := OptionButton.new()
	for choice in choices:
		o.add_item(str(choice))
	o.custom_minimum_size = Vector2(130, 34)
	o.item_selected.connect(on_selected)
	parent.add_child(o)
	return o

func _full_cover() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(c)
	return c

func _build_menu() -> void:
	MenuScreen._build_menu(self)

func _download_team_portraits() -> void:
	var names: Array[String] = []
	for team in teams:
		if str(team.get("name", "")) == selected_team:
			for driver in team.get("drivers", []):
				names.append(str(driver.get("name", "")))
			break
	if not names.is_empty():
		portrait_download_button.disabled = true
		portrait_download_all_button.disabled = true
		portrait_manager.download_for_team(names)

func _download_all_portraits() -> void:
	var names: Array[String] = []
	for team in teams:
		for driver in team.get("drivers", []):
			names.append(str(driver.get("name", "")))
	portrait_download_button.disabled = true
	portrait_download_all_button.disabled = true
	portrait_manager.download_for_team(names)

func _on_portrait_status(message: String) -> void:
	if portrait_status_label != null:
		portrait_status_label.text = message

func _on_portrait_finished() -> void:
	if portrait_download_button != null:
		portrait_download_button.disabled = false
	if portrait_download_all_button != null:
		portrait_download_all_button.disabled = false
	if race != null and game_root != null and game_root.visible:
		_rebuild_player_cards()
		_layout_ui()
		_update_game_ui()

func _on_team_selected(index: int) -> void:
	if championship_mode:
		return
	if index >= 0 and index < teams.size():
		selected_team = str(teams[index]["name"])

func _on_track_selected(index: int) -> void:
	if championship_mode:
		return
	selected_track_index = clampi(index, 0, maxi(0, season_tracks.size() - 1))
	_update_tyre_briefing()
	_update_weather_briefing()

func _update_tyre_briefing() -> void:
	if tyre_briefing_label == null or season_tracks.is_empty():
		return
	var profile: Dictionary = Tyres2012Script.track_profile(Tyres2012Script.catalog(), str(season_tracks[selected_track_index].get("code", "BEL")))
	var options: Array = profile.get("dry", [])
	tyre_briefing_label.text = "2012 neste GP: %s / %s • exigência de pneus %.0f%% (estimada)" % [str(options[0]), str(options[1]), float(profile.get("severity", 1.0)) * 100.0]

func _update_weather_briefing() -> void:
	if weather_briefing_label == null or season_tracks.is_empty():
		return
	var track_data: Dictionary = season_tracks[selected_track_index]
	var climate: Dictionary = WeatherCore.climate_profile(str(track_data.get("code", "")))
	weather_briefing_label.text = "CLIMA DE %s: risco-base %.0f%% de chuva na prova (estimativa de jogo, não estatística histórica)." % [str(track_data.get("country", "GP")).to_upper(), float(climate["chance"]) * 100.0]

func _build_garage() -> void:
	GarageScreen._build_garage(self)

func _open_garage() -> void:
	if replay_ui != null and replay_session != null and replay_session.playback: replay_ui.leave()
	garage.inventory_observe(race, true)
	menu_root.hide()
	garage_root.show()
	staff_root.hide()
	game_root.hide()
	_update_garage()

func _open_staff() -> void:
	if replay_ui != null and replay_session != null and replay_session.playback: replay_ui.leave()
	menu_root.hide()
	garage_root.hide()
	game_root.hide()
	staff_root.show()
	staff_notice.text = "Selecione um profissional ou uma ação de equipe."
	_refresh_staff()
	_layout_ui()

func _refresh_staff() -> void:
	StaffScreen._refresh_staff(self)

func _hire_staff_candidate(role: String, candidate_id: String) -> void:
	var season_serial: int = 0
	var current_round: int = -1
	if championship_mode and championship.has_season():
		season_serial = int(championship.state.get("serial", 0))
		current_round = int(championship.state.get("round_index", -1))
	staff_notice.text = garage.staff_hire_candidate(selected_team, role, candidate_id,
		season_serial, current_round)
	_refresh_staff()
	_update_garage()

func _staff_soul_action(action_id: String) -> void:
	var serial: int = 0
	var next_round: int = 0
	var total_rounds: int = 0
	if championship_mode and championship.has_season() and not championship.is_complete():
		serial = int(championship.state.get("serial", 0))
		next_round = int(championship.state.get("round_index", 0)) + 1
		total_rounds = (championship.state.get("calendar", []) as Array).size()
	staff_notice.text = garage.staff_soul_action(selected_team, action_id,
		serial, next_round, total_rounds)
	_refresh_staff()
	_update_garage()

func _release_staff_candidate(role: String) -> void:
	staff_notice.text = garage.staff_release(selected_team, role)
	_refresh_staff()
	_update_garage()

func _start_garage_research(part: String) -> void:
	if not championship_mode or not championship.has_season() or championship.is_complete():
		garage_notes.text = "Crie/retome uma temporada para desenvolver projetos de P&D."
		return
	garage_notes.text = garage.start_research(selected_team, part,
		int(championship.state.get("serial", 0)), int(championship.state.get("round_index", 0)),
		(championship.state.get("calendar", []) as Array).size())
	_update_garage()

func _cancel_garage_research() -> void:
	garage_notes.text = garage.cancel_research(selected_team)
	_update_garage()

func _buy_part(part: String) -> void:
	garage_notes.text = garage.buy(selected_team, part)
	_update_garage()

func _buy_crew(part: String) -> void:
	garage_notes.text = garage.buy_crew(selected_team, part)
	_update_garage()

func _hire_staff(role: String) -> void:
	garage_notes.text = garage.hire_staff(selected_team, role)
	_update_garage()

func _update_garage() -> void:
	GaragePresentation._update_garage(self)

func _build_game_ui() -> void:
	RaceUiLegacyBuilder._build_game_ui(self)

func _layout_ui() -> void:
	RaceUiLayout._layout_ui(self)

func _apply_hud_visibility() -> void:
	RaceUiLayout._apply_hud_visibility(self)

func _change_hud_layout(index: int) -> void:
	RaceUiLayout._change_hud_layout(self, index)

func _toggle_left_panel() -> void:
	RaceUiLayout._toggle_left_panel(self)

func _toggle_right_panel() -> void:
	RaceUiLayout._toggle_right_panel(self)

func _toggle_context_panel() -> void:
	RaceUiLayout._toggle_context_panel(self)

func _toggle_tactical_map() -> void:
	RaceUiLayout._toggle_tactical_map(self)

func _switch_to_strategic_map() -> void:
	visual_setting = 1
	if visual_picker != null:
		visual_picker.select(1)
	_apply_visual_from_setting()
	_layout_ui()

func _quick_tv() -> void:
	mode_picker.select(2)
	_change_camera_mode(2)
	if race != null and manual_driver >= 0:
		director.override_focus(manual_driver, race.clock)

func _show_menu() -> void:
	if replay_ui != null and replay_session != null and replay_session.playback:
		replay_ui.leave()
	garage.inventory_observe(race, true)
	if race != null:
		race.running = false
	_update_championship_menu()
	menu_root.show()
	var front = menu_root.get_node_or_null("FrontDoor")
	if front != null:
		front.show_home()
	game_root.hide()
	garage_root.hide()
	staff_root.hide()
	cam.position = Vector2(520, 430)
	cam.zoom = Vector2(1.25, 1.25)
	target_zoom = 1.25
	_layout_ui()

func _ask_new_championship() -> void:
	ChampionshipFlow._ask_new_championship(self)

func _new_championship() -> void:
	ChampionshipFlow._new_championship(self)

func _resume_championship() -> void:
	ChampionshipFlow._resume_championship(self)

func _single_race_mode() -> void:
	ChampionshipFlow._single_race_mode(self)

func _update_championship_menu() -> void:
	ChampionshipFlow._update_championship_menu(self)

func _show_championship_table() -> void:
	ChampionshipFlow._show_championship_table(self)

func _reconcile_championship_rewards() -> void:
	ChampionshipFlow._reconcile_championship_rewards(self)

func _commit_championship_result() -> void:
	ChampionshipFlow._commit_championship_result(self)

func _select_pre_race_team_mode(index: int) -> void:
	RaceCommands._select_pre_race_team_mode(self, index)

func _select_live_team_mode(index: int) -> void:
	RaceCommands._select_live_team_mode(self, index)

func _apply_team_control(mode: String) -> void:
	RaceCommands._apply_team_control(self, mode)

func _autonomy_tick() -> void:
	var perf_started := Perf.begin() if Perf.enabled else 0
	RaceCommands._autonomy_tick(self)
	if Perf.enabled: Perf.end(&"ai.team_autonomy",perf_started)

func _engineer_mode_for(car_id: int) -> String:
	return RaceCommands.engineer_mode_for(self, car_id)

func _set_engineer_driver_mode(car_id: int, mode: String) -> void:
	RaceCommands.set_engineer_driver_mode(self, car_id, mode)

func _open_pre_race_strategy() -> void:
	PreRaceStrategy06495.show(self)

func _start_race() -> void:
	RaceSessionController._start_race(self)

func _rebuild_player_cards() -> void:
	RaceUiLegacyCards._rebuild_player_cards(self)

func _create_player_card(car: Dictionary, slot: int) -> Dictionary:
	return RaceUiLegacyCards._create_player_card(self, car, slot)

func _driver_initials(full_name: String) -> String:
	return RaceUiLegacyCards._driver_initials(self, full_name)

func _focus_driver(car_id: int) -> void:
	RaceUiLegacyCards._focus_driver(self, car_id)

func _refresh_player_cards() -> void:
	RaceUiLegacyCards._refresh_player_cards(self)

func _cycle_kers_mode(car_id: int) -> void:
	RaceUiLegacyCards._cycle_kers_mode(self, car_id)

func _open_driver_strategy(car_id: int) -> void:
	RaceUiLegacyCards._open_driver_strategy(self, car_id)

func _set_pitwall_mode(index: int) -> void:
	RaceUiPresenter._set_pitwall_mode(self, index)

func _pitwall_focus_car() -> Dictionary:
	if race == null:
		return {}
	if pitwall_focus_driver >= 0:
		var chosen := _car_by_id(pitwall_focus_driver)
		if not chosen.is_empty():
			return chosen
	var players: Array = race.player_cars()
	if not players.is_empty():
		return players[0]
	return {}

func _refresh_strategy_blocks() -> void:
	RaceUiPresenter._refresh_strategy_blocks(self)

func _refresh_pitwall_summary() -> void:
	RaceUiPresenter._refresh_pitwall_summary(self)

func _change_pace(index: int, id: int) -> void:
	RaceCommands._change_pace(self, index, id)

func _request_pit(id: int, tire_select: OptionButton) -> void:
	RaceCommands._request_pit(self, id, tire_select)

func _change_pit_mode(index: int, car_id: int) -> void:
	RaceCommands._change_pit_mode(self, index, car_id)

func _schedule_pit(id: int, tire_select: OptionButton, lap_select: SpinBox) -> void:
	RaceCommands._schedule_pit(self, id, tire_select, lap_select)

func _cancel_scheduled_pit(id: int) -> void:
	RaceCommands._cancel_scheduled_pit(self, id)

func _toggle_race() -> void:
	RaceCommands._toggle_race(self)

func _change_speed(index: int) -> void:
	RaceViewController._change_speed(self, index)

func _change_visual_setting(index: int) -> void:
	RaceViewController._change_visual_setting(self, index)

func _apply_visual_from_setting() -> void:
	RaceViewController._apply_visual_from_setting(self)

func _frame_strategic_circuit() -> void:
	RaceViewController._frame_strategic_circuit(self)

func _change_camera_mode(index: int) -> void:
	RaceViewController._change_camera_mode(self, index)

func _change_director_preset(index: int) -> void:
	RaceViewController._change_director_preset(self, index)

func _change_tv_shot(index: int) -> void:
	RaceViewController._change_tv_shot(self, index)

func _nearest_rival(car_id: int) -> Variant:
	return RaceViewController._nearest_rival(self, car_id)

func _select_pilot_option(index: int) -> void:
	RaceViewController._select_pilot_option(self, index)

func _on_position_pressed(row_index: int) -> void:
	RaceViewController._on_position_pressed(self, row_index)

func _cycle_info_mode() -> void:
	RaceUiPresenter._cycle_info_mode(self)

func _zoom_by(factor: float) -> void:
	RaceViewController._zoom_by(self, factor)

func _reset_camera() -> void:
	RaceViewController._reset_camera(self)

func _toggle_hud() -> void:
	RaceUiLayout._toggle_hud(self)

func _car_by_id(car_id: int) -> Dictionary:
	if race == null:
		return {}
	for car in race.cars:
		if int(car["id"]) == car_id:
			return car
	return {}

func _end_to_menu() -> void:
	RaceSessionController._end_to_menu(self)

func _process(delta: float) -> void:
	if race == null or not game_root.visible:
		return
	var perf_frame := Perf.begin() if Perf.enabled else 0
	if Perf.enabled:
		Perf.add_sample(&"frame.input_delta",int(delta*1000000))
		Perf.count(&"race_frames")
	if race.running:
		var tick_before: int = replay_session.tick if replay_session != null and replay_session.race == race else 0
		if replay_session == null or replay_session.race != race:
			replay_session = preload("res://scripts/core/race_replay_0660.gd").new()
			replay_session.attach(race, engineer_driver_modes, garage.effective_staff_levels(selected_team))
		# In 10x+ Auto 2D, cap work on the UI thread to avoid the positive
		# feedback loop: slow frame -> more owed ticks -> even slower frame.
		# Every executed tick is still simulated and recorded in exact order.
		if sim_speed >= 10.0:
			replay_session.advance(delta, sim_speed, garage.inventory_observe, 12000, 6)
		else:
			replay_session.advance(delta, sim_speed, garage.inventory_observe)
		# 066724: inform the player about the *measured* acceleration,
		# not the speed multiplier selected in the menu.
		effective_speed_elapsed += maxf(0.0, delta)
		effective_speed_ticks += maxi(0, replay_session.tick - tick_before)
		if effective_speed_elapsed >= 0.75:
			effective_speed_x = float(effective_speed_ticks) * replay_session.STEP / effective_speed_elapsed
			effective_speed_ticks = 0
			effective_speed_elapsed = 0.0
		if race.finished:
			if replay_session.playback:
				race.running = false
			elif championship_race_active:
				_commit_championship_result()
			else:
				run_button.text = "🏁 FIM"
				run_button.disabled = true
	RaceViewController.update_tracking(self, delta)
	RaceViewController.update_free_navigation(self, delta)
	var perf_visual := Perf.begin() if Perf.enabled else 0
	if presentation_race != race:
		presentation_race = race
		presentation.reset()
		presented_3d_revision = -1
	# Render between two *real* simulation ticks. The sporting engine still uses
	# 0.20s fixed steps; a stable fractional tick keeps cars moving at 1x and 5x.
	# This is presentation-only and never feeds positions into RaceEngine/replay.
	var visual_phase: float = -1.0
	if replay_session != null and replay_session.race == race:
		visual_phase = clampf(replay_session.accumulator / replay_session.STEP, 0.0, 1.0)
	var draw_cars: Array = presentation.build(race.cars, selected_team, map_view, delta, race.running, visual_phase)
	if Perf.enabled: Perf.end(&"visual.build_states",perf_visual)
	var perf_maps := Perf.begin() if Perf.enabled else 0
	map_view.set_race_cars(draw_cars, focused_id)
	if race_hud_0620 != null:
		race_hud_0620.update_map(draw_cars, focused_id)
	if mini_map != null and next_ui <= 0.0:
		mini_map.set_cars(draw_cars, focused_id)
	if tactical_mini_map != null and next_ui <= 0.0:
		tactical_mini_map.set_cars(draw_cars, focused_id)
	if Perf.enabled: Perf.end(&"visual.maps",perf_maps)
	if render_mode == 1 and (race.running or not presented_3d_active or presented_3d_revision != presentation.revision or presented_3d_focus != focused_id):
		var perf_3d := Perf.begin() if Perf.enabled else 0
		world_view.set_race_cars(draw_cars, focused_id, delta if race.running else 0.0)
		if Perf.enabled: Perf.end(&"visual.world_3d",perf_3d)
		presented_3d_revision = presentation.revision
		presented_3d_focus = focused_id
	presented_3d_active = render_mode == 1
	next_ui -= delta
	if next_ui <= 0.0:
		_update_game_ui()
		# The track markers stay frame-rate; complex diagnostic panels do
		# not need 4 full recalculations/second in strategic 10x-32x mode.
		# Keep the usual responsive 4 Hz refresh at 1x-5x.
		next_ui = 0.50 if sim_speed >= 10.0 else 0.25
	if Perf.enabled: Perf.end(&"frame.main_cpu",perf_frame)

func _best_lap(order: Array) -> float:
	return RaceFormatting._best_lap(self, order)

func _format_lap(value: float) -> String:
	return RaceFormatting._format_lap(self, value)

func _icon_for_car(car: Dictionary, order: Array, index: int) -> String:
	return RaceFormatting._icon_for_car(self, car, order, index)

func _row_detail(order: Array, idx: int) -> String:
	return RaceFormatting._row_detail(self, order, idx)

func _compound_code(name: String) -> String:
	return RaceFormatting._compound_code(self, name)

func _tyre_color(compound: String) -> Color:
	return RaceFormatting._tyre_color(self, compound)

func _wear_color(wear: float) -> Color:
	return RaceFormatting._wear_color(self, wear)

func _update_telemetry(order: Array) -> void:
	RaceFormatting._update_telemetry(self, order)

func _update_game_ui() -> void:
	var perf_started := Perf.begin() if Perf.enabled else 0
	RaceUiPresenter._update_game_ui(self)
	if Perf.enabled: Perf.end(&"hud.update",perf_started)

func _set_radio_filter(index: int) -> void:
	RadioFeed._set_radio_filter(self, index)

func _render_commentary() -> void:
	RadioFeed._render_commentary(self)

func _focus_player_slot(slot: int) -> void:
	RaceUiLegacyCards._focus_player_slot(self, slot)

func _refresh_car_diagnostics() -> void:
	TelemetryReports._refresh_car_diagnostics(self)

func _open_telemetry_tab() -> void:
	if race == null:
		return
	hud_layout_mode = 0
	hud_layout_picker.select(0)
	show_panels = true
	right_panel_enabled = true
	_layout_ui()
	if tabs != null:
		tabs.current_tab = tabs.get_tab_count() - 1
	_refresh_telemetry_panel()

func _refresh_telemetry_panel() -> void:
	TelemetryReports._refresh_telemetry_panel(self)

func _export_telemetry() -> void:
	TelemetryReports._export_telemetry(self)

func _open_pit_analytics() -> void:
	hud_layout_mode = 0
	hud_layout_picker.select(0)
	show_panels = true
	right_panel_enabled = true
	_layout_ui()
	if tabs != null:
		tabs.current_tab = 4
	_refresh_pit_analytics()

func _refresh_pit_analytics() -> void:
	PitReports._refresh_pit_analytics(self)

func _crew_training_cost_spent() -> int:
	return PitReports._crew_training_cost_spent(self)

func _pit_engineer_recommendation(stats: Dictionary) -> String:
	return PitReports._pit_engineer_recommendation(self, stats)

func _export_pit_csv() -> void:
	PitReports._export_pit_csv(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		if replay_ui == null:
			replay_ui = preload("res://scripts/race_replay_panel_0660.gd").new()
			add_child(replay_ui)
			replay_ui.setup(self)
		replay_ui.open()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		_open_performance_profiler()
		get_viewport().set_input_as_handled()
		return
	RaceViewController._camera_mouse_input(self, event)

func _unhandled_input(event: InputEvent) -> void:
	RaceViewController._unhandled_input(self, event)


func _exit_tree() -> void:
	if garage != null:
		garage.inventory_observe(race, true)

var performance_panel: Window
func _open_performance_profiler() -> void:
	if not is_instance_valid(performance_panel):
		performance_panel = preload("res://scripts/debug/apex_perf_panel_0657.gd").new()
		add_child(performance_panel)
	performance_panel.open_panel(self)
