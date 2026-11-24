extends RefCounted
## UI-only ranking panel builder. Keeps APEX HUD row hierarchy, style and signals.
## Caller owns layout, update timing, sorting, and user actions.
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")

static func build(parent: Node, rank_idle_style: StyleBoxFlat, rank_selected_style: StyleBoxFlat,
		panel: Callable, column: Callable, line: Callable, label: Callable, button: Callable,
		move_metric: Callable, select_car: Callable) -> Dictionary:
	var ranking: PanelContainer = panel.call(parent)
	var left: VBoxContainer = column.call(ranking, 3)
	var rank_header: HBoxContainer = line.call(left, 2)
	var prev: Button = button.call(rank_header, "‹", move_metric.bind(-1), 27)
	prev.tooltip_text = "Métrica anterior"
	var standings_title: Label = label.call(rank_header, "INTERVALO", 13, HudSkin.WHITE)
	standings_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	standings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next: Button = button.call(rank_header, "›", move_metric.bind(1), 27)
	next.tooltip_text = "Próxima métrica"
	var standings_scroll := ScrollContainer.new()
	standings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	standings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(standings_scroll)
	var entries: VBoxContainer = column.call(standings_scroll, 1)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var standing_rows: Array = []
	for i in range(24):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 24
		row.add_theme_constant_override("separation", 3)
		entries.add_child(row)
		var stripe := ColorRect.new()
		stripe.custom_minimum_size = Vector2(3, 20)
		stripe.color = HudSkin.MUTED
		row.add_child(stripe)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(22, 24)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.hide()
		row.add_child(portrait)
		var pos: Label = label.call(row, "%d" % (i + 1), 14, HudSkin.WHITE)
		pos.custom_minimum_size.x = 20
		var driver: Button = button.call(row, "---", select_car.bind(i), 43)
		driver.add_theme_stylebox_override("normal", rank_idle_style)
		driver.add_theme_stylebox_override("hover", HudSkin.button_style("rank_hover"))
		driver.add_theme_stylebox_override("pressed", rank_selected_style)
		driver.alignment = HORIZONTAL_ALIGNMENT_LEFT
		driver.add_theme_font_size_override("font_size", 14)
		driver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		driver.custom_minimum_size.y = 24
		var tyre: Label = label.call(row, "—", 13, HudSkin.MUTED)
		tyre.custom_minimum_size.x = 16
		tyre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var state: Label = label.call(row, "", 11, HudSkin.WARNING)
		state.custom_minimum_size.x = 31
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var detail: Label = label.call(row, "—", 14, HudSkin.WHITE)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.custom_minimum_size.x = 66
		standing_rows.append({"row":row, "stripe":stripe, "portrait":portrait, "pos":pos, "driver":driver,
			"tyre":tyre, "state":state, "detail":detail})
	return {"ranking": ranking, "standings_title": standings_title, "standing_rows": standing_rows}
