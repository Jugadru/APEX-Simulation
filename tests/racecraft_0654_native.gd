extends SceneTree
const R = preload("res://scripts/apex_racecraft_0654.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(4): await process_frame
	host.set_process(false)
	var samples := 0
	var held := 0
	for code in ["GBR","MON"]:
		var found := false
		for i in range(host.season_tracks.size()):
			if host.season_tracks[i].code==code:
				host.selected_track_index=i
				found=true
		assert(found)
		host._start_race()
		host.race.running=true
		var initial := {}
		for tick in range(60):
			host.race.step(.5)
			var cars: Array=host.race.cars.duplicate(true)
			for c in cars:
				c.route_point=host.map_view.point_on_track(c.progress)
				c.route_direction=host.map_view.direction_on_track(c.progress)
			var before := JSON.stringify(cars)
			host.world_view.set_race_cars(cars,-1,.5)
			assert(JSON.stringify(cars)==before)
			var poses: Dictionary = host.world_view.occupation
			if tick==0: initial=poses.duplicate(true)
			assert(poses.size()==cars.size(),"all cars tested")
			for id in poses:
				if not poses[id].visible:
					print("HIDDEN ",code," tick=",tick," id=",id," pose=",poses[id])
					quit(1)
					return
				if poses[id].held:held+=1
				for other in poses:
					if id<other: assert(not R.overlaps(poses[id],poses[other]),"native body overlap")
				samples+=1
		for id in initial:
			assert(host.world_view.occupation[id].progress>initial[id].progress+.005,"traffic must move")
		print("NATIVE_TRACK_PASS ",code," samples=",samples)
	print("RACECRAFT_NATIVE_PASS samples=",samples," traffic holds=",held)
	quit()
