extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in season["tracks"]:
		if str(t["code"]) == "BRA": track = t
	var four: Array = [season["teams"][0],season["teams"][1]]
	var race = Race.new(four,str(four[0]["name"]),321,{},track,{})
	race.configure_weather("Chuva intensa")
	for car in race.player_cars():
		race.set_pit_control_mode(int(car["id"]),"IA")
	race.running = true
	var steps: int = 0
	var sampled: Array = []
	var prev: int = -1
	while not race.finished and steps < 4000:
		race.step(4.0)
		steps += 1
		if int(race.lap) != prev:
			prev = int(race.lap)
			var w: Dictionary = race.weather_snapshot()
			sampled.append({"lap":prev,"rain":w.get("rain_intensity"),"water_mm":w.get("water_mm"),"moisture":w.get("surface_moisture")})
	print("APEX_0643_RAIN_TRACE ", JSON.stringify({"finished":race.finished,"steps":steps,"laps":race.lap,"stops":race.pit_history,"samples":sampled}))
	quit(0 if race.finished else 1)
