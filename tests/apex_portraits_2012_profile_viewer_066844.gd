extends SceneTree
## APEX 0.6.6.8.44 — real scene profile viewer regression.
## Run after fixture generation or installation of the user portrait PNGs.
var failures: Array[String] = []
var checks: int = 0
func ck(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures.append(reason)
		printerr("APEX_PROFILE_VIEWER_066844_FAIL: ", reason)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	ck(packed != null, "main game scene loaded")
	if packed == null:
		quit(2)
		return
	var host = packed.instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host._start_race()
	await process_frame
	var hud = host.race_hud_0620
	ck(hud != null, "real HUD")
	if hud == null:
		quit(2)
		return
	var original: PackedByteArray = var_to_bytes(host.race.get_state_snapshot())
	hud._open_window("radio")
	await process_frame
	ck(not hud.radio_driver_ids.is_empty(), "radio players available")
	for index in range(mini(2, hud.radio_driver_ids.size())):
		hud.radio_driver_picker.select(index)
		hud._radio_driver_changed(index)
		hud._show_profile_2012()
		await process_frame
		var view: PanelContainer = hud.driver_profile_panel_2012
		var portrait: TextureRect = hud.driver_profile_photo_2012
		ck(view != null and view.is_visible_in_tree(), "profile window for driver " + str(index))
		ck(portrait != null and portrait.texture != null, "profile loaded for driver " + str(index))
		if portrait != null and portrait.texture != null:
			ck(portrait.texture.get_size() == Vector2(640,800), "native profile 640x800")
		hud._close_profile_2012()
		await process_frame
	ck(original == var_to_bytes(host.race.get_state_snapshot()), "viewer does not mutate sporting race")
	print("APEX_PROFILE_VIEWER_066844_%s checks=%d issues=%s" % ["PASS" if failures.is_empty() else "FAIL", checks, str(failures)])
	quit(0 if failures.is_empty() else 1)
