extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var code := OS.get_environment("APEX_TRACK")
	if code not in ["GBR","ITA","MON"]:
		printerr("TRAFFIC_FULL_GP_TRACK_FAIL")
		quit(1)
		return
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for item in season.tracks:
		if item.code == code: track = item; break
	var race = Race.new(season.teams, "Ferrari", 99176, {}, track, {})
	race.configure_weather("Seco")
	race.running = true
	var started := Time.get_ticks_msec()
	for tick in range(65000):
		race.step(0.2)
		if race.finished: break
	var report := {"track":code,"finished":race.finished,"laps":race.lap_count,"ticks":race.tick_counter,"cars":race.cars.size(),"hash":Codec.sporting_hash(race,{}),"elapsed_ms":Time.get_ticks_msec()-started}
	print("TRAFFIC_FULL_GP_09177_REPORT ",JSON.stringify(report))
	if race.finished and race.cars.size()==24: print("TRAFFIC_FULL_GP_09177_PASS")
	quit(0 if race.finished and race.cars.size()==24 else 1)
