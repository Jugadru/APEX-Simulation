extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Motion = preload("res://tests/legacy/apex_battle_motion_0652.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in data.tracks:
		if t.code == "GBR": track = t
	var map = load("res://scripts/track_map.gd").new()
	root.add_child(map)
	map.set_track_data(track)
	var a = Race.new(data.teams,"Ferrari",6520,{},track,{})
	var b = Race.new(data.teams,"Ferrari",6520,{},track,{})
	a.running = true
	b.running = true
	var observed := 0
	var previous := {}
	for tick in range(180):
		a.step(4.0)
		b.step(4.0)
		var copies: Array = b.cars.duplicate(true)
		for c in copies:
			c.route_point = map.point_on_track(c.progress)
			c.route_direction = map.direction_on_track(c.progress)
		var offsets := Motion.targets(copies,previous)
		for id in offsets:
			previous[id] = Motion.advance(float(previous.get(id,0)),float(offsets[id]),0.033)
			if absf(float(offsets[id])) > 0.1: observed += 1
		assert(JSON.stringify(a.cars)==JSON.stringify(b.cars),"cars unchanged")
		assert(JSON.stringify(a.events)==JSON.stringify(b.events),"events unchanged")
	assert(observed>0,"native combat drives lateral presentation")
	print("GRAPHICS_NATIVE_PASS 720 simulated seconds / same cars and events / lateral samples=",observed)
	quit(0)
