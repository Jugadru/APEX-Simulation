extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track:Dictionary={}
	for t in data.tracks:
		if t.code=="GBR":track=t.duplicate(true)
	track.laps=3
	var race=Race.new(data.teams,"Ferrari",6552,{},track,{})
	race.configure_weather("Seco")
	race.pit_incidents_enabled=false
	var driver:int=race.player_cars()[0].id
	race.order_pit(driver,"Duro")
	race.running=true
	var previous:Dictionary={}
	for i in range(220):
		for c in race.cars:previous[int(c.id)]=float(c.progress)
		race.step(4.0)
		for c in race.cars:
			assert(float(c.progress)>=float(previous[int(c.id)])-.000001,"progress never rewinds")
		if race.finished:break
	assert(race.finished,"short GP must finish")
	assert(race.get_pit_history().size()>0,"pit completes")
	assert(race.telemetry!=null)
	var counted:=0
	for c in race.cars:
		assert(c.finished)
		assert(int(c.position)>=1 and int(c.position)<=race.cars.size())
		counted+=1
	print("SIM_GP_PASS cars=",counted," laps=3 clock=",race.clock," completed stops=",race.get_pit_history().size())
	quit()
