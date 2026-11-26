extends RefCounted
## Calendar-driven workshop. No race engine/RNG access.
const Inventory = preload("res://scripts/core/component_inventory_0651.gd")
const SERVICES = {"Inspeção":[2.0,1200], "Manutenção preventiva":[6.0,5000], "Reparação":[12.0,12000], "Substituição":[4.0,2500], "Preparação GP":[8.0,6000], "Verificação final":[3.0,1800]}
const ROLES = ["Chefe de Mecânica", "Engenheiro"]
static func ensure(state: Dictionary) -> void:
	if not state.has("workshop"):
		state.workshop = {"schema":1,"hour":0.0,"deadline":72.0,"mode":"Manual","next_id":1,"tasks":[],"log":[]}
static func active(t: Dictionary) -> bool:
	return t.status in ["pendente", "em execução"]
static func staff(state: Dictionary) -> Dictionary:
	var result := {}
	for role in ROLES:
		var person: Dictionary = state.staff_roster.get(role,{})
		if person.is_empty(): continue
		var skill := clampf(float(person.get("skill",50)),0,100)
		result[str(person.id)] = {"id":person.id,"name":person.name,"role":role,"technical":skill,"speed":clampf(skill+3,0,100),"precision":skill,"diagnosis":clampf(skill-3,0,100),"experience":skill,"resistance":skill}
	return result
static func locked(state: Dictionary, id: String) -> bool:
	ensure(state)
	for t in state.workshop.tasks:
		if active(t) and (t.part == id or t.get("old_part","") == id): return true
	return false
# A replacement reserves its destination even when there is no installed old part.
# Derived from persisted tasks and part category; no schema change or second ledger.
static func slot_locked(state: Dictionary, car: int, category: String) -> bool:
	if car not in [1,2] or category.is_empty(): return false
	for t in state.get("workshop",{}).get("tasks",[]):
		if not active(t) or t.service != "Substituição" or int(t.car) != car: continue
		var part: Dictionary = state.component_inventory.parts.get(t.part,{})
		if part.get("category","") == category: return true
	return false

static func create(state: Dictionary, args: Dictionary) -> String:
	ensure(state)
	var car := int(args.get("car",0))
	var id := str(args.get("part",""))
	var service := str(args.get("service",""))
	var responsible := str(args.get("staff",""))
	var people := staff(state)
	if car not in [1,2] or not SERVICES.has(service): return "Carro ou serviço inválido."
	if not people.has(responsible): return "Contrate um profissional técnico em Equipe e Staff."
	var inventory: Dictionary = state.component_inventory
	var error := Inventory.validate(inventory,["Motor","Asa","Chassi"])
	if not error.is_empty(): return error
	if not inventory.parts.has(id): return "Componente inexistente."
	var p: Dictionary = inventory.parts[id]
	var old := ""
	if service == "Substituição":
		if p.status not in ["available","stored"]: return "Substituição exige peça em estoque."
		if slot_locked(state,car,str(p.category)): return "Slot reservado na oficina."
		old = Inventory.installed(inventory,car,str(p.category))
	else:
		if p.status != "installed" or int(p.car) != car: return "Selecione uma peça instalada neste carro."
	if locked(state,id) or (not old.is_empty() and locked(state,old)): return "Componente já reservado por outro serviço."
	var cost := int(SERVICES[service][1])
	if int(state.budget)<cost: return "Orçamento insuficiente."
	var hours := float(SERVICES[service][0]) * (1.15 - float(people[responsible].speed)*0.003)
	var w: Dictionary = state.workshop
	state.budget = int(state.budget)-cost
	w.tasks.append({"id":"OF-%05d" % int(w.next_id),"car":car,"part":id,"old_part":old,"service":service,"priority":clampi(int(args.get("priority",2)),1,3),"staff":responsible,"staff_name":people[responsible].name,"estimated":hours,"remaining":hours,"cost":cost,"status":"pendente","protected":not bool(args.get("auto",false)),"created":w.hour,"quality":float(people[responsible].precision)})
	w.next_id = int(w.next_id)+1
	w.log.append("Hora %.1f: %s / CAR %d / %s reservado por R$ %d." % [w.hour,service,car,people[responsible].name,cost])
	return ""
static func cancel(state: Dictionary, id: String) -> String:
	for t in state.workshop.tasks:
		if t.id != id or not active(t): continue
		var refund := int(float(t.cost)*float(t.remaining)/float(t.estimated))
		state.budget = int(state.budget)+refund
		t.status = "cancelada"
		t.refund = refund
		t.finished = state.workshop.hour
		state.workshop.log.append("%s cancelada pelo jogador; devolução R$ %d (trabalho consumido cobrado)." % [id,refund])
		return ""
	return "Tarefa não está ativa."
static func schedule(state: Dictionary) -> void:
	var people := staff(state)
	var busy := {}
	var queue: Array = state.workshop.tasks.duplicate()
	queue.sort_custom(func(a,b): return a.priority>b.priority if a.priority!=b.priority else a.id<b.id)
	for t in queue:
		if t.status == "em execução":
			if not people.has(t.staff):
				t.status = "pendente"
			else: busy[t.staff] = true
	for t in queue:
		if t.status != "pendente" or busy.has(t.staff) or not people.has(t.staff): continue
		t.status = "em execução"
		if not t.has("started"): t.started = state.workshop.hour
		busy[t.staff] = true
static func complete(state: Dictionary, t: Dictionary) -> void:
	var p: Dictionary = state.component_inventory.parts[t.part]
	var quality := clampf(float(t.quality)/100.0,0,1)
	if t.service == "Substituição":
		# An older save may contain overlapping reservations. Never silently
		# displace a part that was not the recorded replacement target.
		var error := ""
		var current := Inventory.installed(state.component_inventory,int(t.car),str(p.category))
		if current != str(t.get("old_part","")):
			error = "Destino da substituição mudou; cancele e planeje novamente."
		else:
			error = Inventory.operate(state.component_inventory,["Motor","Asa","Chassi"],t.part,"install",int(t.car),{"workshop_task":t.id})
		if not error.is_empty():
			t.status = "pendente"
			t.remaining = 1.0
			state.workshop.log.append(error)
			return
	else:
		var last_km := float(p.get("workshop_km",0))
		var initial := 95.0 if p.condition == null else float(p.condition)
		p.condition = clampf(initial-maxf(0,float(p.km)-last_km)*0.002,0,100)
		p.workshop_km = p.km
		var ceiling := clampf(98.0-float(p.km)*0.0005-float(p.get("repairs",0))*0.8,65,98)
		if t.service in ["Manutenção preventiva","Reparação"]:
			var gain := (12.0 if t.service == "Manutenção preventiva" else 25.0)*(0.65+quality*0.3)
			p.condition = maxf(float(p.condition),minf(ceiling,float(p.condition)+gain))
			p.repairs = int(p.get("repairs",0))+1
		p.integrity = ceiling
	if t.service == "Preparação GP": p.prepared_km = p.km
	if t.service == "Verificação final": p.verified_km = p.km
	Inventory._event(p,"workshop","%s / qualidade %.0f%% / R$ %d / %.1f h de trabalho" % [t.service,65+quality*30,int(t.cost),float(t.estimated)],{"task":t.id,"hour":state.workshop.hour,"cost":t.cost})
	t.status = "concluída"
	t.finished = state.workshop.hour
	t.result = "Serviço concluído; recuperação limitada pelo desgaste permanente." if t.service in ["Manutenção preventiva","Reparação"] else "Inspeção/preparação registrada; condição estimada pelo uso conhecido."
	state.workshop.log.append("%s: %s" % [t.id,t.result])
static func advance(state: Dictionary, hours: float) -> String:
	ensure(state)
	if not is_finite(hours) or hours<=0 or hours>168: return "Avance entre 0 e 168 horas."
	var remaining := hours
	while remaining>0.000001:
		schedule(state)
		var step := remaining
		for t in state.workshop.tasks:
			if t.status == "em execução": step = minf(step,float(t.remaining))
		state.workshop.hour = float(state.workshop.hour)+step
		for t in state.workshop.tasks:
			if t.status != "em execução": continue
			t.remaining = maxf(0,float(t.remaining)-step)
			if float(t.remaining)<0.000001: complete(state,t)
		remaining -= step
	return ""
static func automatic(state: Dictionary) -> String:
	ensure(state)
	var people := staff(state)
	var chief: Dictionary = state.staff_roster.get("Chefe de Mecânica",{})
	if chief.is_empty(): return "Modo automático exige chefe de mecânica contratado."
	state.workshop.mode = "Automático"
	var ids: Array = people.keys()
	var count := 0
	for p in state.component_inventory.parts.values():
		if p.status != "installed" or locked(state,str(p.id)): continue
		var service := "Inspeção" if p.condition == null else ("Reparação" if float(p.condition)<65 else "Manutenção preventiva")
		var person := str(ids[count%ids.size()])
		var planned := 0.0
		for t in state.workshop.tasks:
			if active(t) and t.staff == person: planned += float(t.remaining)
		var duration := float(SERVICES[service][0])*(1.15-float(people[person].speed)*0.003)
		if planned+duration>float(state.workshop.deadline)-float(state.workshop.hour):
			state.workshop.log.append("Prazo insuficiente: adiado %s CAR %d." % [p.name,p.car])
			continue
		var error := create(state,{"car":p.car,"part":p.id,"service":service,"staff":person,"priority":3 if service=="Reparação" else 1,"auto":true})
		if not error.is_empty(): state.workshop.log.append(error)
		else: count+=1
	state.workshop.log.append("Chefe %s: %d serviços planejados; tarefas manuais preservadas." % [chief.name,count])
	schedule(state)
	return ""
