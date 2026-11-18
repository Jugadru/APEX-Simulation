extends RefCounted
## 0.6.6.8.12 — historical 2012 presentation; never mutates racing state.
const Tyres = preload("res://scripts/core/race_tyres_2012.gd")
const REFERENCE_PATH := "res://data/season_reference_2012.json"
const COMPOUND_ORDER := ["Supermacio", "Macio", "Médio", "Duro", "Intermediário", "Chuva"]
const WHITE := Color("#F3F5F6")
const MUTED := Color("#B7C3CC")
const ACCENT := Color("#FF8A21")

static func _load_reference_catalog() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func snapshot(teams: Array, tracks: Array) -> Dictionary:
	# Immutable projection of existing sources, without touching race rules.
	var meta: Dictionary = _load_reference_catalog()
	var tyre_data: Dictionary = Tyres.catalog()
	var compounds: Dictionary = tyre_data.get("compounds", {})
	var models: Dictionary = meta.get("chassis_by_team", {})
	var dates: Dictionary = meta.get("race_dates", {})
	var tyre_list: Array = []
	var team_list: Array = []
	var calendar: Array = []
	for name in COMPOUND_ORDER:
		var spec: Dictionary = compounds.get(name, {})
		tyre_list.append({"name": name, "code": str(spec.get("code", "")),
			"color": str(spec.get("color", "")),
			"wet": name in ["Intermediário", "Chuva"]})
	for team in teams:
		var name: String = str(team.get("name", ""))
		var model: Dictionary = models.get(name, {})
		var drivers: Array[String] = []
		for driver in team.get("drivers", []):
			drivers.append(str(driver.get("name", "")))
		team_list.append({"name": name, "chassis": str(model.get("model", "")),
			"engine": str(model.get("engine", "")),
			"color": str(team.get("color", "#FFFFFF")), "drivers": drivers})
	for index in range(tracks.size()):
		var track: Dictionary = tracks[index]
		var code: String = str(track.get("code", ""))
		var nomination: Dictionary = tyre_data.get("tracks", {}).get(code, {})
		calendar.append({"round": index + 1, "code": code,
			"date": str(dates.get(code, "")),
			"circuit": str(track.get("name", "")),
			"country": str(track.get("country", "")),
			"laps": int(track.get("laps", 0)),
			"dry": nomination.get("dry", []).duplicate()})
	return {"season": int(meta.get("season", 0)),
		"tyres": tyre_list, "teams": team_list, "calendar": calendar}

static func _label(parent: Node, value: String, size_px: int = 13, color: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

static func _column(parent: Node, gap: int = 7) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", gap)
	parent.add_child(box)
	return box

static func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	return row

static func _swatch(parent: Node, color: String) -> void:
	var swatch := ColorRect.new()
	swatch.color = Color.from_string(color, MUTED)
	swatch.custom_minimum_size = Vector2(26, 24)
	parent.add_child(swatch)

static func _action(parent: Node, text_value: String, callback: Callable, locked: bool) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(130, 30)
	button.disabled = locked
	button.tooltip_text = "Etapa ou equipe controlada pela carreira." if locked else "Selecionar no menu, sem iniciar corrida."
	button.pressed.connect(callback)
	parent.add_child(button)

static func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	return _column(scroll)

static func _pick_team(host, index: int, dialog: AcceptDialog) -> void:
	if host.championship_mode or index < 0 or index >= host.teams.size():
		return
	host.team_picker.select(index)
	host._on_team_selected(index)
	dialog.hide()

static func _pick_track(host, index: int, dialog: AcceptDialog) -> void:
	if host.championship_mode or index < 0 or index >= host.season_tracks.size():
		return
	host.track_picker.select(index)
	host._on_track_selected(index)
	dialog.hide()

static func _build(host) -> AcceptDialog:
	var data: Dictionary = snapshot(host.teams, host.season_tracks)
	var dialog := AcceptDialog.new()
	dialog.name = "Season2012Guide"
	dialog.title = "APEX | GUIA DA TEMPORADA 2012"
	dialog.min_size = Vector2i(850, 560)
	dialog.size = Vector2i(1080, 720)
	dialog.get_ok_button().text = "FECHAR GUIA"
	host.menu_root.add_child(dialog)
	var shell := _column(dialog)
	shell.custom_minimum_size = Vector2(990, 610)
	_label(shell, "2012  •  PNEUS, CHASSIS E CALENDÁRIO", 21, ACCENT)
	var summary := _label(shell, "", 12, MUTED)
	summary.name = "Season2012Selection"
	_label(shell, "Dados históricos de apresentação. A física, o desempenho e o desgaste são do APEX.", 11, MUTED)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size.y = 480
	shell.add_child(tabs)
	var tyres := _tab(tabs, "PNEUS")
	_label(tyres, "PIRELLI 2012  •  QUATRO SLICKS + DOIS DE CHUVA", 16, ACCENT)
	for item in data["tyres"]:
		var line := _row(tyres)
		_swatch(line, str(item["color"]))
		var status: String = "MOLHADO" if bool(item["wet"]) else "SECO"
		_label(line, "%s  [%s]  •  %s" % [str(item["name"]), str(item["code"]), status], 14)
	_label(tyres, "2012: Supermacio vermelho, Macio amarelo, Médio branco, Duro prata, Intermediário verde, Chuva azul.", 12, MUTED)
	_label(tyres, "A engine mantém duas opções slick homologadas por GP mais os pneus para pista molhada.", 12, MUTED)
	var teams := _tab(tabs, "CARROS E EQUIPES")
	_label(teams, "12 CHASSIS HISTÓRICOS  •  24 PILOTOS  •  MOTORES V8", 16, ACCENT)
	for i in range(data["teams"].size()):
		var item: Dictionary = data["teams"][i]
		var line := _row(teams)
		_swatch(line, str(item["color"]))
		var body := _column(line, 2)
		_label(body, "%s  •  %s" % [str(item["name"]), str(item["chassis"])], 14)
		_label(body, "%s  |  %s" % [str(item["engine"]), " / ".join(PackedStringArray(item["drivers"]))], 11, MUTED)
		_action(line, "ESCOLHER EQUIPE", _pick_team.bind(host, i, dialog), bool(host.championship_mode))
	_label(teams, "Nomes e cores de referência; não foram adicionados modelos 3D nem pinturas externas.", 11, MUTED)
	var calendar := _tab(tabs, "CALENDÁRIO")
	_label(calendar, "20 ETAPAS  •  DATAS OFICIAIS 2012  •  NOMINAÇÕES APEX", 16, ACCENT)
	for i in range(data["calendar"].size()):
		var item: Dictionary = data["calendar"][i]
		var iso: String = str(item["date"])
		var date_label: String = iso.substr(8, 2) + "/" + iso.substr(5, 2) + "/" + iso.substr(0, 4) if iso.length() == 10 else "DATA INDISPONÍVEL"
		var line := _row(calendar)
		var body := _column(line, 2)
		_label(body, "%02d  •  %s  •  %s" % [int(item["round"]), date_label, str(item["circuit"])], 13)
		var choices: Array = item["dry"]
		_label(body, "%s  |  %d voltas  |  %s" % [str(item["country"]), int(item["laps"]), " + ".join(PackedStringArray(choices))], 11, MUTED)
		_action(line, "PREPARAR GP", _pick_track.bind(host, i, dialog), bool(host.championship_mode))
	_label(calendar, "Fonte: calendário FIA 2012. Não reproduz resultados históricos automaticamente.", 11, MUTED)
	return dialog

static func show(host) -> void:
	if host == null or host.menu_root == null:
		return
	var dialog: AcceptDialog = host.menu_root.get_node_or_null("Season2012Guide") as AcceptDialog
	if dialog == null:
		dialog = _build(host)
	var summary: Label = dialog.find_child("Season2012Selection", true, false) as Label
	if summary != null:
		var current_gp: String = ""
		if host.selected_track_index >= 0 and host.selected_track_index < host.season_tracks.size():
			current_gp = str(host.season_tracks[host.selected_track_index].get("name", ""))
		summary.text = "Equipe: %s  •  GP: %s%s" % [
			str(host.selected_team), current_gp,
			"  •  Controles da carreira ativos" if host.championship_mode else ""]
	dialog.popup_centered(Vector2i(1080, 720))
