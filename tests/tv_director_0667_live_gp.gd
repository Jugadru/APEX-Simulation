extends SceneTree
## Full short race: factual highlights + sporting hash regression in same session.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Director = preload("res://scripts/tv_director.gd")
const BASELINE_HASH := "7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for item in data.tracks:
		if str(item.code) == "GBR": track = item.duplicate(true)
	track.laps = 3
	var race = Race.new(data.teams, "Ferrari", 660, {}, track, {})
	race.configure_weather("Seco")
	var first: int = int(race.player_cars()[0].id)
	var second: int = int(race.player_cars()[1].id)
	race.pit_incident_test_overrides[first] = {"service_fault":"Porca travada", "service_delay":4.0, "release_delay":4.5}
	var replay = Replay.new()
	replay.attach(race, {first:"Assistido",second:"Automático"},{"Engenheiro":2,"Estrategista":2})
	var compound: String = race.available_pit_compounds()[0]
	assert(replay.enqueue("order_pit", [first,compound],3))
	assert(replay.enqueue("order_pit", [second,compound],3))
	var director = Director.new()
	var shown_events: Array[Dictionary] = []
	var shown_ids: Dictionary = {}
	var camera_changes: int = 0
	var last_style: String = ""
	while not race.finished and replay.tick < 20000:
		assert(replay.step_tick(), replay.error)
		if replay.tick % 4 == 0:
			director.screen_clock += 0.8
			var _chosen: int = director.select(race, first, race.clock)
			if director.camera_style != last_style:
				camera_changes += 1
				last_style = director.camera_style
			if director.priority >= 99:
				for ev in race.events:
					if str(ev.message) != director.reason:
						continue
					var id: int = int(ev.event_id)
					if shown_ids.has(id):
						break
					shown_ids[id] = true
					shown_events.append({"event_id":id, "type":str(ev.type), "driver_id":int(ev.driver_id), "at":float(ev.time), "style":director.camera_style})
					break
	assert(race.finished)
	assert(replay.hashes[-1] == BASELINE_HASH, "camera must not change sporting hash")
	assert(shown_events.size() > 0, "director should broadcast at least one real highlight")
	var report: Dictionary = {"pass":true, "track":"GBR", "weather":"Seco", "laps":3, "ticks":replay.tick, "hash":replay.hashes[-1], "broadcast_real_events":shown_events.size(), "camera_style_changes":camera_changes, "events":shown_events}
	var out := FileAccess.open("res://qa/tv_director_0667/live_gp.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"  "))
	out.close()
	print("TV_DIRECTOR_0667_LIVE_GP_PASS ", JSON.stringify({"ticks":replay.tick,"hash":replay.hashes[-1],"real_highlights":shown_events.size(),"camera_changes":camera_changes}))
	quit(0)
