extends SceneTree
## Execute in Godot 4: godot --headless --path . --script res://tests/ui_smoke_test.gd
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null, "Cena principal não carregada")
	var app: Variant = scene.instantiate()
	root.add_child(app)
	await process_frame
	app._start_race()
	assert(app.race != null, "Motor de corrida não iniciou")
	assert(app.race.cars.size() == 24, "Grade de 2012 deveria ter 24 carros")
	assert(app.map_view.route.size() > 500, "Circuito não foi suavizado")
	assert(app.world_view != null, "Mundo 3D não foi criado")
	assert(app.world_viewport.own_world_3d, "Viewport 3D sem mundo próprio")
	assert(app.world_view.route.size() == app.map_view.route.size(), "Rotas não coincidem")
	assert(app.world_view.road_centers.size() > 500, "Malha 3D não foi construída")
	assert(app.world_view.road_widths.size() == app.world_view.road_centers.size(), "Seções de pista incompletas")
	assert(app.world_view.course_root.get_child_count() >= 7, "Pista 3D sem camadas")
	app._change_speed(0)
	assert(app.render_mode == 1, "1x deve ativar visão 3D")
	assert(app.world_container.visible and not app.map_view.visible, "Visibilidade da câmera 3D incorreta")
	app._process(0.016)
	assert(app.world_view.live_cars.size() == 24, "Modelos 3D não instanciados")
	var first_model: Node3D = app.world_view.live_cars.values()[0]
	assert(first_model.get_node_or_null("ChassisVisual/TaperedChassis") != null, "Chassi modelado não carregou")
	assert(first_model.get_node_or_null("ChassisVisual/FrontWingMain") != null, "Asa dianteira ausente")
	assert(first_model.get_node_or_null("ChassisVisual/DriverHelmet") != null, "Capacete ausente")
	assert(first_model.get_node_or_null("FrontLeft/WheelSpin/Rubber") != null, "Roda dianteira ausente")
	assert(first_model.get_node_or_null("RearRight/WheelSpin/Rubber") != null, "Roda traseira ausente")
	assert(first_model.get_node_or_null("NumberTag") != null, "Número do piloto ausente")
	var wheels: Array = first_model.get("wheel_spins")
	assert(wheels.size() == 4, "O carro deveria ter quatro rodas animadas")
	var front_pivots: Array = first_model.get("steering_pivots")
	assert(front_pivots.size() == 2, "O carro deveria esterçar duas rodas dianteiras")
	var original_rotation: float = wheels[0].rotation.x
	first_model.call("update_motion", 0.50, 0.13, 0.08)
	assert(wheels[0].rotation.x != original_rotation, "A roda não girou ao percorrer distância")
	var old_race: Variant = app.race
	app._change_speed(1)
	assert(app.render_mode == 1, "2x deve continuar em 3D")
	app._change_speed(2)
	assert(app.render_mode == 0, "5x deve usar o mapa 2D")
	assert(not app.world_container.visible and app.map_view.visible, "Visibilidade do mapa 2D incorreta")
	assert(app.race == old_race, "Alternar visual não pode reiniciar a simulação")
	app._cycle_info_mode()
	assert(app.table_mode_label.text.contains("Intervalo frente"), "Tabela deve continuar funcionando")
	app.race.running = true
	app.race.step(3.0)
	assert(app.race.clock > 0.0, "Motor de corrida parou")
	print("APEX 0.5.2.3 UI SMOKE OK: 24 carros, 3D real, mapa suave, HUD e motor")
	quit(0)
