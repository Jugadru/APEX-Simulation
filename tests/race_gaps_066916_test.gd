extends SceneTree
## APEX 9.16 — signed circuit proximity, lapped traffic, HUD, Replay 023.
const Radar = preload("res://scripts/presentation/apex_hud_race_gaps_066916.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		printerr("RACE_GAPS_066916_FAIL " + label)

func sample(id: int, progress: float, extras: Dictionary = {}) -> Dictionary:
	var car: Dictionary = {"id":id,"progress":progress,"name":"Piloto %d" % id,
		"finished":false,"disqualified":false,"pit_left":0.0}
	car.merge(extras, true)
	return car

func _run() -> void:
	var grid: Array = [sample(1,0.998),sample(2,1.002),
		sample(3,0.990),sample(4,0.300)]
	var inputs: PackedByteArray = var_to_bytes(grid)
	var observation: Dictionary = Radar.observe(grid,1000.0)
	check(observation.size() == 4, "all four fixture cars observed")
	check(observation[1]["ahead_id"] == 2
		and is_equal_approx(float(observation[1]["ahead_units"]),4.0),
		"timing-line wrap: actual ahead distance is four schematic units")
	check(observation[1]["behind_id"] == 3
		and is_equal_approx(float(observation[1]["behind_units"]),8.0),
		"actual back proximity remains eight units")
	check(Radar.label_for(observation,1) == "F 4u"
		and str(Radar.hint_for(observation,1)).contains("não") == false,
		"ranking metric uses physical units instead of fabricated seconds")
	check(str(observation[4].label) == "LIVRE",
		"far-away driver has no invented nearby rival")
	check(str(observation[1].hint).contains("NÃO é intervalo cronometrado"),
		"source limitations explained in UI tooltip")
	check(inputs == var_to_bytes(grid), "original array and dictionaries stay untouched")
	check(observation == Radar.observe(grid,1000.0),
		"same observations produce exactly the same radar")

	var excluded: Array = [sample(1,0.998),sample(2,1.002,{"pit_left":5.0}),
		sample(3,0.990,{"finished":true}),sample(4,0.400)]
	var skipped: Dictionary = Radar.observe(excluded,1000.0)
	check(skipped[1].label == "LIVRE"
		and skipped[2].label == "—" and skipped[3].label == "—",
		"finished and in-pit cars are never treated as battles")
	var disqualified: Dictionary = Radar.observe([
		sample(1,0.998,{"disqualified":true}),sample(2,1.002)],1000.0)
	check(disqualified[1].label == "—" and disqualified[2].label == "LIVRE",
		"disqualified drivers excluded from proximity")
	check(Radar.observe(grid,1000.0,true)[1].label == "—",
		"race finished disables physical race gap metric")
	var lapped: Dictionary = Radar.observe([
		sample(1,2.998),sample(2,2.002),sample(3,0.500)],1000.0)
	check(lapped[1].ahead_id == 2
		and is_equal_approx(float(lapped[1].ahead_units),4.0),
		"lapped vehicle physically ahead without treating rank as geometry")
	var close_behind: Dictionary = Radar.observe([
		sample(1,0.400), sample(2,0.380), sample(3,0.900)],1000.0)
	check(close_behind[1].label == "T 20u" and close_behind[1].ahead_id == -1,
		"trailing pressure correctly shown when no nearby car ahead")
	check(Radar.label_for({},112) == "—"
		and Radar.hint_for({},112) == "Proximidade indisponível.",
		"missing driver fails closed")
	var tie: Dictionary = Radar.observe([
		sample(1,0.500),sample(4,0.512),sample(2,0.512)],1000.0)
	check(tie[1].ahead_id == 2, "equal physical gaps use stable driver ID")
	var exact_overlap: Dictionary = Radar.observe([
		sample(1,0.500),sample(2,0.500)],1000.0)
	check(exact_overlap[1].label == "LIVRE",
		"exact overlapping progress never creates a fictitious distance")

	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/season_2012.json"))
	if not data is Dictionary:
		check(false,"official 2012 data readable")
		_finish()
		return
	var season: Dictionary = data
	var tracks: Array = season.get("tracks",[])
	check(tracks.size() == 20, "catalogue with all 20 circuits")
	var selected: Dictionary = {}
	for t in tracks:
		if str(t.get("code","")) == "GBR":
			selected = t
			break
	var race = Race.new(season.teams,"Ferrari",6616,{},selected,{})
	check(race.cars.size() == 24 and not race.space_profile.is_empty(),
		"real 24-car British GP initializes with geometric track")
	var player: Dictionary = race.player_cars()[0]
	check(race.schedule_pit(int(player.id),
		str(race.available_pit_compounds()[1]),21),
		"manual BOX V21 approved by original engine")
	race.configure_weather("Chuva intensa")
	var native_before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
	var rng_before: int = race.rng.state
	var native_grid: Array = race.get_sorted()
	var report: Dictionary = Radar.observe(native_grid,
		float(race.space_profile.get("length",1000.0)),false)
	check(report.size() == 24, "radar covers exactly real 24-car grid")
	check(var_to_bytes(race.get_state_snapshot()) == native_before
		and race.rng.state == rng_before
		and int(player.get("pit_scheduled_lap",0)) == 21,
		"full native snapshot, RNG and manual pit unchanged by radar")
	check(Replay.SIMULATION_REVISION in ["023_overtaking_intelligence_v1", "024_race_start_spatial_v1", "025_competitive_grid_start_v1", "026_competitive_traffic_v1", "027_race_traffic_hotfix_v1", "028_racing_line_v1", "029_racing_line_following_v1", "030_racing_line_completion_v1", "031_independent_racecraft_v1", "032_aero_wake_v1", "033_aero_wake_source_v2", "034_aero_traffic_stability_v1", "035_aero_wet_line_v1", "036_tactical_coordination_v1", "037_corner_battle_v1", "038_driver_traffic_v2", "039_traffic_pack_v1", "040_driver_error_recovery_v1"]
		and Replay.PRE_START20_SIMULATION_REVISION == "023_overtaking_intelligence_v1",
		"9.16 HUD remains advisory; archived replay 023 still supported")
	var first = Replay.new()
	first.attach(race)
	race.running = true
	var other_race = Race.new(season.teams,"Ferrari",6616,{},selected,{})
	other_race.schedule_pit(int(other_race.player_cars()[0].id),
		str(other_race.available_pit_compounds()[1]),21)
	other_race.configure_weather("Chuva intensa")
	var second = Replay.new()
	second.attach(other_race)
	other_race.running = true
	var replay_ok: bool = true
	for i in range(50):
		if not first.step_tick() or not second.step_tick():
			replay_ok = false
			break
		Radar.observe(race.get_sorted(),float(race.space_profile.get("length",1000.0)))
	check(replay_ok and first.hashes == second.hashes
		and first.first_divergence < 0,
		"50 authentic 24-car ticks have identical hashes with and without radar")
	check(int(player.get("pit_scheduled_lap",0)) == 21
		and int(player.get("stops",0)) == 0,
		"early ticks cannot bring manual V21 forward")

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	game.set_process(false)
	game.race.running = false
	var hud = game.race_hud_0620
	var before_hash: String = Codec.sporting_hash(game.race, game.replay_session.policy)
	var initial_calls: int = hud.proximity_refreshes_0923
	var order: Array = game.race.get_sorted()
	var order_before: PackedByteArray = var_to_bytes(order)
	check(initial_calls == 0 and hud.race_gap_radar_066916.is_empty(),
		"default HUD starts without proximity work")
	for speed in [1.0, 16.0, 32.0]:
		game.sim_speed = speed
		for metric in range(7):
			hud.metric_index = metric
			hud.refresh_hud(order)
			check(hud.proximity_refreshes_0923 == initial_calls and hud.race_gap_radar_066916.is_empty(),
				"no proximity projection for metric %d at %.0fx" % [metric, speed])
	# Switch via the actual metric callback while paused. It must compute a fresh
	# radar on demand instead of waiting for the simulation or displaying stale values.
	hud.metric_index = 6
	hud._move_metric(1)
	check(hud.proximity_refreshes_0923 == initial_calls + 1, "exactly one projection on selection")
	check(str(hud.METRICS[7]) == "DIST. PISTA"
		and hud.race_gap_radar_066916.size() == 24,
		"native HUD includes new proximity metric for 24 drivers")
	check(str(hud._standing_value(order,0)) ==
		Radar.label_for(hud.race_gap_radar_066916,int(order[0].id)),
		"new metric uses the exact HUD observation snapshot")
	check(str(hud.standing_rows[0]["detail"].tooltip_text).contains("NÃO é intervalo cronometrado"),
		"visible ranking row explains schematic units, not time gap")
	var expected_radar: Dictionary = Radar.observe(order,float(game.race.space_profile.get("length",1000.0)))
	check(hud.race_gap_radar_066916 == expected_radar, "full 24-car radar matches original projection")
	for i in range(order.size()):
		var driver_id: int = int(order[i].id)
		check(str(hud.standing_rows[i]["detail"].text) == Radar.label_for(expected_radar,driver_id),
			"proximity text parity row %d" % i)
		check(str(hud.standing_rows[i]["detail"].tooltip_text) == Radar.hint_for(expected_radar,driver_id),
			"proximity tooltip parity row %d" % i)
	hud.refresh_hud(order)
	check(hud.proximity_refreshes_0923 == initial_calls + 2, "shared order refresh recomputes selected radar")
	hud._move_metric(1)
	check(hud.metric_index == 0 and hud.race_gap_radar_066916.is_empty(),
		"leaving metric clears presentation-only radar")
	check(str(hud.standing_rows[0]["detail"].tooltip_text).is_empty(), "old radar tooltip cleared")
	check(str(hud._standing_value(order,0)) == "—",
		"existing INTERVALO value remains untouched when switching back")
	game._update_game_ui()
	check(hud.proximity_refreshes_0923 == initial_calls + 2, "normal presenter also avoids unused radar")
	check(var_to_bytes(order) == order_before and Codec.sporting_hash(game.race,game.replay_session.policy) == before_hash,
		"HUD switches and shared order do not mutate sporting state")
	game.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	for error in errors:
		printerr(error)
	if errors.is_empty():
		print("RACE_GAPS_066916_PASS checks=%d presentation_only=true" % checks)
	quit(0 if errors.is_empty() else 1)
