extends RefCounted
## Apex 0.6.2.4: legacy UI responsibility extracted from main.gd.
## New 0.6.2.2 race HUD and physics are independent of this compatibility layer.

static func _layout_ui(host) -> void:
	if host.screen == null:
		return
	var sz: Vector2 = host.get_viewport_rect().size
	# screen has FULL_RECT anchors; manually setting its size causes Godot warnings.
	if host.menu_root != null:
		var menu_card: Control = host.menu_root.get_node("MenuCard")
		# Responsive menu: enough width for the controls, while fitting small laptops.
		var menu_width: float = minf(1220.0, maxf(300.0, sz.x - 32.0))
		var menu_height: float = minf(760.0, maxf(280.0, sz.y - 28.0))
		menu_card.position = Vector2((sz.x - menu_width) * 0.5, maxf(12.0, (sz.y - menu_height) * 0.5))
		menu_card.size = Vector2(menu_width, menu_height)
		# On narrow screens, reclaim the decorative sidebar for the form.
		if host.menu_hero != null:
			host.menu_hero.visible = sz.x >= 1100.0
	if host.garage_root != null:
		var garage_card: Control = host.garage_root.get_node("GarageCard")
		var garage_width: float = minf(1120.0, maxf(460.0, sz.x - 42.0))
		var garage_height: float = minf(840.0, maxf(380.0, sz.y - 40.0))
		garage_card.position = Vector2((sz.x - garage_width) * 0.5, (sz.y - garage_height) * 0.5)
		garage_card.size = Vector2(garage_width, garage_height)
	if host.staff_root != null:
		var staff_width: float = minf(1240.0, maxf(420.0, sz.x - 36.0))
		var staff_height: float = minf(850.0, maxf(380.0, sz.y - 32.0))
		host.staff_card.position = Vector2((sz.x - staff_width)*0.5, (sz.y - staff_height)*0.5)
		host.staff_card.size = Vector2(staff_width, staff_height)
	if host.game_root == null:
		return
	var layout: int = host._effective_hud_layout()
	host._apply_hud_visibility()
	host.world_container.position = Vector2.ZERO
	# SubViewportContainer(stretch=true) owns the child viewport size.
	host.top_panel.position = Vector2(10, 8)
	host.top_panel.size = Vector2(sz.x - 20.0, 106.0)
	var side_margin: float = 10.0
	var left_width: float = 355.0 if sz.x >= 1750.0 else (340.0 if sz.x >= 1400.0 else 315.0)
	var right_width: float = 370.0 if sz.x >= 1750.0 else (350.0 if sz.x >= 1400.0 else 320.0)
	if layout == 1:
		left_width = minf(left_width, 340.0)
		right_width = minf(right_width, 350.0)
	host.bottom_bar.position = Vector2(side_margin, sz.y - 70.0)
	host.bottom_bar.size = Vector2(sz.x - side_margin * 2.0, 60.0)
	var side_top: float = 124.0
	var side_height: float = maxf(170.0, host.bottom_bar.position.y - side_top - 10.0)
	host.left_panel.position = Vector2(side_margin, side_top)
	host.left_panel.size = Vector2(left_width, side_height)
	host.right_panel.position = Vector2(sz.x - side_margin - right_width, side_top)
	host.right_panel.size = Vector2(right_width, side_height)
	# Overlay cards stay within the center, avoiding the side panels.
	var center_left: float = host.left_panel.position.x + host.left_panel.size.x + 12.0 if host.left_panel.visible else 16.0
	var center_right: float = host.right_panel.position.x - 12.0 if host.right_panel.visible else sz.x - 16.0
	var free_width: float = maxf(180.0, center_right - center_left)
	if host.telemetry_panel != null:
		host.telemetry_panel.position = Vector2(center_left + 4.0, side_top + 8.0)
		host.telemetry_panel.size = Vector2(minf(444.0, free_width - 12.0), 126.0)
	if host.tactical_map_panel != null:
		host.tactical_map_panel.position = Vector2(center_right - minf(280.0, free_width - 12.0) - 4.0, side_top + 8.0)
		host.tactical_map_panel.size = Vector2(minf(280.0, free_width - 12.0), 210.0)
	# Adapt from 1600×900 to laptop screens without covering either sidebar.
	if host.broadcast_speed_label != null:
		host.broadcast_speed_label.visible = sz.x >= 1510.0
		host.broadcast_camera_label.visible = sz.x >= 1510.0
		host.broadcast_driver_label.visible = sz.x >= 1600.0
		host.broadcast_zoom_minus.visible = sz.x >= 1250.0
		host.broadcast_zoom_plus.visible = sz.x >= 1250.0
		host.broadcast_center.visible = sz.x >= 1150.0
		host.broadcast_tv.visible = sz.x >= 1120.0
		host.broadcast_analytics.visible = sz.x >= 1080.0
		host.driver_picker.custom_minimum_size.x = 144.0 if sz.x >= 1250.0 else 108.0
		host.mode_picker.custom_minimum_size.x = 130.0 if sz.x >= 1250.0 else 106.0
		host.hud_hint.visible = false
	if host.player_card_strip != null:
		var middle_left: float = host.left_panel.position.x + host.left_panel.size.x + 12.0 if host.left_panel.visible else 16.0
		var middle_right: float = host.right_panel.position.x - 12.0 if host.right_panel.visible else sz.x - 16.0
		var middle_width: float = maxf(160.0, middle_right - middle_left)
		var gap_cards: float = 12.0
		var stacked: bool = middle_width < 510.0
		var width_card: float = minf(318.0, maxf(205.0, (middle_width - gap_cards) * 0.5))
		if stacked:
			width_card = minf(340.0, middle_width)
		var card_sizes: Array[float] = []
		for slot in range(host.player_cards.size()):
			var folded: bool = host._card_folded(slot)
			var size_y: float = 86.0 if folded else 250.0
			card_sizes.append(size_y)
			var card: Dictionary = host.player_cards[slot]
			card["details"].visible = not folded
			card["quick_pit"].visible = folded
			card["timing"].visible = not folded
			card["team"].visible = not folded or layout == 0
			card["fold"].text = "+" if folded else "−"
			card["fold"].tooltip_text = "Expandir controles" if folded else "Recolher controles"
		# Do not let two expanded stacked cards cross into the bottom control bar
		# on short windows. Keep card 1 open and auto-collapse card 2 visually.
		if stacked and card_sizes.size() >= 2:
			var stack_room: float = host.bottom_bar.position.y - (side_top + 18.0)
			if card_sizes[0] + card_sizes[1] + gap_cards > stack_room:
				card_sizes[1] = 86.0
				var lower: Dictionary = host.player_cards[1]
				lower["details"].visible = false
				lower["quick_pit"].visible = true
				lower["timing"].visible = false
				lower["fold"].text = "+"
				lower["fold"].tooltip_text = "Espaço limitado: aumente a janela para expandir os dois cartões"
		var total_width: float = width_card if stacked else (width_card * 2.0 + gap_cards)
		var total_height: float = 0.0
		if stacked:
			for h in card_sizes:
				total_height += h + gap_cards
			total_height = maxf(0.0, total_height - gap_cards)
		else:
			for h in card_sizes:
				total_height = maxf(total_height, h)
		var cards_x: float = middle_left + maxf(0.0, (middle_width - total_width) * 0.5)
		var cards_y: float = host.bottom_bar.position.y - total_height - 10.0
		host.player_card_strip.position = Vector2(cards_x, maxf(side_top + 8.0, cards_y))
		host.player_card_strip.size = Vector2(total_width, total_height)
		var cursor: float = 0.0
		for slot in range(host.player_cards.size()):
			var card: Dictionary = host.player_cards[slot]
			var panel: Control = card["panel"]
			panel.position = Vector2(0.0, cursor) if stacked else Vector2(float(slot) * (width_card + gap_cards), 0.0)
			panel.custom_minimum_size = Vector2(width_card, card_sizes[slot])
			panel.size = Vector2(width_card, card_sizes[slot])
			if stacked:
				cursor += card_sizes[slot] + gap_cards
	host._apply_hud_visibility()
	if host.race_hud_0620 != null:
		host.race_hud_0620.layout_hud()


static func _apply_hud_visibility(host) -> void:
	if host.left_panel == null or host.right_panel == null:
		return
	var layout: int = host._effective_hud_layout()
	host.left_panel.visible = host.show_panels and layout != 2 and host.left_panel_enabled
	host.right_panel.visible = host.show_panels and layout != 2 and host.right_panel_enabled
	if host.left_toggle_button != null:
		host.left_toggle_button.text = "POS: ON" if host.left_panel.visible else "POS: OFF"
	if host.right_toggle_button != null:
		host.right_toggle_button.text = "PIT: ON" if host.right_panel.visible else "PIT: OFF"
	if host.hud_button != null:
		host.hud_button.text = "HUD: ON" if host.show_panels else "HUD: OFF"
	if host.telemetry_panel != null:
		host.telemetry_panel.visible = host.show_panels and layout != 2 and host.context_enabled
	if host.tactical_map_panel != null:
		var center_space: float = host.right_panel.position.x - (host.left_panel.position.x + host.left_panel.size.x) if host.left_panel.visible and host.right_panel.visible else host.get_viewport_rect().size.x
		host.tactical_map_panel.visible = host.show_panels and layout != 2 and host.map_overlay_enabled and host.render_mode == 1 and (not host.context_enabled or center_space >= 780.0)
	if host.context_toggle_button != null:
		host.context_toggle_button.text = "PILOTO: ON" if host.context_enabled else "PILOTO"
	if host.tactical_map_button != null:
		host.tactical_map_button.text = "MAPA: ON" if host.map_overlay_enabled else "MAPA 2D"
	if host.player_card_strip != null:
		host.player_card_strip.visible = host.show_panels and layout != 2
	if host.cards_toggle_button != null:
		var all_folded: bool = host._card_folded(0) and host._card_folded(1)
		host.cards_toggle_button.text = "CARDS: +" if all_folded else "CARDS: −"
	# New presentation supersedes every legacy panel; these controls must
	# never receive clicks or duplicate race information in v0.6.2.
	if host.race_hud_0620 != null:
		for old_control in [host.top_panel, host.left_panel, host.right_panel, host.bottom_bar,
			host.telemetry_panel, host.tactical_map_panel, host.player_card_strip]:
			if old_control != null:
				old_control.hide()


static func _change_hud_layout(host, index: int) -> void:
	host.hud_layout_mode = clampi(index, 0, 3)
	if host.hud_layout_mode != 3:
		host.show_panels = true
	host._apply_hud_visibility()
	host._layout_ui()
	host._save_hud_prefs()


static func _toggle_left_panel(host) -> void:
	if host._effective_hud_layout() == 2:
		host.hud_layout_mode = 0
		host.hud_layout_picker.select(0)
		host.left_panel_enabled = true
	else:
		host.left_panel_enabled = not host.left_panel_enabled
	host.show_panels = true
	host._layout_ui()
	host._save_hud_prefs()


static func _toggle_right_panel(host) -> void:
	if host._effective_hud_layout() == 2:
		host.hud_layout_mode = 0
		host.hud_layout_picker.select(0)
		host.right_panel_enabled = true
	else:
		host.right_panel_enabled = not host.right_panel_enabled
	host.show_panels = true
	host._layout_ui()
	host._save_hud_prefs()


static func _toggle_context_panel(host) -> void:
	host.context_enabled = not host.context_enabled
	host._layout_ui()
	host._save_hud_prefs()


static func _toggle_tactical_map(host) -> void:
	host.map_overlay_enabled = not host.map_overlay_enabled
	host._layout_ui()
	host._save_hud_prefs()


static func _toggle_hud(host) -> void:
	if host.race_hud_0620 != null and host.game_root != null and host.game_root.visible:
		host.race_hud_0620.visible = not host.race_hud_0620.visible
		return
	host.show_panels = not host.show_panels
	host._apply_hud_visibility()
	host._layout_ui()
	host._save_hud_prefs()

