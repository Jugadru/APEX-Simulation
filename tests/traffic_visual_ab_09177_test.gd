extends SceneTree
const Baseline = preload("res://tests/legacy/motion_baseline_09177.gd")
const Motion = preload("res://scripts/apex_racecraft_0654.gd")
const Snapshot = preload("res://scripts/race_view_snapshot_0658.gd")
const Fixture = preload("res://tests/motion_fixture_09173.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const STEPS := 312
var failures := 0
func _initialize() -> void: call_deferred("run")
func detached(cars: Array) -> Array:
	var result: Array=[]
	for source in cars:
		var car: Dictionary={}
		for key in Snapshot.FIELDS:
			if source.has(key): car[key]=source[key]
		result.append(car)
	return result
func run_case(host, timeline: Array, interval: float, candidate: bool) -> Dictionary:
	var snap := Snapshot.new()
	var last_tick := 0
	var poses: Dictionary={}
	var prior_nominal: Dictionary={}
	var last_input: Dictionary={}
	var metrics := {"interval":interval,"candidate":candidate,"frames":0,"held":0,"stationary":0,"recoveries":0,"max_stationary_streak":0,"events":[],"max_step":0.0,"max_extra_step":0.0,"overlaps":0,"max_lag":0.0,"reversals":0,"worst":{},"cpu_us":0}
	var sampler: Callable=host.world_view._sample_occupied_pose
	var streak: Dictionary={}
	snap.capture_completed_tick(timeline[0])
	for frame in range(int(floor(float(STEPS)*0.2/interval))+1):
		var seconds:=float(frame)*interval
		var tick:=mini(STEPS,int(floor(seconds/0.2+0.00000001)))
		while last_tick<tick:
			last_tick+=1
			snap.capture_completed_tick(timeline[last_tick])
		var phase:=clampf((seconds-float(tick)*0.2)/0.2,0.0,1.0)
		var draw:=snap.build(timeline[tick],"Ferrari",host.map_view,interval,true,phase)
		host.world_view.pose_anchors.clear()
		var old:=poses
		var start:=Time.get_ticks_usec()
		if candidate:
			poses=Motion.solve_interval(draw,old,interval,sampler,last_input)
		else:
			poses=Baseline.solve_interval(draw,old,interval,sampler,last_input)
		last_input=Motion.nominal_history(draw)
		metrics.cpu_us+=Time.get_ticks_usec()-start
		metrics.frames+=1
		var nominal: Dictionary={}
		for car in draw:
			if Motion.eligible(car):
				var id:=int(car.id)
				nominal[id]=sampler.call(car,float(car.race_lane),0.0)
				if not poses.has(id): failures+=1
		for id in poses:
			var p: Dictionary=poses[id]
			if bool(p.get("held",false)): metrics.held+=1
			if nominal.has(id):
				metrics.max_lag=maxf(float(metrics.max_lag),float(nominal[id].progress)-float(p.progress))
			if old.has(id) and prior_nominal.has(id) and nominal.has(id):
				var displacement:=Vector2(p.position).distance_to(Vector2(old[id].position))
				var nominal_step:=Vector2(nominal[id].position).distance_to(Vector2(prior_nominal[id].position))
				if bool(p.get("stationary_recovery",false)): metrics.recoveries+=1
				if displacement<0.015 and nominal_step>=0.015:
					metrics.stationary+=1
					streak[id]=int(streak.get(id,0))+1
					metrics.max_stationary_streak=maxi(metrics.max_stationary_streak,int(streak[id]))
					metrics.events.append({"id":id,"tick":tick,"frame":frame,"nominal":nominal_step,"lag":float(nominal[id].progress)-float(p.progress),"held":p.get("held",false)})
				else: streak[id]=0
				if float(p.progress)<float(old[id].progress)-0.00000001: metrics.reversals+=1
				if displacement>float(metrics.max_step):
					metrics.max_step=displacement
					metrics.worst={"frame":frame,"tick":tick,"id":id,"visual_step":displacement,"nominal_step":nominal_step,"prior_lag":float(prior_nominal[id].progress)-float(old[id].progress),"resynced":bool(p.get("resynced",false)),"old":str(old[id]),"new":str(p)}
				metrics.max_extra_step=maxf(float(metrics.max_extra_step),displacement-nominal_step)
			for other in poses:
				if int(id)<int(other) and Motion.overlaps(p,poses[other]): metrics.overlaps+=1
		prior_nominal=nominal
	if metrics.overlaps>0: failures+=1
	return metrics
func run() -> void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5): await process_frame
	host.set_process(false)
	var reports: Array=[]
	var track_code: String=OS.get_environment("APEX_VISUAL_TRACK") if OS.has_environment("APEX_VISUAL_TRACK") else "MON"
	var configs: Array=[{"profile":"stock","seed":42},{"profile":"stock","seed":6558},{"profile":"developed","seed":42},{"profile":"developed","seed":6558}]
	if track_code!="MON": configs=[configs[0]]
	for cfg in configs:
		for i in range(host.season_tracks.size()):
			if host.season_tracks[i].code==track_code: host.selected_track_index=i
		Fixture.configure(host,str(cfg.profile),int(cfg.seed))
		host._start_race()
		if not Fixture.matches(host,str(cfg.profile),int(cfg.seed)):
			printerr("FIXED_TIMELINE_FIXTURE_FAIL ",cfg)
			quit(1)
			return
		host.race.running=true
		var timeline: Array=[detached(host.race.cars)]
		# Use the real live scheduler's fixed ticks, including staff/commands.
		for i in range(STEPS):
			if not host.replay_session.step_tick():
				printerr("FIXED_TIMELINE_TICK_FAIL ",i)
				quit(1)
				return
			timeline.append(detached(host.race.cars))
		var hash_before: String=Codec.sporting_hash(host.race,host.replay_session.policy)
		var timeline_hash: String=Codec.digest(timeline)
		var variants: Array=[]
		for interval in [1.0/30.0,1.0/6.0,0.5]:
			for candidate in [false,true]:
				variants.append(run_case(host,timeline,float(interval),bool(candidate)))
		for i in range(0,variants.size(),2):
			var old: Dictionary=variants[i]
			var new: Dictionary=variants[i+1]
			if new.stationary>old.stationary or new.max_stationary_streak>old.max_stationary_streak or new.max_step>old.max_step+0.01 or new.reversals>old.reversals or new.overlaps>old.overlaps:
				failures+=1
				printerr("TRAFFIC_VISUAL_AB_09177_REGRESSION ",track_code," ",cfg," ",old.interval)
		if hash_before!=Codec.sporting_hash(host.race,host.replay_session.policy) or timeline_hash!=Codec.digest(timeline): failures+=1
		reports.append({"track":track_code,"profile":cfg.profile,"seed":cfg.seed,"ticks":STEPS,"hash":hash_before,"timeline_hash":timeline_hash,"variants":variants})
	print("TRAFFIC_VISUAL_AB_09177_REPORT ",JSON.stringify({"cases":reports,"failures":failures}))
	# Safety gate, not a substitute for the existing comparative quality gate.
	if track_code=="MON":
		var total_old:=0
		var total_new:=0
		for row in reports:
			for i in range(0,row.variants.size(),2):
				total_old+=int(row.variants[i].stationary)
				total_new+=int(row.variants[i+1].stationary)
		if total_new>=total_old: failures+=1
	if failures==0: print("TRAFFIC_VISUAL_AB_09177_PASS")
	quit(0 if failures==0 else 1)
