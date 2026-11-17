extends SceneTree
const R=preload("res://scripts/core/race_replay_0660.gd")
const C=preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var h=load("res://scenes/main.tscn").instantiate();root.add_child(h);await process_frame
	h.set_process(false);h.seed_picker.value=660;h.team_control_mode="Automático";h._start_race()
	var live=h.replay_session
	var initial:Dictionary=live.export_data()
	var direct=R.new();direct.attach(C.restore(initial.checkpoints[0].state),initial.checkpoints[0].policy.modes,initial.checkpoints[0].policy.staff)
	h.race.running=true
	for i in range(1200):
		if i==150:
			h.race.set_pace(int(h.race.player_cars()[0].id),"Atacar")
			h.race._event("engineer_question",int(h.race.player_cars()[0].id),"Pergunta registrada da fixture.",54)
		h.render_mode=0 if i%2==0 else 1
		h._process(0.016 if i%3==0 else 0.03)
		if i%37==0:
			h.race.running=false;h._process(0.25);h.race.running=true
	assert(h.race.lap >= 2)
	direct.commands=live.commands.duplicate(true)
	for i in range(live.tick):assert(direct.step_tick())
	assert(live.hashes==direct.hashes,"UI/2D/3D must not change sport")
	var inventory:String=C.digest(h.garage.get_team(h.selected_team))
	var livehash:String=C.sporting_hash(live.race,live.policy)
	h.replay_ui=load("res://scripts/race_replay_panel_0660.gd").new();h.add_child(h.replay_ui);h.replay_ui.setup(h)
	h.replay_ui.watch();assert(h.replay_session.playback)
	h.replay_ui.target.value=live.tick;h.replay_ui.seek_target()
	assert(h.replay_session.first_divergence==-1)
	h.garage.inventory_observe(h.race, true)
	h._commit_championship_result()
	assert(C.digest(h.garage.get_team(h.selected_team))==inventory,"replay cannot affect inventory")
	h.replay_ui.leave();assert(h.replay_session==live)
	assert(C.sporting_hash(h.race,live.policy)==livehash)
	assert(C.digest(h.garage.get_team(h.selected_team))==inventory)
	h.queue_free();await process_frame
	print("REPLAY_INTEGRATION_PASS renders, UI, replay seek, live restore, inventory isolation")
	quit()
