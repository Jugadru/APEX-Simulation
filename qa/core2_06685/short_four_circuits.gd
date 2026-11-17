extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const SCENARIOS = [
	{"code":"GBR","weather":"Seco","seed":660},
	{"code":"BEL","weather":"Chuva intensa","seed":661},
	{"code":"ITA","weather":"Seco","seed":662},
	{"code":"SIN","weather":"Chuva intensa","seed":663}
]
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var output: Dictionary = {}
	for fixture in SCENARIOS:
		var track: Dictionary = {}
		for item in season.tracks:
			if str(item.code) == str(fixture.code): track = item
		assert(not track.is_empty())
		var race = Race.new(season.teams,"Ferrari",int(fixture.seed),{},track,{})
		race.configure_weather(str(fixture.weather))
		var replay = Replay.new()
		replay.attach(race)
		var hashes: Dictionary = {}
		for i in range(80):
			assert(replay.step_tick())
			if replay.tick in [1,20,40,80]: hashes[str(replay.tick)]=str(replay.hashes[-1])
		output[str(fixture.code)]={"hashes":hashes,"events":race.events.size(),"tick":replay.tick,"positions":race.cars.map(func(c):return int(c.position))}
	print("APEX_06685_4C_SHORT " + JSON.stringify(output))
	quit(0)
