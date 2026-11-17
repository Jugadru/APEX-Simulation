extends Control
## APEX Race HUD 0.6.2 — separate presentation layer.
## Reads the real RaceEngine state, and delegates all race commands to main.gd.
## No simulation values are invented here.

const MiniMap = preload("res://scripts/apex_mini_map.gd")
const Stints = preload("res://scripts/apex_strategy_planner_0620.gd")
const BASE := Color("#09121f")
const SURFACE := Color(0.039, 0.070, 0.111, 0.94)
const ACCENT := Color("#52dfc2")
const WHITE := Color("#f2f6fb")
const MUTED := Color("#a3b7c8")
const YELLOW := Color("#ffd16c")
const BORDER := Color("#36536a")
const METRICS := ["INTERVALO", "LÍDER", "PITS", "MELHOR VOLTA", "PNEUS", "ATRÁS"]
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
var speed_label: Label
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
var media_buttons: Array = []
var speed_index: int = 0
var ranking: PanelContainer
var weather_box: PanelContainer
var map_box: PanelContainer
var bottom_bar: PanelContainer
var tiny_top: PanelContainer
var player_strip: Control
var actions_top: HBoxContainer
var large_area: Control
var expanded_context: Array = [-1, -1]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_create_ui()
	visible = false

func _frame(color: Color = SURFACE, radius: int = 9) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = BORDER
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

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
	b.custom_minimum_size.y = 28
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_stylebox_override("normal", _frame(Color("#102135"), 5))
	b.add_theme_stylebox_override("hover", _frame(Color("#22445a"), 5))
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
	tiny_top = _panel(self)
	var stats := _line(tiny_top, 9)
	lap_label = _text(stats, "VOLTA —/—", 13, ACCENT)
	session_label = _text(stats, "00:00:00", 12, MUTED)

	actions_top = HBoxContainer.new()
	actions_top.add_theme_constant_override("separation", 4)
	add_child(actions_top)
	for item in [{"name":"CORRIDA", "id":"corrida"}, {"name":"ESTRAT.", "id":"estrategia"}, {"name":"DADOS", "id":"dados"}, {"name":"EVENTOS", "id":"eventos"}, {"name":"RÁDIO", "id":"radio"}]:
		var b := _btn(actions_top, str(item["name"]), _open_window.bind(str(item["id"])), 78 if str(item["id"]) != "radio" else 62)
		b.tooltip_text = "Abrir %s" % str(item["name"])
		media_buttons.append(b)

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
		row.custom_minimum_size.y = 25
		row.add_theme_constant_override("separation", 3)
		entries.add_child(row)
		var stripe := ColorRect.new()
		stripe.custom_minimum_size = Vector2(3, 20)
		stripe.color = MUTED
		row.add_child(stripe)
		var pos := _text(row, "%d" % (i + 1), 11, MUTED)
		pos.custom_minimum_size.x = 23
		var driver := _btn(row, "---", _select_grid_car.bind(i), 48)
		driver.alignment = HORIZONTAL_ALIGNMENT_LEFT
		driver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		driver.custom_minimum_size.y = 23
		var detail := _text(row, "—", 11, WHITE)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.custom_minimum_size.x = 81
		standing_rows.append({"row":row, "stripe":stripe, "pos":pos, "driver":driver, "detail":detail})

	weather_box = _panel(self)
	var weather_column := _column(weather_box, 4)
	_text(weather_column, "CONDIÇÕES DA PISTA", 11, ACCENT)
	weather_line = _text(weather_column, "Aguardando clima", 11, WHITE)
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

	player_strip = Control.new()
	player_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_strip)

	bottom_bar = _panel(self)
	var tools := _line(bottom_bar, 6)
	pause_button = _btn(tools, "▶ INICIAR", _pause, 92)
	_btn(tools, "‹", _step_speed.bind(-1), 29)
	speed_label = _text(tools, "1×", 13, ACCENT)
	speed_label.custom_minimum_size.x = 35
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn(tools, "›", _step_speed.bind(1), 29)
	_text(tools, "EQUIPE", 10, MUTED)
	team_mode_picker = _select(tools, ["MANUAL", "AUTO"], _set_team_mode)
	_text(tools, "VISUAL", 10, MUTED)
	view_picker = _select(tools, ["MAPA 2D", "AÉREA 3D", "DIRETOR TV"], _set_view)
	view_picker.select(1)
	_btn(tools, "−", _zoom.bind(0.83), 30)
	_btn(tools, "+", _zoom.bind(1.20), 30)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(spacer)
	_btn(tools, "MENU", _menu, 57)

	background_dimmer = ColorRect.new()
	background_dimmer.color = Color(0.0, 0.0, 0.0, 0.55)
	background_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background_dimmer)
	background_dimmer.hide()
	large_area = Control.new()
	large_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(large_area)
	overlay_window = _panel(large_area, Color("#0a1727"))
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
	for node in player_strip.get_children():
		player_strip.remove_child(node)
		node.queue_free()
	race_card_panels.clear()
	expanded_context = [-1, -1]
	if host == null or host.race == null:
		return
	var cars: Array = host.race.player_cars()
	for i in range(mini(2, cars.size())):
		_create_driver_card(cars[i], i)
	if host.map_view != null:
		minimap.set_track(host.map_view.route)
	metric_index = 0
	team_mode_picker.select(1 if host.team_control_mode == "Automático" else 0)
	active_window = ""
	large_area.hide()
	background_dimmer.hide()
	visible = true
	layout_hud()
	refresh_hud()

func _create_driver_card(car: Dictionary, slot: int) -> void:
	var base := _panel(player_strip)
	var interior := _line(base, 7)
	var controls := _column(interior, 2)
	var icons := ["T", "D", "E", "C"]
	for k in range(4):
		var b := _btn(controls, icons[k], _expand_driver.bind(slot, k), 29)
		b.custom_minimum_size.y = 22
		b.tooltip_text = CONTEXTS[k]
	var core := _column(interior, 4)
	core.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_line := _line(core, 3)
	var name := _text(title_line, str(car.get("name", "Piloto")), 13, WHITE)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pos := _text(title_line, "P%d" % int(car.get("position", 0)), 14, ACCENT)
	var status := _text(core, "Pneu — • Ritmo —", 11, MUTED)
	status.clip_text = true
	var action_line := _line(core, 5)
	var follow := _btn(action_line, "SEGUIR", _follow.bind(int(car["id"])), 67)
	follow.tooltip_text = "Seguir piloto na câmera"
	var quick := _btn(action_line, "BOX", _quick_box.bind(slot), 68)
	quick.tooltip_text = "Chamar imediatamente com o composto da estratégia"
	var expanded := _panel(player_strip, Color(0.045, 0.084, 0.134, 0.98))
	var content := _column(expanded, 7)
	var heading := _line(content, 4)
	var heading_label := _text(heading, "", 14, ACCENT)
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn(heading, "×", _collapse_driver.bind(slot), 29)
	var detail_body := _column(content, 5)
	expanded.hide()
	race_card_panels.append({"base":base, "expanded":expanded, "content":detail_body, "heading":heading_label,
		"id":int(car["id"]), "slot":slot, "pos":pos, "name":name, "status":status, "quick":quick,
		"context":-1, "target_tire":str(car.get("pit_target", "Duro")), "tire_picker":null,
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
	expanded_context[slot] = context
	card["context"] = context
	card["expanded"].show()
	card["heading"].text = CONTEXTS[context].to_upper()
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
		_text(body, "ATUAL: %s · %d voltas neste jogo" % [str(car.get("tire", "—")), int(car.get("stint_laps", 0))], 11, YELLOW)
		var tyre_row := _line(body, 5)
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
	var heading := _text(line, title, 11, MUTED)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var data := _text(line, "—", 11, WHITE)
	data.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	data.custom_minimum_size.x = 115
	data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data.clip_text = true
	card["data_labels"].append(data)

func _collapse_driver(slot: int) -> void:
	if slot >= 0 and slot < race_card_panels.size():
		expanded_context[slot] = -1
		race_card_panels[slot]["expanded"].hide()
		layout_hud()

func layout_hud() -> void:
	if host == null:
		return
	var width_px: float = maxf(800.0, get_viewport_rect().size.x)
	var height_px: float = maxf(580.0, get_viewport_rect().size.y)
	# HUD uses full-rect anchors and follows the parent automatically.
	tiny_top.position = Vector2(13.0, 10.0)
	tiny_top.size = Vector2(247.0, 39.0)
	actions_top.position = Vector2(width_px - 428.0, 10.0)
	actions_top.size = Vector2(414.0, 31.0)
	var left_width := 218.0
	var right_width := 226.0
	ranking.position = Vector2(12.0, 59.0)
	ranking.size = Vector2(left_width, minf(672.0, height_px - 138.0))
	weather_box.position = Vector2(width_px - right_width - 12.0, 59.0)
	weather_box.size = Vector2(right_width, 105.0)
	map_box.position = Vector2(width_px - right_width - 12.0, 174.0)
	map_box.size = Vector2(right_width, 204.0)
	bottom_bar.position = Vector2(12.0, height_px - 61.0)
	bottom_bar.size = Vector2(width_px - 24.0, 50.0)
	var center_left: float = ranking.position.x + left_width + 18.0
	var center_right: float = weather_box.position.x - 18.0
	var card_gap: float = 13.0
	var card_width: float = minf(375.0, (center_right - center_left - card_gap) / 2.0)
	var card_bottom: float = bottom_bar.position.y - 9.0
	var card_height: float = 119.0
	var strip_width: float = (card_width * 2.0) + card_gap
	var start_x: float = center_left + (center_right - center_left - strip_width) * 0.5
	player_strip.position = Vector2(start_x, 0.0)
	player_strip.size = Vector2(strip_width, height_px)
	for i in range(race_card_panels.size()):
		var card: Dictionary = race_card_panels[i]
		var xx: float = i * (card_width + card_gap)
		card["base"].position = Vector2(xx, card_bottom - card_height)
		card["base"].size = Vector2(card_width, card_height)
		var context: int = int(expanded_context[i])
		var expanded_height: float = 338.0 if context == 2 else (248.0 if context == 1 else 193.0)
		if context == 3:
			expanded_height = 227.0
		card["expanded"].position = Vector2(xx, card_bottom - card_height - expanded_height - 7.0)
		card["expanded"].size = Vector2(card_width, expanded_height)
	background_dimmer.position = Vector2.ZERO
	background_dimmer.size = Vector2(width_px, height_px)
	large_area.position = Vector2.ZERO
	large_area.size = Vector2(width_px, height_px)
	var modal_width: float = minf(1060.0, width_px - 120.0)
	var modal_height: float = minf(740.0, height_px - 105.0)
	overlay_window.position = Vector2((width_px - modal_width) / 2.0, (height_px - modal_height) / 2.0)
	overlay_window.size = Vector2(modal_width, modal_height)

func update_map(cars: Array, focused: int) -> void:
	if visible:
		minimap.set_cars(cars, focused)

func refresh_hud() -> void:
	if host == null or host.race == null or not visible:
		return
	var race = host.race
	var clock_value: int = int(race.clock)
	lap_label.text = "V%02d / %02d" % [int(race.lap), int(race.lap_count)]
	session_label.text = "%02d:%02d:%02d" % [int(clock_value / 3600), int(clock_value / 60) % 60, clock_value % 60]
	pause_button.text = "BANDEIRADA" if race.finished else ("Ⅱ PAUSAR" if race.running else "▶ CONTINUAR")
	pause_button.disabled = bool(race.finished)
	speed_label.text = "%d×" % int(host.sim_speed)
	var weather: Dictionary = race.weather_snapshot()
	weather_line.text = "%s • %s\nÁgua %d%%   •   Pista %.0f°C\nChuva (15 min): %d%%" % [str(weather.get("sky", "—")), str(weather.get("track_state", "—")), int(weather.get("wetness", 0)), float(weather.get("track_c", 0.0)), int(weather.get("rain_probability", 0))]
	var order: Array = race.get_sorted()
	standings_title.text = METRICS[metric_index]
	for i in range(standing_rows.size()):
		var row: Dictionary = standing_rows[i]
		row["row"].visible = i < order.size()
		if i >= order.size():
			continue
		var car: Dictionary = order[i]
		var car_name: String = str(car.get("name", "Piloto"))
		var pieces: PackedStringArray = car_name.split(" ", false)
		var last: String = car_name if pieces.is_empty() else pieces[pieces.size() - 1]
		var initials: String = last.left(3).to_upper()
		var my_team: bool = str(car.get("team", "")) == str(host.selected_team)
		row["pos"].text = "%02d" % (i + 1)
		row["driver"].text = initials
		row["driver"].tooltip_text = "%s — seguir na câmera" % car_name
		row["driver"].add_theme_color_override("font_color", ACCENT if my_team else WHITE)
		row["stripe"].color = Color.from_string(str(car.get("color", "#ffffff")), WHITE)
		row["detail"].text = _standing_value(order, i)
	for i in range(race_card_panels.size()):
		var card: Dictionary = race_card_panels[i]
		var car: Dictionary = _driver_from_slot(i)
		if car.is_empty():
			continue
		card["name"].text = str(car.get("name", "Piloto"))
		card["pos"].text = "P%02d" % int(car.get("position", 0))
		var tire: String = str(car.get("tire", "Médio"))
		var pit_text: String = "BOX CHAMADO" if bool(car.get("pit_request", false)) else ("PIT V%d" % int(car.get("pit_scheduled_lap", 0)) if int(car.get("pit_scheduled_lap", 0)) > 0 else str(car.get("pace", "Normal")))
		var warning: String = "⚠ PNEUS CRÍTICOS · " if float(car.get("wear", 0.0)) >= 90.0 else ("⚠ PNEUS · " if float(car.get("wear", 0.0)) >= 75.0 else "")
		card["status"].text = "%s%s · %d%% desgaste | %s" % [warning, _compound(tire), int(round(float(car.get("wear", 0.0)))), pit_text]
		card["status"].tooltip_text = "Jogo atual: %s (%d voltas). Próxima troca: %s. Controle: %s" % [tire, int(car.get("stint_laps", 0)), str(car.get("pit_target", "—")), str(car.get("pit_control_mode", "Manual"))]
		card["quick"].disabled = bool(car.get("finished", false)) or bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
		_update_driver_context(i)
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
			card["pace_picker"].disabled = host.team_control_mode != "Manual"
	elif mode == 2:
		var pit_state: String = "BOX CHAMADO" if bool(car.get("pit_request", false)) else ("V%d programada" % int(car.get("pit_scheduled_lap", 0)) if int(car.get("pit_scheduled_lap", 0)) > 0 else "Sem parada marcada")
		var advice: Dictionary = host.race.get_engineer_advice(int(car["id"]))
		var life: float = float(advice.get("life_laps", -1.0))
		values = [pit_state, ("%.1f voltas" % life if life >= 0.0 else "Sem estimativa")]
		if card.has("pit_mode_picker"):
			var pit_mode: OptionButton = card["pit_mode_picker"]
			pit_mode.select(1 if str(car.get("pit_control_mode", "Manual")) == "IA" else 0)
			pit_mode.disabled = host.team_control_mode != "Manual"
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

func _step_speed(direction: int) -> void:
	var current: int = SPEEDS.find(float(host.sim_speed))
	if current < 0:
		current = 2
	speed_index = clampi(current + direction, 0, SPEEDS.size() - 1)
	host._change_speed(speed_index)
	refresh_hud()

func _set_team_mode(index: int) -> void:
	host._select_live_team_mode(index)

func _set_view(index: int) -> void:
	if index == 0:
		host.visual_picker.select(1)
		host._change_visual_setting(1)
	elif index == 1:
		host.visual_picker.select(3)
		host._change_visual_setting(3)
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
		"dados": _build_data_window()
		"eventos": _build_events_window()
		"radio": _build_radio_window()
	layout_hud()
	_update_window_data()

func _build_race_window() -> void:
	overlay_title.text = "CONTROLE DA CORRIDA"
	_text(overlay_content, "Escolha a perspectiva sem reiniciar a prova.", 12, MUTED)
	var views := _line(overlay_content, 8)
	_btn(views, "MAPA 2D", _choose_view_window.bind(0), 150)
	_btn(views, "CÂMERA AÉREA", _choose_view_window.bind(1), 150)
	_btn(views, "DIRETOR TV", _choose_view_window.bind(2), 150)
	_text(overlay_content, "Câmera", 14, ACCENT)
	var cams := _line(overlay_content, 8)
	_btn(cams, "LIVRE", _choose_camera_mode.bind(0), 120)
	_btn(cams, "SEGUIR", _choose_camera_mode.bind(1), 120)
	_btn(cams, "DIRETOR", _choose_camera_mode.bind(2), 120)
	_text(overlay_content, "A classificação à esquerda permite seguir qualquer piloto.", 12, MUTED)

func _choose_view_window(index: int) -> void:
	_set_view(index)
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
		var frame := _panel(overlay_content, Color("#102035"))
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
	_text(overlay_content, "Sem projeção de tráfego pós-pit até o motor fornecer essa estimativa.", 11, MUTED)

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
	_text(overlay_content, "Céu: %s | Pista: %s | Água: %d%% | Previsão de chuva (15 min): %d%%" % [str(weather.get("sky", "—")), str(weather.get("track_state", "—")), int(weather.get("wetness", 0)), int(weather.get("rain_probability", 0))], 13)
	_text(overlay_content, "Ar %.1f°C  •  Pista %.1f°C  •  Vento %.1f km/h  •  Aderência %s" % [float(weather.get("air_c", 0.0)), float(weather.get("track_c", 0.0)), float(weather.get("wind", 0.0)), str(weather.get("grip", "—"))], 12, MUTED)
	_text(overlay_content, "TELEMETRIA DA EQUIPE", 15, ACCENT)
	for car in host.race.player_cars():
		_text(overlay_content, "%s  |  Última %s  |  Melhor %s  |  Posição P%d" % [str(car.get("name", "—")), host._format_lap(float(car.get("last_lap", 9999.0))), host._format_lap(float(car.get("best_lap", 9999.0))), int(car.get("position", 0))], 12)
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
	overlay_title.text = "HISTÓRICO DE RÁDIO"
	_text(overlay_content, "Comunicações e comentários que o jogo registrou nesta corrida.", 12, MUTED)
	var radio := RichTextLabel.new()
	radio.bbcode_enabled = true
	radio.fit_content = true
	radio.custom_minimum_size.y = 350
	radio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if host.commentary != null:
		radio.text = str(host.commentary.formatted(0))
	else:
		radio.text = "Aguardando comunicações."
	overlay_content.add_child(radio)

func _update_window_data() -> void:
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
