extends SceneTree
const Snapshot=preload("res://scripts/race_view_snapshot_0658.gd")
const Race=preload("res://scripts/race_engine.gd")
const Map=preload("res://scripts/track_map.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race=Race.new(data.teams,"Ferrari",6558,{},data.tracks[8],{})
	var route:=Map.new()
	root.add_child(route)
	route.set_track_data(data.tracks[8])
	var results:=[]
	for history_size in [0,500]:
		for car in race.cars:
			car["benchmark_history"]=[]
			for i in range(history_size):car.benchmark_history.append({"lap":i,"time":90.0,"tires":[1,2,3,4]})
		for rep in range(3):
			var state:=Snapshot.new()
			for mode in (["deep","compact"] if rep%2==0 else ["compact","deep"]):
				var start:=Time.get_ticks_usec()
				for frame in range(120):
					for car in race.cars:car.progress+=0.00001
					if mode=="compact":state.build(race.cars,"Ferrari",route,1.0/60,true)
					else:
						var draw_cars:=[]
						for car in race.cars:
							var view:Dictionary=car.duplicate(true)
							view.player=car.team=="Ferrari"
							view.route_point=route.point_on_track(float(car.progress))
							view.route_direction=route.direction_on_track(float(car.progress))
							draw_cars.append(view)
				results.append({"history_entries":history_size,"rep":rep,"mode":mode,"frames":120,"microseconds":Time.get_ticks_usec()-start})
	FileAccess.open("res://qa/race_state_0658/copy_benchmark.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	print("COPY_BENCH_PASS synthetic history isolation, not FPS benchmark")
	quit()
