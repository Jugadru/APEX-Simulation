extends SceneTree
## Independent sampled road-arc diagnostic. Keep view_0658_motion unchanged:
## its chord sweep remains a separate, deliberately conservative diagnostic.
const Motion = preload("res://scripts/apex_racecraft_0654.gd")
const Fixture = preload("res://tests/motion_fixture_09173.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void: call_deferred("run")
func advance(a: Dictionary,b: Dictionary) -> float:
	var total: float = float(b.route_length)
	return fposmod(float(b.arc_distance)-float(a.arc_distance)+total*0.5,total)-total*0.5
func sample(world, a: Dictionary,b: Dictionary,t: float) -> Dictionary:
	var distance: float = fposmod(float(a.arc_distance)+advance(a,b)*t,float(b.route_length))
	var index: int = clampi(world.road_distances.bsearch(distance,true)-1,0,world.road_centers.size()-1)
	var next: int = (index+1)%world.road_centers.size()
	var fraction: float = clampf((distance-float(world.road_distances[index]))/maxf(.000001,float(world.projection_index.lengths[index])),0,1)
	var center: Vector3 = world.road_centers[index].lerp(world.road_centers[next],fraction)
	var side: Vector3 = world.road_normals[index].lerp(world.road_normals[next],fraction).normalized()
	var width: float = lerpf(world.road_widths[index],world.road_widths[next],fraction)
	var lane: float = clampf(lerpf(float(a.lane),float(b.lane),t),-maxf(0,width-1.45),maxf(0,width-1.45))
	var pos: Vector3 = center+side*lane
	return {"position":Vector2(pos.x,pos.z),"direction":Vector2(side.z,-side.x),"half_width":b.half_width,"half_length":b.half_length}
func match_pose(a: Dictionary,b: Dictionary) -> bool:
	return Vector2(a.position).distance_to(Vector2(b.position))<0.001 and Vector2(a.direction).dot(Vector2(b.direction))>0.99999
func run() -> void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(5): await process_frame
	host.set_process(false)
	var track_code: String = OS.get_environment("APEX_VISUAL_TRACK") if OS.has_environment("APEX_VISUAL_TRACK") else "MON"
	var seed_value: int = int(OS.get_environment("APEX_TRAFFIC_SEED")) if OS.has_environment("APEX_TRAFFIC_SEED") else 6558
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].code)==track_code: host.selected_track_index=i
	Fixture.configure(host,"stock",seed_value)
	var climate: String=OS.get_environment("APEX_ARC_CLIMATE") if OS.has_environment("APEX_ARC_CLIMATE") else "Seco"
	for i in range(host.weather_mode_picker.item_count):
		if host.weather_mode_picker.get_item_text(i)==climate: host.weather_mode_picker.select(i); break
	host._start_race()
	if not Fixture.matches(host,"stock",seed_value) or str(host.race.weather_mode)!=climate:
		printerr("TRAFFIC_ARC_FIXTURE_FAIL")
		quit(1)
		return
	host.race.running=true
	var host_pipeline: bool = OS.get_environment("APEX_ARC_PIPELINE") == "host"
	var frames: int = 240 if host_pipeline else 360
	var previous: Dictionary={}
	var chord_alerts:=0;var arc_alerts:=0;var endpoints:=0;var bad_anchors:=0;var checks:=0;var coverage:=0;var discontinuities:=0
	var reversals:=0
	var elapsed_sim:=0.0
	var max_lag:=0.0;var max_hold:=0;var stationary:=0
	for frame in range(frames):
		host.sim_speed=1.0 if frame<120 else (16.0 if frame<240 else 32.0)
		var draw: Array=[]
		if host_pipeline:
			host._process(1.0/30.0)
			if host.render_mode != 1 or not host.presented_3d_active:
				printerr("TRAFFIC_ARC_HOST_3D_INACTIVE")
				quit(1)
				return
			for id in host.world_view.previous_nominal:
				draw.append({"id":id,"progress":host.world_view.previous_nominal[id].progress})
		else:
			elapsed_sim+=host.sim_speed/30.0
			while host.replay_session.tick<int(floor(elapsed_sim/0.2+0.0000001)):
				if not host.replay_session.step_tick():
					printerr("TRAFFIC_ARC_TICK_FAIL")
					quit(1)
					return
				host._observe_live_tick(host.race)
			var phase: float=clampf((elapsed_sim-float(host.replay_session.tick)*0.2)/0.2,0.0,1.0)
			draw=host.presentation.build(host.race.cars,host.selected_team,host.map_view,1.0/30.0,true,phase)
			host.world_view.set_race_cars(draw,host.focused_id,1.0/30.0)
		var poses: Dictionary=host.world_view.occupation
		var world=host.world_view
		var ids: Array=[]
		var max_motion:=0.0
		for id in poses:
			if not previous.has(id): continue
			var a: Dictionary=previous[id];var b: Dictionary=poses[id]
			if not a.has("arc_distance") or not b.has("arc_distance"):
				bad_anchors+=1;continue
			if not match_pose(sample(world,a,b,0.0),a) or not match_pose(sample(world,a,b,1.0),b):
				bad_anchors+=1;continue
			var travel: float=advance(a,b)
			if travel< -0.001:
				reversals+=1
				if reversals<=5: print("REVERSE ",frame," ",id," ",travel," ",a," ",b)
			max_motion=maxf(max_motion,maxf(absf(travel),absf(float(b.lane)-float(a.lane))))
			ids.append(id)
		for a in poses:
			for b in poses:
				if int(a)>=int(b):continue
				if Motion.overlaps(poses[a],poses[b]): endpoints+=1
				if previous.has(a) and previous.has(b) and Motion.swept(previous[a],poses[a],previous[b],poses[b]): chord_alerts+=1
		if ids.size()!=poses.size() and frame>0: discontinuities+=1
		# Every pair of continuous on-track cars, not only pairs with chord alerts.
		# 0.5 units per subinterval, max 256; larger jumps fail coverage.
		var steps: int=maxi(1,int(ceil(max_motion/0.5)))
		if steps>256:
			bad_anchors+=1
			if bad_anchors<=10: print("TRAFFIC_ARC_BIG_STEP ",frame," ",max_motion)
			previous=poses
			continue
		var prior: Dictionary={}
		for id in ids: prior[id]=previous[id]
		var flagged: Dictionary={}
		for n in range(1,steps+1):
			var next: Dictionary={}
			for id in ids: next[id]=sample(world,previous[id],poses[id],float(n)/float(steps))
			for i in range(ids.size()):
				for j in range(i+1,ids.size()):
					var a=ids[i];var b=ids[j]
					checks+=1
					if Motion.overlaps(next[a],next[b]) or Motion.swept(prior[a],next[a],prior[b],next[b]):
						var key: String="%d/%d" % [a,b]
						if not flagged.has(key):
							flagged[key]=true
							arc_alerts+=1
							if arc_alerts<=10: print("TRAFFIC_ARC_ALERT ",frame," ",key," substep ",n,"/",steps)
			prior=next
		for c in draw:
			var id: int=int(c.id)
			if not poses.has(id) or not previous.has(id): continue
			max_lag=maxf(max_lag,(float(c.progress)-float(poses[id].progress))*float(poses[id].route_length))
			if int(poses[id].get("hold_frames",0))>0: stationary+=1
			max_hold=maxi(max_hold,int(poses[id].get("hold_frames",0)))
		coverage+=ids.size()
		previous=poses
	var min_width: float=INF
	for width in host.world_view.road_widths: min_width=minf(min_width,float(width))
	var result: Dictionary={"min_road_half_width":min_width,"climate":climate,"world_scale":host.world_view.visual_world_scale,"track":track_code,"seed":seed_value,"frames":frames,"pipeline":"host" if host_pipeline else "fixed","ticks":host.replay_session.tick,"coverage":coverage,"pair_substeps":checks,"chord_alerts":chord_alerts,"arc_alerts":arc_alerts,"endpoint_overlaps":endpoints,"bad_anchors":bad_anchors,"discontinuities":discontinuities,"reverse_arc":reversals,"max_lag":max_lag,"stationary":stationary,"max_hold":max_hold,"hash":Codec.sporting_hash(host.race,host.replay_session.policy)}
	print("TRAFFIC_ARC_09177_REPORT ",JSON.stringify(result))
	if (track_code!="MON" or min_width>=host.world_view.MONACO_MIN_ASPHALT_HALF_WIDTH-0.000001) and arc_alerts==0 and endpoints==0 and bad_anchors==0 and reversals==0 and checks>0 and discontinuities==0 and coverage==24*(frames-1) and host.replay_session.tick>100 and max_hold<=2 and max_lag<32.0:
		print("TRAFFIC_ARC_09177_PASS")
		quit(0)
	else: quit(1)
