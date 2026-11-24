extends SceneTree
const R = preload("res://scripts/apex_racecraft_0654.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5): await process_frame
	host.set_process(false)
	var reports: Array = []
	for seed in [42,6617,6558]:
		for i in range(host.season_tracks.size()):
			if host.season_tracks[i].code=="MON": host.selected_track_index=i
		host.seed_picker.value=seed
		host._start_race()
		host.race.running=true
		var states: Array=[]
		var metrics: Array=[]
		var caps: Array=[INF,0.8,1.6,2.4,INF,INF]
		for cap in caps:
			states.append(host.world_view.occupation.duplicate(true))
			metrics.append({"cap":str(cap),"held":0,"max_hold":0,"runs":{},"max_step":0.0,"overlaps":0,"stationary":0,"resync":0,"cpu_us":0})
		var nominal_overlaps := 0
		var distant_arc_overlaps := 0
		var examples: Array = []
		for tick in range(125):
			host.race.step(.5)
			var cars: Array=host.race.cars.duplicate(true)
			host.world_view.pose_anchors.clear()
			var nominal: Dictionary={}
			for car in cars:
				car.route_point=host.map_view.point_on_track(car.progress)
				car.route_direction=host.map_view.direction_on_track(car.progress)
				if R.eligible(car):
					nominal[int(car.id)]=host.world_view._sample_occupied_pose(car,float(car.race_lane),0.0)
			var length: float=host.world_view.projection_index.total_length
			for id in nominal:
				for other in nominal:
					if int(id)>=int(other) or not R.overlaps(nominal[id],nominal[other]): continue
					nominal_overlaps+=1
					var gap := absf(float(nominal[id].progress)-float(nominal[other].progress))
					gap = minf(fposmod(gap,1.0),1.0-fposmod(gap,1.0))*length
					if gap > 6.4:
						distant_arc_overlaps+=1
						if examples.size()<12: examples.append({"tick":tick,"a":id,"b":other,"arc_gap":gap,"world_gap":Vector2(nominal[id].position).distance_to(Vector2(nominal[other].position))})
			for n in range(caps.size()):
				var old: Dictionary=states[n]
				var start:=Time.get_ticks_usec()
				var poses:=R.solve(cars,old,.5,host.world_view._sample_occupied_pose,float(caps[n]),n>=4,n==5)
				var row: Dictionary=metrics[n]
				row["synchronized"]=n>=4
				row["local_repair"]=n==5
				row.cpu_us+=Time.get_ticks_usec()-start
				for id in poses:
					var pose: Dictionary=poses[id]
					if bool(pose.get("held",false)):
						row.held+=1
						row.runs[id]=int(row.runs.get(id,0))+1
						row.max_hold=maxi(int(row.max_hold),int(row.runs[id]))
					else: row.runs[id]=0
					if bool(pose.get("resynced",false)): row.resync+=1
					if old.has(id) and tick>0:
						var step:=Vector2(pose.position).distance_to(Vector2(old[id].position))
						row.max_step=maxf(float(row.max_step),step)
						if step<.015: row.stationary+=1
					for other in poses:
						if int(id)<int(other) and R.overlaps(pose,poses[other]): row.overlaps+=1
				states[n]=poses
		for row in metrics: row.erase("runs")
		reports.append({"seed":seed,"nominal_overlaps":nominal_overlaps,"distant_arc_overlaps":distant_arc_overlaps,"examples":examples,"variants":metrics})
	print("MOTION_RETREAT_PROBE_09173_REPORT ",JSON.stringify(reports))
	# Diagnostic only; the main benchmark is the acceptance gate.
	print("MOTION_RETREAT_PROBE_09173_PASS")
	quit(0)
