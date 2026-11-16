extends SceneTree
func _initialize()->void: call_deferred("run")
func run()->void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(8): await process_frame
	host._open_garage()
	var hub=host.garage_root.get_node("ManagementHub")
	var g=host.garage
	g.staff_hire_candidate(host.selected_team,"Chefe de Mecânica","mec_b")
	g.staff_hire_candidate(host.selected_team,"Engenheiro","eng_b")
	g.workshop_action(host.selected_team,"auto")
	g.workshop_action(host.selected_team,"advance",{"hours":0.5})
	hub.show_page("factory")
	for resolution in [Vector2i(1600,900),Vector2i(1920,1080)]:
		root.mode=Window.MODE_FULLSCREEN if resolution.x==1920 else Window.MODE_WINDOWED
		root.size=resolution
		host._layout_ui()
		for page in ["Visão geral","Fila de tarefas","Equipe técnica","Componentes","Histórico"]:
			hub.workshop.show_tab(page)
			for i in range(10): await process_frame
			assert(hub.workshop.body.get_global_rect().end.x<=host.get_viewport_rect().size.x+1)
			await RenderingServer.frame_post_draw
			var img:=root.get_texture().get_image()
			assert(img.get_size()==resolution)
			img.save_png("res://qa/living_factory_2/%s_%d.png" % [page.replace(" ","_"),resolution.x])
	g.workshop_action(host.selected_team,"advance",{"hours":8})
	hub.workshop.show_tab("Histórico")
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://qa/living_factory_2/servicos_concluidos_1920.png")
	print("WORKSHOP_HUD_PASS native five pages, both resolutions")
	quit()
