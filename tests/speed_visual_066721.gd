extends SceneTree
const Snapshot = preload("res://scripts/race_view_snapshot_0658.gd")
const Controller = preload("res://scripts/apex_race_view_controller.gd")
const Main = preload("res://scripts/main.gd")
class FakeRoute:
	extends RefCounted
	func geometry_revision() -> int: return 1
	func point_on_track(progress: float) -> Vector2: return Vector2(progress * 1000, 0)
	func direction_on_track(_progress: float) -> Vector2: return Vector2.RIGHT
class FakeHost:
	extends RefCounted
	var sim_speed := 1.0
	var visual_setting := 2 # 066722: manual camera tests legacy speed isolation; Auto now switches at 10x
	var render_mode := 1
	var speed_picker = null

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(is_equal_approx(Main.new().sim_speed, 1.0))
	var host := FakeHost.new()
	for i in range(6):
		Controller._change_speed(host, i)
		assert(is_equal_approx(host.sim_speed, [1,2,5,10,16,32][i]))
		assert(host.render_mode == 1, "Speed must not switch camera")
	var route := FakeRoute.new()
	var snap := Snapshot.new()
	var car := {"id":1,"name":"TEST","team":"Ferrari","progress":0.0,"race_lane":0.0,"pit_stage":"none","pit_left":0.0,"finished":false}
	var out := snap.build([car], "Ferrari", route, 1.0/60.0, true, 0.0)
	assert(is_zero_approx(out[0].progress))
	car.progress = 0.02
	for item in [[0.0,0.0],[0.25,0.005],[0.5,0.01],[0.75,0.015],[0.99,0.0198]]:
		out = snap.build([car], "Ferrari", route, 1.0/60.0, true, item[0])
		assert(absf(float(out[0].progress)-item[1])<0.00001,"Interpolated sporting ticks")
	var held: float = float(out[0].progress)
	out = snap.build([car], "Ferrari", route, 1.0/60.0, false, 0.99)
	assert(is_equal_approx(float(out[0].progress),held),"Pause holds pose")
	car.progress=0.04
	out=snap.build([car], "Ferrari", route, 1.0/60.0, true, 0.0)
	assert(absf(float(out[0].progress)-0.02)<0.00001,"No jump on completed tick")
	car.progress=0.005 # rewind / seek
	out=snap.build([car], "Ferrari", route, 1.0/60.0, true, 0.3)
	assert(absf(float(out[0].progress)-0.005)<0.00001,"No interpolation across seek")
	snap.reset()
	assert(snap.previous_targets.is_empty())
	var profiles: Dictionary = {}
	for speed in [1.0, 5.0]:
		var candidate := Snapshot.new()
		var legacy := Snapshot.new()
		var c := car.duplicate()
		c.progress=0.0
		candidate.build([c],"Ferrari",route,1.0/60.0,true,0.0)
		legacy.build([c],"Ferrari",route,1.0/60.0,true)
		var elapsed:=0.0
		var ticks:=0
		var static_new:=0
		var static_old:=0
		var prev_new:=0.0
		var prev_old:=0.0
		var speed_samples_new: Array = []
		var speed_samples_old: Array = []
		for frame in range(120):
			elapsed+=1.0/60.0*speed
			while elapsed>=0.2:
				elapsed-=0.2
				ticks+=1
				c.progress+=0.002
			var out_new: Array = candidate.build([c],"Ferrari",route,1.0/60.0,true,elapsed/0.2)
			var out_old: Array = legacy.build([c],"Ferrari",route,1.0/60.0,true)
			if absf(float(out_new[0].progress)-prev_new)<0.000001: static_new+=1
			if absf(float(out_old[0].progress)-prev_old)<0.000001: static_old+=1
			if frame > 20:
				speed_samples_new.append(float(out_new[0].progress)-prev_new)
				speed_samples_old.append(float(out_old[0].progress)-prev_old)
			prev_new=float(out_new[0].progress)
			prev_old=float(out_old[0].progress)
		print("SPEED_PROFILE speed=",speed," stationary_new=",static_new," stationary_old=",static_old)
		var mean_new:=0.0
		var mean_old:=0.0
		for v in speed_samples_new: mean_new+=v / speed_samples_new.size()
		for v in speed_samples_old: mean_old+=v / speed_samples_old.size()
		var var_new:=0.0
		var var_old:=0.0
		for v in speed_samples_new: var_new+=pow(v-mean_new,2) / speed_samples_new.size()
		for v in speed_samples_old: var_old+=pow(v-mean_old,2) / speed_samples_old.size()
		var cv_new:=sqrt(var_new)/maxf(mean_new,0.0000001)
		var cv_old:=sqrt(var_old)/maxf(mean_old,0.0000001)
		assert(cv_new<cv_old*0.85,"Visual speed variation must decrease")
		profiles["%dx"%int(speed)]={"ticks":ticks,"static_frames_prior":static_old,"static_frames_new":static_new,"cv_old":cv_old,"cv_new":cv_new,"last_progress":float(c.progress)}
	print("SPEED_VISUAL_066721_PASS ",JSON.stringify(profiles))
	quit(0)
