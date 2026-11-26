extends RefCounted
## Apex 0.6.2.4: legacy UI responsibility extracted from main.gd.
## New 0.6.2.2 race HUD and physics are independent of this compatibility layer.

const AnalyticsChartScript = preload("res://scripts/pit_analytics_chart.gd")
const GREEN := Color("#46dcc0")
const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")
const MUTED := Color("#9eb8c8")
const MiniMapScript = preload("res://scripts/apex_mini_map.gd")
const RaceHud0622 = preload("res://scripts/apex_race_hud_0622.gd")
const StrategyTimelineScript = preload("res://scripts/apex_stint_timeline.gd")
const TABLE_MODES := ["Para o líder", "Intervalo frente", "Intervalo atrás", "Pneus", "Melhor volta"]
const Track3DScript = preload("res://scripts/track_3d.gd")
const VISUAL_OPTIONS := ["Auto F1M", "Mapa estratégico", "Câmera 3D", "Aérea estratégica"]
const WHITE := Color("#e9f4fd")
const YELLOW := Color("#ffce76")
static func _build_game_ui(host) -> void:
	host.game_root = host._full_cover()
	# The 3D world stays independent from Control nodes.
	host.world_container = SubViewportContainer.new()
	host.world_container.name = "Apex3DDisplay"
	host.world_container.stretch = true
	host.world_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.world_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.game_root.add_child(host.world_container)
	host.world_viewport = SubViewport.new()
	host.world_viewport.size = Vector2i(1920, 1080)
	host.world_viewport.own_world_3d = true
	# Explicit opt-in GPU profile; the existing visual default is unchanged.
	var economical_graphics: bool = OS.get_environment("APEX_GRAPHICS_PROFILE") == "gtx1650"
	host.world_viewport.msaa_3d = Viewport.MSAA_2X if economical_graphics else Viewport.MSAA_4X
	host.world_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	host.world_container.add_child(host.world_viewport)
	host.world_view = Track3DScript.new()
	host.world_viewport.add_child(host.world_view)
	host.world_container.hide()

	# TOP BAR — circuit / live session / accessible quick layout controls.
	host.top_panel = host._panel(host.game_root, Color(0.035, 0.073, 0.12, 0.96))
	var top_content = host._vbox(host.top_panel, 5)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_content.add_child(top_row)
	var brand = host._label(top_row, "APEX", 23, GREEN)
	brand.custom_minimum_size.x = 83
	var meta = host._vbox(top_row, 0)
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.heading_label = host._label(meta, "TEMPORADA 2012  /  GP DA BÉLGICA", 14, WHITE)
	host._label(meta, "APEX RACE CONTROL  •  HUD LEGADA OCULTA / V0.6.2.0", 11, MUTED)
	host.top_shortcuts = HBoxContainer.new()
	host.top_shortcuts.add_theme_constant_override("separation", 4)
	top_row.add_child(host.top_shortcuts)
	host.left_toggle_button = host._button(host.top_shortcuts, "POS", host._toggle_left_panel, 48)
	host.right_toggle_button = host._button(host.top_shortcuts, "PIT", host._toggle_right_panel, 48)
	host.context_toggle_button = host._button(host.top_shortcuts, "PILOTO", host._toggle_context_panel, 67)
	host.tactical_map_button = host._button(host.top_shortcuts, "MAPA 2D", host._toggle_tactical_map, 78)
	host.cards_toggle_button = host._button(host.top_shortcuts, "CARDS", host._toggle_all_driver_cards, 70)
	host._button(host.top_shortcuts, "DADOS", host._open_pit_analytics, 68)
	host._button(host.top_shortcuts, "TELEM", host._open_telemetry_tab, 68)
	host.hud_layout_picker = host._option(host.top_shortcuts, ["Auto", "Completa", "Compacta", "Cinema"], host._change_hud_layout)
	host.hud_layout_picker.custom_minimum_size.x = 110
	host.hud_layout_picker.select(host.hud_layout_mode)
	host._label(host.top_shortcuts, "VISÃO", 11, MUTED)
	host.visual_picker = host._option(host.top_shortcuts, VISUAL_OPTIONS, host._change_visual_setting)
	host.visual_picker.custom_minimum_size.x = 130
	host.visual_picker.select(0)
	var top_progress_row := HBoxContainer.new()
	top_progress_row.add_theme_constant_override("separation", 12)
	top_content.add_child(top_progress_row)
	host.header_label = host._label(top_progress_row, "V00/44   •   00:00:00", 13, WHITE)
	host.header_label.custom_minimum_size.x = 205
	host.race_progress = ProgressBar.new()
	host.race_progress.show_percentage = false
	host.race_progress.min_value = 0
	host.race_progress.max_value = 44
	host.race_progress.value = 0
	host.race_progress.custom_minimum_size.y = 9
	host.race_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_progress_row.add_child(host.race_progress)
	host.status_label = host._label(top_progress_row, "PARADO", 13, YELLOW)
	host.status_label.custom_minimum_size.x = 104
	host.status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	host.live_event_label = host._label(top_content, "RÁDIO DA PROVA  •  GRID FORMADO", 12, MUTED)
	host.live_event_label.clip_text = true

	# LEFT PANEL — names, tyre compound, wear, stops and cycling timing mode.
	host.left_panel = host._panel(host.game_root, Color(0.035, 0.071, 0.112, 0.90))
	var left_content = host._vbox(host.left_panel, 7)
	var left_header := HBoxContainer.new()
	left_content.add_child(left_header)
	host.position_header = host._label(left_header, "CLASSIFICAÇÃO", 16, GREEN)
	host.position_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cycle_button = host._button(left_header, "⇆", host._cycle_info_mode, 40)
	cycle_button.tooltip_text = "Alternar a coluna de dados (tecla I)"
	host.table_mode_label = host._label(left_content, "DIFERENÇA: %s" % TABLE_MODES[host.table_mode].to_upper(), 12, MUTED)
	host.table_mode_label.name = "TableModeLabel"
	host.table_legend = host._label(left_content, "P    PILOTO                               PNEU  DESG.  BOX     Δ", 11, MUTED)
	host.table_legend.clip_text = true
	host.table_scroll = ScrollContainer.new()
	host.table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.table_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_content.add_child(host.table_scroll)
	var entries := VBoxContainer.new()
	entries.add_theme_constant_override("separation", 3)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.table_scroll.add_child(entries)
	for i in range(24):
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 36
		row.add_theme_stylebox_override("panel", HudThemeScript.panel(Color(0.09, 0.15, 0.22, 0.65), 5, Color(0.13, 0.23, 0.31, 0.7), 3))
		entries.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		row.add_child(line)
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(4, 23)
		bar.color = Color.WHITE
		line.add_child(bar)
		var pos = host._label(line, "%02d" % (i + 1), 13, MUTED)
		pos.custom_minimum_size.x = 24
		var icon = host._label(line, "•", 13, YELLOW)
		icon.custom_minimum_size.x = 12
		var name_btn = host._button(line, "—", host._on_position_pressed.bind(i), 108)
		name_btn.custom_minimum_size.y = 27
		name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_btn.add_theme_font_size_override("font_size", 13)
		name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_btn.tooltip_text = "Clicar para seguir este piloto"
		var tire = host._label(line, "—", 13, YELLOW)
		tire.custom_minimum_size.x = 28
		var wear = host._label(line, "0%", 12, MUTED)
		wear.custom_minimum_size.x = 32
		wear.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var pit = host._label(line, "0", 12, MUTED)
		pit.custom_minimum_size.x = 16
		pit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var detail = host._label(line, "—", 12, MUTED)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.custom_minimum_size.x = 72
		host.main_rows.append({"container": row, "color_bar": bar, "pos": pos, "icon": icon, "button": name_btn, "tire": tire, "wear": wear, "pit": pit, "detail": detail})
	host._label(left_content, "★ Sua equipe  •  ▶ Câmera  •  ⌛ Fila  •  ⇆ Alternar dados", 10, MUTED)

	# RIGHT PANEL — existing strategy/analytics logic wrapped in legible sections.
	host.right_panel = host._panel(host.game_root, Color(0.035, 0.071, 0.112, 0.92))
	var right_content = host._vbox(host.right_panel, 7)
	host.pit_wall_header = host._label(right_content, "PIT WALL  /  %s" % host.selected_team.to_upper(), 15, GREEN)
	host.pit_wall_header.clip_text = true
	var insight_row := HBoxContainer.new()
	insight_row.add_theme_constant_override("separation", 6)
	right_content.add_child(insight_row)
	host.pitwall_mode_buttons.clear()
	for title in ["CHUVA", "PNEUS", "ESTRATÉGIA"]:
		var insight_btn = host._button(insight_row, title, host._set_pitwall_mode.bind(host.pitwall_mode_buttons.size()), 0)
		insight_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.pitwall_mode_buttons.append(insight_btn)
	host.pitwall_summary_panel = PanelContainer.new()
	host.pitwall_summary_panel.add_theme_stylebox_override("panel", HudThemeScript.panel(Color(0.05, 0.11, 0.18, 0.94), 8, Color("#365270"), 5))
	right_content.add_child(host.pitwall_summary_panel)
	var pitwall_summary_box = host._vbox(host.pitwall_summary_panel, 3)
	host.pitwall_summary_title = host._label(pitwall_summary_box, "ESTRATÉGIA", 12, GREEN)
	host.pitwall_summary_body = host._label(pitwall_summary_box, "Aguardando início da corrida.", 10, WHITE)
	host.pitwall_summary_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._set_pitwall_mode(host.pitwall_mode)

	host.tabs = TabContainer.new()
	host.tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_content.add_child(host.tabs)
	var strategy_tab := ScrollContainer.new()
	strategy_tab.name = "Estratégia"
	strategy_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.tabs.add_child(strategy_tab)
	host.strategy_area = host._vbox(strategy_tab, 8)
	host.strategy_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._label(host.strategy_area, "PLANO DA EQUIPE / 2012", 14, GREEN)
	var strategy_note = host._label(host.strategy_area, "Acompanhe as duas estratégias. As ordens de ritmo e pit stop estão nos cartões inferiores dos pilotos.", 10, MUTED)
	strategy_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.strategy_primary = host._label(host.strategy_area, "Carro 1: aguardando corrida", 12, WHITE)
	host.strategy_primary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.strategy_secondary = host._label(host.strategy_area, "Carro 2: aguardando corrida", 12, WHITE)
	host.strategy_secondary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.strategy_stints = StrategyTimelineScript.new()
	host.strategy_stints.custom_minimum_size = Vector2(180, 132)
	host.strategy_stints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.strategy_area.add_child(host.strategy_stints)
	var strategy_tip = host._label(host.strategy_area, "Cores = compostos já utilizados. Área escura = distância ainda não percorrida. Não há previsão automática de paradas nesta versão.", 10, MUTED)
	strategy_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var radio_tab := VBoxContainer.new()
	radio_tab.name = "Rádio"
	host.tabs.add_child(radio_tab)
	host._label(radio_tab, "APEX / TRANSMISSÃO DA CORRIDA", 13, GREEN)
	var radio_tools := HBoxContainer.new()
	radio_tools.add_theme_constant_override("separation", 4)
	radio_tab.add_child(radio_tools)
	host.radio_filter_buttons.clear()
	for choice in ["TODOS", "TRANSMISSÃO", "EQUIPE", "PILOTOS"]:
		var filter_btn = host._button(radio_tools, choice, host._set_radio_filter.bind(host.radio_filter_buttons.size()), 0)
		filter_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_btn.custom_minimum_size.y = 28
		host.radio_filter_buttons.append(filter_btn)
	host.radio_log = RichTextLabel.new()
	host.radio_log.bbcode_enabled = true
	host.radio_log.fit_content = false
	host.radio_log.scroll_following = true
	host.radio_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	radio_tab.add_child(host.radio_log)
	var cast_note = host._label(radio_tab, "Transmissão = narração da corrida | Equipe = comunicações internas | Pilotos = rádio dos seus pilotos.", 10, MUTED)
	cast_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._set_radio_filter(0)
	var garage_tab := ScrollContainer.new()
	garage_tab.name = "Carro"
	garage_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.tabs.add_child(garage_tab)
	var diagnostics = host._vbox(garage_tab, 8)
	diagnostics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._label(diagnostics, "DIAGNÓSTICO / CARROS", 14, GREEN)
	var diag_note = host._label(diagnostics, "Desenvolvimento e telemetria disponíveis no protótipo. Ainda não há sensores simulados de dano, combustível ou ERS.", 10, MUTED)
	diag_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.garage_readout = host._label(diagnostics, "", 12, MUTED)
	host.garage_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var diag1 = host._panel(diagnostics, Color(0.07, 0.14, 0.22, 0.91))
	host.diagnostic_primary = host._label(host._vbox(diag1, 4), "Carro 1", 12, WHITE)
	host.diagnostic_primary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var diag2 = host._panel(diagnostics, Color(0.07, 0.14, 0.22, 0.91))
	host.diagnostic_secondary = host._label(host._vbox(diag2, 4), "Carro 2", 12, WHITE)
	host.diagnostic_secondary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var focus_row := HBoxContainer.new()
	diagnostics.add_child(focus_row)
	var camera_one = host._button(focus_row, "CÂMERA CARRO 1", host._focus_player_slot.bind(0))
	camera_one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var camera_two = host._button(focus_row, "CÂMERA CARRO 2", host._focus_player_slot.bind(1))
	camera_two.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var director_tab := VBoxContainer.new()
	director_tab.name = "Diretor TV"
	host.tabs.add_child(director_tab)
	host._label(director_tab, "ESTILO DE TRANSMISSÃO", 11, MUTED)
	host.director_preset = host._option(director_tab, ["Ação", "Transmissão"], host._change_director_preset)
	host._label(director_tab, "ÂNGULO DE CÂMERA", 11, MUTED)
	host.tv_shot_picker = host._option(director_tab, ["Automático", "Traseira", "Lateral direita", "Lateral esquerda", "Aérea", "Batalha"], host._change_tv_shot)
	var director_hint = host._label(director_tab, "O Diretor TV escolhe os enquadramentos quando está no automático.", 11, MUTED)
	director_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.info_label = host._label(director_tab, "", 12, MUTED)
	host.info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var analytics_tab := ScrollContainer.new()
	analytics_tab.name = "Análises"
	analytics_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.tabs.add_child(analytics_tab)
	var analytics_content = host._vbox(analytics_tab, 9)
	analytics_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._label(analytics_content, "PIT WALL ANALYTICS", 16, GREEN)
	host.analytics_summary_label = host._label(analytics_content, "Nenhuma parada concluída.", 13, WHITE)
	host.analytics_chart = AnalyticsChartScript.new()
	host.analytics_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	analytics_content.add_child(host.analytics_chart)
	host._label(analytics_content, "LINHA: serviço  •  AMARELO: referência sem treino", 10, MUTED)
	host._label(analytics_content, "COMPARAÇÃO DA GRID (média de serviço)", 12, GREEN)
	host.analytics_compare_label = host._label(analytics_content, "Sem dados ainda.", 12, WHITE)
	host._label(analytics_content, "HISTÓRICO DA SUA EQUIPE", 12, GREEN)
	host.analytics_history_label = host._label(analytics_content, "Aguardando primeira parada.", 12, WHITE)
	host._label(analytics_content, "ANÁLISE DO ENGENHEIRO", 12, GREEN)
	host.analytics_advice_label = host._label(analytics_content, "Dados insuficientes para recomendações.", 12, WHITE)
	host.analytics_advice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._label(analytics_content, "RELATÓRIO PÓS-CORRIDA", 12, GREEN)
	host.analytics_final_label = host._label(analytics_content, "Disponível na bandeirada.", 12, WHITE)
	host.analytics_final_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._button(analytics_content, "EXPORTAR HISTÓRICO CSV", host._export_pit_csv)
	host.analytics_export_label = host._label(analytics_content, "Exportação disponível após uma parada.", 11, MUTED)
	host.analytics_export_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var pista_tab := ScrollContainer.new()
	pista_tab.name = "Pista"
	pista_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.tabs.add_child(pista_tab)
	host.map_panel_in_pitwall = host._vbox(pista_tab, 8)
	host.map_panel_in_pitwall.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A single compact row keeps both track conditions and the mini-map visible.
	var track_info_row := HBoxContainer.new()
	track_info_row.add_theme_constant_override("separation", 6)
	host.map_panel_in_pitwall.add_child(track_info_row)
	var weather_panel := PanelContainer.new()
	weather_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weather_panel.add_theme_stylebox_override("panel", HudThemeScript.panel(Color(0.06, 0.12, 0.20, 0.95), 8, Color("#365270"), 6))
	track_info_row.add_child(weather_panel)
	var weather_box = host._vbox(weather_panel, 2)
	host.weather_header = host._label(weather_box, "☀ CONDIÇÕES", 12, GREEN)
	host.weather_label = host._label(weather_box, "Ar 21°C  Pista 28°C\nSeca\nAderência Normal\nBorracha 8%", 10, WHITE)
	host.weather_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._label(weather_box, "SIMULADO • informativo", 9, MUTED)
	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.add_theme_stylebox_override("panel", HudThemeScript.panel(Color(0.04, 0.10, 0.17, 0.97), 8, Color("#365270"), 5))
	track_info_row.add_child(map_panel)
	var minimap_box = host._vbox(map_panel, 2)
	host._label(minimap_box, "MINIMAPA • AO VIVO", 11, GREEN)
	host.mini_map = MiniMapScript.new()
	host.mini_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.mini_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.mini_map.custom_minimum_size = Vector2(155, 100)
	minimap_box.add_child(host.mini_map)
	var weather_note = host._label(host.map_panel_in_pitwall, "Previsão atualizada durante a prova (15 min). Risco não é intensidade; água na pista afeta pneus, ritmo e DRS.", 10, MUTED)
	weather_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# v0.5.3.3 — one authoritative telemetry feed for sectors, laps, standings and events.
	var telemetry_tab := ScrollContainer.new()
	telemetry_tab.name = "Telemetria"
	telemetry_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	telemetry_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.tabs.add_child(telemetry_tab)
	var telemetry_contents = host._vbox(telemetry_tab, 8)
	telemetry_contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._label(telemetry_contents, "TELEMETRIA / DADOS REAIS DA SIMULAÇÃO", 14, GREEN)
	var caveat = host._label(telemetry_contents, "Setores estimados pelas passagens em 1/3, 2/3 e 3/3 do progresso da volta; não são os setores oficiais de cada circuito. Sem sensores de velocidade ou temperatura nesta versão.", 10, MUTED)
	caveat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.telemetry_summary_label = host._label(telemetry_contents, "Aguardando o início da corrida.", 12, WHITE)
	host.telemetry_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.telemetry_player_labels.clear()
	for index in range(2):
		var telemetry_card = host._panel(telemetry_contents, Color(0.07, 0.13, 0.21, 0.88))
		var telemetry_card_box = host._vbox(telemetry_card, 5)
		var pilot_info = host._label(telemetry_card_box, "CARRO %d — aguardando dados" % (index + 1), 12, WHITE)
		pilot_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		host.telemetry_player_labels.append(pilot_info)
	host._button(telemetry_contents, "EXPORTAR TELEMETRIA CSV + JSON", host._export_telemetry, 0)
	host.telemetry_export_label = host._label(telemetry_contents, "Exportação disponível a partir do grid. Arquivos salvos na pasta de dados do Apex.", 10, MUTED)
	host.telemetry_export_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	host.pit_status_label = host._label(right_content, "PIT LANE: livre", 11, YELLOW)
	host.pit_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.pit_timer_label = host._label(right_content, "CRONÔMETRO: aguardando parada", 11, GREEN)
	host.pit_timer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Persistent 2D strategic overlay, independent from the race and 3D cameras.
	host.tactical_map_panel = host._panel(host.game_root, Color(0.025, 0.055, 0.09, 0.91))
	var tactical_box = host._vbox(host.tactical_map_panel, 4)
	var tactical_head := HBoxContainer.new()
	tactical_box.add_child(tactical_head)
	host.tactical_map_caption = host._label(tactical_head, "MAPA 2D  •  AO VIVO", 12, GREEN)
	host.tactical_map_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var open_map: Button = host._button(tactical_head, "ABRIR", host._switch_to_strategic_map, 60)
	open_map.tooltip_text = "Ver circuito completo sem reiniciar GP"
	host.tactical_mini_map = MiniMapScript.new()
	host.tactical_mini_map.custom_minimum_size = Vector2(230, 150)
	host.tactical_mini_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.tactical_mini_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tactical_box.add_child(host.tactical_mini_map)

	# BOTTOM SPOTLIGHT — telemetry is computed from the actual active car.
	host.telemetry_panel = host._panel(host.game_root, Color(0.045, 0.095, 0.15, 0.91))
	var tele_content = host._vbox(host.telemetry_panel, 3)
	var tele_top := HBoxContainer.new()
	tele_content.add_child(tele_top)
	host.telemetry_name = host._label(tele_top, "FOCO DA TRANSMISSÃO", 15, GREEN)
	host.telemetry_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.telemetry_pit = host._label(tele_top, "NA PISTA", 11, YELLOW)
	host._button(tele_top, "×", host._toggle_context_panel, 32)
	var tele_mid := HBoxContainer.new()
	tele_mid.add_theme_constant_override("separation", 7)
	tele_content.add_child(tele_mid)
	host.telemetry_tire = host._label(tele_mid, "PNEU —", 12, WHITE)
	host.telemetry_tire.custom_minimum_size.x = 78
	host.telemetry_wear = ProgressBar.new()
	host.telemetry_wear.show_percentage = false
	host.telemetry_wear.min_value = 0
	host.telemetry_wear.max_value = 100
	host.telemetry_wear.value = 0
	host.telemetry_wear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.telemetry_wear.custom_minimum_size = Vector2(68, 12)
	tele_mid.add_child(host.telemetry_wear)
	host.telemetry_camera = host._label(tele_mid, "TV", 11, MUTED)
	host.telemetry_camera.custom_minimum_size.x = 94
	host.telemetry_stats = host._label(tele_content, "Última — | Melhor — | Intervalo —", 12, WHITE)
	host.telemetry_stats.clip_text = true
	host.telemetry_subtitle = host._label(tele_content, "RITMO Normal • Sem parada solicitada", 10, MUTED)
	host.telemetry_subtitle.clip_text = true

	# DRIVER COMMAND CARDS — compact F1M / Motorsport Manager inspired controls.
	host.player_card_strip = Control.new()
	host.game_root.add_child(host.player_card_strip)

	# BROADCAST CONTROL STRIP — a single low-profile row, always below driver cards.
	host.bottom_bar = host._panel(host.game_root, Color(0.025, 0.055, 0.093, 0.91))
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 6)
	host.bottom_bar.add_child(controls)
	host.run_button = host._button(controls, "▶ INICIAR", host._toggle_race, 104)
	host.run_button.add_theme_stylebox_override("normal", HudThemeScript.panel(Color("#146f67"), 7, GREEN, 5))
	host.run_button.add_theme_stylebox_override("hover", HudThemeScript.panel(Color("#19857a"), 7, GREEN, 5))
	host.broadcast_speed_label = host._label(controls, "RITMO", 10, MUTED)
	host.speed_picker = host._option(controls, ["1×", "2×", "5×", "10×", "16×", "32×"], host._change_speed)
	host.speed_picker.select(0) # 066721: 1x is explicitly selected
	host.speed_picker.custom_minimum_size.x = 74
	host._label(controls, "EQUIPE", 10, MUTED)
	host.live_team_mode_picker = host._option(controls, ["MANUAL", "AUTO"], host._select_live_team_mode)
	host.live_team_mode_picker.custom_minimum_size.x = 102
	host.broadcast_camera_label = host._label(controls, "CÂMERA", 10, MUTED)
	host.mode_picker = host._option(controls, ["Livre", "Seguir piloto", "Diretor TV"], host._change_camera_mode)
	host.mode_picker.select(2)
	host.mode_picker.custom_minimum_size.x = 130
	host.broadcast_driver_label = host._label(controls, "PILOTO", 10, MUTED)
	host.driver_picker = host._option(controls, ["Líder"], host._select_pilot_option)
	host.driver_picker.custom_minimum_size.x = 150
	host.broadcast_zoom_minus = host._button(controls, "−", func(): host._zoom_by(0.85), 34)
	host.broadcast_zoom_plus = host._button(controls, "+", func(): host._zoom_by(1.15), 34)
	host.broadcast_center = host._button(controls, "CENTRO", host._reset_camera, 69)
	host.broadcast_tv = host._button(controls, "TV", host._quick_tv, 48)
	host.broadcast_analytics = host._button(controls, "DADOS", host._open_pit_analytics, 64)
	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(filler)
	host.hud_button = host._button(controls, "HUD", host._toggle_hud, 63)
	host._button(controls, "MENU", host._end_to_menu, 67)
	host.hud_hint = host._label(controls, "ESPAÇO pausa • I intervalos • M visual • C HUD • V cards", 10, MUTED)
	host.hud_hint.visible = false

	# Race HUD 0.6.2 is a separate layer. All legacy widgets remain as
	# noninteractive read-only compatibility nodes, while this is the only
	# visible race interface.
	host.race_hud_0620 = RaceHud0622.new()
	host.race_hud_0620.name = "RaceHUD0622"
	host.race_hud_0620.host = host
	host.game_root.add_child(host.race_hud_0620)

