extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
func _initialize()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var results:Array=[]
	for fps in [30,60,144]:
		var race=Race.new(data.teams,"Ferrari",660,{},data.tracks[0],{});race.running=true
		for i in range(fps*10):race.step(1.0/fps)
		results.append({"fps":fps,"clock":race.clock,"ticks":race.tick_counter,"hash":JSON.stringify([race.cars,race.events,race.rng.state]).sha256_text()})
	FileAccess.open(OS.get_environment("APEX_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(results))
	print("BASELINE_PASS ",results);quit()
