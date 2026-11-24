extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const Identity = preload("res://scripts/presentation/apex_hud_driver_identity_09175.gd")
const PortraitLocal = preload("res://scripts/apex_portrait_local_2012.gd")
var failures: Array[String]=[]
var checks: int=0
var graphical: bool=false

func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures.append(description)
		printerr("DRIVER_HUD_IDENTITY_09175_FAIL ",description)
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in range(4): await process_frame
func capture(label: String) -> void:
	if not graphical: return
	await RenderingServer.frame_post_draw
	var img: Image=root.get_texture().get_image()
	check(img!=null and not img.is_empty(),"native capture "+label)
	if img!=null and not img.is_empty():
		check(img.save_png("res://qa/driver_hud_09175/"+label+".png")==OK,"saved "+label)
func run() -> void:
	graphical=DisplayServer.get_name()!="headless"
	if graphical: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/driver_hud_09175"))
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await settle()
	host.set_process(false)
	host.seed_picker.value=42
	host._start_race()
	host.race.running=false
	var hud=host.race_hud_0620
	await settle()
	check(hud.race_card_panels.size()==2,"existing two cards")
	check(hud.standing_rows.size()==24,"existing 24 standings")
	var strict: bool = "--require-real-portraits" in OS.get_cmdline_user_args()
	var hud_count: int = PortraitLocal.available_count("hud")
	var profile_count: int = PortraitLocal.available_count("profile")
	print("PORTRAIT_PACK_COUNTS HUD=", hud_count, " PROFILE=", profile_count)
	if strict:
		check(hud_count == 24 and profile_count == 24, "strict real local pack 48 resources")
	for key in PortraitLocal.DRIVER_IDS:
		for kind in ["hud", "profile"]:
			var name: String = str(key)
			var tex: Texture2D = PortraitLocal.get_texture(name, kind)
			if tex != null:
				check(tex == PortraitLocal.get_texture(name, kind), "cached texture " + name + " " + kind)
				check(tex.get_size() == (Vector2(384,400) if kind == "hud" else Vector2(640,800)), "pack dimensions " + name + " " + kind)
	check(PortraitLocal.get_texture("unknown fictional driver") == null, "unknown driver never receives another portrait")
	var hash_before: String=Codec.sporting_hash(host.race,host.replay_session.policy)
	var initial_nodes: Array=[]
	for i in range(2):
		var card: Dictionary=hud.race_card_panels[i]
		var driver: Dictionary=host.race.player_cars()[i]
		var badge=card.get("driver_identity")
		check(badge is Identity,"local identity control")
		if not badge is Identity:
			quit(1)
			return
		initial_nodes.append(badge)
		check(badge.portrait == PortraitLocal.get_texture(str(driver.name)), "card matches local portrait or fallback")
		check(badge.driver_id==int(card.id) and badge.driver_name==str(driver.name) and badge.team_name==str(driver.team),"real driver identity")
		check(badge.team_tint==Color.from_string(str(driver.color),Color.WHITE) and badge.driver_slot==i,"team colour and slot")
		check(badge.mouse_filter==Control.MOUSE_FILTER_IGNORE and badge.focus_mode==Control.FOCUS_NONE,"no input interception")
		check(card.tabs.size()==4 and card.quick is Button and card.follow is Button,"existing buttons")
		for key in ["compound_badge","status","wear_bar","pace_value","energy_value","energy_bar","neighbours","drs"]:
			check(card.has(key),"preserved "+key)
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		await settle()
		for mode in [1,2,0]:
			hud._change_hud_mode(mode)
			await settle()
			var viewport: Rect2=hud.get_viewport_rect()
			for i in range(2):
				var card: Dictionary=hud.race_card_panels[i]
				var base: Control=card.base
				var badge: Control=card.driver_identity
				check(base.visible==(mode!=0),"mode visibility unchanged")
				if mode==0: continue
				check(base.get_global_rect().end.x<=viewport.end.x+1.0 and base.get_global_rect().end.y<=viewport.end.y+1.0,"card inside viewport")
				check(base.get_global_rect().encloses(badge.get_global_rect()),"badge inside header")
				var name_label: Label=card.name
				var camera: Button=card.follow
				check(name_label.size.x>=36.0,"driver name retains width")
				check(not badge.get_global_rect().intersects(camera.get_global_rect()),"camera unobstructed")
				check(base.get_global_rect().encloses(camera.get_global_rect()),"camera inside card")
				for tab in card.tabs:
					check(base.get_global_rect().encloses(tab.get_global_rect()),"tab inside card")
			if graphical and mode!=0:
				await capture("%dx%d_mode%d" % [resolution.x,resolution.y,mode])
	hud._change_hud_mode(1)
	for i in range(2):
		for context in range(4):
			hud._expand_driver(i,context)
			await settle()
			var card: Dictionary=hud.race_card_panels[i]
			check(card.expanded.visible and hud.expanded_context[i]==context,"original expandable context")
			check(card.expanded.get_global_rect().end.y<=card.base.get_global_rect().position.y+1.0,"detail opens upward")
			hud._collapse_driver(i)
	# Check the actual ranking, radio selection and profile viewer in this tree.
	for i in range(hud.standing_rows.size()):
		var row: Dictionary = hud.standing_rows[i]
		var car: Dictionary = host.race.get_sorted()[i]
		check(row.portrait.texture == PortraitLocal.get_texture(str(car.name)), "ranking portrait binding")
	hud._open_window("radio")
	await settle()
	for i in range(hud.radio_driver_ids.size()):
		hud.radio_driver_picker.select(i)
		hud._radio_driver_changed(i)
		await settle()
		var car: Dictionary = host._car_by_id(hud.radio_driver_ids[i])
		check(hud.radio_identity_badge.portrait == PortraitLocal.get_texture(str(car.name)), "radio selected identity")
		hud._show_profile_2012()
		await settle()
		var expected: Texture2D = PortraitLocal.get_texture(str(car.name), "profile")
		check(is_instance_valid(hud.driver_profile_panel_2012), "profile viewer opened")
		if expected != null:
			check(is_instance_valid(hud.driver_profile_photo_2012) and hud.driver_profile_photo_2012.texture == expected, "profile uses correct photo")
		if graphical:
			await capture("profile_%d" % i)
		hud._close_profile_2012()
	if graphical: await capture("radio")
	hud._close_window()
	# Existing controls and sporting state stay connected.
	for i in range(10): hud.refresh_hud()
	await settle()
	for i in range(2):
		check(hud.race_card_panels[i].driver_identity==initial_nodes[i],"identity not rebuilt on refresh")
	check(Codec.sporting_hash(host.race,host.replay_session.policy)==hash_before,"HUD never modifies sporting state")
	hud._expand_driver(0,2)
	await settle()
	var card: Dictionary=hud.race_card_panels[0]
	card.lap_picker.value=21
	hud._schedule(0)
	check(host.replay_session.step_tick(),"existing manual command executed")
	check(int(host._car_by_id(int(card.id)).pit_scheduled_lap)==21,"manual BOX V21 stays intact")
	# Starting another team must create fresh identity from that roster.
	host._show_menu()
	host.championship_mode=false
	var previous_team: String=str(host.selected_team)
	for i in range(host.teams.size()):
		if str(host.teams[i].name)!=previous_team:
			host._on_team_selected(i)
			break
	host._start_race()
	host.race.running=false
	await settle()
	for i in range(2):
		var next_card: Dictionary=hud.race_card_panels[i]
		check(next_card.driver_identity.team_name==host.selected_team,"new session identity")
		check(next_card.driver_identity!=initial_nodes[i],"old identity discarded")
	print("DRIVER_HUD_IDENTITY_09175_REPORT ",JSON.stringify({"checks":checks,"failures":failures,"graphical":graphical}))
	if failures.is_empty(): print("DRIVER_HUD_IDENTITY_09175_PASS")
	quit(0 if failures.is_empty() else 1)
