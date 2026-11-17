extends SceneTree
## Run: godot --headless --path . --script res://tests/smoke_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")
const TrackScript = preload("res://scripts/track_map.gd")

func _initialize() -> void:
	var season = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	assert(season["teams"].size() == 12)
	assert(season["tracks"].size() == 20)
	var track: Dictionary = season["tracks"][11] # Belgium
	var race = RaceScript.new(season["teams"], "Ferrari", 42, {"Motor":1, "Asa":1, "Chassi":1}, track)
	assert(race.cars.size() == 24)
	var player = race.player_cars()
	assert(player.size() == 2)
	race.order_pit(int(player[0]["id"]), "Duro")
	race.set_pace(int(player[0]["id"]), "Atacar")
	race.running = true
	for i in range(700):
		race.step(0.2)
	assert(race.clock > 100.0)
	assert(race.get_sorted().size() == 24)
	assert(race.get_sorted()[0]["progress"] > 0.1)
	var m = TrackScript.new()
	get_root().add_child(m)
	m.set_track_data(track)
	assert(m.route.size() > 100)
	assert(m.point_on_track(0.0).distance_to(m.point_on_track(1.0)) < 5.0)
	print("APEX TEST OK: 2012 track, 24 drivers, continuous engine, pit command")
	quit(0)
