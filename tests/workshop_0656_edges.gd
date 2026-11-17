extends SceneTree
const G=preload("res://scripts/garage.gd")
const W=preload("res://scripts/core/workshop_0656.gd")
func _initialize()->void:
	var g=G.new("user://edge.json")
	g.team_data={}
	var s:Dictionary=g.get_team("Ferrari")
	g.staff_hire_candidate("Ferrari","Chefe de Mecânica","mec_a")
	g.staff_hire_candidate("Ferrari","Engenheiro","eng_b")
	var id:String=g.Inventory.installed(s.component_inventory,1,"Motor")
	assert(W.create(s,{"car":1,"part":id,"service":"Reparação","staff":"mec_a"})=="")
	var protected:Dictionary=s.workshop.tasks[0].duplicate(true)
	s.budget=1200
	W.automatic(s)
	assert(s.budget>=0)
	assert(s.workshop.tasks[0].id==protected.id and s.workshop.tasks[0].protected)
	assert(s.workshop.tasks[0].service==protected.service)
	var a:Dictionary=s.duplicate(true)
	var b:Dictionary=s.duplicate(true)
	W.advance(a,8)
	for i in range(8): W.advance(b,1)
	for i in range(a.workshop.tasks.size()):
		assert(is_equal_approx(float(a.workshop.tasks[i].remaining),float(b.workshop.tasks[i].remaining)))
		assert(a.workshop.tasks[i].status==b.workshop.tasks[i].status)
	# A departed employee cannot continue working.
	s.staff_roster.erase("Chefe de Mecânica")
	var remaining:float=s.workshop.tasks[0].remaining
	W.advance(s,24)
	assert(s.workshop.tasks[0].status=="pendente")
	assert(float(s.workshop.tasks[0].remaining)==remaining)
	g.workshop_action("Ferrari","assign",{"id":protected.id,"staff":"eng_b"})
	W.advance(s,24)
	assert(s.workshop.tasks[0].status=="concluída")
	# Recovery never produces a new component, never resets known usage.
	s.budget=1000000
	s.component_inventory.parts[id].km=10000.0
	for i in range(12):
		assert(W.create(s,{"car":1,"part":id,"service":"Reparação","staff":"eng_b"})=="")
		W.advance(s,24)
	assert(float(s.component_inventory.parts[id].condition)<98)
	assert(float(s.component_inventory.parts[id].km)==10000)
	assert(s.component_inventory.parts.size()==6)
	s.workshop.deadline=s.workshop.hour
	var count:int=s.workshop.tasks.size()
	g.staff_hire_candidate("Ferrari","Chefe de Mecânica","mec_a")
	W.automatic(s)
	assert(s.workshop.tasks.size()==count,"no time until GP")
	print("WORKSHOP_EDGES_PASS budget, protected manual, time chunk invariance, departure, reassignment, permanent wear, deadline")
	quit()
