extends SceneTree
const Unit=preload("res://tests/replay_0660_test.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Race=preload("res://scripts/race_engine.gd")
func _initialize()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var r=Race.new(data.teams,"Ferrari",660,{},data.tracks[0],{})
	r.running=true
	var start:=Time.get_ticks_usec()
	for i in range(200):r.step(0.05)
	var sim:=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	for i in range(200):Codec.sporting_hash(r,{})
	print("COST sim_us/tick=",sim/200.0," hash_us/tick=",(Time.get_ticks_usec()-start)/200.0)
	quit()
