extends RefCounted
## Module extracted from main.gd v0.6.2.0. Works through the live scene host.
## Keeps existing callbacks while separating responsibilities.

static func _load_season_data(host) -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if typeof(raw) != TYPE_DICTIONARY:
		push_error("APEX: season_2012.json inválido.")
		return
	var season: Dictionary = raw
	host.season_title = str(int(season.get("season", 2012)))
	host.teams = season.get("teams", [])
	host.season_tracks = season.get("tracks", [])
	if host.teams.size() > 0:
		host.selected_team = str(host.teams[2]["name"]) if host.teams.size() > 2 else str(host.teams[0]["name"])
	if host.season_tracks.size() > 11:
		host.selected_track_index = 11
	else:
		host.selected_track_index = 0

static func _load_hud_prefs(host) -> void:
	var config := ConfigFile.new()
	if config.load("user://hud_layout_0611.cfg") != OK:
		return
	# Migrate 0.5.3.2 saved modes: 0 Complete, 1 Compact, 2 Cinema.
	if config.has_section_key("race", "broadcast_layout"):
		host.hud_layout_mode = clampi(int(config.get_value("race", "broadcast_layout", 0)), 0, 3)
	else:
		var old_mode: int = clampi(int(config.get_value("race", "layout", 0)), 0, 2)
		host.hud_layout_mode = [0, 2, 3][old_mode]
	host.left_panel_enabled = bool(config.get_value("race", "positions", true))
	host.right_panel_enabled = bool(config.get_value("race", "pit_wall", true))
	host.map_overlay_enabled = bool(config.get_value("race", "tactical_map", true))
	host.context_enabled = bool(config.get_value("race", "driver_context", false))
	host.show_panels = bool(config.get_value("race", "visible", true))
	host.card_fold_preferences.clear()
	for slot in range(2):
		var key := "driver_card_%d_folded" % slot
		if config.has_section_key("race", key):
			host.card_fold_preferences[slot] = bool(config.get_value("race", key, false))

static func _save_hud_prefs(host) -> void:
	var config := ConfigFile.new()
	config.load("user://hud_layout_0611.cfg")
	config.set_value("race", "broadcast_layout", host.hud_layout_mode)
	config.set_value("race", "positions", host.left_panel_enabled)
	config.set_value("race", "pit_wall", host.right_panel_enabled)
	config.set_value("race", "tactical_map", host.map_overlay_enabled)
	config.set_value("race", "driver_context", host.context_enabled)
	config.set_value("race", "visible", host.show_panels)
	for slot in host.card_fold_preferences.keys():
		config.set_value("race", "driver_card_%d_folded" % int(slot), bool(host.card_fold_preferences[slot]))
	config.save("user://hud_layout_0611.cfg")

static func _effective_hud_layout(host) -> int:
	# Internal values: 0 = complete, 1 = compact, 2 = cinema.
	match host.hud_layout_mode:
		0:
			var dimensions: Vector2 = host.get_viewport_rect().size
			return 1 if dimensions.x < 1500.0 or dimensions.y < 850.0 else 0
		1:
			return 0
		2:
			return 1
		_:
			return 2

static func _card_folded(host, slot: int) -> bool:
	if host.card_fold_preferences.has(slot):
		return bool(host.card_fold_preferences[slot])
	# In Auto/Cinema/Compacta, keep the broadcast view clean by default.
	# Selecting explicit Completa opens the controls until the user overrides.
	return host.hud_layout_mode != 1

static func _toggle_driver_card(host, slot: int) -> void:
	host.card_fold_preferences[slot] = not host._card_folded(slot)
	host._layout_ui()
	host._save_hud_prefs()

static func _toggle_all_driver_cards(host) -> void:
	var should_expand: bool = true
	for slot in range(2):
		if not host._card_folded(slot):
			should_expand = false
			break
	for slot in range(2):
		host.card_fold_preferences[slot] = not should_expand
	host._layout_ui()
	host._save_hud_prefs()

