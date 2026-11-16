extends SceneTree
## Run in Godot 4: godot --headless --path . --script res://tests/camera_regression_test.gd
## This test catches the camera reset from _apply_camera() after a broadcast shot.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	assert(scene != null, "Cena principal não carregada")
	var app: Node2D = scene.instantiate()
	root.add_child(app)
	await process_frame
	app._start_race()
	app._change_speed(0)  # 1× = 3D
	assert(app.render_mode == 1)
	app._change_camera_mode(1)  # Seguir piloto
	var camera: Camera3D = app.world_view.camera_3d
	var initial: Vector3 = camera.position
	app._process(0.2)
	assert(app.world_view.camera_mode_3d == "chase", "Seguir piloto não ativou a câmera traseira")
	var following: Vector3 = camera.position
	assert(following.distance_to(initial) > 0.01, "Câmera não sai do centro da pista")
	app.world_view.set_zoom(2.45)
	assert(camera.position.distance_to(following) < 0.001, "Zoom redefiniu câmera no centro!")
	app._change_tv_shot(2)  # lateral direita
	app._process(0.18)
	assert(app.world_view.camera_mode_3d == "corner", "Plano lateral direito não foi aplicado")
	app._change_tv_shot(3)  # lateral esquerda
	app._process(0.18)
	assert(app.world_view.camera_mode_3d == "trackside", "Plano lateral esquerdo não foi aplicado")
	app._change_tv_shot(4)  # aérea
	app._process(0.18)
	assert(app.world_view.camera_mode_3d == "helicopter", "Plano aéreo não foi aplicado")
	app._change_tv_shot(5)  # batalha
	app._process(0.18)
	assert(app.world_view.camera_mode_3d == "battle", "Plano de batalha não foi aplicado")
	app._change_tv_shot(0)
	app._change_camera_mode(2)  # Diretor TV
	var seen: Dictionary = {}
	for i in range(10):
		app.director.hold_until = -1.0
		var now: float = float(20 + i * 14)
		app.director.select(app.race, app.manual_driver, now)
		seen[app.director.camera_style] = true
	assert(seen.size() >= 2, "Diretor TV permaneceu no mesmo ângulo")
	assert(app.race.cars.size() == 24)
	print("APEX CAMERA FIX OK — segue piloto, zoom não centraliza, ângulos manuais e TV variam")
	quit(0)
