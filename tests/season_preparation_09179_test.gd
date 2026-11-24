extends SceneTree
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Portrait=preload("res://scripts/apex_portrait_local_2012.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize()->void: call_deferred("run")
func check(ok:bool, label:String)->void:
	checks+=1
	if not ok:
		failures.append(label)
		printerr("SEASON_PREPARATION_09179_FAIL ",label)
func settle()->void:
	for i in range(5): await process_frame
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://qa/season_preparation_09179/"+label+".png")==OK,"capture "+label)
func run()->void:
	if DisplayServer.get_name()!="headless": DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/season_preparation_09179"))
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await settle()
	host.set_process(false)
	var front=host.menu_root.get_node("FrontDoor")
	var preview=host.menu_root.find_child("SeasonPreparationPreview",true,false)
	front.open_standard()
	check(preview.drafting and not host.championship_mode and not host.championship.has_season(),"Standard opens unsaved draft")
	check(host.track_picker.disabled and host.selected_track_index==0 and host.seed_picker.editable,"first round locked, seed editable")
	check(preview.create_button.is_visible_in_tree() and not host.start_button.is_visible_in_tree(),"distinct create action")
	host.start_button.pressed.emit()
	check(host.race==null,"hidden start cannot launch GP")
	for i in range(host.teams.size()):
		host.team_picker.select(i)
		host.team_picker.item_selected.emit(i)
		var team:Dictionary=host.teams[i]
		check(preview.team_name.text==str(team.name),"team "+str(i))
		for j in range(2):
			check(preview.names[j].text==str(team.drivers[j].name),"roster "+str(i)+"/"+str(j))
			check(preview.portraits[j].texture==Portrait.get_texture(str(team.drivers[j].name),"hud"),"local optional portrait")
			check(preview.portraits[j].visible==(preview.portraits[j].texture!=null),"fallback")
	host.team_picker.select(0);host.team_picker.item_selected.emit(0)
	host.seed_picker.value=99179
	host.weather_mode_picker.select(3);host.weather_mode_picker.item_selected.emit(3)
	host.pre_race_team_mode_picker.select(1);host.pre_race_team_mode_picker.item_selected.emit(1)
	check(preview.conditions.text.contains("99179") and preview.conditions.text.contains("Chuva intensa") and preview.conditions.text.contains("Automático"),"live conditions")
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		host._layout_ui()
		await settle()
		var bounds:Rect2=host.menu_root.get_node("MenuCard").get_global_rect()
		check(host.get_viewport_rect().encloses(bounds),"card fits logical viewport "+str(resolution))
		check(bounds.encloses(preview.get_global_rect()),"roster and summary fit "+str(resolution))
		check(bounds.encloses(preview.create_button.get_global_rect()) and preview.create_button.is_visible_in_tree(),"fixed create CTA "+str(resolution))
		check(not host.menu_scroll.is_ancestor_of(preview.create_button),"CTA outside scroll")
		await capture("draft_%dx%d"%[resolution.x,resolution.y])
	host._open_staff();host._navigate_back()
	check(preview.drafting and int(host.seed_picker.value)==99179 and host.team_control_mode=="Automático","draft retained through Staff")
	preview.create_button.pressed.emit()
	await settle()
	check(host.championship_new_dialog.visible and host.championship_new_dialog.dialog_text.contains(host.selected_team) and host.championship_new_dialog.dialog_text.contains("99179"),"confirmation reflects draft")
	host.championship_new_dialog.hide()
	check(not host.championship.has_season(),"cancel no save")
	preview.create_button.pressed.emit()
	host.championship_new_dialog.confirmed.emit()
	host.championship_new_dialog.hide()
	await settle()
	check(host.championship.has_season() and host.championship_mode and not preview.drafting,"create actual season")
	check(host.championship.state.seed==99179 and host.championship.state.team==host.selected_team and host.championship.state.calendar.size()==20,"actual season data")
	check(host.team_picker.disabled and host.track_picker.disabled and not host.seed_picker.editable and host.start_button.visible and not preview.create_button.visible,"season locked, start visible")
	await capture("season_ready")
	var saved:Dictionary=host.championship.state.duplicate(true)
	var saved_file:String=FileAccess.get_file_as_string(host.championship.save_path)
	front.open_standard()
	host.team_picker.select(1);host.team_picker.item_selected.emit(1)
	preview.create_button.pressed.emit()
	check(host.championship_new_dialog.dialog_text.contains("substituída"),"replacement warning")
	host.championship_new_dialog.hide()
	check(host.championship.state==saved and FileAccess.get_file_as_string(host.championship.save_path)==saved_file,"draft and cancel preserve existing season on disk")
	host.championship.state.round_index=host.championship.state.calendar.size()
	host._resume_championship()
	check(host.start_button.disabled and preview.circuit.text=="Temporada concluída","completed championship cannot start another round")
	host.championship.state=saved.duplicate(true)
	front.continue_season()
	check(host.selected_team==saved.team and not preview.drafting and host.championship_mode,"continue restores saved team")
	host.start_button.pressed.emit()
	await settle()
	check(host.race!=null and host.race.cars.size()==24 and host.championship_race_active,"launch real championship GP")
	if host.race==null: quit(1);return
	check(host.race.track.code==saved.calendar[0].code,"actual first circuit")
	host.race.running=false
	var race=host.race
	var hash_before:String=Codec.sporting_hash(race,host.replay_session.policy)
	host._show_menu();front.open_sandbox()
	check(not preview.drafting and not host.championship_mode and not host.track_picker.disabled,"sandbox freely configurable")
	front.apply_preset(1)
	check(host.season_tracks[host.selected_track_index].code=="ITA" and preview.circuit.text==str(host.season_tracks[host.selected_track_index].name),"preset summary")
	await settle();await capture("sandbox")
	front.show_home();front.resume_race()
	check(host.race==race and Codec.sporting_hash(race,host.replay_session.policy)==hash_before,"resume preserves sporting hash")
	print("SEASON_PREPARATION_09179_REPORT ",JSON.stringify({"checks":checks,"failures":failures,"graphical":DisplayServer.get_name()!="headless"}))
	if failures.is_empty():print("SEASON_PREPARATION_09179_PASS")
	quit(0 if failures.is_empty() else 1)
