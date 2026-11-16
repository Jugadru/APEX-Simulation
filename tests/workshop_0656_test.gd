extends SceneTree
const Garage=preload("res://scripts/garage.gd")
const W=preload("res://scripts/core/workshop_0656.gd")
func _initialize()->void: call_deferred("run")
func run()->void:
	var g=Garage.new("user://workshop_test.json")
	g.team_data={}
	var s:Dictionary=g.get_team("Ferrari")
	var old:Dictionary=s.duplicate(true)
	old.erase("workshop")
	g.team_data["Ferrari"]=old
	g.save()
	g=Garage.new("user://workshop_test.json")
	s=g.get_team("Ferrari")
	assert(JSON.stringify(s.component_inventory)==JSON.stringify(JSON.parse_string(JSON.stringify(old.component_inventory))),"legacy inventory unchanged")
	g.staff_hire_candidate("Ferrari","Chefe de Mecânica","mec_a")
	g.staff_hire_candidate("Ferrari","Engenheiro","eng_b")
	var ids:Array=[]
	for car in [1,2]:
		for category in g.PARTS: ids.append(g.Inventory.installed(s.component_inventory,car,category))
	var budget:int=s.budget
	assert(W.create(s,{"car":1,"part":ids[0],"service":"Reparação","staff":"mec_a"})=="")
	assert(W.create(s,{"car":1,"part":ids[1],"service":"Inspeção","staff":"mec_a"})=="")
	assert(W.create(s,{"car":2,"part":ids[3],"service":"Inspeção","staff":"eng_b"})=="")
	assert(not W.create(s,{"car":1,"part":ids[0],"service":"Reparação","staff":"eng_b"}).is_empty())
	W.schedule(s)
	assert(s.workshop.tasks[0].status=="em execução")
	assert(s.workshop.tasks[1].status=="pendente")
	assert(s.workshop.tasks[2].status=="em execução")
	assert(s.budget==budget-14400)
	assert(g.component_action("Ferrari",ids[0],"remove",0).contains("reservada"))
	W.advance(s,1)
	assert(s.workshop.tasks[0].remaining>0)
	g.save()
	var saved:=JSON.stringify(JSON.parse_string(JSON.stringify(s)))
	g=Garage.new("user://workshop_test.json")
	s=g.get_team("Ferrari")
	assert(JSON.stringify(JSON.parse_string(JSON.stringify(s)))==saved,"pending save roundtrip")
	W.advance(s,24)
	for t in s.workshop.tasks: assert(t.status=="concluída")
	assert(s.component_inventory.parts[ids[0]].condition<100)
	assert(s.component_inventory.parts[ids[0]].km==0)
	assert(s.component_inventory.parts.size()==6)
	assert(W.create(s,{"car":1,"part":ids[0],"service":"Reparação","staff":"mec_a"})=="")
	var before:int=s.budget
	assert(W.cancel(s,s.workshop.tasks[-1].id)=="")
	assert(s.budget==before+12000)
	var rich:int=s.budget
	s.budget=0
	assert(not W.create(s,{"car":1,"part":ids[0],"service":"Reparação","staff":"mec_a"}).is_empty())
	s.budget=rich
	assert(W.automatic(s)=="")
	assert(s.workshop.mode=="Automático")
	g.workshop_action("Ferrari","manual")
	assert(s.workshop.mode=="Manual")
	g.inventory_locked=true
	var frozen:=JSON.stringify(s)
	assert(g.workshop_action("Ferrari","advance",{"hours":8}).contains("bloqueada"))
	assert(JSON.stringify(s)==frozen)
	assert(g.Inventory.validate(s.component_inventory,g.PARTS)=="")

	# A spare is an existing part removed from car 2, never a fabricated duplicate.
	g.inventory_locked=false
	for t in s.workshop.tasks:
		if W.active(t): W.cancel(s,t.id)
	var spare:String=ids[3]
	assert(g.component_action("Ferrari",spare,"remove",0).contains("salvo"))
	assert(W.create(s,{"car":1,"part":spare,"service":"Substituição","staff":"mec_a"})=="")
	assert(not W.create(s,{"car":2,"part":spare,"service":"Substituição","staff":"eng_b"}).is_empty())
	W.advance(s,8)
	assert(g.Inventory.installed(s.component_inventory,1,"Motor")==spare)
	assert(s.component_inventory.parts[ids[0]].status=="available")
	assert(s.component_inventory.parts.size()==6)
	assert(g.Inventory.validate(s.component_inventory,g.PARTS)=="")
	# Failed persistence must restore budget, reservations and clock.
	var prior:=JSON.stringify(g.get_team("Ferrari"))
	g.save_path="/missing-parent-apex0656/test.json"
	assert(g.workshop_action("Ferrari","advance",{"hours":1}).contains("revertida"))
	assert(JSON.stringify(g.get_team("Ferrari"))==prior)
	print("WORKSHOP_PASS migration, save, costs, calendar, completion, cancellation, staff contention, auto/manual, locks")
	quit()
