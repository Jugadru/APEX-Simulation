extends RefCounted
## APEX 0.6.4.9.5 — pre-race preview and explicit manual first-stop booking.
## Only manual selections are booked on the real engine. Automatic remains unchanged.
const Race = preload("res://scripts/race_engine.gd")
const Planner = preload("res://scripts/core/race_pre_race_strategy_06495.gd")
const Chart = preload("res://scripts/apex_pre_race_tyre_chart_06495.gd")
const PanelTheme = preload("res://scripts/apex_hud_theme.gd")
const ORANGE := Color("#ff7900")
const WHITE := Color("#eef2f7")
const MUTED := Color("#a9b6c4")

static func fingerprint(host) -> String:
	if host.season_tracks.is_empty():
		return ""
	var track: Dictionary = host.season_tracks[host.selected_track_index]
	var seed_value: int = int(host.championship.round_seed()) if host.championship_mode else int(host.seed_picker.value)
	var weather_name: String = host.weather_mode_picker.get_item_text(host.weather_mode_picker.selected)
	return JSON.stringify([host.selected_team,str(track.get("code","")),seed_value,weather_name,
		host.team_control_mode,bool(host.championship_mode),host.garage.get_team(host.selected_team).get("levels",{})])

static func _label(parent: Node, content: String, size_px: int = 13, tint: Color = WHITE, wrap_text: bool = false) -> Label:
	var label := Label.new()
	label.text = content
	label.add_theme_font_size_override("font_size",size_px)
	label.add_theme_color_override("font_color",tint)
	if wrap_text:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

static func _col(parent: Node, gap: int = 7) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",gap)
	parent.add_child(box)
	return box

static func _button(parent: Node, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 42
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

static func _plan_brief(plan: Dictionary, total_laps: int) -> String:
	if not bool(plan.get("valid",false)):
		return str(plan.get("reason","Plano indisponível"))
	var lines: Array[String] = []
	var stint_index: int = 0
	for block in plan["stints"]:
		stint_index += 1
		lines.append("%d. %-14s  V%02d–%02d   %d voltas   |  condição final ~%.0f%%" % [
			stint_index,str(block["compound"]),int(block["from"]),int(block["to"]),int(block["laps"]),
			100.0-float(block["wear_end"])])
	var first: Dictionary = plan["stints"][0]
	var win: int = int(first["to"])
	lines.append("Janela projetada inicial: V%d–V%d (centro V%d)" % [maxi(1,win-2),mini(total_laps-1,win+2),win])
	if plan.has("adjustment"):
		lines.append(str(plan["adjustment"]))
	return "\n".join(lines)

static func show(host) -> void:
	if host.season_tracks.is_empty():
		return
	var track: Dictionary = host.season_tracks[host.selected_track_index]
	var seed_value: int = int(host.championship.round_seed()) if host.championship_mode else int(host.seed_picker.value)
	var preview = Race.new(host.teams,host.selected_team,seed_value,
		host.garage.get_team(host.selected_team)["levels"],track,
		host.garage.effective_crew_levels(host.selected_team))
	if host.championship_mode:
		preview.set_championship_round(int(host.championship.state.get("round_index",0)))
		preview.set_rival_development(host.championship.get_rival_levels())
	if host.weather_mode_picker != null:
		preview.configure_weather(host.weather_mode_picker.get_item_text(host.weather_mode_picker.selected))
	var output: Dictionary = Planner.generate(preview)
	if host.pre_race_strategy_dialog != null and is_instance_valid(host.pre_race_strategy_dialog):
		host.pre_race_strategy_dialog.queue_free()
	var popup := Window.new()
	popup.name = "PreRaceStrategy06495"
	popup.title = "APEX | Estratégia inicial de corrida v0.6.4.9.5"
	popup.min_size = Vector2i(760,520)
	popup.size = Vector2i(1180,720)
	popup.theme = PanelTheme.build()
	popup.close_requested.connect(popup.hide)
	host.menu_root.add_child(popup)
	host.pre_race_strategy_dialog = popup
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_stylebox_override("panel",PanelTheme.panel(Color("#121923"),10,Color("#47505a"),15))
	popup.add_child(shell)
	var page := _col(shell,11)
	_label(page,"ESTRATÉGIA PRÉ-CORRIDA  /  APEX",23,ORANGE)
	_label(page,"%s  •  %d voltas  •  %s  •  %s" % [str(track.get("name","GP")),int(preview.lap_count),host.selected_team,host.team_control_mode],13,WHITE)
	var note := _label(page,"Projeção determinística a partir dos compostos disponíveis, desgaste estimado e tempo de box. Não prevê ultrapassagens, chuva futura nem paradas rivais.",12,MUTED,true)
	note.custom_minimum_size.y = 35
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(content)
	for i in range(2):
		var plan: Dictionary = output.get("plans",[])[i] if output.get("plans",[]).size() > i else {}
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",PanelTheme.panel(Color("#202934"),8,Color("#3e4650"),12))
		content.add_child(card)
		var stack := _col(card,9)
		_label(stack,"CARRO %d — %s" % [i+1,str(plan.get("name","Piloto"))],16,ORANGE)
		_label(stack,"PNEU DE LARGADA: %s" % str(plan.get("start","—")),12,WHITE)
		var chart = Chart.new()
		chart.custom_minimum_size = Vector2(440,185)
		chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_child(chart)
		chart.set_plan(plan,int(preview.lap_count))
		var lines := _label(stack,_plan_brief(plan,int(preview.lap_count)),12,WHITE,true)
		lines.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_label(stack,"Curva: condição estimada (100% → 0%). Laranja: parada.",11,MUTED,true)
	var statuses := ""
	if bool(output.get("first_stop_overlap",false)):
		statuses = "ATENÇÃO: primeira parada projetada na mesma volta; confirme ou revise manualmente durante a corrida."
	elif not bool(output.get("valid",false)):
		statuses = str(output.get("reason","Não foi possível calcular os planos."))
	else:
		statuses = "Janelas dos dois carros calculadas; as paradas futuras continuam sob avaliação durante o GP."
	var alert := _label(page,statuses,12,ORANGE,true)
	alert.custom_minimum_size.y = 33
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation",12)
	page.add_child(bottom)
	var manual: bool = host.team_control_mode == "Manual"
	var applicable: bool = bool(output.get("valid",false)) and not bool(output.get("first_stop_overlap",false))
	for plan in output.get("plans",[]):
		applicable = applicable and bool(plan.get("valid",false))
	var action := _button(bottom,"APLICAR PRIMEIRAS PARADAS (MANUAL)",func(): _approve(host,output,popup))
	action.disabled = not manual or not applicable
	action.tooltip_text = "Somente em Manual: agenda a PRIMEIRA parada de cada carro. Outras paradas são recomendações, não ordens."
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dismiss := _button(bottom,"FECHAR / APENAS CONSULTAR",popup.hide)
	dismiss.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not manual:
		_label(page,"MODO AUTOMÁTICO: apenas visualização. A IA preserva a própria autoridade sobre box durante o GP.",11,MUTED)
	else:
		_label(page,"Nenhuma parada é agendada até clicar APLICAR. Alterar equipe, GP, seed, clima ou modo invalida o plano salvo.",11,MUTED)
	popup.popup_centered(Vector2i(1180,720))

static func _approve(host, data: Dictionary, window: Window) -> void:
	if host.team_control_mode != "Manual" or not bool(data.get("valid",false)) or bool(data.get("first_stop_overlap",false)):
		return
	var bookings: Array = []
	for plan in data.get("plans",[]):
		if not bool(plan.get("valid",false)) or plan.get("stints",[]).size() < 2:
			return
		var first: Dictionary = plan["stints"][0]
		bookings.append({"id":int(plan["id"]),"lap":int(first["to"]),"target":str(plan["stints"][1]["compound"])})
	host.pre_race_strategy_pending = {"fingerprint":fingerprint(host),"bookings":bookings}
	if host.pre_race_strategy_status != null:
		host.pre_race_strategy_status.text = "Plano confirmado: duas primeiras paradas serão agendadas ao entrar no grid."
	window.hide()

static func apply_pending(host) -> void:
	var plan: Dictionary = host.pre_race_strategy_pending.duplicate(true)
	host.pre_race_strategy_pending.clear()
	if plan.is_empty():
		return
	if str(plan.get("fingerprint","")) != fingerprint(host) or host.team_control_mode != "Manual":
		if host.pre_race_strategy_status != null:
			host.pre_race_strategy_status.text = "Plano anterior descartado: as configurações de corrida mudaram."
		return
	if host.race == null:
		return
	var planned: Array = plan.get("bookings",[])
	if planned.size() != 2 or int(planned[0]["lap"]) == int(planned[1]["lap"]):
		return
	# Validate every order before any mutation to keep the application atomic.
	var eligible: Array = host.race.available_pit_compounds()
	var actual: Array = host.race.player_cars()
	for booking in planned:
		if not eligible.has(str(booking["target"])) or int(booking["lap"]) >= int(host.race.lap_count) or int(booking["lap"]) < 1:
			return
		var present: bool = false
		for car in actual:
			if int(car["id"]) == int(booking["id"]):
				present = true
		if not present:
			return
	for booking in planned:
		var ok: bool = host.race.schedule_pit(int(booking["id"]),str(booking["target"]),int(booking["lap"]))
		if not ok:
			push_error("APEX 06495: erro inesperado ao aplicar plano inicial")
