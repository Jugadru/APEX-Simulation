extends SceneTree
const Motion=preload("res://scripts/apex_racecraft_0654.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	host.set_process(false)
	host.seed_picker.value=6558
	host._start_race()
	host.race.running=true
	var previous:Dictionary={}
	for tick in range(240):
		host.sim_speed=1.0 if tick<120 else 16.0
		host._process(1.0/30)
		var poses:Dictionary=host.world_view.occupation
		for a in poses:
			for b in poses:
				if a>=b:continue
				assert(not Motion.overlaps(poses[a],poses[b]),"presentation overlap")
				if previous.has(a) and previous.has(b):
					assert(not Motion.swept(previous[a],poses[a],previous[b],poses[b]),"presentation swept collision")
		previous=poses
	print("VIEW_MOTION_PASS 240 frames x1/x16, interpolated poses, no overlap or swept crossing")
	quit()
