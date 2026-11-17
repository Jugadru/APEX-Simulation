extends SceneTree
## Xvfb/llvmpipe real Godot render of the preserved Core 2 + ReBroadcast 3D UI.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600,900)
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5): await process_frame
	host.set_process(false)
	host.seed_picker.value=660
	host._start_race()
	host._change_visual_setting(2)
	host.race_hud_0620._change_hud_mode(1)
	for i in range(40):
		host._process(1.0/60.0)
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var actual: Vector2i = img.get_size()
	var output: String = "res://qa/core2_06686/hud_compact_3d_1600x900.png"
	var ok: bool = host.render_mode == 1 and actual.x >= 1599 and actual.y == 900 and img.save_png(output) == OK
	print("APEX_06686_VISUAL ",JSON.stringify({"status":"PASS" if ok else "FAIL","view":"3D" if host.render_mode==1 else "2D","size":str(actual),"capture":output}))
	quit(0 if ok else 1)
