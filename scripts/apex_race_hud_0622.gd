extends Control
## APEX Race HUD v0.6.6.8.1 — ReBroadcast visual QA; Core 2 remains authoritative.
## Reads the real RaceEngine state, and delegates all race commands to main.gd.
## No simulation values are invented here.

const MiniMap = preload("res://scripts/apex_mini_map.gd")
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")
const ReBroadcast = preload("res://scripts/apex_hud_rebroadcast_0668.gd")
const Stints = preload("res://scripts/apex_strategy_planner_0620.gd")
const EngineerInteractive = preload("res://scripts/core/race_engineer_interactive.gd")
const DriverPerception = preload("res://scripts/core/race_driver_perception_0633.gd")
const DriverMemory = preload("res://scripts/core/race_driver_memory_0634.gd")
const StintDialogue = preload("res://scripts/core/race_stint_dialogue_0635.gd")
const SoulDriver = preload("res://scripts/core/race_soul_driver_0636.gd")
const SoulReactive = preload("res://scripts/core/race_soul_reactive_0637.gd")
const Engineer2 = preload("res://scripts/core/race_engineer_0645.gd")
const Engineer3 = preload("res://scripts/core/race_engineer_0646.gd")
const DriverSoul2 = preload("res://scripts/core/race_driver_soul_0647.gd")
const TeamRadioAdvice = preload("res://scripts/core/race_team_radio_advice_06689.gd")
const RaceEngineer = preload("res://scripts/core/race_engineer_0639.gd")
const PitWallIntel = preload("res://scripts/core/race_pitwall_intelligence_0640.gd")
const PitWallStrategy3 = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const StrategyGraphData06498 = preload("res://scripts/core/race_strategy_graph_data_06498.gd")
const StrategyChart06498 = preload("res://scripts/apex_dynamic_strategy_chart_06498.gd")
const StrategySimulator06499 = preload("res://scripts/core/race_strategy_simulator_06499.gd")
# Híbrido UI01 (0.6.3.5) + UI03 (0.6.4.5).
# Apenas apresentação: IA, rádio, pits, física e callbacks da 0.6.4.5 continuam intactos.
const BASE := HudSkin.BASE
const SURFACE := HudSkin.SURFACE
const ACCENT := HudSkin.ORANGE
const SOUL_ACCENT := HudSkin.TYRE_GREEN
const WHITE := HudSkin.WHITE
const MUTED := HudSkin.MUTED
const YELLOW := HudSkin.WARNING
const BORDER := HudSkin.BORDER
const METRICS := ["INTERVALO", "LÍDER", "PITS", "MELHOR VOLTA", "PNEUS", "ATRÁS", "ÚLTIMA VOLTA"]
const CONTEXTS := ["Telemetria", "Desempenho", "Estratégia", "Carro"]
const SPEEDS := [1.0, 2.0, 5.0, 10.0, 16.0, 32.0]

var host
var metric_index: int = 0
var active_window: String = ""
var race_card_panels: Array = []
var standing_rows: Array = []
var standings_title: Label
var lap_label: Label
var session_label: Label
var weather_line: Label
var minimap
var speed_label: OptionButton
var pause_button: Button
var team_mode_picker: OptionButton
var view_picker: OptionButton
var overlay_window: PanelContainer
var overlay_title: Label
var overlay_content: VBoxContainer
var overlay_scroll: ScrollContainer
var overlay_close: Button
var background_dimmer: ColorRect
var modal_timeline
var modal_driver_rows: Array = []
var radio_driver_ids: Array[int] = []
var radio_driver_picker: OptionButton
var radio_response_label: Label
var radio_portrait_texture: TextureRect
var radio_portrait_placeholder: Label
var radio_identity_info: Label
var radio_history: RichTextLabel
var radio_category: int = 0
var radio_category_buttons: Array[Button] = []
var radio_only_selected: bool = false
var radio_only_button: Button
var radio_driver_memory: Dictionary = {}
var radio_stint_memory: Dictionary = {}
var radio_soul_profiles: Dictionary = {}
var radio_reactive_memories: Dictionary = {}
var radio_reactive_event_id: int = 0
var radio_reactive_last_check: float = -999.0
var radio_reactive_label: Label
var radio_reactive_toast: Button
var radio_reactive_toast_until: int = 0
var radio_reactive_latest: String = "Aguardando acontecimentos da corrida."
var radio_soul_status: Label
var radio_soul_request_label: Label
var radio_soul_notified: Dictionary = {}
var radio_soul_last_refresh: float = -999.0
var media_buttons: Array = []
var speed_index: int = 0
var ranking: PanelContainer
var weather_box: PanelContainer
var map_box: PanelContainer
var bottom_bar: PanelContainer
var driver_tab_buttons: Array = []
var tiny_top: PanelContainer
var player_strip: Control
var actions_top: HBoxContainer
var large_area: Control
var expanded_context: Array = [-1, -1]
var engineer_reports: Dictionary = {}
var engineer_cards: Array = []
var pitwall3_cards: Array = []
var pitwall3_feedback: Label
var dynamic_graph_data = StrategyGraphData06498.new()
var dynamic_chart_views: Array = []
var dynamic_garage_status: Label
var simulator_cards: Array = []
var simulator_selection: Dictionary = {}
var engineer_last_radio: Dictionary = {}
var engineer_last_lap: Dictionary = {}
var engineer_mode_picker: OptionButton
var engineer_history_by_driver: Dictionary = {}
var engineer_history_keys: Dictionary = {}
var engineer_history_text: RichTextLabel
var engineer_query_cooldowns: Dictionary = {}
var engineer_radio_answers: Dictionary = {}
# Estilos compartilhados entre atualizações do ranking.
var rank_idle_style: StyleBoxFlat
var rank_selected_style: StyleBoxFlat
var hud_mode: int = 1 # 0 Broadcast, 1 Compact, 2 Full; independent from legacy layout
var hud_mode_picker: OptionButton
var pit_quick_panel: PanelContainer
var status_banner: Label
var ranking_field_writes: int = 0
var ranking_refreshes: int = 0

func _ready() -> void:
	hud_mode = ReBroadcast.load_mode()
	theme = HudSkin.build()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_create_ui()
	visible = false

func _frame(color: Color = SURFACE, radius: int = 7) -> StyleBoxFlat:
	return HudSkin.panel(color, radius, HudSkin.BORDER_SOFT, 8)

func _panel(parent: Node, color: Color = SURFACE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _frame(color))
	parent.add_child(p)
	return p

func _column(parent: Node, space: int = 5) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", space)
	parent.add_child(c)
	return c

func _line(parent: Node, space: int = 5) -> HBoxContainer:
	var c := HBoxContainer.new()
	c.add_theme_constant_override("separation", space)
	parent.add_child(c)
	return c

func _text(parent: Node, text_value: String, font_size: int = 12, color: Color = WHITE) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _btn(parent: Node, caption: String, callback: Callable, width: float = 0.0) -> Button:
	var b := Button.new()
	b.text = caption
	if width > 0.0:
		b.custom_minimum_size.x = width
	b.custom_minimum_size.y = 29
	b.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, HudSkin.button_style(state))
	b.add_theme_color_override("font_color", WHITE)
	b.add_theme_color_override("font_hover_color", WHITE)
	b.add_theme_color_override("font_pressed_color", WHITE)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _select(parent: Node, captions: Array, callback: Callable) -> OptionButton:
	var result := OptionButton.new()
	for caption in captions:
		result.add_item(str(caption))
	result.item_selected.connect(callback)
	result.add_theme_font_size_override("font_size", 11)
	parent.add_child(result)
	return result

func _create_ui() -> void:
	rank_idle_style = HudSkin.button_style("rank")
	rank_selected_style = HudSkin.button_style("rank_selected")
	tiny_top = _panel(self)
	tiny_top.add_theme_stylebox_override("panel", HudSkin.panel(SURFACE, 6, HudSkin.BORDER_SOFT, 8, true))
	var stats := _line(tiny_top, 9)
	lap_label = _text(stats, "VOLTA —/—", 13, ACCENT)
	session_label = _text(stats, "00:00:00", 12, MUTED)
	status_banner = _text(stats, "PARADA", 11, YELLOW)

	actions_top = HBoxContainer.new()
	actions_top.add_theme_constant_override("separation", 4)
	add_child(actions_top)
	for item in [{"name":"CORRIDA", "id":"corrida"}, {"name":"ESTRAT.", "id":"estrategia"}, {"name":"DADOS", "id":"dados"}, {"name":"EVENTOS", "id":"eventos"}, {"name":"RÁDIO", "id":"radio"}, {"name":"ENG.", "id":"engineer"}]:
		var b := _btn(actions_top, str(item["name"]), _open_window.bind(str(item["id"])), 78 if str(item["id"]) != "radio" else 62)
		b.tooltip_text = "Abrir %s" % str(item["name"])
		media_buttons.append(b)
	hud_mode_picker = _select(actions_top, ReBroadcast.MODES, _change_hud_mode)
	hud_mode_picker.select(hud_mode)
	hud_mode_picker.custom_minimum_size.x = 125
	hud_mode_picker.tooltip_text = "HUD ReBroadcast: transmissão, gestão compacta ou análise completa"
	# Alerta curto e clicável, sem sobrepor o minimapa nem os painéis laterais.
	radio_reactive_toast = _btn(self, "", _open_window.bind("radio"))
	radio_reactive_toast.add_theme_stylebox_override("normal", HudSkin.panel(HudSkin.SURFACE_SOLID, 6, HudSkin.ORANGE, 8, true))
	radio_reactive_toast.add_theme_stylebox_override("hover", HudSkin.button_style("hover"))
	radio_reactive_toast.add_theme_color_override("font_color", ACCENT)
	radio_reactive_toast.alignment = HORIZONTAL_ALIGNMENT_LEFT
	radio_reactive_toast.clip_text = true
	radio_reactive_toast.hide()

	ranking = _panel(self)
	var left := _column(ranking, 3)
	var rank_header := _line(left, 2)
	var prev := _btn(rank_header, "‹", _move_metric.bind(-1), 27)
	prev.tooltip_text = "Métrica anterior"
	standings_title = _text(rank_header, "INTERVALO", 11, ACCENT)
	standings_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	standings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next := _btn(rank_header, "›", _move_metric.bind(1), 27)
	next.tooltip_text = "Próxima métrica"
	var standings_scroll := ScrollContainer.new()
	standings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	standings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(standings_scroll)
	var entries := _column(standings_scroll, 1)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(24):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 28
		row.add_theme_constant_override("separation", 3)
		entries.add_child(row)
		var stripe := ColorRect.new()
		stripe.custom_minimum_size = Vector2(3, 20)
		stripe.color = MUTED
		row.add_child(stripe)
		# 2012 portrait pack — one cached thumbnail per visible ranking row.
		# This is presentation-only: no race tick, strategy or position changes.
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(22, 24)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.visible = false
		row.add_child(portrait)
		var pos := _text(row, "%d" % (i + 1), 13, MUTED)
		pos.custom_minimum_size.x = 20
		var driver := _btn(row, "---", _select_grid_car.bind(i), 43)
		driver.add_theme_stylebox_override("normal", rank_idle_style)
		driver.add_theme_stylebox_override("hover", HudSkin.button_style("rank_hover"))
		driver.add_theme_stylebox_override("pressed", rank_selected_style)
		driver.alignment = HORIZONTAL_ALIGNMENT_LEFT
		driver.add_theme_font_size_override("font_size", 13)
		driver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		driver.custom_minimum_size.y = 26
		var tyre := _text(row, "—", 13, MUTED)
		tyre.custom_minimum_size.x = 16
		tyre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var state := _text(row, "", 11, YELLOW)
		state.custom_minimum_size.x = 31
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var detail := _text(row, "—", 12, WHITE)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.custom_minimum_size.x = 66
		standing_rows.append({"row":row, "stripe":stripe, "portrait":portrait, "pos":pos, "driver":driver,
			"tyre":tyre, "state":state, "detail":detail})

	weather_box = _panel(self)
	weather_box.minimum_size_changed.connect(layout_hud, CONNECT_DEFERRED)
	var weather_column := _column(weather_box, 4)
	_text(weather_column, "CONDIÇÕES DA PISTA", 11, ACCENT)
	weather_line = _text(weather_column, "Aguardando clima", 12, WHITE)
	weather_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	map_box = _panel(self)
	var map_column := _column(map_box, 2)
	var map_heading := _line(map_column, 5)
	var mini_heading := _text(map_heading, "MINIMAPA", 11, ACCENT)
	mini_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(map_heading, "2D ↗", _set_view.bind(0), 52)
	minimap = MiniMap.new()
	minimap.custom_minimum_size = Vector2(190, 143)
	minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_column.add_child(minimap)

	# FULL-only quick links; every button opens an existing, functional
	# Pit Wall/strategy/engineering window, without writing to race state.
	pit_quick_panel = _panel(self, HudSkin.SURFACE)
	var quick_column := _column(pit_quick_panel, 5)
	_text(quick_column, "PIT WALL / CENTRO DE DECISÕES", 11, ACCENT)
	var quick_first := _line(quick_column, 4)
	_btn(quick_first, "RESUMO", _open_window.bind("pitwall3"), 101).tooltip_text = "Pit Wall 3.0 e situações dos dois carros"
	_btn(quick_first, "PLANO", _open_window.bind("estrategia"), 99).tooltip_text = "Planejar stints e agendar paradas"
	var quick_second := _line(quick_column, 4)
	_btn(quick_second, "DECISÃO", _open_window.bind("engineer"), 101).tooltip_text = "Ordens e análises do engenheiro"
	_btn(quick_second, "ANÁLISE", _open_window.bind("graficos"), 99).tooltip_text = "Gráficos dinâmicos baseados na simulação"

	player_strip = Control.new()
	player_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_strip)

	# Compact floating transport in the gap between the two driver cards.
	# Team / camera / zoom controls live in the CORRIDA menu, not a full-width bar.
	bottom_bar = _panel(self, SURFACE)
	var tools := _line(bottom_bar, 5)
	pause_button = _btn(tools, "▶", _pause, 68)
	pause_button.tooltip_text = "Pausar ou continuar (Espaço)"
	_btn(tools, "‹", _step_speed.bind(-1), 31).tooltip_text = "Diminuir velocidade"
	# 066721: make all time scales, including 1x, selectable in the race HUD.
	speed_label = _select(tools, ["1×", "2×", "5×", "10×", "16×", "32×"], _pick_speed)
	speed_label.custom_minimum_size.x = 63
	speed_label.select(0)
	speed_label.tooltip_text = "Velocidade da simulação — 1× é tempo real"
	speed_label.add_theme_color_override("font_color", ACCENT)
	_btn(tools, "›", _step_speed.bind(1), 31).tooltip_text = "Aumentar velocidade"
	# State holders are deliberately hidden; other game shortcuts still use them.
	team_mode_picker = _select(self, ["MANUAL", "AUTO"], _set_team_mode)
	team_mode_picker.hide()
	view_picker = _select(self, ["MAPA 2D", "AÉREA 3D", "DIRETOR TV"], _set_view)
	view_picker.select(1)
	view_picker.hide()

	background_dimmer = ColorRect.new()
	background_dimmer.color = Color(0.0, 0.0, 0.0, 0.45)
	background_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background_dimmer)
	background_dimmer.hide()
	large_area = Control.new()
	large_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(large_area)
	overlay_window = _panel(large_area, HudSkin.SURFACE_SOLID)
	var outer := _column(overlay_window, 7)
	var modal_header := _line(outer, 7)
	overlay_title = _text(modal_header, "", 18, ACCENT)
	overlay_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_close = _btn(modal_header, "FECHAR ×", _close_window, 77)
	overlay_scroll = ScrollContainer.new()
	overlay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(overlay_scroll)
	overlay_content = _column(overlay_scroll, 10)
	overlay_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	large_area.hide()

func begin_race() -> void:
	# No subjective radio memory survives into the next Grand Prix.
	radio_driver_memory.clear()
	engineer_reports.clear()
	engineer_cards.clear()
	engineer_last_radio.clear()
	engineer_last_lap.clear()
	engineer_history_by_driver.clear()
	engineer_history_keys.clear()
	engineer_query_cooldowns.clear()
	engineer_radio_answers.clear()
	radio_stint_memory.clear()
	radio_soul_profiles.clear()
	radio_soul_notified.clear()
	radio_reactive_memories.clear()
	radio_reactive_event_id = 0
	radio_reactive_last_check = -999.0
	radio_reactive_latest = "Aguardando acontecimentos da corrida."
	radio_reactive_toast_until = 0
	if radio_reactive_toast != null:
		radio_reactive_toast.hide()
	radio_soul_last_refresh = -999.0
	radio_only_selected = false
	radio_category = 0
	for node in player_strip.get_children():
		player_strip.remove_child(node)
		node.queue_free()
	race_card_panels.clear()
	expanded_context = [-1, -1]
	if host == null or host.race == null:
		return
	# Chart model reads the existing initial planner once at the real GP start.
	dynamic_graph_data.reset(host.race)
	var cars: Array = host.race.player_cars()
	for i in range(mini(2, cars.size())):
		_create_driver_card(cars[i], i)
	if host.map_view != null:
		minimap.set_track(host.map_view.route)
	metric_index = 0
	ranking_field_writes = 0
	ranking_refreshes = 0
	team_mode_picker.select(1 if host.team_control_mode == "Automático" else 0)
	active_window = ""
	large_area.hide()
	background_dimmer.hide()
	visible = true
	layout_hud()
	refresh_hud()

func _create_driver_card(car: Dictionary, slot: int) -> void:
	var base := _panel(player_strip, Color(0.033, 0.062, 0.099, 0.97))
	var interior := _line(base, 7)
	var controls := _column(interior, 3)
	var tab_buttons: Array = []
	for k in range(4):
		var b := _btn(controls, ["T", "D", "E", "C"][k], _expand_driver.bind(slot, k), 31)
		b.custom_minimum_size.y = 29
		b.tooltip_text = CONTEXTS[k] + " — abrir detalhes acima do piloto"
		tab_buttons.append(b)
	# Real driver photograph if it has been downloaded/licensed; NEVER a car photo.
	# The offline fallback is just the driver's initials, not another image.
	var driver_name: String = str(car.get("name", "Piloto"))
	var identity: Dictionary = {}
	var portrait_tex: Texture2D = null
	if host != null and host.portrait_manager != null:
		identity = host.portrait_manager.get_info(driver_name)
		portrait_tex = host.portrait_manager.get_photo(driver_name)
	var portrait_holder := _panel(interior, Color.from_string(str(car.get("color", "#253f57")), BORDER).darkened(0.58))
	portrait_holder.custom_minimum_size = Vector2(82, 114)
	var portrait_column := _column(portrait_holder, 2)
	if portrait_tex != null:
		var face := TextureRect.new()
		face.texture = portrait_tex
		face.custom_minimum_size = Vector2(76, 85)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.tooltip_text = host.portrait_manager.get_credit(driver_name) + " · " + host.portrait_manager.get_source_url(driver_name)
		portrait_column.add_child(face)
	else:
		var bits: PackedStringArray = driver_name.split(" ", false)
		var portrait_mark := _text(portrait_column, str(identity.get("abbr", bits[bits.size()-1].left(3).to_upper())), 18, WHITE)
		portrait_mark.custom_minimum_size = Vector2(76, 85)
		portrait_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portrait_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var identity_line := _text(portrait_column, "#%d %s %s" % [
		int(identity.get("number", 0)), str(identity.get("abbr", "---")),
		str(identity.get("country", "---"))], 10, WHITE)
	identity_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity_line.tooltip_text = "Temporada histórica 2012; identidade separada dos dados esportivos."
	var core := _column(interior, 5)
	core.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_line := _line(core, 6)
	var pos := _text(title_line, "P%d" % int(car.get("position", 0)), 17, ACCENT)
	var name := _text(title_line, str(car.get("name", "Piloto")), 15, WHITE)
	name.clip_text = true
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var status := _text(core, "Pneu —  •  —%", 13, WHITE)
	status.clip_text = true
	var second_line := _text(core, "Ritmo —", 12, MUTED)
	second_line.clip_text = true
	var tyre_bar := ProgressBar.new()
	tyre_bar.custom_minimum_size = Vector2(0.0, 8.0)
	tyre_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tyre_bar.min_value = 0
	tyre_bar.max_value = 100
	tyre_bar.show_percentage = false
	tyre_bar.add_theme_stylebox_override("background", _frame(Color("#2F3944"), 3))
	tyre_bar.add_theme_stylebox_override("fill", _frame(ACCENT, 3))
	core.add_child(tyre_bar)
	var action_line := _line(core, 5)
	var follow := _btn(action_line, "SEGUIR", _follow.bind(int(car["id"])), 86)
	follow.tooltip_text = "Seguir este piloto com a câmera"
	var quick := _btn(action_line, "CHAMAR BOX", _quick_box.bind(slot), 110)
	quick.tooltip_text = "Chamar imediatamente o carro para os boxes"
	var expanded := _panel(player_strip, Color(0.039, 0.074, 0.115, 0.985))
	var content := _column(expanded, 8)
	var heading := _line(content, 5)
	var heading_label := _text(heading, "", 14, ACCENT)
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(heading, "×", _collapse_driver.bind(slot), 29)
	var detail_body := _column(content, 6)
	expanded.hide()
	race_card_panels.append({"base":base, "expanded":expanded, "content":detail_body, "heading":heading_label,
		"id":int(car["id"]), "slot":slot, "pos":pos, "name":name, "identity":identity_line, "status":status, "secondary":second_line,
		"wear_bar":tyre_bar, "tabs":tab_buttons, "quick":quick, "context":-1,
		"target_tire":str(car.get("pit_target", "Duro")), "tire_picker":null,
		"lap_picker":null, "data_labels":[], "buttons":[], "follow":follow})

func _driver_from_slot(slot: int) -> Dictionary:
	if host == null or host.race == null or slot < 0 or slot >= race_card_panels.size():
		return {}
	return host._car_by_id(int(race_card_panels[slot]["id"]))

func _expand_driver(slot: int, context: int) -> void:
	if slot < 0 or slot >= race_card_panels.size():
		return
	var card: Dictionary = race_card_panels[slot]
	if expanded_context[slot] == context:
		_collapse_driver(slot)
		return
	# On small screens, opening both detail panels would cause overlap.
	if get_viewport_rect().size.x < 1460.0:
		var other_slot: int = 1 - slot
		if other_slot >= 0 and other_slot < race_card_panels.size() and expanded_context[other_slot] >= 0:
			_collapse_driver(other_slot)
	expanded_context[slot] = context
	card["context"] = context
	card["expanded"].show()
	card["heading"].text = CONTEXTS[context].to_upper()
	for k in range(4):
		(card["tabs"][k] as Button).add_theme_color_override("font_color", ACCENT if k == context else WHITE)
	var body: VBoxContainer = card["content"]
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	card["data_labels"] = []
	card["buttons"] = []
	card.erase("pace_picker")
	card.erase("advice_label")
	card.erase("pit_mode_picker")
	card["tire_picker"] = null
	card["lap_picker"] = null
	var car: Dictionary = _driver_from_slot(slot)
	if context == 0:
		for label in ["Última volta", "Melhor volta", "Setores (aprox.)", "Voltas completadas"]:
			_add_metric(card, label)
		var sector_note := _text(body, "Setores são aproximações do motor, não FIA.", 10, MUTED)
		sector_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif context == 1:
		for label in ["Ritmo atual", "Plano do STAFF", "Tráfego", "KERS e DRS"]:
			_add_metric(card, label)
		var pace := _select(body, ["Conservar", "Normal", "Atacar"], _set_pace.bind(slot))
		pace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card["pace_picker"] = pace
		var kers := _btn(body, "ALTERAR KERS", _kers.bind(slot))
		card["buttons"].append(kers)
	elif context == 2:
		for label in ["Pit / agendamento", "Vida estimada do pneu"]:
			_add_metric(card, label)
		_text(body, "ENGENHEIRO", 10, MUTED)
		var advice_text := _text(body, "Aguardando dados", 11, WHITE)
		advice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		advice_text.custom_minimum_size.y = 42
		card["advice_label"] = advice_text
		var tyre_row := _line(body, 5)
		_text(body, "ATUAL: %s · %d voltas neste jogo" % [str(car.get("tire", "—")), int(car.get("stint_laps", 0))], 11, YELLOW)
		_text(tyre_row, "PRÓXIMO PNEU", 10, MUTED)
		var tires: Array = host.race.available_pit_compounds()
		var picker := _select(tyre_row, tires, _pick_tire.bind(slot))
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card["tire_picker"] = picker
		var target: String = str(card.get("target_tire", car.get("pit_target", "Médio")))
		picker.select(maxi(0, tires.find(target)))
		var pit_row := _line(body, 4)
		_text(pit_row, "PARAR NA VOLTA", 10, MUTED)
		var lap := SpinBox.new()
		lap.min_value = 1
		lap.max_value = maxi(1, int(host.race.lap_count) - 1)
		lap.value = minf(float(lap.max_value), float(int(car.get("laps_done", 0)) + 2))
		lap.custom_minimum_size.x = 75
		pit_row.add_child(lap)
		card["lap_picker"] = lap
		_btn(pit_row, "AGENDAR", _schedule.bind(slot), 72)
		_btn(body, "CANCELAR AGENDAMENTO", _cancel_pit.bind(slot))
		var ai_row := _line(body, 5)
		_text(ai_row, "ENGENHEIRO DE BOX", 10, MUTED)
		var ai_picker := _select(ai_row, ["MANUAL", "IA"], _driver_pit_mode.bind(slot))
		ai_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card["pit_mode_picker"] = ai_picker
	elif context == 3:
		for label in ["Pneu atual", "Idade / desgaste", "Carro / potência", "Confiabilidade e danos"]:
			_add_metric(card, label)
		var car_note := _text(body, "O motor atual não simula danos individuais. Não há números fictícios.", 10, MUTED)
		car_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_driver_context(slot)
	layout_hud()

func _add_metric(card: Dictionary, title: String) -> void:
	var line := _line(card["content"], 5)
	var heading := _text(line, title, 12, MUTED)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var data := _text(line, "—", 12, WHITE)
	data.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	data.custom_minimum_size.x = 115
	data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data.clip_text = true
	card["data_labels"].append(data)

func _collapse_driver(slot: int) -> void:
	if slot >= 0 and slot < race_card_panels.size():
		expanded_context[slot] = -1
		race_card_panels[slot]["expanded"].hide()
		for button in race_card_panels[slot]["tabs"]:
			(button as Button).remove_theme_color_override("font_color")
		layout_hud()

func layout_hud() -> void:
	if host == null:
		return
	var width_px: float = maxf(800.0, get_viewport_rect().size.x)
	var height_px: float = maxf(580.0, get_viewport_rect().size.y)
	var full: bool = hud_mode == 2
	var broadcast: bool = hud_mode == 0
	# HUD uses full-rect anchors and follows the parent automatically.
	tiny_top.position = Vector2(13.0, 9.0)
	tiny_top.size = Vector2(300.0, 40.0)
	actions_top.position = Vector2(width_px - 665.0, 9.0)
	actions_top.size = Vector2(652.0, 31.0)
	var toast_width: float = minf(490.0, maxf(180.0, width_px - 515.0))
	radio_reactive_toast.position = Vector2((width_px - toast_width) * 0.5, 54.0)
	radio_reactive_toast.size = Vector2(toast_width, 43.0)
	var left_width: float = 295.0 if full else 283.0
	var right_width: float = 242.0 if full else 228.0
	var card_height: float = 170.0 if full else 148.0
	var card_y: float = height_px - card_height - 13.0
	ranking.position = Vector2(12.0, 55.0)
	# The leaderboard must never collide vertically with the driver cards.
	var rank_bottom: float = height_px - 70.0 if broadcast else card_y - 9.0
	ranking.size = Vector2(left_width, maxf(155.0, minf(668.0, rank_bottom - 55.0)))
	weather_box.position = Vector2(width_px - right_width - 12.0, 55.0)
	weather_box.size = Vector2(right_width, 126.0)
	map_box.position = Vector2(width_px - right_width - 12.0, 190.0)
	map_box.size = Vector2(right_width, 199.0)
	pit_quick_panel.position = Vector2(width_px - right_width - 12.0, 400.0)
	pit_quick_panel.size = Vector2(right_width, 109.0)
	pit_quick_panel.visible = full
	# Small island in the centre: only pause and speed, no full-width stripe.
	bottom_bar.size = Vector2(255.0, 48.0)
	bottom_bar.position = Vector2((width_px - bottom_bar.size.x) * 0.5, height_px - 57.0)
	player_strip.position = Vector2.ZERO
	player_strip.size = Vector2(width_px, height_px)
	var card_width: float = clampf((width_px - 295.0) * 0.5, 226.0, 428.0)
	for i in range(race_card_panels.size()):
		var card: Dictionary = race_card_panels[i]
		var xx: float = 17.0 if i == 0 else width_px - card_width - 17.0
		card["base"].position = Vector2(xx, card_y)
		card["base"].size = Vector2(card_width, card_height)
		card["base"].visible = not broadcast
		card["expanded"].visible = not broadcast and expanded_context[i] >= 0
		var context: int = int(expanded_context[i])
		var expanded_height: float = 337.0 if context == 2 else (233.0 if context == 1 else 200.0)
		if context == 3:
			expanded_height = 215.0
		expanded_height = minf(expanded_height, maxf(130.0, card_y - 74.0))
		# The strategy pane's real content can require more than the nominal
		# 337 px. The old layout ignored the PanelContainer minimum (369 px),
		# making its actual bottom overlap the driver card by 24 px.
		# Anchor its real rendered height above the lower card instead.
		expanded_height = maxf(expanded_height, (card["expanded"] as Control).get_combined_minimum_size().y)
		# Details rise from each driver and shift toward the circuit to avoid
		# covering the standings on the left or the weather/map on the right.
		var detail_x: float = left_width + 24.0 if i == 0 else width_px - right_width - 24.0 - card_width
		card["expanded"].position = Vector2(detail_x, card_y - expanded_height - 8.0)
		card["expanded"].size = Vector2(card_width, expanded_height)
	background_dimmer.position = Vector2.ZERO
	background_dimmer.size = Vector2(width_px, height_px)
	large_area.position = Vector2.ZERO
	large_area.size = Vector2(width_px, height_px)
	# Contextual windows fit their content, not the entire display.
	var modal_width: float = 710.0
	var modal_height: float = 445.0
	match active_window:
		"corrida":
			modal_width = 675.0
			modal_height = 375.0
		"estrategia":
			modal_width = 1000.0
			modal_height = 580.0
		"dados":
			modal_width = 790.0
			modal_height = 430.0
		"eventos", "radio":
			modal_width = 840.0
			modal_height = 570.0
		"engineer":
			modal_width = 900.0
			modal_height = 710.0
		"pitwall3":
			modal_width = 1060.0
			modal_height = 735.0
		"graficos":
			modal_width = 1190.0
			modal_height = 770.0
		"simulator":
			modal_width = 1250.0
			modal_height = 790.0
	modal_width = minf(modal_width, width_px - 56.0)
	modal_height = minf(modal_height, height_px - 105.0)
	overlay_window.position = Vector2((width_px - modal_width) * 0.5, (height_px - modal_height) * 0.5)
	overlay_window.size = Vector2(modal_width, modal_height)

func update_map(cars: Array, focused: int) -> void:
	if visible:
		minimap.set_cars(cars, focused)

func refresh_hud() -> void:
	if host == null or host.race == null or not visible:
		return
	var race = host.race
	# Snapshots only on completed-lap changes; no RaceEngine mutation.
	dynamic_graph_data.capture(race)
	var clock_value: int = int(race.clock)
	ReBroadcast.set_text_if_changed(lap_label, "V%02d / %02d" % [int(race.lap), int(race.lap_count)])
	var session_text: String = "%02d:%02d:%02d" % [int(clock_value / 3600), int(clock_value / 60) % 60, clock_value % 60]
	if race.running and host.sim_speed >= 10.0:
		var actual_x: float = float(host.effective_speed_x)
		if actual_x > 0.0:
			session_text += " • %.0fx real" % actual_x
		if host.replay_session != null and host.replay_session.cpu_limited:
			session_text += " • CPU"
		speed_label.tooltip_text = "Solicitada: %dx; efetiva recente: %.1fx. A CPU pode limitar a aceleração sem descartar ticks." % [int(host.sim_speed), actual_x]
	else:
		speed_label.tooltip_text = "Velocidade solicitada; 1× é tempo real se a CPU acompanhar."
	ReBroadcast.set_text_if_changed(session_label, session_text)
	ReBroadcast.set_text_if_changed(pause_button, "FIM" if race.finished else ("Ⅱ" if race.running else "▶"))
	ReBroadcast.set_text_if_changed(status_banner,
		"FINAL" if race.finished else ("AO VIVO" if race.running else "PAUSA"))
	pause_button.disabled = bool(race.finished)
	var speed_position: int = SPEEDS.find(float(host.sim_speed))
	if speed_position >= 0 and speed_label.selected != speed_position:
		speed_label.select(speed_position)
	var weather: Dictionary = race.weather_snapshot()
	var weather_brief: String = "%s • %s\nÁgua %.1f mm · umidade %d%%\nChuva %d%% · Prev. %d%% (15m)" % [
		str(weather.get("sky", "—")), str(weather.get("track_state", "—")),
		float(weather.get("water_mm", 0.0)), int(weather.get("surface_moisture_percent", 0)),
		int(round(float(weather.get("rain_intensity", 0.0)) * 100.0)), int(weather.get("rain_probability", 0))]
	ReBroadcast.set_text_if_changed(weather_line, weather_brief)
	weather_line.tooltip_text = "Condição atual, água e umidade medidas; previsão é estimativa."
	var order: Array = race.get_sorted()
	# A scheduled UI order may still be in the deterministic command queue
	# until the next tick. Showing it as confirmed would mislead the player.
	var pending_pits: Dictionary = ReBroadcast.pending_pit_by_driver(host.replay_session)
	ReBroadcast.set_text_if_changed(standings_title, METRICS[metric_index])
	ranking_refreshes += 1
	for i in range(standing_rows.size()):
		var row: Dictionary = standing_rows[i]
		if row["row"].visible != (i < order.size()):
			row["row"].visible = i < order.size()
		if i >= order.size():
			continue
		var car: Dictionary = order[i]
		var mini: TextureRect = row["portrait"]
		if host.portrait_manager != null:
			# The PortraitManager caches textures; the ranking does not decode PNG every tick.
			var driver_name: String = str(car.get("name", ""))
			var photo: Texture2D = host.portrait_manager.get_photo(driver_name)
			if mini.texture != photo:
				mini.texture = photo
				mini.tooltip_text = driver_name
			mini.visible = photo != null
		elif mini.visible:
			mini.visible = false
		var official_abbr: String = ""
		if host.portrait_manager != null:
			official_abbr = host.portrait_manager.get_abbreviation(str(car.get("name", "")))
		ranking_field_writes += ReBroadcast.update_row(row, car, i, str(host.selected_team),
			_standing_value(order, i), _compound(str(car.get("tire", "Médio"))),
			int(host.manual_driver), rank_idle_style, rank_selected_style,
			pending_pits.get(int(car.get("id", -1)), {}), official_abbr)
	for i in range(race_card_panels.size()):
		var card: Dictionary = race_card_panels[i]
		var car: Dictionary = _driver_from_slot(i)
		if car.is_empty():
			continue
		card["name"].text = str(car.get("name", "Piloto"))
		card["pos"].text = "P%02d" % int(car.get("position", 0))
		var tire: String = str(car.get("tire", "Médio"))
		var pending: Dictionary = pending_pits.get(int(car.get("id", -1)), {})
		var pit_text: String = "BOX CHAMADO" if bool(car.get("pit_request", false)) else ("PIT V%d" % int(car.get("pit_scheduled_lap", 0)) if int(car.get("pit_scheduled_lap", 0)) > 0 else str(car.get("pace", "Normal")))
		if not pending.is_empty():
			pit_text = "ORDEM PENDENTE " + ReBroadcast.pending_label(pending)
		var warning: String = "⚠ CRÍTICO " if float(car.get("wear", 0.0)) >= 90.0 else ("⚠ " if float(car.get("wear", 0.0)) >= 75.0 else "")
		card["status"].text = "%s%s · %dv • desgaste %d%%" % [warning, _compound(tire), int(car.get("stint_laps", 0)), int(round(float(car.get("wear", 0.0))))]
		card["status"].tooltip_text = "PNEU ATUAL: %s (%d voltas). Planejado: %s. Controle: %s" % [tire, int(car.get("stint_laps", 0)), str(car.get("pit_target", "—")), str(car.get("pit_control_mode", "Manual"))]
		card["secondary"].text = "Ritmo %s  •  %s" % [str(car.get("pace", "Normal")), pit_text if pit_text != str(car.get("pace", "Normal")) else "Pista"]
		(card["wear_bar"] as ProgressBar).value = clampf(100.0 - float(car.get("wear", 0.0)), 0.0, 100.0)
		card["quick"].disabled = bool(car.get("finished", false)) or bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0 or not pending.is_empty()
		card["quick"].tooltip_text = ReBroadcast.pending_description(pending) if not pending.is_empty() else "Solicitar box na próxima entrada permitida"
		_update_driver_context(i)
	_update_engineer_reports()
	_announce_soul_requests()
	_update_reactive_radio()
	if radio_reactive_toast != null and radio_reactive_toast.visible and Time.get_ticks_msec() >= radio_reactive_toast_until:
		radio_reactive_toast.hide()
	if active_window != "":
		_update_window_data()

func _standing_value(sorted_cars: Array, idx: int) -> String:
	var car: Dictionary = sorted_cars[idx]
	var final: bool = host != null and host.race != null and bool(host.race.finished)
	match metric_index:
		0: return "—" if idx == 0 else (str(car.get("interval_label", "")) if final else "+%.2fs" % float(car.get("interval", 0.0)))
		1: return "—" if idx == 0 else (str(car.get("gap_label", "")) if final else "+%.2fs" % float(car.get("gap", 0.0)))
		2: return str(int(car.get("stops", 0)))
		3: return host._format_lap(float(car.get("best_lap", 9999.0)))
		4: return "%s %d" % [_compound(str(car.get("tire", "Médio"))), int(car.get("stint_laps", 0))]
		5:
			if idx >= sorted_cars.size() - 1:
				return "—"
			var behind: Dictionary = sorted_cars[idx + 1]
			return str(behind.get("interval_label", "")) if final else "+%.2fs" % float(behind.get("interval", 0.0))
		6:
			var last_time: float = float(car.get("last_lap", 0.0))
			return host._format_lap(last_time) if last_time > 0.0 and last_time < 9999.0 else "—"
	return "—"

func _compound(tire: String) -> String:
	return str(host.race.tyre_code(tire)) if host != null and host.race != null else tire.left(1)

func _update_driver_context(slot: int) -> void:
	if slot < 0 or slot >= race_card_panels.size():
		return
	var card: Dictionary = race_card_panels[slot]
	var mode: int = int(card.get("context", -1))
	if mode < 0 or expanded_context[slot] < 0:
		return
	var car: Dictionary = _driver_from_slot(slot)
	if car.is_empty():
		return
	var values: Array = []
	if mode == 0:
		var sectors: Dictionary = host.race.telemetry.latest_sectors(int(car["id"])) if host.race.telemetry != null else {}
		var sector_line := ""
		for i in range(1, 4):
			if i > 1:
				sector_line += "  "
			sector_line += "S%d %s" % [i, host._format_lap(float(sectors.get("s%d" % i, 9999.0)))]
		values = [host._format_lap(float(car.get("last_lap", 9999.0))), host._format_lap(float(car.get("best_lap", 9999.0))), sector_line, str(int(car.get("laps_done", 0)))]
	elif mode == 1:
		var energy: Dictionary = host.race.get_race_control_status(int(car["id"]))
		var pace: String = str(car.get("pace", "Normal"))
		var reference: String = str(car.get("ai_plan", {}).get("pace", "Sem previsão"))
		var traffic: String = str(car.get("combat_state", "clear"))
		var energy_line: String = "KERS %dkJ | DRS %s" % [int(energy.get("kers_remaining_kj", 0)), "ON" if bool(energy.get("drs_active", false)) else "OFF"]
		values = [pace, reference, "Disputa" if traffic in ["duel", "attacking", "defending"] else "Pista livre", energy_line]
		if card.has("pace_picker") and is_instance_valid(card["pace_picker"]):
			var index: int = ["Conservar", "Normal", "Atacar"].find(pace)
			if index >= 0:
				card["pace_picker"].select(index)
			card["pace_picker"].disabled = host._engineer_mode_for(int(car["id"])) != "Manual"
	elif mode == 2:
		var pit_state: String = "BOX CHAMADO" if bool(car.get("pit_request", false)) else ("V%d programada" % int(car.get("pit_scheduled_lap", 0)) if int(car.get("pit_scheduled_lap", 0)) > 0 else "Sem parada marcada")
		var advice: Dictionary = host.race.get_engineer_advice(int(car["id"]))
		var life: float = float(advice.get("life_laps", -1.0))
		values = [pit_state, ("%.1f voltas" % life if life >= 0.0 else "Sem estimativa")]
		if card.has("pit_mode_picker"):
			var pit_mode: OptionButton = card["pit_mode_picker"]
			pit_mode.select(1 if str(car.get("pit_control_mode", "Manual")) == "IA" else 0)
			pit_mode.disabled = host._engineer_mode_for(int(car["id"])) == "Automático"
		if card.has("advice_label"):
			(card["advice_label"] as Label).text = str(advice.get("message", "Aguardando dados"))
	elif mode == 3:
		var compound: String = str(car.get("tire", "Médio"))
		var garage_state: Dictionary = host.garage.get_team(host.selected_team)
		var levels: Dictionary = garage_state.get("levels", {})
		values = [compound, "%dv • %d%%" % [int(car.get("stint_laps", 0)), int(round(float(car.get("wear", 0.0))))], "Motor nível %d" % int(levels.get("Motor", 0)), "Não modelados neste motor"]
	var labels: Array = card.get("data_labels", [])
	for idx in range(mini(labels.size(), values.size())):
		(labels[idx] as Label).text = str(values[idx])
		(labels[idx] as Label).tooltip_text = str(values[idx])

func _change_hud_mode(index: int) -> void:
	hud_mode = clampi(index, 0, 2)
	if hud_mode_picker != null and hud_mode_picker.selected != hud_mode:
		hud_mode_picker.select(hud_mode)
	var write_status: Error = ReBroadcast.save_mode(hud_mode)
	if write_status != OK:
		push_warning("APEX HUD: preferência não pôde ser gravada (%d)" % write_status)
	layout_hud()


func _move_metric(step: int) -> void:
	metric_index = posmod(metric_index + step, METRICS.size())
	refresh_hud()

func _select_grid_car(index: int) -> void:
	if host.race == null:
		return
	host._on_position_pressed(index)

func _quick_box(slot: int) -> void:
	var car: Dictionary = _driver_from_slot(slot)
	if car.is_empty():
		return
	var target: String = str(race_card_panels[slot].get("target_tire", car.get("pit_target", "Médio")))
	host.race.order_pit(int(car["id"]), target)
	refresh_hud()

func _pick_tire(index: int, slot: int) -> void:
	var card: Dictionary = race_card_panels[slot]
	var picker: OptionButton = card["tire_picker"]
	card["target_tire"] = picker.get_item_text(index)

func _schedule(slot: int) -> void:
	var card: Dictionary = race_card_panels[slot]
	var car: Dictionary = _driver_from_slot(slot)
	if car.is_empty() or card["lap_picker"] == null:
		return
	var target: String = str(card.get("target_tire", car.get("pit_target", "Médio")))
	host.race.schedule_pit(int(car["id"]), target, int((card["lap_picker"] as SpinBox).value))
	refresh_hud()

func _cancel_pit(slot: int) -> void:
	var car: Dictionary = _driver_from_slot(slot)
	if not car.is_empty():
		host.race.cancel_scheduled_pit(int(car["id"]))
		refresh_hud()

func _driver_pit_mode(index: int, slot: int) -> void:
	var car: Dictionary = _driver_from_slot(slot)
	if not car.is_empty():
		host._change_pit_mode(index, int(car["id"]))
		refresh_hud()

func _set_pace(index: int, slot: int) -> void:
	var car: Dictionary = _driver_from_slot(slot)
	if not car.is_empty():
		host._change_pace(index, int(car["id"]))
		refresh_hud()

func _kers(slot: int) -> void:
	var car: Dictionary = _driver_from_slot(slot)
	if not car.is_empty():
		host._cycle_kers_mode(int(car["id"]))
		refresh_hud()

func _follow(id: int) -> void:
	host._focus_driver(id)

func _pause() -> void:
	host._toggle_race()
	refresh_hud()

func _pick_speed(index: int) -> void:
	host._change_speed(index)
	refresh_hud()

func _step_speed(direction: int) -> void:
	var current: int = SPEEDS.find(float(host.sim_speed))
	if current < 0:
		current = 2
	speed_index = clampi(current + direction, 0, SPEEDS.size() - 1)
	host._change_speed(speed_index)
	refresh_hud()

func _set_team_mode(index: int) -> void:
	team_mode_picker.select(index)
	host._select_live_team_mode(index)

func _set_view(index: int) -> void:
	if index == 0:
		host.visual_picker.select(1)
		host._change_visual_setting(1)
	elif index == 1:
		host.visual_picker.select(3)
		host._change_visual_setting(3)
		# The aerial preset follows race action by default. "Livre" is still
		# available separately in CORRIDA > CÂMERA.
		host.mode_picker.select(2)
		host._change_camera_mode(2)
	else:
		host.visual_picker.select(2)
		host._change_visual_setting(2)
		host.mode_picker.select(2)
		host._change_camera_mode(2)
	view_picker.select(index)

func _zoom(scale: float) -> void:
	host._zoom_by(scale)

func _menu() -> void:
	_close_window()
	host._end_to_menu()

func _close_window() -> void:
	active_window = ""
	background_dimmer.hide()
	large_area.hide()

func _open_window(which: String) -> void:
	if active_window == which:
		_close_window()
		return
	active_window = which
	background_dimmer.show()
	large_area.show()
	for child in overlay_content.get_children():
		overlay_content.remove_child(child)
		child.queue_free()
	modal_driver_rows.clear()
	modal_timeline = null
	match which:
		"corrida": _build_race_window()
		"estrategia": _build_strategy_window()
		"pitwall3": _build_pitwall3_window()
		"graficos": _build_dynamic_graphs_window()
		"simulator": _build_strategy_simulator_window()
		"dados": _build_data_window()
		"eventos": _build_events_window()
		"radio": _build_radio_window()
		"engineer": _build_engineer_window()
	layout_hud()
	_update_window_data()

func _build_race_window() -> void:
	overlay_title.text = "CONTROLE DA CORRIDA"
	_text(overlay_content, "Visão, câmera e delegação de decisões. Atalhos: M (visual), R (centralizar), Espaço (pausar).", 12, MUTED)
	_text(overlay_content, "VISUALIZAÇÃO", 12, ACCENT)
	var views := _line(overlay_content, 8)
	var auto_button: Button = _btn(views, "AUTO", _choose_auto_view_window, 83)
	auto_button.tooltip_text = "1x a 5x: transmissão 3D. 10x a 32x: mapa 2D otimizado."
	_btn(views, "MAPA 2D", _choose_view_window.bind(0), 124)
	_btn(views, "AÉREA 3D", _choose_view_window.bind(1), 124)
	_btn(views, "DIRETOR TV", _choose_view_window.bind(2), 128)
	_text(overlay_content, "CÂMERA", 12, ACCENT)
	var cams := _line(overlay_content, 8)
	_btn(cams, "LIVRE", _choose_camera_mode.bind(0), 125)
	_btn(cams, "SEGUIR", _choose_camera_mode.bind(1), 125)
	_btn(cams, "DIRETOR", _choose_camera_mode.bind(2), 125)
	var zoom_row := _line(overlay_content, 7)
	_btn(zoom_row, "− ZOOM", _zoom.bind(0.83), 105)
	_btn(zoom_row, "+ ZOOM", _zoom.bind(1.20), 105)
	_btn(zoom_row, "CENTRALIZAR", _center_camera, 155)
	var team_line := _line(overlay_content, 8)
	_text(team_line, "CONTROLE DO STAFF", 12, ACCENT)
	var live_mode := _select(team_line, ["MANUAL", "AUTO"], _set_team_mode)
	live_mode.select(1 if host.team_control_mode == "Automático" else 0)
	_btn(team_line, "MENU PRINCIPAL", _menu, 145)

func _center_camera() -> void:
	host._reset_camera()

func _choose_view_window(index: int) -> void:
	_set_view(index)
	_close_window()

func _choose_auto_view_window() -> void:
	# Return explicitly to speed-aware Auto after a manual camera choice.
	host.visual_picker.select(0)
	host._change_visual_setting(0)
	view_picker.select(0 if host.render_mode == 0 else 1)
	_close_window()

func _choose_camera_mode(index: int) -> void:
	host.mode_picker.select(index)
	host._change_camera_mode(index)
	_close_window()

func _build_strategy_window() -> void:
	overlay_title.text = "ESTRATÉGIA — OS DOIS CARROS"
	_text(overlay_content, "Cor sólida = stint realizado. Transparência = parada agendada; área cinza = futuro sem plano.", 12, MUTED)
	modal_timeline = Stints.new()
	modal_timeline.custom_minimum_size = Vector2(680, 155)
	modal_timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_content.add_child(modal_timeline)
	_text(overlay_content, "PLANEJAR PARADAS", 14, ACCENT)
	for i in range(mini(2, host.race.player_cars().size())):
		var car: Dictionary = host.race.player_cars()[i]
		var frame := _panel(overlay_content, HudSkin.SURFACE_ALT)
		var content := _column(frame, 5)
		var name := _text(content, str(car.get("name", "Piloto")), 14, WHITE)
		var briefing := _text(content, "", 11, MUTED)
		briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var commands := _line(content, 7)
		_text(commands, "Pneu", 11, MUTED)
		var compounds: Array = host.race.available_pit_compounds()
		var tire_select := _select(commands, compounds, func(_n): pass)
		tire_select.custom_minimum_size.x = 150
		tire_select.select(maxi(0, compounds.find(_hud_tire_for(int(car["id"]), str(car.get("pit_target", "Duro"))))))
		tire_select.item_selected.connect(_sync_modal_tire.bind(int(car["id"]), tire_select))
		_text(commands, "Volta", 11, MUTED)
		var lap := SpinBox.new()
		lap.min_value = 1
		lap.max_value = maxi(1, int(host.race.lap_count) - 1)
		lap.value = minf(float(lap.max_value), float(int(car.get("laps_done", 0)) + 2))
		lap.custom_minimum_size.x = 88
		commands.add_child(lap)
		_btn(commands, "AGENDAR", _modal_schedule.bind(int(car["id"]), tire_select, lap), 96)
		var quick := _btn(commands, "CHAMAR BOX", _modal_pit.bind(int(car["id"]), tire_select), 119)
		_btn(commands, "CANCELAR", _modal_cancel.bind(int(car["id"])), 90)
		modal_driver_rows.append({"id":int(car["id"]), "name":name, "briefing":briefing, "pit":quick, "lap":lap})
	var launch := _line(overlay_content, 8)
	_btn(launch, "ABRIR PIT WALL 3.0 · CENÁRIOS", _open_window.bind("pitwall3"), 285)
	_btn(launch, "GRÁFICOS DINÂMICOS 9.8", _open_window.bind("graficos"), 210)
	_btn(launch, "SIMULADOR 9.9", _open_window.bind("simulator"), 155)
	_text(launch, "Projeções de tráfego e coordenação dos dois carros (estimativas, não certezas).", 11, MUTED)

func _hud_tire_for(id: int, fallback: String) -> String:
	for card in race_card_panels:
		if int(card["id"]) == id:
			return str(card.get("target_tire", fallback))
	return fallback

func _sync_modal_tire(index: int, id: int, picker: OptionButton) -> void:
	for card in race_card_panels:
		if int(card["id"]) == id:
			card["target_tire"] = picker.get_item_text(index)
			break

func _modal_schedule(id: int, tire_select: OptionButton, lap: SpinBox) -> void:
	host.race.schedule_pit(id, tire_select.get_item_text(tire_select.selected), int(lap.value))
	refresh_hud()

func _modal_pit(id: int, tire_select: OptionButton) -> void:
	host.race.order_pit(id, tire_select.get_item_text(tire_select.selected))
	refresh_hud()

func _modal_cancel(id: int) -> void:
	host.race.cancel_scheduled_pit(id)
	refresh_hud()

func _build_data_window() -> void:
	overlay_title.text = "CENTRAL DE DADOS"
	var weather: Dictionary = host.race.weather_snapshot()
	_text(overlay_content, "CLIMA E PISTA", 15, ACCENT)
	_text(overlay_content, "Céu: %s • Pista: %s • Chuva atual: %d%% • Previsão 15 min: %d%%" % [str(weather.get("sky", "—")), str(weather.get("track_state", "—")), int(round(float(weather.get("rain_intensity", 0.0)) * 100.0)), int(weather.get("rain_probability", 0))], 13)
	_text(overlay_content, "Água na linha %.2f mm • Fora da linha %.2f mm • Umidade residual %d%%" % [float(weather.get("water_mm", 0.0)), float(weather.get("off_line_water_mm", 0.0)), int(weather.get("surface_moisture_percent", 0))], 13, ACCENT)
	var forecast_water: Dictionary = host.race.weather.forecast(host.race.clock, minf(900.0, host.race.base_lap * 3.0))
	_text(overlay_content, "Água prevista em ~3 voltas: %.2f mm • Variação: %+.2f mm • Chuva esperada: %d%%" % [float(forecast_water.get("water_mm", 0.0)), float(forecast_water.get("water_trend_mm", 0.0)), int(round(float(forecast_water.get("rain_intensity", 0.0))*100.0))], 12, MUTED)
	_text(overlay_content, "SLICK: linha seca | INTER: água moderada | CHUVA: água acumulada. Níveis estimados por modelo próprio, não telemetria FIA.", 11, MUTED)
	_text(overlay_content, "Ar %.1f°C  •  Pista %.1f°C  •  Vento %.1f km/h  •  Aderência %s" % [float(weather.get("air_c", 0.0)), float(weather.get("track_c", 0.0)), float(weather.get("wind", 0.0)), str(weather.get("grip", "—"))], 12, MUTED)
	_text(overlay_content, "Borracha %d%%  •  Aderência relativa %.3f  •  Abrasão %.2f" % [int(weather.get("rubber", 0)), float(weather.get("grip_factor", 1.0)), float(weather.get("surface_abrasion", 1.0))], 11, MUTED)
	_text(overlay_content, "TELEMETRIA DA EQUIPE", 15, ACCENT)
	for car in host.race.player_cars():
		_text(overlay_content, "%s  |  Última %s  |  Melhor %s  |  Posição P%d" % [str(car.get("name", "—")), host._format_lap(float(car.get("last_lap", 9999.0))), host._format_lap(float(car.get("best_lap", 9999.0))), int(car.get("position", 0))], 12)
		_text(overlay_content, "Temperatura do pneu: superfície %.1f°C / núcleo %.1f°C  •  graining %d%%  •  blister %d%%" % [float(car.get("tyre_surface_c", 0.0)), float(car.get("tyre_core_c", 0.0)), int(round(float(car.get("tyre_graining", 0.0)) * 100.0)), int(round(float(car.get("tyre_blistering", 0.0)) * 100.0))], 11, MUTED)
	_text(overlay_content, "PIT STOPS DA EQUIPE", 15, ACCENT)
	for car in host.race.player_cars():
		_text(overlay_content, "%s: %d paradas | %s | desgaste %d%%" % [str(car.get("name", "—")), int(car.get("stops", 0)), str(car.get("tire", "—")), int(float(car.get("wear", 0.0)))], 12)
	_text(overlay_content, "As informações são amostras do motor de corrida; abra novamente para atualizar este relatório.", 11, MUTED)

func _build_events_window() -> void:
	overlay_title.text = "EVENTOS DA CORRIDA"
	_text(overlay_content, "Registros gerados por acontecimentos da simulação.", 12, MUTED)
	if host.race.events.is_empty():
		_text(overlay_content, "Sem eventos no momento.", 12)
		return
	var events: Array = host.race.events
	for i in range(events.size() - 1, maxi(-1, events.size() - 31), -1):
		var item: Dictionary = events[i]
		var time: int = int(item.get("time", 0))
		_text(overlay_content, "%02d:%02d  •  %s" % [int(time / 60), time % 60, str(item.get("message", ""))], 12)

func _build_radio_window() -> void:
	overlay_title.text = "RÁDIO — PERGUNTAR AO ENGENHEIRO"
	_text(overlay_content, "Consultas não emitem ordens. AUTORIZAR PASSAGEM executa apenas com clique explícito; revogável.", 11, MUTED)
	var driver_line := _line(overlay_content, 8)
	_text(driver_line, "PILOTO", 11, ACCENT)
	radio_driver_ids.clear()
	radio_driver_picker = OptionButton.new()
	radio_driver_picker.custom_minimum_size.x = 250
	radio_driver_picker.add_theme_font_size_override("font_size", 12)
	for car in host.race.player_cars():
		radio_driver_ids.append(int(car.get("id", -1)))
		radio_driver_picker.add_item(str(car.get("name", "Piloto")))
	driver_line.add_child(radio_driver_picker)
	radio_driver_picker.item_selected.connect(_radio_driver_changed)
	_btn(driver_line, "OUVIR PILOTO", _ask_driver, 147).tooltip_text = "Consultar a percepção do piloto e comparar com a telemetria; sem executar ordens"
	radio_only_button = _btn(driver_line, "SÓ ESTE: NÃO", _toggle_radio_driver_filter, 119)
	radio_only_button.tooltip_text = "Filtrar as mensagens de Equipe e Pilotos pelo piloto selecionado"
	_refresh_radio_filter_button()
	# Driver Identity Pack 2012 — portrait is a real person, downloaded by
	# the user from Wikimedia Commons; otherwise display neutral initials.
	var identity_row := _line(overlay_content, 10)
	var identity_frame := _panel(identity_row, Color("#101C2A"))
	var identity_box := _column(identity_frame, 1)
	radio_portrait_texture = TextureRect.new()
	radio_portrait_texture.custom_minimum_size = Vector2(90, 110)
	radio_portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	radio_portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	identity_box.add_child(radio_portrait_texture)
	radio_portrait_placeholder = _text(identity_box, "—", 17, WHITE)
	radio_portrait_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	radio_identity_info = _text(identity_row, "Temporada 2012 • foto opcional de pessoa real", 12, WHITE)
	radio_identity_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_identity_info.custom_minimum_size = Vector2(260, 60)
	radio_identity_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refresh_radio_identity()
	var questions := _line(overlay_content, 5)
	for topic in ["pneus", "ritmo", "trafego", "box"]:
		var button := _btn(questions, str(EngineerInteractive.QUESTIONS[topic]), _ask_engineer.bind(topic))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "Consultar o engenheiro sem alterar o comando da equipe"
	var discuss_line := _line(overlay_content, 8)
	_btn(discuss_line, "DISCUTIR STINT", _discuss_stint, 162).tooltip_text = "Confrontar sensação fictícia e telemetria; não executa box"
	_btn(discuss_line, "COMPARAR COMPANHEIRO", _compare_teammate, 194).tooltip_text = "Análise consultiva; não executa ordens"
	_text(discuss_line, "Discussões não executam ordens.", 11, MUTED)
	var order_line := _line(overlay_content, 8)
	_btn(order_line, "AUTORIZAR NÃO DEFENDER", _authorize_teammate_pass, 194).tooltip_text = "Ordem REAL do jogador: líder não bloqueia agressivamente o companheiro por até 15s. Exige vantagem de ritmo comprovada."
	_btn(order_line, "CANCELAR AUTORIZAÇÃO", _cancel_teammate_pass, 172).tooltip_text = "Cancelar no próximo tick a autorização ativa; não altera BOX"
	var response_line := _line(overlay_content, 8)
	_btn(response_line, "APOIAR PILOTO", _answer_stint.bind("piloto"), 139).tooltip_text = "Reconhecer a opinião do piloto no rádio; não altera o ritmo, pneus ou estratégia"
	_btn(response_line, "PRIORIZAR DADOS", _answer_stint.bind("engenheiro"), 153).tooltip_text = "Dar prioridade à telemetria no diálogo; não envia ordens"
	_text(response_line, "Primeiro discuta o stint; escolha como responder.", 11, MUTED)
	radio_soul_status = _text(overlay_content, "Apex Soul: estado ficcional do piloto, só para o rádio.", 11, ACCENT)
	radio_soul_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_soul_status.custom_minimum_size.y = 38
	var request_row := _line(overlay_content, 7)
	_btn(request_row, "OUVIR PEDIDO", _answer_soul_request.bind("ouvir"), 125).tooltip_text = "Reconhece a solicitação do piloto. Nenhum comando é enviado."
	_btn(request_row, "EXPLICAR PLANO", _answer_soul_request.bind("explicar"), 148).tooltip_text = "Resposta do pit wall no rádio; não muda a estratégia."
	_text(request_row, "Pedidos consultivos · sem ordens automáticas.", 11, MUTED)
	radio_soul_request_label = _text(overlay_content, "SOUL 2.0 · Aguardando pedido do piloto.", 11, SOUL_ACCENT)
	radio_soul_request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_soul_request_label.custom_minimum_size.y = 38
	_update_soul_status()
	radio_reactive_label = _text(overlay_content, "RÁDIO ESPONTÂNEO · " + radio_reactive_latest, 11, YELLOW)
	radio_reactive_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_reactive_label.custom_minimum_size.y = 36
	radio_response_label = _text(overlay_content, "Selecione o piloto e faça uma pergunta.", 12, WHITE)
	radio_response_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_response_label.custom_minimum_size.y = 61
	_text(overlay_content, "HISTÓRICO DE RÁDIO", 11, ACCENT)
	var categories := _line(overlay_content, 6)
	radio_category_buttons.clear()
	for i in range(4):
		var label: String = ["TODOS", "TRANSMISSÃO", "EQUIPE", "PILOTOS"][i]
		var b := _btn(categories, label, _set_radio_category.bind(i))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = ["Todos os eventos", "Narrador, analista e boxes da transmissão", "Comunicações internas da equipe", "Apenas mensagens dos seus pilotos"][i]
		radio_category_buttons.append(b)
	radio_history = RichTextLabel.new()
	radio_history.bbcode_enabled = true
	radio_history.fit_content = false
	radio_history.scroll_following = true
	radio_history.custom_minimum_size.y = 245
	radio_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	radio_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_content.add_child(radio_history)
	_set_radio_category(radio_category)

func _set_radio_category(index: int) -> void:
	radio_category = clampi(index, 0, 3)
	for i in range(radio_category_buttons.size()):
		var b: Button = radio_category_buttons[i]
		var active: bool = i == radio_category
		b.add_theme_stylebox_override("normal", _frame(Color("#55321D") if active else HudSkin.SURFACE_ALT, 5))
		b.add_theme_color_override("font_color", ACCENT if active else WHITE)
	_refresh_radio_filter_button()
	_refresh_interactive_history()

func _refresh_radio_identity() -> void:
	if radio_portrait_texture == null or not is_instance_valid(radio_portrait_texture):
		return
	if radio_driver_picker == null or host == null or host.race == null or host.portrait_manager == null:
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var driver_id: int = radio_driver_ids[index]
	var driver_name: String = ""
	for car in host.race.player_cars():
		if int(car.get("id", -1)) == driver_id:
			driver_name = str(car.get("name", ""))
			break
	if driver_name.is_empty():
		return
	var info: Dictionary = host.portrait_manager.get_info(driver_name)
	var photo: Texture2D = host.portrait_manager.get_photo(driver_name)
	radio_portrait_texture.texture = photo
	radio_portrait_texture.visible = photo != null
	if radio_portrait_placeholder != null:
		var bits: PackedStringArray = driver_name.split(" ", false)
		radio_portrait_placeholder.text = str(info.get("abbr", bits[bits.size()-1].left(3).to_upper()))
		radio_portrait_placeholder.visible = photo == null
	var detail: String = "%s  •  #%d  •  %s  •  %s" % [
		driver_name, int(info.get("number", 0)),
		str(info.get("abbr", "---")), str(info.get("country", "---"))]
	if photo != null:
		detail += "\n" + host.portrait_manager.get_credit(driver_name)
		radio_portrait_texture.tooltip_text = host.portrait_manager.get_source_url(driver_name)
	else:
		detail += "\nFoto ainda não baixada: apenas iniciais, sem carros."
	radio_identity_info.text = detail

func _radio_driver_changed(_index: int) -> void:
	_refresh_radio_identity()
	if radio_response_label != null and is_instance_valid(radio_response_label):
		radio_response_label.text = "Selecione uma pergunta para consultar o piloto ou o engenheiro."
	_update_soul_status()
	_refresh_interactive_history()

func _toggle_radio_driver_filter() -> void:
	radio_only_selected = not radio_only_selected
	_refresh_radio_filter_button()
	_refresh_interactive_history()

func _refresh_radio_filter_button() -> void:
	if radio_only_button != null and is_instance_valid(radio_only_button):
		radio_only_button.text = "SÓ ESTE: SIM" if radio_only_selected else "SÓ ESTE: NÃO"
		radio_only_button.disabled = radio_category < 2

func _selected_radio_id() -> int:
	if not radio_only_selected or radio_category < 2 or radio_driver_picker == null or radio_driver_ids.is_empty():
		return -1
	var index: int = radio_driver_picker.selected
	return radio_driver_ids[index] if index >= 0 and index < radio_driver_ids.size() else -1

func _soul_profile(car_id: int) -> Dictionary:
	if not radio_soul_profiles.has(car_id):
		radio_soul_profiles[car_id] = SoulDriver.initial_profile(car_id)
	return radio_soul_profiles[car_id]

func _announce_soul_requests() -> void:
	# A alma existe no motor, mesmo sem a janela de rádio aberta; o HUD
	# registra uma única emissão por identificador de pedido e por piloto.
	if host == null or host.race == null or not host.race.running or host.race.finished:
		return
	for car in host.race.player_cars():
		var car_id: int = int(car.get("id", -1))
		var request: Dictionary = DriverSoul2.latest(car)
		var seq: int = int(request.get("id", 0))
		if seq <= 0 or seq <= int(radio_soul_notified.get(car_id, 0)):
			continue
		radio_soul_notified[car_id] = seq
		var name: String = str(car.get("name", "Piloto"))
		var message: String = str(request.get("message", ""))
		var reason: String = str(request.get("reason", ""))
		radio_reactive_latest = "PEDIDO · %s: %s" % [name, message]
		if radio_reactive_toast != null:
			radio_reactive_toast.text = "📻  %s: %s" % [name, message]
			radio_reactive_toast.tooltip_text = reason + " · Clique para abrir o rádio."
			radio_reactive_toast_until = Time.get_ticks_msec() + 9000
			radio_reactive_toast.show()
		if host.commentary != null:
			host.commentary.add_soul_spontaneous(float(host.race.clock), name, message,
				"Pedido recebido para análise, nenhuma ordem foi executada.", car_id)
		if active_window == "radio":
			_update_soul_status()


func _answer_soul_request(choice: String) -> void:
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var car_id: int = int(radio_driver_ids[index])
	var car: Dictionary = host._car_by_id(car_id)
	var request: Dictionary = DriverSoul2.latest(car)
	if request.is_empty():
		radio_response_label.text = "O piloto ainda não apresentou pedido contextual."
		return
	var answer: Dictionary = DriverSoul2.respond(car, int(request.get("id", 0)), choice)
	if not bool(answer.get("applied", false)):
		radio_response_label.text = str(answer.get("reason", "Pedido já respondido."))
		return
	var name: String = str(car.get("name", "Piloto"))
	radio_response_label.text = "%s: %s\nENGENHEIRO: %s" % [
		name, str(answer.get("driver", "")), str(answer.get("engineer", ""))]
	if host.commentary != null:
		host.commentary.add_soul_alignment(float(host.race.clock), name,
			"Pedido %s — %s" % [str(request.get("kind", "")), choice],
			str(answer.get("driver", "")), str(answer.get("engineer", "")), car_id)
	_update_soul_status()
	_set_radio_category(2)


func _update_reactive_radio() -> void:
	# Executa com a corrida em andamento, inclusive com a janela de rádio fechada.
	# Não interfere na física/IA, não agenda nem executa pit stops.
	if host == null or host.race == null or not host.race.running or host.race.finished:
		return
	var now: float = float(host.race.clock)
	if now - radio_reactive_last_check < 2.0 and now >= radio_reactive_last_check:
		return
	radio_reactive_last_check = now
	var snapshot: Dictionary = host.race.get_state_snapshot()
	var fresh_events: Array = []
	if host.race.telemetry != null:
		fresh_events = host.race.telemetry.events_since(radio_reactive_event_id)
	else:
		for event in snapshot.get("recent_events", []):
			if int(event.get("event_id", 0)) > radio_reactive_event_id:
				fresh_events.append(event)
	for event in fresh_events:
		radio_reactive_event_id = maxi(radio_reactive_event_id, int(event.get("event_id", 0)))
	for car in host.race.player_cars():
		var car_id: int = int(car.get("id", -1))
		var current: Dictionary = radio_reactive_memories.get(car_id, {})
		var radio_profile: Dictionary = _soul_profile(car_id).duplicate(true)
		var emotion: Dictionary = car.get("driver_soul", {})
		radio_profile["confidence"] = clampf(float(radio_profile.get("confidence", 0.55)) + (float(emotion.get("confidence", 0.55)) - 0.55) * 0.4 - float(emotion.get("pressure", 0.0)) * 0.1, 0.2, 0.9)
		var result: Dictionary = SoulReactive.observe(car_id, snapshot, radio_profile, current, fresh_events)
		radio_reactive_memories[car_id] = result.get("memory", current)
		if not bool(result.get("emitted", false)):
			continue
		var name: String = str(result.get("car_name", "Piloto"))
		var driver_words: String = str(result.get("message", ""))
		var engineer_words: String = str(result.get("engineer", ""))
		radio_reactive_latest = "%s · %s: %s" % [str(result.get("kind", "alerta")).to_upper(), name, driver_words]
		if radio_reactive_toast != null:
			radio_reactive_toast.text = "📻  %s: %s" % [name, driver_words]
			radio_reactive_toast.tooltip_text = radio_reactive_latest + " · Clique para abrir o rádio"
			radio_reactive_toast_until = Time.get_ticks_msec() + 9000
			radio_reactive_toast.show()
		if host.commentary != null:
			host.commentary.add_soul_spontaneous(now, name, driver_words, engineer_words, car_id)
		if active_window == "radio" and radio_reactive_label != null and is_instance_valid(radio_reactive_label):
			radio_reactive_label.text = "RÁDIO ESPONTÂNEO · " + radio_reactive_latest

func _update_soul_status() -> void:
	if radio_soul_status == null or not is_instance_valid(radio_soul_status):
		return
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		radio_soul_status.text = "Apex Soul: aguardando piloto."
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var car_id: int = radio_driver_ids[index]
	radio_soul_status.text = SoulDriver.status(car_id, host.race.get_state_snapshot(), _soul_profile(car_id))
	var car: Dictionary = host._car_by_id(car_id)
	radio_soul_status.text += "\n" + DriverSoul2.summary(car)
	if radio_soul_request_label != null and is_instance_valid(radio_soul_request_label):
		var request: Dictionary = DriverSoul2.latest(car)
		if request.is_empty():
			radio_soul_request_label.text = "SOUL 2.0 · Nenhum pedido contextual nesta corrida."
		else:
			radio_soul_request_label.text = "V%d · %s: %s [%s]" % [
				int(request.get("lap", 0)), str(request.get("kind", "")).to_upper(),
				str(request.get("message", "")),
				"RESPONDIDO" if bool(request.get("answered", false)) else "AGUARDANDO RESPOSTA"]
	radio_soul_last_refresh = float(host.race.clock)

func _answer_stint(choice: String) -> void:
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var car_id: int = radio_driver_ids[index]
	var result: Dictionary = SoulDriver.choose(_soul_profile(car_id), choice)
	if not bool(result.get("applied", false)):
		radio_response_label.text = str(result.get("reason", "Aguardando discussão."))
		return
	radio_soul_profiles[car_id] = result["profile"]
	var snapshot: Dictionary = host.race.get_state_snapshot()
	var driver_name: String = "Piloto"
	for item in snapshot.get("cars", []):
		if int(item.get("id", -1)) == car_id:
			driver_name = str(item.get("name", "Piloto"))
			break
	radio_response_label.text = "%s: %s\nENGENHEIRO: %s" % [driver_name, str(result["driver"]), str(result["engineer"])]
	if host.commentary != null:
		host.commentary.add_soul_alignment(float(snapshot.get("time", 0.0)), driver_name,
			str(result["decision"]), str(result["driver"]), str(result["engineer"]), car_id)
	_update_soul_status()
	_set_radio_category(2)

func _ask_driver() -> void:
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var car_id: int = radio_driver_ids[index]
	var snapshot: Dictionary = host.race.get_state_snapshot()
	var previous: Dictionary = radio_driver_memory.get(car_id, {})
	var thought: Dictionary = DriverMemory.observe(car_id, snapshot, previous)
	if thought.is_empty():
		return
	var driver_name: String = str(thought["car_name"])
	var impression: String = str(thought["message"])
	var feeling: Dictionary = SoulDriver.perceive(car_id, snapshot, _soul_profile(car_id))
	if absf(float(feeling.get("difference", 0.0))) >= 7.0:
		impression += " Minha percepção de desgaste está %s da leitura dos sensores." % ("acima" if float(feeling["difference"]) > 0.0 else "abaixo")
	if bool(thought.get("repeat", false)):
		radio_response_label.text = "%s: %s" % [driver_name, str(thought["message"])]
		_set_radio_category(2)
		return
	var facts: Dictionary = EngineerInteractive.answer("pneus", car_id, snapshot, host.race.get_engineer_advice(car_id))
	if facts.is_empty():
		return
	radio_driver_memory[car_id] = thought["memory"]
	radio_response_label.text = "%s: %s\nENGENHEIRO: %s" % [driver_name, impression, str(facts["reply"])]
	if host.commentary != null:
		host.commentary.add_driver_consultation(float(snapshot.get("time", 0.0)), driver_name, impression, str(facts["reply"]), car_id)
	_update_soul_status()
	_set_radio_category(2)

func _compare_teammate() -> void:
	# Radio-only consultation, using a read-only engine snapshot.
	# The player's existing team-order request still comes from Soul 2.0.
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var car_id: int = radio_driver_ids[index]
	var snapshot: Dictionary = host.race.get_state_snapshot()
	var selected: Dictionary = {}
	var teammate: Dictionary = {}
	for entry in snapshot.get("cars", []):
		if int(entry.get("id", -1)) == car_id:
			selected = entry
	if selected.is_empty():
		return
	for entry in snapshot.get("cars", []):
		if int(entry.get("id", -1)) != car_id and str(entry.get("team", "")) == str(selected.get("team", "")):
			teammate = entry
			break
	var evaluation: Dictionary = TeamRadioAdvice.evaluate(selected, teammate, snapshot.get("weather", {}))
	radio_response_label.text = "%s: %s\nENGENHEIRO: %s" % [
		str(selected.get("name", "Piloto")), str(evaluation.get("driver", "")), str(evaluation.get("engineer", ""))]
	_set_radio_category(2)

# Explicit player command, not a radio question. The leader is asked to avoid
# an early defensive block for up to 15s; the follower still must overtake safely.
func _authorize_teammate_pass() -> void:
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var chase_id: int = radio_driver_ids[index]
	var snapshot: Dictionary = host.race.get_state_snapshot()
	var selected: Dictionary = {}
	var leader: Dictionary = {}
	for car in snapshot.get("cars", []):
		if int(car.get("id", -1)) == chase_id:
			selected = car
	if selected.is_empty():
		return
	for car in snapshot.get("cars", []):
		if int(car.get("id", -1)) != chase_id and str(car.get("team", "")) == str(selected.get("team", "")):
			leader = car
			break
	var decision: Dictionary = TeamRadioAdvice.evaluate(selected, leader, snapshot.get("weather", {}))
	if str(decision.get("state", "")) != "avaliar_passagem" or int(decision.get("chasing_id", -1)) != chase_id:
		radio_response_label.text = "ENGENHEIRO: ordem não autorizada: piloto atrás precisa de duas voltas de vantagem, proximidade e condições seguras. Use COMPARAR COMPANHEIRO."
	else:
		var front_id: int = int(decision.get("leading_id", -1))
		if host.race.authorize_team_yield(front_id, chase_id):
			radio_response_label.text = "ORDEM ENFILEIRADA: %s evitará defesa agressiva contra %s por até 15s após confirmação no próximo tick. Sem garantia de ultrapassagem; BOX preservado." % [str(leader.get("name", "Líder")), str(selected.get("name", "Companheiro"))]
		else:
			radio_response_label.text = "ENGENHEIRO: comando não aceito; situação pode ter mudado ou já existe uma ordem pendente."
	_set_radio_category(2)

func _cancel_teammate_pass() -> void:
	if host == null or host.race == null:
		return
	var car_id: int = -1
	if radio_driver_picker != null and radio_driver_picker.selected >= 0 and radio_driver_picker.selected < radio_driver_ids.size():
		car_id = radio_driver_ids[radio_driver_picker.selected]
	var front: Dictionary = {}
	for c in host.race.player_cars():
		if int(c.get("team_yield_ticks", 0)) > 0 and (int(c.get("team_yield_to_id", -1)) == car_id or int(c.get("id", -1)) == car_id):
			front = c
			break
	if front.is_empty():
		radio_response_label.text = "ENGENHEIRO: não existe autorização ativa para o piloto selecionado."
	elif host.race.cancel_team_yield(int(front.id)):
		radio_response_label.text = "CANCELAMENTO ENFILEIRADO: autorização encerrada no próximo tick. BOX preservado."
	else:
		radio_response_label.text = "ENGENHEIRO: cancelamento não aceito; confira comandos pendentes."
	_set_radio_category(2)

func _discuss_stint() -> void:
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var car_id: int = radio_driver_ids[index]
	var snapshot: Dictionary = host.race.get_state_snapshot()
	var advice: Dictionary = host.race.get_engineer_advice(car_id)
	var last: Dictionary = radio_stint_memory.get(car_id, {})
	var profile: Dictionary = _soul_profile(car_id)
	var feeling: Dictionary = SoulDriver.perceive(car_id, snapshot, profile)
	var exchange: Dictionary = StintDialogue.evaluate(car_id, snapshot, advice, last, feeling.merged(profile, true))
	if exchange.is_empty():
		return
	if bool(exchange.get("repeat", false)):
		radio_response_label.text = "Sem mudança relevante desde a última discussão de stint."
		_set_radio_category(2)
		return
	var driver_name: String = str(exchange["car_name"])
	var driver_words: String = str(exchange["driver"])
	var engineer_words: String = str(exchange["engineer"])
	radio_stint_memory[car_id] = exchange["memory"]
	radio_soul_profiles[car_id] = SoulDriver.begin_discussion(profile)
	radio_response_label.text = "%s: %s\nENGENHEIRO: %s" % [driver_name, driver_words, engineer_words]
	if host.commentary != null:
		host.commentary.add_stint_discussion(float(snapshot.get("time", 0.0)), driver_name, driver_words, engineer_words, car_id)
	_update_soul_status()
	_set_radio_category(2)

func _ask_engineer(topic: String) -> void:
	if host == null or host.race == null or radio_driver_picker == null or radio_driver_ids.is_empty():
		return
	var index: int = radio_driver_picker.selected
	if index < 0 or index >= radio_driver_ids.size():
		return
	var car_id: int = radio_driver_ids[index]
	# O instantâneo é cópia; o módulo não recebe referência mutável aos carros.
	var snapshot: Dictionary = host.race.get_state_snapshot()
	var advice: Dictionary = host.race.get_engineer_advice(car_id)
	var response: Dictionary = EngineerInteractive.answer(topic, car_id, snapshot, advice)
	if response.is_empty():
		return
	radio_response_label.text = "ENGENHEIRO PARA %s: %s" % [str(response["car_name"]), str(response["reply"])]
	if host.commentary != null:
		host.commentary.add_team_question(float(snapshot.get("time", 0.0)), str(response["question"]), str(response["car_name"]), str(response["reply"]), car_id)
	_set_radio_category(2)

func _refresh_interactive_history() -> void:
	if radio_history == null or not is_instance_valid(radio_history):
		return
	var value: String = str(host.commentary.formatted(radio_category, _selected_radio_id())) if host != null and host.commentary != null else "Aguardando comunicações."
	if radio_history.text != value:
		radio_history.text = value

func _update_window_data() -> void:
	if active_window == "engineer":
		_refresh_engineer_window()
	if active_window == "graficos":
		_refresh_dynamic_graphs_window()
	if active_window == "simulator":
		_refresh_strategy_simulator_window()
	if active_window == "radio":
		_refresh_interactive_history()
		if host != null and host.race != null and (float(host.race.clock) - radio_soul_last_refresh >= 5.0 or float(host.race.clock) < radio_soul_last_refresh):
			_update_soul_status()
	if active_window == "estrategia" and host.race != null:
		if modal_timeline != null:
			modal_timeline.set_race_state(host.race.player_cars(), host.race.pit_history, int(host.race.lap_count))
		for row in modal_driver_rows:
			var car: Dictionary = host._car_by_id(int(row["id"]))
			if car.is_empty():
				continue
			var advice: Dictionary = host.race.get_engineer_advice(int(car["id"]))
			var pit_status: String = "BOX CHAMADO" if bool(car.get("pit_request", false)) else ("Agendado V%d" % int(car.get("pit_scheduled_lap", 0)) if int(car.get("pit_scheduled_lap", 0)) > 0 else "Sem parada marcada")
			(row["briefing"] as Label).text = "P%d • %s • desgaste %d%% • %s\nEngenheiro: %s" % [int(car.get("position", 0)), str(car.get("tire", "Médio")), int(float(car.get("wear", 0.0))), pit_status, str(advice.get("message", "—"))]
			(row["pit"] as Button).disabled = bool(car.get("pit_request", false)) or bool(car.get("finished", false)) or float(car.get("pit_left", 0.0)) > 0.0
			(row["lap"] as SpinBox).min_value = mini(int(host.race.lap_count) - 1, maxi(1, int(car.get("laps_done", 0)) + 1))



# 0.6.4.0 — Pit Wall Intelligence: preserve the 0.6.3.9 decision engine,
# add per-driver delegation, explanations and a bounded history of radio changes.
func _engineer_report(car: Dictionary, teammate: Dictionary) -> Dictionary:
	var id: int = int(car.get("id", -1))
	var staff: Dictionary = host.garage.effective_staff_levels(host.selected_team)
	var advice: Dictionary = host.race.get_engineer_advice(id)
	var conditions: Dictionary = host.race.weather_snapshot()
	var report: Dictionary = RaceEngineer.evaluate(car, advice, conditions, staff, host.race.lap_count)
	var base_report: Dictionary = Engineer2.enrich(car,
		PitWallIntel.enrich(car, report, advice, conditions, teammate, float(host.race.pit_loss)), advice)
	return Engineer3.assess(car, base_report, advice, conditions, teammate, staff,
		host.race.available_pit_compounds(), int(host.race.lap_count),
		float(host.race.pit_loss), float(host.race.base_lap),
		int(host.race._next_pit_entry_lap(car)))

func _record_engineer_history(id: int, note: String, at_lap: int) -> void:
	var history: Array = engineer_history_by_driver.get(id, [])
	var car: Dictionary = host._car_by_id(id)
	history.append("V%02d · %s: %s" % [maxi(0, at_lap), str(car.get("name", "Piloto")), note])
	while history.size() > 12:
		history.pop_front()
	engineer_history_by_driver[id] = history

func _update_engineer_reports() -> void:
	if host == null or host.race == null:
		return
	var team: Array = host.race.player_cars()
	for car in team:
		var car_id: int = int(car.get("id", -1))
		var teammate: Dictionary = {}
		for another in team:
			if int(another.get("id", -1)) != car_id:
				teammate = another
				break
		var report: Dictionary = _engineer_report(car, teammate)
		engineer_reports[car_id] = report
		var key: String = str(report.get("radio_key_3", ""))
		var current_lap: int = int(car.get("laps_done", 0))
		var history_previous: String = str(engineer_history_keys.get(car_id, ""))
		if key != history_previous:
			engineer_history_keys[car_id] = key
			if key != "":
				_record_engineer_history(car_id, str(report.get("condition", "")) + " — " + str(report.get("alert", "")), current_lap)
		var previous: String = str(engineer_last_radio.get(car_id, ""))
		var last_lap: int = int(engineer_last_lap.get(car_id, -100))
		if key == "":
			engineer_last_radio[car_id] = ""
		elif host.replay_session == null and key != previous and current_lap >= 1 and not bool(host.race.finished) and host.race.running and current_lap - last_lap >= 4:
			engineer_last_radio[car_id] = key
			engineer_last_lap[car_id] = current_lap
			host.race._event("engineer_strategy", car_id,
				"RACE ENGINEER 3.0 (SIMULAÇÃO) | %s: %s %s" % [
				str(car.get("name", "Piloto")), str(report.get("alert", "")),
				str(report.get("action", ""))], 66)
	if active_window == "engineer":
		_refresh_engineer_window()
	elif active_window == "pitwall3":
		_refresh_pitwall3_window()

func _build_engineer_window() -> void:
	overlay_title.text = "RACE ENGINEER 3.0  /  HUD UI03 · SOUL 2.0 · REVISÃO POR VOLTA"
	_text(overlay_content, "Evidências e cenários baseados no estado real do motor. Em MANUAL e ASSISTIDO, o BOX depende de confirmação; qualquer ordem agendada permanece protegida.", 12, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var controls := _line(overlay_content, 8)
	_text(controls, "CONTROLE GLOBAL (AMBOS)", 12, ACCENT)
	engineer_mode_picker = _select(controls, ["MANUAL", "AUTOMÁTICO"], _engineer_change_mode)
	engineer_mode_picker.select(1 if host.team_control_mode == "Automático" else 0)
	_text(overlay_content, "Selecionar controle global redefine os dois pilotos. A escolha individual abaixo tem precedência até novo comando global.", 11, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var pitwall_link := _line(overlay_content, 8)
	_btn(pitwall_link, "PIT WALL 3.0 · PLANEJAR DOIS CARROS", _open_window.bind("pitwall3"), 314)
	_btn(pitwall_link, "GRÁFICOS 9.8", _open_window.bind("graficos"), 160)
	_btn(pitwall_link, "SIMULADOR 9.9", _open_window.bind("simulator"), 163)
	_text(pitwall_link, "Under/overcut, tráfego, chuva e double stack.", 11, MUTED)
	engineer_cards.clear()
	for car in host.race.player_cars():
		var car_id: int = int(car.get("id", -1))
		var frame := _panel(overlay_content, HudSkin.SURFACE_ALT)
		var layout := _column(frame, 5)
		var heading := _line(layout, 9)
		var title := _text(heading, str(car.get("name", "Piloto")), 15, ACCENT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_text(heading, "DELEGAÇÃO", 10, MUTED)
		var driver_mode: OptionButton = _select(heading, ["MANUAL", "ASSISTIDO", "AUTOMÁTICO"], _engineer_driver_control.bind(car_id))
		driver_mode.select(["Manual", "Assistido", "Automático"].find(host._engineer_mode_for(car_id)))
		var status := _text(layout, "Aguardando leitura", 12, YELLOW)
		var explanation := _text(layout, "", 12, WHITE)
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var evidence := _text(layout, "", 11, MUTED)
		evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var tradeoff := _text(layout, "", 11, SOUL_ACCENT)
		tradeoff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var command := _text(layout, "", 11, MUTED)
		command.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var actions := _line(layout, 6)
		var btn_apply := _btn(actions, "APROVAR RITMO + KERS", _engineer_accept_pace.bind(car_id), 181)
		var btn_pit := _btn(actions, "ACEITAR BOX", _engineer_accept_pit.bind(car_id), 118)
		var btn_ask := _btn(actions, "RÁDIO: PLANO", _engineer_ask.bind(car_id, "plano"), 139)
		var questions := _line(layout, 6)
		_text(questions, "PERGUNTAR", 10, ACCENT)
		var ask_tyres := _btn(questions, "PNEUS", _engineer_ask.bind(car_id, "pneus"), 100)
		var ask_weather := _btn(questions, "CHUVA", _engineer_ask.bind(car_id, "clima"), 100)
		var ask_traffic := _btn(questions, "TRÁFEGO/BOX", _engineer_ask.bind(car_id, "trafego"), 138)
		var response := _text(layout, "", 11, WHITE)
		response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		response.hide()
		engineer_cards.append({"id": car_id, "name": title, "status": status, "text": explanation,
			"evidence": evidence, "tradeoff": tradeoff, "order": command, "pace": btn_apply,
			"pit": btn_pit, "ask": btn_ask, "ask_tyres": ask_tyres, "ask_weather": ask_weather,
			"ask_traffic": ask_traffic, "response": response, "driver_mode": driver_mode})
	_text(overlay_content, "DIÁRIO DO PIT WALL · ALERTAS E DECISÕES", 13, ACCENT)
	engineer_history_text = RichTextLabel.new()
	engineer_history_text.bbcode_enabled = false
	engineer_history_text.custom_minimum_size.y = 145
	engineer_history_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_content.add_child(engineer_history_text)
	_refresh_engineer_window()

func _refresh_engineer_window() -> void:
	if host == null or host.race == null or active_window != "engineer":
		return
	if engineer_mode_picker != null and is_instance_valid(engineer_mode_picker):
		engineer_mode_picker.select(1 if host.team_control_mode == "Automático" else 0)
	for ui in engineer_cards:
		var id: int = int(ui["id"])
		var report: Dictionary = engineer_reports.get(id, {})
		var car: Dictionary = host._car_by_id(id)
		if report.is_empty() or car.is_empty():
			continue
		var mode: String = host._engineer_mode_for(id)
		var mode_index: int = ["Manual", "Assistido", "Automático"].find(mode)
		(ui["driver_mode"] as OptionButton).select(maxi(0, mode_index))
		(ui["status"] as Label).text = "%s · %s  |  V%d/%d  |  pneus %.0f%%" % [
			str(report.get("risk", "ACOMPANHAR")), str(report.get("condition", "AVALIANDO")),
			int(car.get("laps_done", 0)), int(host.race.lap_count), float(car.get("wear", 0.0))]
		(ui["text"] as Label).text = str(report.get("alert", "")) + "  |  " + str(report.get("action", "")) + "\n" + str(report.get("tactic", "")) + " · confiança " + str(report.get("confidence", "—")) + " (qualitativa) · " + DriverSoul2.summary(car)
		var req: Dictionary = DriverSoul2.latest(car)
		if not req.is_empty() and not bool(req.get("answered", false)):
			(ui["text"] as Label).text += "\nPEDIDO PILOTO: %s (sem executar ordens)" % str(req.get("kind", ""))
		(ui["evidence"] as Label).text = str(report.get("evidence", "")) + "\n" + str(report.get("thermal_note", "")) + "  " + str(report.get("weather_note", ""))
		var lap_review: Dictionary = car.get("lap_strategy_06496", {})
		if not lap_review.is_empty():
			(ui["evidence"] as Label).text += "\nREVISÃO V%d: %s · %s" % [
				int(lap_review.get("lap", 0)), str(lap_review.get("action", "MANTER")),
				str(lap_review.get("reason", ""))]
		var team_coord: Dictionary = car.get("team_pit_coord_06497", {})
		if bool(team_coord.get("overlap", false)):
			(ui["evidence"] as Label).text += "\nEQUIPE: %s — %s" % [
				str(team_coord.get("decision", "MANTER")), str(team_coord.get("reason", ""))]
		(ui["tradeoff"] as Label).text = str(report.get("hold_case", "")) + "\n" + str(report.get("stop_case", "")) + "  ·  " + str(report.get("traffic_note", "")) + "\n" + str(report.get("stack_note", "")) + "\n" + " | ".join(report.get("alternatives", []))
		var authority: String = "Você autoriza ritmo/KERS e box."
		if mode == "Assistido":
			authority = "STAFF assume ritmo/KERS; BOX só com sua decisão."
		elif mode == "Automático":
			authority = "STAFF controla ritmo/KERS; IA original controla BOX."
		(ui["order"] as Label).text = "GATILHO BOX: %s  |  %s  |  %s" % [
			str(report.get("pit_gate", "")), authority, str(report.get("staff_note", ""))]
		(ui["pace"] as Button).disabled = mode != "Manual" or bool(car.get("finished", false))
		(ui["pit"] as Button).disabled = mode == "Automático" or not bool(report.get("can_call_pit", false)) or bool(car.get("finished", false))
		var response_text: String = str(engineer_radio_answers.get(id, ""))
		(ui["response"] as Label).text = response_text
		(ui["response"] as Label).visible = not response_text.is_empty()
	if engineer_history_text != null and is_instance_valid(engineer_history_text):
		var lines: Array[String] = []
		for car in host.race.player_cars():
			var car_id: int = int(car.get("id", -1))
			var history: Array = engineer_history_by_driver.get(car_id, [])
			for idx in range(maxi(0, history.size() - 6), history.size()):
				lines.append(str(history[idx]))
		var value: String = "Nenhum alerta registrado nesta corrida." if lines.is_empty() else "\n".join(lines)
		if engineer_history_text.text != value:
			engineer_history_text.text = value

func _engineer_change_mode(index: int) -> void:
	_set_team_mode(index)
	_update_engineer_reports()
	_refresh_engineer_window()

func _engineer_driver_control(index: int, id: int) -> void:
	if host == null or host.race == null:
		return
	var modes: Array[String] = ["Manual", "Assistido", "Automático"]
	if index < 0 or index >= modes.size():
		return
	host._set_engineer_driver_mode(id, modes[index])
	var car: Dictionary = host._car_by_id(id)
	_record_engineer_history(id, "Controle individual definido: %s" % modes[index], int(car.get("laps_done", 0)))
	_update_engineer_reports()
	_refresh_engineer_window()

func _engineer_accept_pace(id: int) -> void:
	if host == null or host.race == null or host._engineer_mode_for(id) != "Manual":
		return
	var car: Dictionary = host._car_by_id(id)
	if car.is_empty() or bool(car.get("finished", false)):
		return
	# Re-evaluate at click time, never trust a cached HUD card.
	var team: Array = host.race.player_cars()
	var mate: Dictionary = {}
	for entry in team:
		if int(entry.get("id", -1)) != id:
			mate = entry
			break
	var report: Dictionary = _engineer_report(car, mate)
	host.race.set_pace(id, str(report["pace"]))
	if bool(car.get("kers_equipped", false)):
		host.race.set_kers_mode(id, str(report["kers"]))
	host.race._event("engineer_command", id, "DIREÇÃO | %s: ritmo/KERS aprovados (%s)." %
		[str(car.get("name", "")), str(report.get("reason", ""))], 65)
	_record_engineer_history(id, "Ordem aprovada: ritmo %s, KERS %s" % [str(report["pace"]), str(report["kers"])], int(car.get("laps_done", 0)))
	_update_engineer_reports()

func _engineer_accept_pit(id: int) -> void:
	if host == null or host.race == null or host._engineer_mode_for(id) == "Automático":
		return
	var car: Dictionary = host._car_by_id(id)
	if car.is_empty():
		return
	if int(car.get("pit_scheduled_lap", 0)) > 0:
		_update_engineer_reports()
		return
	var team: Array = host.race.player_cars()
	var mate: Dictionary = {}
	for entry in team:
		if int(entry.get("id", -1)) != id:
			mate = entry
			break
	var latest: Dictionary = _engineer_report(car, mate)
	var tyre: String = str(latest.get("compound", ""))
	if not bool(latest.get("can_call_pit", false)) or not host.race.available_pit_compounds().has(tyre):
		return
	# Protected manual V21 still cannot be overwritten by this button.
	host.race.order_pit(id, tyre)
	_record_engineer_history(id, "Box recomendado aceito: %s" % tyre, int(car.get("laps_done", 0)))
	_update_engineer_reports()

func _engineer_ask(id: int, topic: String = "plano") -> void:
	if host == null or host.race == null or topic not in ["plano", "pneus", "clima", "trafego"]:
		return
	var car: Dictionary = host._car_by_id(id)
	if car.is_empty():
		return
	var team: Array = host.race.player_cars()
	var mate: Dictionary = {}
	for entry in team:
		if int(entry.get("id", -1)) != id:
			mate = entry
			break
	var report: Dictionary = _engineer_report(car, mate)
	var answer: String = Engineer3.answer(report, topic)
	# Previna spam no log, mas permita ver a resposta atual mesmo em pausa.
	var now: float = float(host.race.clock)
	var key: String = "%d|%s" % [id, topic]
	var last: float = float(engineer_query_cooldowns.get(key, -100.0))
	engineer_radio_answers[id] = answer
	if now - last < 4.0:
		_refresh_engineer_window()
		return
	engineer_query_cooldowns[key] = now
	var question: String = {"plano":"Qual é o plano?", "pneus":"Como estão meus pneus?",
		"clima":"O que muda com a chuva?", "trafego":"O que acontece se eu parar?"}[topic]
	if host.commentary != null:
		host.commentary.add_team_question(now, question, str(car.get("name", "Piloto")), answer, id)
	host.race._event("engineer_question", id, "RÁDIO FICTÍCIO | %s: %s" %
		[str(car.get("name", "")), answer], 54)
	_record_engineer_history(id, "Rádio (%s): %s" % [topic, str(report.get("action", ""))], int(car.get("laps_done", 0)))
	_refresh_engineer_window()

# 0.6.4.9 — Pit Wall & Strategy 3.0. Dedicated optional panel: live
# projections and explicitly confirmed manual orders, no hidden actions.
func _pitwall3_read(car: Dictionary, teammate: Dictionary) -> Dictionary:
	if host == null or host.race == null or car.is_empty():
		return {}
	var advice: Dictionary = host.race.get_engineer_advice(int(car.get("id", -1)))
	return PitWallStrategy3.assess(car, teammate, host.race.get_sorted(), advice,
		host.race.weather_snapshot(), host.race.available_pit_compounds(),
		int(host.race.lap_count), float(host.race.pit_loss), float(host.race.base_lap),
		int(host.race._next_pit_entry_lap(car)))

func _build_pitwall3_window() -> void:
	overlay_title.text = "PIT WALL 3.0  /  UNDERCUT · OVERCUT · DOUBLE STACK"
	var header := _line(overlay_content, 7)
	_btn(header, "ESTRATÉGIA / AGENDAMENTO LIVRE", _open_window.bind("estrategia"), 285)
	_btn(header, "RACE ENGINEER 3.0", _open_window.bind("engineer"), 210)
	_btn(header, "GRÁFICOS 9.8", _open_window.bind("graficos"), 155)
	_btn(header, "SIMULADOR 9.9", _open_window.bind("simulator"), 155)
	_text(overlay_content, "Comparação consultiva dos DOIS pilotos. Retorno ~P e tráfego são estimativas instantâneas que não incluem futuras paradas, acidentes ou variação exata do ritmo.", 12, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pitwall3_feedback = _text(overlay_content, "Nada agendado por este painel.", 11, YELLOW)
	pitwall3_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pitwall3_cards.clear()
	for car in host.race.player_cars():
		var id: int = int(car.get("id", -1))
		var panel := _panel(overlay_content, HudSkin.SURFACE_ALT)
		var col := _column(panel, 5)
		var name := _text(col, str(car.get("name", "Piloto")), 15, ACCENT)
		var mode := _text(col, "", 11, MUTED)
		var strategy := _text(col, "Aguardando análise.", 13, WHITE)
		strategy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var scenarios := _text(col, "", 11, SOUL_ACCENT)
		scenarios.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var notes := _text(col, "", 11, MUTED)
		notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var row := _line(col, 7)
		var schedule := _btn(row, "AGENDAR PRÓX. ENTRADA", _pitwall3_schedule.bind(id, 0), 220)
		var extend := _btn(row, "ESTENDER +1V / AGENDAR", _pitwall3_schedule.bind(id, 1), 215)
		var accept := _btn(row, "BOX NA JANELA", _pitwall3_accept.bind(id), 163)
		pitwall3_cards.append({"id":id, "name":name, "mode":mode, "strategy":strategy,
			"scenarios":scenarios, "notes":notes, "schedule":schedule,
			"extend":extend, "accept":accept})
	_text(overlay_content, "AGENDAR altera a estratégia somente após o clique. Os dois botões recusam conflito direto de volta com o companheiro. Para alterar uma ordem existente, use ESTRATÉGIA e confirme o cancelamento/agendamento.", 11, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_pitwall3_window()

func _refresh_pitwall3_window() -> void:
	if host == null or host.race == null or active_window != "pitwall3":
		return
	var players: Array = host.race.player_cars()
	for ui in pitwall3_cards:
		var id: int = int(ui["id"])
		var car: Dictionary = host._car_by_id(id)
		var teammate: Dictionary = {}
		for other in players:
			if int(other.get("id", -1)) != id:
				teammate = other
				break
		if car.is_empty():
			continue
		var report: Dictionary = _pitwall3_read(car, teammate)
		var driver_mode: String = host._engineer_mode_for(id)
		(ui["mode"] as Label).text = "P%02d · %s · desgaste %.0f%% · controle %s · próxima entrada V%d · perda no pit ~%.1fs" % [
			int(car.get("position", 0)), str(car.get("tire", "—")), float(report.get("wear", 0.0)),
			driver_mode, int(report.get("next_lap", 0)), float(report.get("pit_loss", 0.0))]
		(ui["strategy"] as Label).text = "%s — %s" % [str(report.get("plan", "")), str(report.get("reason", ""))]
		var scenarios: Array[String] = []
		for case in report.get("cases", []):
			var traffic: String = "Risco de tráfego" if bool(case.get("traffic", false)) else "ar livre estimado"
			if str(case.get("kind", "")) == "MANTER":
				scenarios.append("MANTER STINT: P%d agora · %.1f voltas estimadas de vida" % [int(car.get("position", 0)), float(report.get("life_laps", 0.0))])
			else:
				scenarios.append("%s: %s" % [str(case.get("label", "")), traffic])
		(ui["scenarios"] as Label).text = "  |  ".join(scenarios)
		(ui["notes"] as Label).text = "%s\nEQUIPE: %s  |  COMP.: %s  |  PORTA: %s" % [
			str(report.get("forecast_note", "")), str(report.get("stack_note", "")),
			str(report.get("compound", "indefinido")), str(report.get("gate", ""))]
		var lap_review: Dictionary = car.get("lap_strategy_06496", {})
		if not lap_review.is_empty():
			(ui["notes"] as Label).text += "\nREAVALIAÇÃO V%d — %s: %s" % [
				int(lap_review.get("lap", 0)), str(lap_review.get("action", "MANTER")),
				str(lap_review.get("reason", ""))]
		var team_coord: Dictionary = car.get("team_pit_coord_06497", {})
		if bool(team_coord.get("overlap", false)):
			(ui["notes"] as Label).text += "\nCOORDENAÇÃO AUTO: %s — %s" % [
				str(team_coord.get("decision", "MANTER")), str(team_coord.get("reason", ""))]
		var entry: int = int(report.get("next_lap", 0))
		(ui["schedule"] as Button).disabled = not PitWallStrategy3.can_manual_schedule(report, car, teammate, driver_mode,
			entry, int(host.race.lap_count))
		(ui["extend"] as Button).disabled = not PitWallStrategy3.can_manual_schedule(report, car, teammate, driver_mode,
			entry+1, int(host.race.lap_count))
		var confirmed: Dictionary = engineer_reports.get(id, {})
		(ui["accept"] as Button).disabled = driver_mode == "Automático" or not bool(confirmed.get("can_call_pit", false)) or bool(report.get("team_overlap", false))

func _pitwall3_schedule(id: int, offset: int) -> void:
	if host == null or host.race == null or offset not in [0, 1]:
		return
	var car: Dictionary = host._car_by_id(id)
	var mate: Dictionary = {}
	for other in host.race.player_cars():
		if int(other.get("id", -1)) != id:
			mate = other
			break
	if car.is_empty():
		return
	var report: Dictionary = _pitwall3_read(car, mate)
	var lap: int = int(report.get("next_lap", 0)) + offset
	if not PitWallStrategy3.can_manual_schedule(report, car, mate,
		host._engineer_mode_for(id), lap, int(host.race.lap_count)):
		if pitwall3_feedback != null:
			pitwall3_feedback.text = "NÃO AGENDADO: carro, janela, composto ou garagem impedem a ordem. Revise as condições acima."
		_refresh_pitwall3_window()
		return
	var success: bool = host.race.schedule_pit(id, str(report.get("compound", "")), lap)
	if pitwall3_feedback != null:
		pitwall3_feedback.text = ("CONFIRMADO: %s · BOX V%d · %s." % [str(car.get("name", "")), lap, str(report.get("compound", ""))]) if success else "NÃO AGENDADO: motor recusou a ordem."
	if success:
		_record_engineer_history(id, "Pit Wall 3.0: agendamento manual V%d" % lap, int(car.get("laps_done", 0)))
	_update_engineer_reports()
	_refresh_pitwall3_window()

func _pitwall3_accept(id: int) -> void:
	if host == null or host.race == null or host._engineer_mode_for(id) == "Automático":
		return
	var car: Dictionary = host._car_by_id(id)
	var mate: Dictionary = {}
	for other in host.race.player_cars():
		if int(other.get("id", -1)) != id:
			mate = other
			break
	if car.is_empty():
		return
	var report: Dictionary = _pitwall3_read(car, mate)
	var engineer: Dictionary = _engineer_report(car, mate)
	if not bool(engineer.get("can_call_pit", false)) or bool(report.get("team_overlap", false)):
		if pitwall3_feedback != null:
			pitwall3_feedback.text = "BOX NÃO AUTORIZADO: janela do motor fechada ou potencial double stack."
		return
	_engineer_accept_pit(id)
	if pitwall3_feedback != null:
		pitwall3_feedback.text = "BOX enviado ao motor na janela autorizada para %s." % str(car.get("name", "Piloto"))
	_refresh_pitwall3_window()


# v0.6.4.9.8: one read-only chart panel, accessible from Strategy, Pit Wall and
# Race Engineer without replacing the hybrid HUD or their control callbacks.
func _build_dynamic_graphs_window() -> void:
	overlay_title.text = "APEX 9.8  /  DESGASTE · ESTRATÉGIA · GARAGEM"
	var links := _line(overlay_content, 9)
	_btn(links, "ESTRATÉGIA", _open_window.bind("estrategia"), 145)
	_btn(links, "PIT WALL 3.0", _open_window.bind("pitwall3"), 158)
	_btn(links, "RACE ENGINEER 3.0", _open_window.bind("engineer"), 202)
	_btn(links, "SIMULADOR 9.9", _open_window.bind("simulator"), 165)
	_text(overlay_content, "Leitura da corrida real por volta concluída. A linha tracejada futura é uma projeção consultiva, não uma ordem de box. Alterações nas condições podem invalidá-la.", 12, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dynamic_garage_status = _text(overlay_content, "GARAGEM: avaliando...", 13, YELLOW)
	dynamic_garage_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var key := _line(overlay_content, 13)
	_text(key, "● VERDE ÁGUA: real", 11, SOUL_ACCENT)
	_text(key, "┄ AMARELO: previsto", 11, YELLOW)
	_text(key, "┄ COMPOSTOS: plano inicial", 11, WHITE)
	_text(key, "│ LARANJA: sugestão", 11, ACCENT)
	_text(key, "│ ROSA: box agendado", 11, Color("#ff758e"))
	var cards := _line(overlay_content, 10)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dynamic_chart_views.clear()
	for car in host.race.player_cars():
		var id: int = int(car.get("id", -1))
		var panel := _panel(cards, HudSkin.SURFACE_ALT)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_stretch_ratio = 1.0
		var column := _column(panel, 6)
		var heading := _text(column, str(car.get("name", "Piloto")), 15, ACCENT)
		var detail := _text(column, "Coletando dados...", 12, WHITE)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var graph = StrategyChart06498.new()
		graph.custom_minimum_size = Vector2(360.0, 315.0)
		graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(graph)
		var status := _text(column, "", 11, YELLOW)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var comparison := _text(column, "", 11, MUTED)
		comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dynamic_chart_views.append({"id":id,"graph":graph,"heading":heading,"detail":detail,
			"status":status,"comparison":comparison})
	_text(overlay_content, "INI = estratégia projetada pelo planejador 9.5 antes da largada; ATUAL = stints e paradas executadas, com marcador de ordem ou janela do motor. Sem interpolação de voltas não observadas. Pit Wall e Race Engineer permanecem no controle original.", 11, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_dynamic_graphs_window()

func _refresh_dynamic_graphs_window() -> void:
	if host == null or host.race == null or active_window != "graficos":
		return
	var snapshots: Array = []
	for item in dynamic_chart_views:
		var car: Dictionary = host._car_by_id(int(item["id"]))
		if car.is_empty():
			continue
		var view: Dictionary = dynamic_graph_data.view(host.race, car)
		snapshots.append(view)
		(item["graph"] as Control).set_snapshot(view)
		(item["heading"] as Label).text = "%s  ·  %s" % [str(view["name"]), str(view["tire"])]
		var rate: float = float(view.get("rate", -1.0))
		var rate_label: String = "indisponível" if rate <= 0.0 else ("%.2f p.p./volta (%s)" % [rate, str(view["rate_source"])])
		(item["detail"] as Label).text = "V%d/%d  •  desgaste medido %.1f%%  •  %d pit(s)
Tendência prevista: %s  •  limite do composto %.0f%%" % [
			int(view["lap"]), int(view["total"]), float(view["wear"]), int(view["stops"]), rate_label, float(view["cliff"])]
		var booking: int = int(view["scheduled"])
		var window: int = int(view["window_start"])
		var marker: String = "BOX AGENDADO V%d (ordem confirmada)" % booking if booking > 0 else ("JANELA INDICADA V%d%s" % [window, ("–%d" % int(view["window_end"])) if int(view["window_end"]) > window else ""] if window > 0 else "Sem janela de parada indicada pelo motor")
		if bool(view["pit_called"]) or bool(view["pit_active"]):
			marker = "CHAMADA / SERVIÇO DE BOX EM ANDAMENTO"
		(item["status"] as Label).text = marker + "  ·  próximo composto sugerido: " + str(view["target"])
		var original: Dictionary = view.get("baseline", {})
		var original_stops: Array[String] = []
		if bool(original.get("valid", false)):
			var blocks: Array = original.get("stints", [])
			for k in range(maxi(0, blocks.size()-1)):
				original_stops.append("V%d" % int(blocks[k].get("to", 0)))
		else:
			original_stops.append("não disponível para o clima/compostos iniciais")
		var actual_stops: Array[String] = []
		for pit in view.get("pits", []):
			actual_stops.append("V%d" % int(pit.get("lap", 0)))
		(item["comparison"] as Label).text = "PLANO INICIAL (projeção): %s
PITS EXECUTADOS: %s" % [
			", ".join(original_stops), ", ".join(actual_stops) if not actual_stops.is_empty() else "nenhum até agora"]
	if snapshots.size() == 2 and dynamic_garage_status != null:
		var conflict: Dictionary = StrategyGraphData06498.garage_status(snapshots[0], snapshots[1])
		var kind: String = str(conflict.get("kind", "INDEFINIDO"))
		dynamic_garage_status.text = "GARAGEM COMPARTILHADA · %s — %s" % [kind, str(conflict.get("message", ""))]
		dynamic_garage_status.add_theme_color_override("font_color", YELLOW if kind in ["CONFIRMADO", "ATENÇÃO", "POTENCIAL"] else SOUL_ACCENT)


# v0.6.4.9.9: six read-only what-if pit entries for both drivers. A click
# selects a preview only; scheduling remains exclusively in original panels.
func _build_strategy_simulator_window() -> void:
	overlay_title.text = "APEX STRATEGY SIMULATOR 1.0  /  PRÓXIMAS CINCO VOLTAS"
	var links := _line(overlay_content, 7)
	_btn(links, "ESTRATÉGIA / ORDENS", _open_window.bind("estrategia"), 210)
	_btn(links, "PIT WALL 3.0", _open_window.bind("pitwall3"), 160)
	_btn(links, "RACE ENGINEER 3.0", _open_window.bind("engineer"), 204)
	_btn(links, "GRÁFICOS 9.8", _open_window.bind("graficos"), 150)
	_text(overlay_content, "CENÁRIOS HIPOTÉTICOS, NÃO ORDENS. Retorno calculado com progresso, ritmo recente, perda de pit, desgaste e clima do motor. Rivais mantêm o ritmo observado e NÃO param no horizonte; previsão não considera incidentes.", 12, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	simulator_cards.clear()
	for car in host.race.player_cars():
		var id: int = int(car.get("id", -1))
		var panel := _panel(overlay_content, HudSkin.SURFACE_ALT)
		var col := _column(panel, 7)
		var header := _text(col, str(car.get("name", "Piloto")), 15, ACCENT)
		var status := _text(col, "Calculando cenários com telemetria...", 12, MUTED)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var row := _line(col, 5)
		var buttons: Array = []
		for offset in range(6):
			var button := _btn(row, "—", _select_strategy_simulator_case.bind(id, offset), 150)
			button.custom_minimum_size.y = 51
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buttons.append(button)
		var detail := _text(col, "", 12, WHITE)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var engineer := _text(col, "", 12, SOUL_ACCENT)
		engineer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		simulator_cards.append({"id":id,"header":header,"status":status,
			"buttons":buttons,"detail":detail,"engineer":engineer})
	_text(overlay_content, "Legenda: P = posição projetada após perda de pit; CONF. = qualidade qualitativa, não probabilidade. O simulador nunca altera estratégia, pneus, modo AUTOMÁTICO ou chamadas de box. Para executar uma decisão, abra o painel original de ESTRATÉGIA.", 11, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_strategy_simulator_window()

func _select_strategy_simulator_case(id: int, offset: int) -> void:
	simulator_selection[id] = offset
	_refresh_strategy_simulator_window()

func _refresh_strategy_simulator_window() -> void:
	if host == null or host.race == null or active_window != "simulator":
		return
	var team: Array = host.race.player_cars()
	for ui in simulator_cards:
		var id: int = int(ui["id"])
		var car: Dictionary = host._car_by_id(id)
		if car.is_empty():
			continue
		var mate: Dictionary = {}
		for other in team:
			if int(other.get("id", -1)) != id:
				mate = other
				break
		var result: Dictionary = StrategySimulator06499.evaluate(host.race, car, mate, dynamic_graph_data)
		var scenarios: Array = result["scenarios"]
		var selected: int = mini(int(simulator_selection.get(id, 0)), maxi(0, scenarios.size() - 1))
		(ui["header"] as Label).text = "%s  ·  P%d  ·  %s  ·  V%d/%d" % [str(result["name"]), int(result["position"]), str(result["tire"]), int(result["lap"]), int(result["total"])]
		var order: String = "ORDEM ATUAL PROTEGIDA V%d" % int(result["booked"]) if int(result["booked"]) > 0 else ("BOX JÁ CHAMADO/EM SERVIÇO" if bool(result["protected"]) else "SEM ORDEM CONFIRMADA")
		(ui["status"] as Label).text = "%s  ·  próxima entrada real V%d  ·  sugestão atual do motor V%d  ·  %s" % [order, int(result["next_entry"]), int(result["engine_lap"]), str(result["rate_source"])]
		var buttons: Array = ui["buttons"]
		for offset in range(buttons.size()):
			var btn: Button = buttons[offset]
			btn.disabled = offset >= scenarios.size()
			if btn.disabled:
				btn.text = "INDISPONÍVEL"
				continue
			var entry: Dictionary = scenarios[offset]
			btn.text = "%s · V%d
~P%d · %s" % ["AGORA" if offset == 0 else ("+%dV" % offset), int(entry["lap"]), int(entry["rejoin_position"]), str(entry["risk"])]
			btn.add_theme_color_override("font_color", ACCENT if offset == selected else WHITE)
			btn.add_theme_stylebox_override("normal", HudSkin.button_style("rank_selected") if offset == selected else HudSkin.button_style("normal"))
		if scenarios.is_empty():
			(ui["detail"] as Label).text = "Sem janela futura válida antes da chegada ou corrida encerrada."
			(ui["engineer"] as Label).text = "RACE ENGINEER: Apenas observação."
			continue
		var chosen: Dictionary = scenarios[selected]
		var wear_text: String = "indisponível" if float(chosen["wear"]) < 0.0 else "%.1f%% (margem ao limite %.1f p.p.)" % [float(chosen["wear"]), float(chosen["wear_to_cliff"])]
		var traffic: String = "TRÁFEGO perto de %s (%.1fs)" % [str(chosen["nearest"]), absf(float(chosen["nearest_gap_s"]))] if bool(chosen["traffic"]) else "ar livre estimado"
		var garage: Dictionary = chosen["garage"]
		(ui["detail"] as Label).text = "V%d → retorno ~P%d  |  %s  |  perda de pit %.1fs
Pneu previsto: %s  |  água: %.0f%% → %.0f%%  |  garagem %s: %s
RISCO %s · CONF. %s (%s)" % [int(chosen["lap"]), int(chosen["rejoin_position"]), traffic, float(chosen["pit_loss_s"]), wear_text, 100.0*float(chosen["rain_now"]), 100.0*float(chosen["rain_estimated"]), str(garage["level"]), str(garage["message"]), str(chosen["risk"]), str(chosen["confidence"]), str(chosen["uncertainty"])]
		(ui["engineer"] as Label).text = StrategySimulator06499.explain(scenarios, chosen)
