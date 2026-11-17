extends SceneTree
func _initialize()->void: call_deferred("run")
func run()->void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5): await process_frame
	host._open_garage()
	var g=host.garage
	g.staff_hire_candidate(host.selected_team,"Chefe de Mecânica","mec_a")
	var s:Dictionary=g.get_team(host.selected_team)
	var id:String=g.Inventory.installed(s.component_inventory,1,"Motor")
	var hub=host.garage_root.get_node("ManagementHub")
	hub.show_page("factory")
	var panel=hub.workshop
	panel.show_tab("Fila de tarefas")
	panel.part_select.selected=panel.part_ids.find(id)
	panel.create_task()
	g.workshop_action(host.selected_team,"start")
	host._start_race()
	assert(host.race==null)
	assert(panel.notice.text.contains("execução"))
	g.workshop_action(host.selected_team,"advance",{"hours":8})
	for service in ["Manutenção preventiva","Reparação","Preparação GP","Verificação final"]:
		assert(g.Workshop.create(s,{"car":1,"part":id,"service":service,"staff":"mec_a"})=="")
		g.workshop_action(host.selected_team,"advance",{"hours":24})
		assert(s.workshop.tasks[-1].status=="concluída")
	assert(s.component_inventory.parts[id].has("verified_km"))
	host._show_menu()
	host._start_race()
	assert(host.race!=null)
	assert(g.workshop_action(host.selected_team,"advance",{"hours":8}).contains("bloqueada"))
	print("WORKSHOP_INTEGRATION_PASS form, all services, readiness, departure guard, race starts, session lock")
	quit()
