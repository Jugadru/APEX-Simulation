extends RefCounted
const UI = preload("res://scripts/apex_management_style.gd")
const Model = preload("res://scripts/core/workshop_0656.gd")
var hub
var body: VBoxContainer
var content: VBoxContainer
var status: Label
var notice: Label
var tab := "Visão geral"
var legacy
var legacy_body: VBoxContainer
var part_select: OptionButton
var car_select: OptionButton
var service_select: OptionButton
var staff_select: OptionButton
var priority_select: OptionButton
var part_ids: Array = []
var staff_ids: Array = []
var _form_team := ""
var _drafts: Dictionary = {}

func _remember_draft() -> void:
	if not is_instance_valid(car_select) or not content.is_ancestor_of(car_select): return
	var part: int = part_select.selected
	var staff: int = staff_select.selected
	_drafts[_form_team] = {"car":car_select.selected,"part":part_ids[part] if part >= 0 and part < part_ids.size() else "",
		"service":service_select.selected,"staff":staff_ids[staff] if staff >= 0 and staff < staff_ids.size() else "",
		"priority":priority_select.selected}

func _restore_draft() -> void:
	var draft: Dictionary = _drafts.get(_form_team, {})
	if draft.is_empty(): return
	car_select.select(clampi(int(draft.car),0,car_select.item_count-1))
	service_select.select(clampi(int(draft.service),0,service_select.item_count-1))
	priority_select.select(clampi(int(draft.priority),0,priority_select.item_count-1))
	var part: int = part_ids.find(draft.part)
	var staff: int = staff_ids.find(draft.staff)
	if part >= 0: part_select.select(part)
	if staff >= 0: staff_select.select(staff)
func setup(parent: Node, manager) -> void:
	hub = manager
	body = UI.column(parent,10)
	var banner := UI.card(body,"LIVING FACTORY 2.0 / OFICINA OPERACIONAL")
	status = UI.label(banner,"",18,UI.ORANGE)
	var controls := UI.row(banner,8)
	for e in [["Manual","manual"],["Chefe: planejar serviços","auto"],["Iniciar fila","start"],["Avançar 1 h","advance"]]:
		UI.button(controls,e[0],act.bind(e[1],{"hours":1}))
	var time_controls := UI.row(banner,8)
	UI.button(time_controls,"Avançar 8 h",act.bind("advance",{"hours":8}))
	UI.button(time_controls,"Prazo GP: +72 h",act.bind("deadline",{"hours":72}))
	var tabs := UI.row(body,8)
	for name in ["Visão geral","Fila de tarefas","Equipe técnica","Componentes","Histórico"]:
		UI.button(tabs,name,show_tab.bind(name))
	notice = UI.label(body,"Serviços avançam apenas pelo calendário de gestão. Prazo GP é uma meta operacional ajustável.",14,UI.MUTED)
	content = UI.column(body,8)
	legacy_body = UI.column(body,8)
	legacy = preload("res://scripts/apex_component_workshop_0651.gd").new()
	legacy.setup(legacy_body,hub)
func act(action: String, args: Dictionary = {}) -> void:
	var message: String = hub.host.garage.workshop_action(hub.host.selected_team,action,args)
	hub.refresh()
	notice.text = message
func show_tab(name: String) -> void:
	tab = name
	refresh()
func option(parent: Node, items: Array) -> OptionButton:
	var select := OptionButton.new()
	for item in items: select.add_item(str(item))
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(select)
	return select
func refresh() -> void:
	_remember_draft()
	_form_team = str(hub.host.selected_team)
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var state: Dictionary = hub.host.garage.get_team(hub.host.selected_team)
	var w: Dictionary = state.workshop
	status.text = "%s • Dia %d / %02dh • Saldo R$ %d • Prazo GP %.1f h" % [w.mode,1+int(float(w.hour)/24),int(w.hour)%24,int(state.budget),maxf(0,float(w.deadline)-float(w.hour))]
	legacy_body.visible = tab == "Componentes"
	if tab == "Componentes":
		legacy.refresh()
		return
	var people := Model.staff(state)
	if tab == "Visão geral":
		var row := UI.row(content,12)
		for car in [1,2]:
			var card := UI.card(row,"CAR %02d / PRONTIDÃO" % car)
			for p in state.component_inventory.parts.values():
				if int(p.car)==car:
					UI.label(card,"%s • %s • %.1f km%s" % [p.name,"Diagnóstico pendente" if p.condition==null else "%.0f%%" % float(p.condition),float(p.km)," • reservado" if Model.locked(state,str(p.id)) else (" • verificada" if float(p.get("verified_km",-1))==float(p.km) else (" • preparada" if float(p.get("prepared_km",-1))==float(p.km) else ""))],16)
			var count := 0
			for t in w.tasks:
				if t.car==car and Model.active(t): count+=1
			UI.label(card,"%d serviços ativos" % count,18,UI.ORANGE)
		UI.label(content,"Condição: estimativa de oficina pelo uso registrado. Não modifica desempenho de corrida. Preparação e verificação são por componente.",15,UI.MUTED)
		UI.label(content,"Mecânicos: chefe de mecânica e engenheiro contratados em Equipe e Staff. Sem titular, o trabalho aguarda contratação ou reatribuição.",15,UI.MUTED)
	elif tab == "Fila de tarefas":
		var form := UI.card(content,"PLANEJAR SERVIÇO / custo reservado na criação")
		var row := UI.row(form,8)
		car_select = option(row,["CAR 01","CAR 02"])
		part_ids = state.component_inventory.parts.keys()
		var labels: Array = []
		for id in part_ids:
			var p: Dictionary = state.component_inventory.parts[id]
			labels.append("%s / CAR %d / %s" % [p.name,p.car,str(id).left(6)])
		part_select = option(row,labels)
		service_select = option(row,Model.SERVICES.keys())
		var second := UI.row(form,8)
		staff_ids = people.keys()
		labels = []
		for id in staff_ids: labels.append(people[id].name)
		staff_select = option(second,labels)
		priority_select = option(second,["Prioridade baixa","Prioridade normal","Prioridade alta"])
		priority_select.selected = 1
		_restore_draft()
		UI.button(second,"Reservar serviço",create_task,true).disabled = staff_ids.is_empty()
		UI.label(form,"Inspeção 2h / R$1.200 • Preventiva 6h / R$5.000 • Reparação 12h / R$12.000 • Troca 4h / R$2.500 • Preparação 8h / R$6.000 • Verificação 3h / R$1.800. Tempo ajustado pela competência.",13,UI.MUTED)
		for t in w.tasks:
			if not Model.active(t): continue
			var card := UI.card(content,"%s / CAR %d / %s" % [t.id,t.car,t.service])
			UI.label(card,"%s • %s • prioridade %d • %.1f / %.1f h restantes • R$ %d" % [t.status,t.staff_name,t.priority,float(t.remaining),float(t.estimated),t.cost],16)
			var progress := ProgressBar.new()
			progress.value = 100*(1-float(t.remaining)/float(t.estimated))
			card.add_child(progress)
			var actions := UI.row(card,8)
			UI.button(actions,"Cancelar / devolver saldo não usado",act.bind("cancel",{"id":t.id}))
			UI.button(actions,"Prioridade " + str(int(t.priority)%3+1),act.bind("priority",{"id":t.id,"priority":int(t.priority)%3+1}))
			if t.status == "pendente":
				for id in people:
					UI.button(actions,people[id].name,act.bind("assign",{"id":t.id,"staff":id}))
	elif tab == "Equipe técnica":
		if people.is_empty(): UI.label(content,"Sem técnicos contratados. Abra Equipe e Staff para contratar chefe de mecânica e engenheiro.",20,UI.ORANGE)
		for id in people:
			var p: Dictionary = people[id]
			var busy := "Disponível"
			for t in w.tasks:
				if t.staff==id and t.status=="em execução": busy = "Ocupado • " + t.id
			var card := UI.card(content,p.name + " / " + p.role)
			UI.label(card,busy,20,UI.ORANGE)
			UI.label(card,"Técnica %.0f • Velocidade %.0f • Precisão %.0f • Diagnóstico %.0f • Experiência %.0f • Resistência %.0f" % [p.technical,p.speed,p.precision,p.diagnosis,p.experience,p.resistance],16)
		UI.label(content,"Competências derivadas do atributo do contrato existente. Velocidade ajusta duração; precisão limita recuperação. Demais indicadores são informativos nesta versão. Um profissional por tarefa simultânea.",15,UI.MUTED)
	elif tab == "Histórico":
		for i in range(w.tasks.size()-1,-1,-1):
			var t: Dictionary = w.tasks[i]
			if Model.active(t): continue
			UI.label(content,"%s • %s • %s • %.1f h trabalhadas • R$ %d líquidos\n%s" % [t.id,t.service,t.status,float(t.estimated)-float(t.remaining),int(t.cost)-int(t.get("refund",0)),t.get("result","")],16)
		for i in range(w.log.size()-1,-1,-1): UI.label(content,str(w.log[i]),14,UI.MUTED)
func create_task() -> void:
	if staff_ids.is_empty() or part_ids.is_empty(): return
	act("create",{"car":car_select.selected+1,"part":part_ids[part_select.selected],"service":Model.SERVICES.keys()[service_select.selected],"staff":staff_ids[staff_select.selected],"priority":priority_select.selected+1})
