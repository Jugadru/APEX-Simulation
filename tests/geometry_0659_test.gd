extends SceneTree
const Map=preload("res://scripts/track_map.gd")
const World=preload("res://scripts/track_3d.gd")
func old_point(map, progress:float)->Vector2:
	if map.route.is_empty():return Vector2.ZERO
	var distance:float=fposmod(progress,1.0)*map.route_length
	var lo:=0
	var hi:int=map.cumulative.size()-1
	while hi-lo>1:
		var mid:int=(hi+lo)/2
		if map.cumulative[mid]<distance:lo=mid
		else:hi=mid
	return map.route[lo].lerp(map.route[hi],(distance-map.cumulative[lo])/maxf(.00001,map.cumulative[hi]-map.cumulative[lo]))
func old_projection(points:Array[Vector3],origin:Vector3)->Dictionary:
	var result:Dictionary={"nearest":0,"along":0.0,"distance":INF}
	for i in range(points.size()):
		var a:Vector3=points[i]
		var segment:Vector3=points[(i+1)%points.size()]-a
		var t:=clampf((origin-a).dot(segment)/maxf(.000001,segment.length_squared()),0,1)
		var distance:=origin.distance_squared_to(a+segment*t)
		if distance<float(result.distance):result={"nearest":i,"along":t*segment.length(),"distance":distance}
	return result
func _initialize()->void:call_deferred("run")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var map:=Map.new()
	var world:=World.new()
	var rng:=RandomNumberGenerator.new()
	rng.seed=6559
	var builds:=[]
	var queries:=0
	var segments:=0
	var visited:=0
	for track in data.tracks:
		map.set_track_data(track)
		world.route=map.route
		world._build_road_sections()
		var build_start:=Time.get_ticks_usec()
		world.projection_index.build(world.road_centers)
		builds.append({"track":track.code,"microseconds":Time.get_ticks_usec()-build_start,"segments":world.road_centers.size(),"serialized_index_bytes":var_to_bytes([world.projection_index.points,world.projection_index.vectors,world.projection_index.lengths,world.projection_index.squared,world.projection_index.lows,world.projection_index.highs]).size()})
		assert(absf(world.projection_index.total_length-(world.road_distances[-1]+world.road_centers[-1].distance_to(world.road_centers[0])))<0.00000001)
		var hint:=-1
		for i in range(300):
			var p:float=float(i)/299 if i<150 else rng.randf_range(-2,5)
			var sample:Dictionary=map.sample_on_track(p)
			assert(sample.point.distance_to(old_point(map,p))<0.0001,"position equivalence")
			var tangent:Vector2=old_point(map,p+.0015)-old_point(map,p-.0015)
			tangent=Vector2.RIGHT if tangent.length_squared()<.000001 else tangent.normalized()
			assert(sample.direction.distance_to(tangent)<0.00001,"direction equivalence")
			var origin:Vector3=world._to_world(sample.point)+Vector3(rng.randf_range(-12,12),0,rng.randf_range(-12,12))
			var expected:=old_projection(world.road_centers,origin)
			var got:Dictionary=world.projection_index.project(origin,hint)
			assert(got.nearest==expected.nearest,"global nearest including crossing/ties")
			assert(absf(float(got.along)-float(expected.along))<0.00001)
			hint=int(got.nearest)
			visited+=world.projection_index.last_candidates
			segments+=world.road_centers.size()
			queries+=1
	var view=load("res://scripts/race_view_snapshot_0658.gd").new()
	var source=[{"id":0,"team":"Ferrari","progress":.3}]
	view.build(source,"Ferrari",map,.016,false)
	map.set_track_data(data.tracks[0])
	var rebuilt:Array=view.build(source,"Ferrari",map,.016,false)
	assert(rebuilt[0].route_point==map.point_on_track(.3),"paused route revision invalidates presentation samples")
	assert(map.geometry_sampler.point_cache.size()<=256 and map.geometry_sampler.direction_cache.size()<=256)
	map.set_track_data({"points":[]})
	assert(map.point_on_track(.1)==Vector2.ZERO,"empty rebuild invalidates cache")
	world.projection_index.build([Vector3.ZERO,Vector3.ZERO,Vector3(1,0,0),Vector3.ZERO])
	for origin in [Vector3.ZERO,Vector3(100,0,1),Vector3(.5,2,0)]:
		var a:=old_projection(world.projection_index.points,origin)
		var b:Dictionary=world.projection_index.project(origin,3)
		assert(a.nearest==b.nearest and is_equal_approx(float(a.along),float(b.along)),"degenerates and ties")
	world.projection_index.build([])
	assert(world.projection_index.project(Vector3.ZERO).is_empty())
	assert(visited<segments/2,"broadphase actually culls")
	FileAccess.open("res://qa/geometry_0659/equivalence.json",FileAccess.WRITE).store_string(JSON.stringify({"builds":builds,"tracks":data.tracks.size(),"queries":queries,"candidates":visited,"legacy_candidates":segments}))
	map.free()
	world.free()
	print("GEOMETRY_PASS ",queries," queries, candidates ",visited," / ",segments)
	quit()
