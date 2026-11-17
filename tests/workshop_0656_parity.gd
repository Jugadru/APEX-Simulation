extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
func _initialize()->void: call_deferred("run")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track:Dictionary={}
	for t in data.tracks:
		if t.code=="GBR": track=t.duplicate(true)
	var race=Race.new(data.teams,"Ferrari",6552,{},track,{})
	race.configure_weather("Seco")
	race.running=true
	var steps:=0
	while not race.finished and steps<4000:
		race.step(4.0)
		steps+=1
	assert(race.finished)
	var output:Dictionary={"clock":race.clock,"cars":race.cars,"events":race.events,"pits":race.get_pit_history()}
	var output_path:=OS.get_environment("APEX_PARITY_OUTPUT")
	if output_path.is_empty(): output_path="user://silverstone_parity.json"
	var f:=FileAccess.open(output_path,FileAccess.WRITE)
	f.store_string(JSON.stringify(output))
	print("SILVERSTONE_PARITY_PASS laps=",track.laps," clock=",race.clock," seed=6552")
	quit()
