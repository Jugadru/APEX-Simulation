extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const R=preload("res://scripts/core/race_replay_0660.gd")
const C=preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var engine=Race.new(data.teams,"Ferrari",660,{},data.tracks[0],{})
	engine.configure_weather("Automático")
	engine.weather.rain_events.assign([{"start":5.0,"duration":40.0,"power":0.95}])
	var s=R.new();s.attach(engine)
	var rainy:Dictionary={};var peak:=0.0
	for i in range(400):
		assert(s.step_tick())
		peak=maxf(peak,float(engine.weather_snapshot().rain_intensity))
		if i==125:rainy=s.checkpoint()
	assert(peak>0.5 and float(engine.weather_snapshot().rain_intensity)==0.0)
	var r=R.new();assert(r.load_data(s.export_data()));r.checkpoints=[r.checkpoints[0],rainy]
	assert(r.seek(400),r.error)
	assert(C.sporting_hash(r.race,r.policy)==s.hashes[-1])
	print("REPLAY_WEATHER_PASS no rain/rain/no rain and restore in rain, peak=",peak)
	quit()
