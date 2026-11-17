extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const CASES = [
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
	var passed := true
	for fixture in CASES:
		var track: Dictionary = {}
		for item in season.tracks:
			if str(item.code)==str(fixture.code): track=item
		if track.is_empty():
			push_error("Track missing: "+str(fixture.code))
			quit(1)
			return
		var engine=Race.new(season.teams,"Ferrari",int(fixture.seed),{},track,{})
		engine.configure_weather(str(fixture.weather))
		var replay=Replay.new()
		replay.attach(engine)
		var car_id: int = int(engine.player_cars()[0].id)
		if str(fixture.code)=="BEL":
			if not replay.enqueue("schedule_pit",[car_id,engine.available_pit_compounds()[0],21],1):
				push_error("Schedule V21 failed")
				quit(1)
				return
		var markers: Dictionary = {}
		var started: int = Time.get_ticks_usec()
		for n in range(750):
			if not replay.step_tick():
				push_error("Race step failed: "+replay.error)
				quit(1)
				return
			if replay.tick in [1,80,250,500,750]:
				markers[str(replay.tick)]=str(replay.hashes[-1])
		if str(fixture.code)=="BEL":
			var player: Dictionary = {}
			for c in engine.player_cars():
				if int(c.id)==car_id:player=c
			if int(player.get("pit_scheduled_lap",0))!=21:
				push_error("Manual V21 overwritten or unexpectedly executed")
				passed=false
		var positions: Array = []
		for c in engine.get_sorted(): positions.append(int(c.id))
		output[str(fixture.code)]={"ticks":replay.tick,"hashes":markers,"positions_by_id":positions,"events":engine.events.size(),"checkpoints":replay.checkpoints.size(),"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"wall_ms":float(Time.get_ticks_usec()-started)/1000.0}
		print("CORE2_06686_TRACK "+JSON.stringify({"code":str(fixture.code),"tick":replay.tick,"hash":replay.hashes[-1],"ms":output[str(fixture.code)].wall_ms}))
	var path: String = OS.get_environment("APEX_06686_OUTPUT")
	if not path.is_empty():
		var f:=FileAccess.open(path,FileAccess.WRITE)
		if f!=null:
			f.store_string(JSON.stringify(output,"  "))
			f.close()
	print("CORE2_06686_FOUR_CIRCUITS "+JSON.stringify(output))
	quit(0 if passed else 1)
