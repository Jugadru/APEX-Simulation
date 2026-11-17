extends RefCounted
const UI = preload("res://scripts/apex_management_style.gd")
const Inventory = preload("res://scripts/core/component_inventory_0651.gd")
var hub
var body: VBoxContainer
var listing: VBoxContainer
var details: VBoxContainer
var notice: Label
var status: Label
var selected := ""
var car := 1
var view := "car"
var selectors: Dictionary = {}

func setup(parent: Node, manager) -> void:
	hub = manager
	body = UI.column(parent, 12)
	var banner := UI.card(body, "LIVING FACTORY — COMPONENT MANAGEMENT")
	UI.label(banner, "01 / OFICINA     •     MOTOR / ASA / CHASSI", 14, UI.ORANGE)
	status = UI.label(banner, "", 16, UI.MUTED)
	var tabs := UI.row(body, 8)
	for entry in [["car1", "CAR 01"], ["car2", "CAR 02"], ["inventory", "INVENTORY / ESTOQUE"]]:
		var b := UI.button(tabs, entry[1], switch_view.bind(entry[0]))
		b.toggle_mode = true
		selectors[entry[0]] = b
	var columns := UI.row(body, 16)
	listing = UI.column(columns, 10)
	listing.size_flags_stretch_ratio = 1.1
	details = UI.column(columns, 10)
	listing.custom_minimum_size.x = 400
	details.custom_minimum_size.x = 420
	notice = UI.label(body, "Selecione um componente para consultar seu histórico.", 16, UI.ORANGE)
	UI.label(body, "Quilometragem registrada desde a migração • distância equivalente no circuito. Condição diagnosticada pela oficina, sem alterar as fórmulas de corrida. Especificação segue o nível compartilhado do P&D existente.", 14, UI.MUTED)

func switch_view(key: String) -> void:
	view = "inventory" if key == "inventory" else "car"
	if key == "car1": car = 1
	if key == "car2": car = 2
	selected = ""
	refresh()

func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func refresh() -> void:
	clear(listing)
	clear(details)
	var state: Dictionary = hub.host.garage.get_team(hub.host.selected_team)
	var inventory: Dictionary = state.component_inventory
	var error := Inventory.validate(inventory, hub.host.garage.PARTS)
	status.text = "CONSULTA / SESSÃO EM CURSO — operações bloqueadas" if hub.host.garage.inventory_locked else "OFICINA ABERTA • alterações salvas automaticamente"
	for key in selectors:
		selectors[key].set_pressed_no_signal(key == ("inventory" if view == "inventory" else "car%d" % car))
	if not error.is_empty():
		UI.label(listing, error, 20, UI.ORANGE)
		return
	var count := 0
	var shown: Array[String] = []
	for id in inventory.parts:
		var p: Dictionary = inventory.parts[id]
		if view == "car" and int(p.car) != car: continue
		if view == "inventory" and p.status == "installed": continue
		shown.append(id)
		count += 1
		var card := UI.card(listing, "%s / SPEC %d" % [str(p.name).to_upper(), int(p.specification)])
		UI.label(card, "%s    •    %.3f km" % [state_name(p.status), float(p.km)], 16, UI.GREEN if p.status != "unusable" else UI.ORANGE)
		UI.label(card, "ID " + str(id), 12, UI.MUTED)
		UI.button(card, "INSPECIONAR  →", select_part.bind(id), id == selected)
	if count == 0: UI.label(listing, "Nenhuma peça nesta área. Remova um componente instalado para disponibilizá-lo no estoque.", 20, UI.MUTED)
	if view == "car":
		for category in hub.host.garage.PARTS:
			if Inventory.installed(inventory, car, category).is_empty():
				UI.label(listing, "%s / SLOT VAZIO — instale uma peça antes da corrida" % category, 17, UI.ORANGE)
	if selected.is_empty() and not shown.is_empty(): selected = shown[0]
	if not inventory.parts.has(selected):
		UI.label(details, "COMPONENT DETAILS\nSelecione um componente.", 22)
		return
	var p: Dictionary = inventory.parts[selected]
	var detail := UI.card(details, "COMPONENT DETAILS")
	UI.label(detail, "%s • especificação %d" % [p.name, int(p.specification)], 25)
	UI.label(detail, "CAR %02d" % int(p.car) if int(p.car) > 0 else "SEM VÍNCULO / " + state_name(p.status), 15, UI.ORANGE)
	UI.label(detail, "CONSERVAÇÃO — %s\nLIMITE DE RECUPERAÇÃO — %s\nDISTÂNCIA — %.3f km\nUso anterior desconhecido preservado" % ["Diagnóstico pendente" if p.condition == null else "%.1f%%" % float(p.condition), "Diagnóstico pendente" if p.integrity == null else "%.1f%%" % float(p.integrity), float(p.km)], 17, UI.MUTED)
	var actions := UI.card(details, "WORKSHOP ACTIONS")
	UI.label(actions, "Departamento responsável: equipe técnica / oficina", 14, UI.MUTED)
	var locked: bool = hub.host.garage.inventory_locked
	if p.status == "installed":
		UI.button(actions, "REMOVER PARA O ESTOQUE", act.bind("remove", 0)).disabled = locked
	elif p.status in ["available", "stored"]:
		var row := UI.row(actions, 8)
		for target in [1,2]:
			var existing := Inventory.installed(inventory, target, str(p.category))
			UI.button(row, ("PLANEJAR TROCA" if not existing.is_empty() else "PLANEJAR INSTALAÇÃO") + " / CAR %02d" % target, act.bind("install", target), true).disabled = locked
		UI.label(actions, "Ao substituir, a peça anterior retorna ao estoque.", 14, UI.MUTED)
		UI.button(actions, "ARMAZENAR" if p.status == "available" else "DISPONIBILIZAR", act.bind("store" if p.status == "available" else "release", 0)).disabled = locked
	else:
		UI.label(actions, "Componente inutilizado / instalação indisponível", 17, UI.ORANGE)
	var history := UI.card(details, "HISTÓRICO / %d EVENTOS" % p.history.size())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 155
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	history.add_child(scroll)
	var lines := UI.column(scroll, 8)
	for index in range(p.history.size()-1, -1, -1):
		var event: Dictionary = p.history[index]
		var suffix := " • %.3f km" % float(event.km) if event.has("km") else ""
		UI.label(lines, str(event.get("message", "")) + suffix + "\n" + str(event.get("at", "")) + (" • temporada %d / etapa %d" % [int(event.get("season",0)), int(event.get("round",0))] if event.has("round") else ""), 14, UI.MUTED)

func select_part(id: String) -> void:
	selected = id
	refresh()

func act(action: String, target: int) -> void:
	if action == "install":
		var panel = hub.workshop
		panel.show_tab("Fila de tarefas")
		panel.car_select.selected = target-1
		panel.part_select.selected = panel.part_ids.find(selected)
		panel.service_select.selected = panel.Model.SERVICES.keys().find("Substituição")
		panel.notice.text = "Escolha o responsável e reserve a substituição. A instalação ocorrerá ao concluir o serviço."
		return
	var host = hub.host
	var context := {"season": int(host.championship.state.get("serial",0)), "round": int(host.championship.state.get("round_index",0))+1}
	var result: String = host.garage.component_action(host.selected_team, selected, action, target, context)
	refresh()
	notice.text = result

static func state_name(value: String) -> String:
	return {"installed":"INSTALADA", "available":"DISPONÍVEL", "stored":"ARMAZENADA", "unusable":"INUTILIZADA"}.get(value, value)
