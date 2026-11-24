extends RefCounted
## APEX 0.6.2.3 — extracted responsibility; main.gd remains the scene host.
## The wrapper preserves legacy signals and callbacks.

const FrontMenu = preload("res://scripts/apex_front_menu.gd")
const GREEN := Color("#46dcc0")
const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")
const MUTED := Color("#9eb8c8")
const WHITE := Color("#e9f4fd")
const YELLOW := Color("#ffce76")
static func _build_menu(host) -> void:
	host.menu_root = host._full_cover()
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.05, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.menu_root.add_child(shade)
	var card = host._panel(host.menu_root, Color("#071624"))
	card.name = "MenuCard"
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(outer)
	outer.add_theme_constant_override("margin_left", 18)
	outer.add_theme_constant_override("margin_right", 18)
	outer.add_theme_constant_override("margin_top", 18)
	outer.add_theme_constant_override("margin_bottom", 18)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	outer.add_child(root)

	var hero := VBoxContainer.new()
	host.menu_hero = hero
	hero.custom_minimum_size = Vector2(205, 0)
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(hero)
	var hero_panel := PanelContainer.new()
	hero_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_panel.add_theme_stylebox_override("panel", HudThemeScript.panel(Color("#0a2032"), 18, Color("#204e70"), 16))
	hero.add_child(hero_panel)
	var hero_box = host._vbox(hero_panel, 10)
	host._label(hero_box, "APEX", 44, Color("#ff8126"))
	host._button(hero_box, "MENU PRINCIPAL", func(): host.menu_root.get_node("FrontDoor").show_home())
	host._label(hero_box, "RACE CONTROL", 20, WHITE)
	var pill := Label.new()
	pill.text = "TEMPORADA %s" % host.season_title
	pill.add_theme_font_size_override("font_size", 12)
	pill.add_theme_color_override("font_color", YELLOW)
	hero_box.add_child(pill)
	var hero_desc = host._label(hero_box, "Prepare a próxima corrida e acompanhe o desenvolvimento da sua equipe.", 13, MUTED)
	hero_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._label(hero_box, "• Escolha equipe e circuito", 13, WHITE)
	host._label(hero_box, "• Ajuste semente da corrida", 13, WHITE)
	host._label(hero_box, "• Teste incidentes de box", 13, WHITE)
	var helper = host._label(hero_box, "1×/2× = câmera 3D • 5×/10×/16×/32× = mapa estratégico", 12, MUTED)
	helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer = host._label(hero_box, "v0.6.5.0 • Living Factory / Soul Staff 1.0", 12, GREEN)
	footer.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	var cfg_panel := PanelContainer.new()
	cfg_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cfg_panel.add_theme_stylebox_override("panel", HudThemeScript.panel(Color("#0c1b2b"), 18, Color("#244764"), 18))
	root.add_child(cfg_panel)
	# The form scrolls; the primary action must remain visible at any window height.
	var menu_column := VBoxContainer.new()
	menu_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_column.add_theme_constant_override("separation", 10)
	cfg_panel.add_child(menu_column)
	host.menu_scroll = ScrollContainer.new()
	host.menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_column.add_child(host.menu_scroll)
	var box = host._vbox(host.menu_scroll, 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var section_title = host._label(box, "PREPARAÇÃO DO GP", 26, WHITE)
	host._label(box, "MODO CARREIRA • TEMPORADA 2012", 14, GREEN)
	host.championship_status = host._label(box, "Nenhuma temporada iniciada.", 12, WHITE)
	host.championship_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var championship_actions := HBoxContainer.new()
	championship_actions.add_theme_constant_override("separation", 7)
	box.add_child(championship_actions)
	var start_season = host._button(championship_actions, "NOVA TEMPORADA", host._ask_new_championship)
	start_season.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.championship_continue_button = host._button(championship_actions, "CONTINUAR", host._resume_championship)
	host.championship_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var single_race = host._button(championship_actions, "GP AVULSO", host._single_race_mode)
	single_race.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._button(box, "CLASSIFICAÇÃO / RESULTADOS DA TEMPORADA", host._show_championship_table)
	host.championship_new_dialog = ConfirmationDialog.new()
	host.championship_new_dialog.title = "Nova temporada de 2012"
	host.championship_new_dialog.dialog_text = "Criar uma temporada nova? O campeonato salvo anteriormente sera substituido. As melhorias da oficina serao mantidas."
	host.championship_new_dialog.confirmed.connect(host._new_championship)
	host.menu_root.add_child(host.championship_new_dialog)
	host.championship_table_dialog = AcceptDialog.new()
	host.championship_table_dialog.title = "APEX / Campeonato 2012"
	host.championship_table_dialog.dialog_text = ""
	host.championship_report_text = RichTextLabel.new()
	host.championship_report_text.custom_minimum_size = Vector2(790, 585)
	host.championship_report_text.scroll_active = true
	host.championship_report_text.fit_content = false
	host.championship_report_text.add_theme_font_size_override("normal_font_size", 15)
	host.championship_table_dialog.add_child(host.championship_report_text)
	host.menu_root.add_child(host.championship_table_dialog)
	host._label(box, "Equipe", 13, MUTED)
	var team_names: Array = []
	for t in host.teams:
		team_names.append(str(t["name"]))
	host.team_picker = host._option(box, team_names, host._on_team_selected)
	host.team_picker.fit_to_longest_item = false
	host.team_picker.select(maxi(0, team_names.find(host.selected_team)))
	host.team_picker.custom_minimum_size = Vector2(0, 40)
	host._label(box, "Circuito (%s)" % host.season_title, 13, MUTED)
	var track_names: Array = []
	for tr in host.season_tracks:
		track_names.append("%s — %s" % [str(tr["country"]), str(tr["name"])])
	host.track_picker = host._option(box, track_names, host._on_track_selected)
	host.track_picker.fit_to_longest_item = false
	host.track_picker.select(host.selected_track_index)
	host.track_picker.custom_minimum_size = Vector2(0, 40)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	host._label(left, "Semente da simulação", 13, MUTED)
	host.seed_picker = SpinBox.new()
	host.seed_picker.min_value = 0
	host.seed_picker.max_value = 999999999
	host.seed_picker.value = 42
	host.seed_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(host.seed_picker)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	host._label(right, "Incidentes de box", 13, MUTED)
	host.pit_test_picker = host._option(right, ["Raros (corrida normal)", "TESTE: pistola/porca", "TESTE: liberação insegura", "TESTE: os dois incidentes"], func(_index): pass)
	host.pit_test_picker.fit_to_longest_item = false
	host.pit_test_picker.select(0)
	host.pit_test_picker.custom_minimum_size = Vector2(0, 38)
	host._label(box, "Condições de largada / cenário climático", 13, MUTED)
	host.weather_mode_picker = host._option(box, ["Automático", "Seco", "Variável", "Chuva intensa"], func(_index): pass)
	host.weather_mode_picker.fit_to_longest_item = false
	host.weather_mode_picker.select(0)
	host.weather_mode_picker.custom_minimum_size = Vector2(0, 38)
	host.weather_mode_picker.tooltip_text = "Automático: sorteio determinístico por GP com risco próprio da pista. Seco / Variável / Chuva intensa: cenários de teste."
	host.weather_briefing_label = host._label(box, "", 11, MUTED)
	host.weather_briefing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._update_weather_briefing()
	host._label(box, "GESTÃO DA EQUIPE DURANTE A CORRIDA", 13, GREEN)
	host.pre_race_team_mode_picker = host._option(box, ["Manual — eu decido", "Automático — STAFF decide"], host._select_pre_race_team_mode)
	host.pre_race_team_mode_picker.fit_to_longest_item = false
	host.pre_race_team_mode_picker.select(0)
	host.pre_race_team_mode_picker.tooltip_text = "Manual mantém ritmo/KERS e box sob seu controle. Automático delega ritmo/KERS e ativa IA de boxes nos dois pilotos."
	host._label(box, "MOTOR APEX CORE 2 • 2012", 13, GREEN)
	host.tyre_briefing_label = host._label(box, "", 12, GREEN)
	host.tyre_briefing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._update_tyre_briefing()
	var physics_note = host._label(box, "Core 2: pista molhada altera ritmo, desgaste, DRS e estratégia. Compostos de chuva disponíveis; parâmetros experimentais de balanceamento.", 11, MUTED)
	physics_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var briefing = host._label(box, "Escolha sua equipe, prepare a estratégia e entre no grid.", 12, MUTED)
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._button(box, "▰  PLANEJADOR DE STINTS / ANTES DA LARGADA", host._open_pre_race_strategy)
	host.pre_race_strategy_status = host._label(box, "Opcional: visualize o plano e, em Manual, confirme as primeiras paradas.", 11, MUTED)
	host.pre_race_strategy_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._button(box, "⚙  OFICINA DO CARRO", host._open_garage)
	host._button(box, "★  SOUL STAFF 1.0 / GESTÃO DE EQUIPE", host._open_staff)
	host.portrait_download_button = host._button(box, "↓  BAIXAR RETRATOS DA EQUIPE (WIKIMEDIA)", host._download_team_portraits)
	host.portrait_download_all_button = host._button(box, "↓  BAIXAR RETRATOS DE TODA A GRID", host._download_all_portraits)
	host.portrait_status_label = host._label(box, "Identidade visual neutra: pilotos identificados por nome e iniciais.", 11, MUTED)
	host.portrait_download_button.hide()
	host.portrait_download_all_button.hide()
	host.portrait_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var note = host._label(box, "Tabela lateral: líder / frente / trás / pneus / melhor volta no botão ⇆.", 12, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Fixed footer outside ScrollContainer: the start button can never scroll away.
	host.menu_actions = VBoxContainer.new()
	host.menu_actions.add_theme_constant_override("separation", 0)
	menu_column.add_child(host.menu_actions)
	host.start_button = host._button(host.menu_actions, "▶  INICIAR CORRIDA  /  ENTRAR NO GRID", host._request_start_race)
	host.start_button.name = "StartRaceButton"
	host.start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.start_button.custom_minimum_size = Vector2(0, 52)
	host.start_button.tooltip_text = "Iniciar o Grande Prêmio com a equipe, pista e configurações selecionadas."
	host._update_championship_menu()


	var front := FrontMenu.new()
	front.setup(host)
	front.configuration_title = section_title
	host._button(host.menu_actions, "VOLTAR AO MENU PRINCIPAL", front.show_home)
