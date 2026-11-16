extends RefCounted
## Apex 0.6.2.4: legacy UI responsibility extracted from main.gd.
## New 0.6.2.2 race HUD and physics are independent of this compatibility layer.

const GREEN := Color("#46dcc0")
const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")
const MUTED := Color("#9eb8c8")
const WHITE := Color("#e9f4fd")
const YELLOW := Color("#ffce76")
static func _rebuild_player_cards(host) -> void:
	if host.player_card_strip == null:
		return
	for child in host.player_card_strip.get_children():
		host.player_card_strip.remove_child(child)
		child.queue_free()
	host.player_cards.clear()
	if host.race == null:
		return
	for car in host.race.player_cars():
		var card = host._create_player_card(car, host.player_cards.size())
		host.player_card_strip.add_child(card["panel"])
		host.player_cards.append(card)


static func _create_player_card(host, car: Dictionary, slot: int) -> Dictionary:
	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(290, 250)
	card_panel.add_theme_stylebox_override("panel", HudThemeScript.panel(Color(0.04, 0.08, 0.14, 0.95), 14, Color("#305774"), 10))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)
	card_panel.add_child(root)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	root.add_child(top)
	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(54, 60)
	var team_color: Color = Color.from_string(str(car.get("color", "#6dded2")), GREEN)
	portrait_panel.add_theme_stylebox_override("panel", HudThemeScript.panel(team_color.darkened(0.55), 12, team_color, 4))
	top.add_child(portrait_panel)
	var photo_texture: Texture2D = host.portrait_manager.get_photo(str(car.get("name", "")))
	if photo_texture != null:
		var photo := TextureRect.new()
		photo.texture = photo_texture
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.custom_minimum_size = Vector2(50, 56)
		portrait_panel.add_child(photo)
	else:
		var portrait_box := VBoxContainer.new()
		portrait_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		portrait_panel.add_child(portrait_box)
		var initials = host._label(portrait_box, host._driver_initials(str(car.get("name", "P"))), 22, WHITE)
		initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var tag = host._label(portrait_box, "2012", 9, team_color.lightened(0.35))
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.clip_text = true
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	var title = host._label(info, str(car.get("name", "Piloto")), 14, WHITE)
	title.clip_text = true
	var team_line = host._label(info, "%s • GRID P%d" % [str(car.get("team", "Equipe")), int(car.get("grid", 0))], 10, MUTED)
	team_line.clip_text = true
	var position = host._label(info, "P%02d • LAP 1/%02d" % [int(car.get("position", 0)), int(host.race.lap_count)], 12, GREEN)
	var timing = host._label(info, "Últ. —   Melhor —", 11, WHITE)
	timing.clip_text = true
	var status = host._label(info, "Ritmo Normal • Sem box solicitado", 9, MUTED)
	status.clip_text = true
	var fold_btn = host._button(top, "−", host._toggle_driver_card.bind(slot), 32)
	fold_btn.custom_minimum_size = Vector2(32, 30)
	fold_btn.tooltip_text = "Recolher cartão"
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 5)
	root.add_child(details)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 7)
	details.add_child(metrics)
	var tire_info = host._label(metrics, "PNEU —", 11, YELLOW)
	tire_info.custom_minimum_size.x = 72
	var wear_bar := ProgressBar.new()
	wear_bar.show_percentage = false
	wear_bar.min_value = 0
	wear_bar.max_value = 100
	wear_bar.value = 0
	wear_bar.custom_minimum_size = Vector2(70, 10)
	wear_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics.add_child(wear_bar)
	var wear_label = host._label(metrics, "0%", 10, MUTED)
	wear_label.custom_minimum_size.x = 36
	# An independently controlled 2012 KERS mode; 2012 HRT and Marussia have none.
	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 5)
	details.add_child(energy_row)
	var kers_button = host._button(energy_row, "KERS • EQ 400kJ", host._cycle_kers_mode.bind(int(car["id"])), 0)
	kers_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kers_button.custom_minimum_size.y = 27
	kers_button.add_theme_font_size_override("font_size", 10)
	kers_button.tooltip_text = "Alternar KERS: Economizar, Equilibrado, Atacar (máximo 400kJ/volta)"
	var drs_label = host._label(energy_row, "DRS: OFF", 10, MUTED)
	drs_label.custom_minimum_size.x = 64
	drs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var selectors := HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 6)
	details.add_child(selectors)
	var pace_picker = host._option(selectors, ["Conservar", "Normal", "Atacar"], host._change_pace.bind(int(car["id"])))
	pace_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pace_picker.custom_minimum_size = Vector2(0, 30)
	pace_picker.tooltip_text = "Ordem de ritmo do piloto"
	var tire_options: Array = host.race.available_pit_compounds()
	var tire_picker = host._option(selectors, tire_options, func(_i): pass)
	tire_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tire_picker.custom_minimum_size = Vector2(0, 30)
	var desired_tire: String = str(car.get("pit_target", "Duro"))
	tire_picker.select(maxi(0, tire_options.find(desired_tire)))
	tire_picker.tooltip_text = "Pneu da próxima parada • opções válidas para o GP"
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	details.add_child(buttons)
	var follow_btn = host._button(buttons, "SEGUIR", host._focus_driver.bind(int(car["id"])), 74)
	var pit_btn = host._button(buttons, "CHAMAR BOX", host._request_pit.bind(int(car["id"]), tire_picker), 0)
	pit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	details.add_child(mode_row)
	host._label(mode_row, "CONTROLE DE BOX", 10, MUTED)
	var mode_picker = host._option(mode_row, ["Manual", "IA"], host._change_pit_mode.bind(int(car["id"])))
	mode_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_picker.tooltip_text = "Manual: engenheiro apenas recomenda. IA: engenheiro decide e chama boxes; ordens agendadas prevalecem."
	# Explicit scheduling is distinct from the NEXT-ENTRY BOX command.
	var schedule_row := HBoxContainer.new()
	schedule_row.add_theme_constant_override("separation", 5)
	details.add_child(schedule_row)
	host._label(schedule_row, "VOLTA", 10, MUTED)
	var pit_lap := SpinBox.new()
	pit_lap.min_value = 1.0
	pit_lap.max_value = float(maxi(1, int(host.race.lap_count) - 1))
	pit_lap.step = 1.0
	pit_lap.value = float(mini(int(host.race.lap_count) - 1, int(car.get("laps_done", 0)) + 2))
	pit_lap.custom_minimum_size = Vector2(77, 28)
	pit_lap.tooltip_text = "Volta exata em que o carro entrará no pit lane"
	schedule_row.add_child(pit_lap)
	var schedule_btn = host._button(schedule_row, "AGENDAR BOX", host._schedule_pit.bind(int(car["id"]), tire_picker, pit_lap), 0)
	schedule_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cancel_btn = host._button(schedule_row, "CANCELAR", host._cancel_scheduled_pit.bind(int(car["id"])), 0)
	cancel_btn.visible = false
	var quick_pit = host._button(top, "BOX", host._request_pit.bind(int(car["id"]), tire_picker), 42)
	quick_pit.custom_minimum_size = Vector2(42, 30)
	quick_pit.tooltip_text = "Chamar box usando o pneu selecionado; expanda para mudar o composto."
	var record := {"panel": card_panel, "id": int(car["id"]), "position": position, "timing": timing, "status": status, "title": title, "team": team_line, "follow": follow_btn, "pit": pit_btn, "quick_pit": quick_pit, "pace": pace_picker, "tire": tire_picker, "details": details, "fold": fold_btn, "slot": slot, "tire_info": tire_info, "wear_bar": wear_bar, "wear_label": wear_label, "kers_button": kers_button, "drs_label": drs_label, "schedule_lap": pit_lap, "schedule_button": schedule_btn, "cancel_schedule": cancel_btn, "pit_mode": mode_picker}
	return record


static func _refresh_player_cards(host) -> void:
	if host.race == null or host.player_cards.is_empty():
		return
	for card in host.player_cards:
		var car: Dictionary = host._car_by_id(int(card["id"]))
		if car.is_empty():
			continue
		var pos: int = int(car.get("position", 0))
		var wear_value: float = float(car.get("wear", 0.0))
		card["position"].text = "P%02d • LAP %d/%02d" % [pos, int(car.get("laps_done", 0)) + 1, int(host.race.lap_count)]
		card["position"].add_theme_color_override("font_color", GREEN if int(card["id"]) == host.manual_driver else WHITE)
		card["timing"].text = "Últ. %s   Melhor %s" % [host._format_lap(float(car.get("last_lap", 9999.0))), host._format_lap(float(car.get("best_lap", 9999.0)))]
		var pit_status := "Na pista"
		if float(car.get("pit_left", 0.0)) > 0.0:
			pit_status = "Nos boxes • %s" % str(car.get("pit_stage", "service")).capitalize()
		elif bool(car.get("pit_request", false)):
			pit_status = "Box solicitado • %s" % str(car.get("pit_target", "Médio"))
		elif int(car.get("pit_scheduled_lap", 0)) > 0:
			pit_status = "BOX V%d agendado • %s" % [int(car["pit_scheduled_lap"]), str(car.get("pit_target", "Médio"))]
		if host._card_folded(int(card["slot"])):
			var short_status: String = "BOX" if bool(car.get("pit_request", false)) else ("PIT" if float(car.get("pit_left", 0.0)) > 0.0 else str(car.get("pace", "Normal")))
			card["status"].text = "%s %d%% • %s" % [host._compound_code(str(car.get("tire", "Médio"))), int(round(wear_value)), short_status]
		else:
			var contest_state: String = str(car.get("combat_state", "clear"))
			var contest_text: String = " • DISPUTA" if contest_state in ["attacking", "duel", "defending"] else ""
			card["status"].text = "Ritmo %s • %s%s" % [str(car.get("pace", "Normal")), pit_status, contest_text]
		card["title"].text = str(car.get("name", "Piloto"))
		card["team"].text = "%s • GRID P%d" % [str(car.get("team", "Equipe")), int(car.get("grid", 0))]
		card["follow"].text = "NA CÂMERA" if int(card["id"]) == host.manual_driver else "SEGUIR"
		var pace_idx: int = ["Conservar", "Normal", "Atacar"].find(str(car.get("pace", "Normal")))
		if pace_idx >= 0 and card["pace"].selected != pace_idx:
			card["pace"].select(pace_idx)
		var pit_mode_index: int = 1 if str(car.get("pit_control_mode", "Manual")) == "IA" else 0
		card["pit_mode"].disabled = host._engineer_mode_for(int(car["id"])) == "Automático"
		card["pace"].disabled = host._engineer_mode_for(int(car["id"])) != "Manual"
		if card["pit_mode"].selected != pit_mode_index:
			card["pit_mode"].select(pit_mode_index)
		var pit_active: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
		var pit_scheduled: bool = int(car.get("pit_scheduled_lap", 0)) > 0
		card["schedule_button"].disabled = pit_active or bool(car.get("finished", false)) or int(car.get("laps_done", 0)) >= int(host.race.lap_count) - 1
		card["cancel_schedule"].visible = pit_scheduled and not pit_active
		var lap_choice: SpinBox = card["schedule_lap"]
		lap_choice.min_value = float(mini(int(host.race.lap_count) - 1, int(car.get("laps_done", 0)) + 1))
		card["pit"].disabled = pit_active or bool(car.get("finished", false))
		card["quick_pit"].disabled = pit_active or bool(car.get("finished", false))
		card["quick_pit"].text = "PIT" if pit_active else "BOX"
		card["pit"].text = "BOX SOLICITADO" if pit_active else "CHAMAR BOX"
		card["tire_info"].text = "PNEU %s" % host._compound_code(str(car.get("tire", "Médio")))
		card["tire_info"].add_theme_color_override("font_color", host._tyre_color(str(car.get("tire", "Médio"))))
		card["wear_bar"].value = wear_value
		var fill = host._wear_color(wear_value)
		card["wear_bar"].add_theme_stylebox_override("fill", HudThemeScript.panel(fill, 5, fill, 0))
		card["wear_label"].text = "%d%%" % int(round(wear_value))
		card["wear_label"].add_theme_color_override("font_color", host._wear_color(wear_value))
		var energy: Dictionary = host.race.get_race_control_status(int(car["id"]))
		var kers_enabled: bool = bool(energy.get("kers_equipped", false))
		var remaining_kj: float = float(energy.get("kers_remaining_kj", 0.0))
		var kers_mode: String = str(energy.get("kers_mode", "Equilibrado"))
		var kers_short := "EQ"
		if kers_mode == "Economizar":
			kers_short = "ECO"
		elif kers_mode == "Atacar":
			kers_short = "ATQ"
		var power_kw: float = float(energy.get("kers_power_kw", 0.0))
		var kers_gain: float = float(energy.get("kers_gain_lap_s", 0.0))
		var drs_gain: float = float(energy.get("drs_gain_lap_s", 0.0))
		card["kers_button"].text = ("KERS %s %dkW • %dkJ" % [kers_short, int(round(power_kw)), int(round(remaining_kj))] if power_kw > 0.1 else "KERS %s • %dkJ" % [kers_short, int(round(remaining_kj))]) if kers_enabled else "SEM KERS"
		card["kers_button"].tooltip_text = "Modo %s | potência atual %.0f kW | ganho estimado nesta volta: %.2fs. Clique para alternar." % [kers_mode, power_kw, kers_gain]
		var kers_bg: Color = Color("#146f67") if power_kw > 0.1 else Color("#11263b")
		card["kers_button"].add_theme_stylebox_override("normal", HudThemeScript.panel(kers_bg, 7, GREEN if power_kw > 0.1 else Color("#385670"), 4))
		card["kers_button"].disabled = not kers_enabled or bool(car.get("finished", false)) or host._engineer_mode_for(int(car["id"])) != "Manual"
		var drs_on: bool = bool(energy.get("drs_active", false))
		var drs_available: bool = bool(energy.get("drs_track_enabled", true))
		card["drs_label"].text = "DRS ABERTO" if drs_on else ("DRS CHUVA" if not drs_available else ("DRS V3" if int(car.get("laps_done", 0)) < 2 else "DRS OFF"))
		card["drs_label"].tooltip_text = "DRS: ganho estimado nesta volta %.2fs; exige até 1s no ponto de detecção, zona de ativação e pista seca." % drs_gain
		card["drs_label"].add_theme_color_override("font_color", GREEN if drs_on else MUTED)


static func _driver_initials(host, full_name: String) -> String:
	var parts := full_name.split(" ", false)
	if parts.is_empty():
		return "AP"
	if parts.size() == 1:
		return parts[0].substr(0, mini(2, parts[0].length())).to_upper()
	return (parts[0].substr(0, 1) + parts[parts.size() - 1].substr(0, 1)).to_upper()


static func _focus_driver(host, car_id: int) -> void:
	host.manual_driver = car_id
	host.pitwall_focus_driver = car_id
	if host.race != null:
		var target_name := ""
		for car in host.race.cars:
			if int(car["id"]) == car_id:
				target_name = str(car["name"])
				break
		for j in range(1, host.driver_picker.item_count):
			if host.driver_picker.get_item_text(j) == target_name:
				host.driver_picker.select(j)
				break
	host.mode_picker.select(1)
	host._change_camera_mode(1)


static func _focus_player_slot(host, slot: int) -> void:
	if host.race == null:
		return
	var cars_owned: Array = host.race.player_cars()
	if slot >= 0 and slot < cars_owned.size():
		host._focus_driver(int(cars_owned[slot]["id"]))


static func _cycle_kers_mode(host, car_id: int) -> void:
	if host.race == null or host._engineer_mode_for(car_id) != "Manual":
		return
	var energy: Dictionary = host.race.get_race_control_status(car_id)
	if not bool(energy.get("kers_equipped", false)):
		return
	var modes: Array = ["Economizar", "Equilibrado", "Atacar"]
	var current: int = modes.find(str(energy.get("kers_mode", "Equilibrado")))
	host.race.set_kers_mode(car_id, str(modes[(current + 1) % modes.size()]))
	host._refresh_player_cards()


static func _open_driver_strategy(host, car_id: int) -> void:
	host.pitwall_focus_driver = car_id
	host.hud_layout_mode = 0
	host.show_panels = true
	host.right_panel_enabled = true
	host._layout_ui()
	if host.tabs != null:
		host.tabs.current_tab = 0
	host._set_pitwall_mode(2)

