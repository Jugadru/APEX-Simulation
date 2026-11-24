extends SceneTree
const Map=preload("res://scripts/track_map.gd")
const World=preload("res://scripts/track_3d.gd")
const Model=preload("res://scripts/car_model_3d.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures.append(label)
func winding(world, i:int, band:Array)->float:
	var j:int=(i+1)%world.road_widths.size()
	var a:Vector3=world._edge_at(i,band[0],0,0);var b:Vector3=world._edge_at(i,band[1],0,0)
	var c:Vector3=world._edge_at(j,band[0],0,0);var d:Vector3=world._edge_at(j,band[1],0,0)
	return minf(Vector2(c.x-a.x,c.z-a.z).cross(Vector2(b.x-a.x,b.z-a.z)),Vector2(c.x-b.x,c.z-b.z).cross(Vector2(d.x-b.x,d.z-b.z)))
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var map=Map.new();var world=World.new()
	root.add_child(world)
	for track in data.tracks:
		if track.code!="MON": continue
		map.set_track_data(track)
		var original:PackedVector2Array=map.route.duplicate()
		world.set_track_data(map.route,track.name)
		check(map.route==original and world.route==original,"2D route unchanged")
		check(is_equal_approx(world.visual_world_scale,0.90),"Monaco scale selected")
		check(world.road_outer_widths.size()==world.road_widths.size(),"outer widths aligned")
		check(world.road_widths.min()>=Model.OCCUPATION_HALF_WIDTH+0.20-0.000001,"minimum asphalt width covers half envelope plus margin")
		var bands:Array=[[-1.38,1.38],[-1.18,1.18],[-1.0,1.0],[-1.10,-.91],[.91,1.10],[-.908,-.883],[.883,.908],[-1.50,1.50]]
		var min_area:=INF
		for band in bands:
			for i in range(world.road_widths.size()):
				var area:float=winding(world,i,band)
				check(is_finite(area) and area>0.0000001,"fold/zero triangle %s section %d" % [str(band),i])
				min_area=minf(min_area,area)
		for i in range(200):
			var car:Dictionary={"id":i,"route_point":map.point_on_track(float(i)/200.0),"progress":float(i)/200.0}
			var pose:Dictionary=world._sample_occupied_pose(car,2.95,0)
			check(float(pose.road_half_width)-absf(float(pose.lane))>=Model.OCCUPATION_HALF_WIDTH+0.20-0.00001,"sampler width clearance")
			check(int(pose.get("arc_sweep_max_steps",32))==64,"longer arc budget only on Monaco")
		print("TRAFFIC_ROAD_WIDTH_09177_METRICS ",JSON.stringify({"sections":world.road_widths.size(),"bands":bands.size(),"minimum_half_width":world.road_widths.min(),"minimum_signed_area":min_area}))
	for track in data.tracks:
		if track.code!="BEL": continue
		map.set_track_data(track);world.set_track_data(map.route,track.name)
		check(is_equal_approx(world.visual_world_scale,world.WORLD_SCALE) and world.road_outer_widths.is_empty(),"Spa resets Monaco-only geometry")
		var pose:Dictionary=world._sample_occupied_pose({"id":0,"route_point":map.point_on_track(0.1),"progress":0.1},0,0)
		check(int(pose.get("arc_sweep_max_steps",32))==32,"legacy cap preserved")
	map.free();world.queue_free();await process_frame
	print("TRAFFIC_ROAD_WIDTH_09177_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
	if failures.is_empty():print("TRAFFIC_ROAD_WIDTH_09177_PASS")
	quit(0 if failures.is_empty() else 1)
