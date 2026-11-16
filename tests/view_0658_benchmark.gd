extends SceneTree
const P=preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	assert(DisplayServer.get_name()!="headless")
	var width:=int(OS.get_environment("APEX_BENCH_WIDTH"))
	root.mode=Window.MODE_FULLSCREEN if width==1920 else Window.MODE_WINDOWED
	root.size=Vector2i(width, width*9/16)
	var host=load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	for i in range(8):await process_frame
	assert(root.size==Vector2i(width,width*9/16),"Measured viewport must match requested resolution")
	host.set_process(false)
	for i in range(host.season_tracks.size()):
		if host.season_tracks[i].code=="GBR":host.selected_track_index=i
	host.seed_picker.value=6558
	host._start_race()
	host.render_mode=1
	host.race.running=true
	host.sim_speed=1.0
	for i in range(30):
		host._process(1.0/60)
		await process_frame
	P.set_enabled(true)
	P.reset({"seed":6558,"width":width,"frames":180,"delta":1.0/60,"scenario":"GBR 24 cars native 3D x1"})
	for i in range(180):
		host._process(1.0/60)
		await process_frame
	P.set_enabled(false)
	var running:=P.snapshot()
	var sporting:=JSON.stringify({"cars":host.race.cars,"events":host.race.events,"rng":host.race.rng.state}).sha256_text()
	host.race.running=false
	host._process(1.0/60)
	P.reset({"scenario":"paused same scene","frames":90})
	P.set_enabled(true)
	for i in range(90):
		host._process(1.0/60)
		await process_frame
	P.set_enabled(false)
	var result:Dictionary={"running":running,"paused":P.snapshot(),"sporting_sha256":sporting}
	var output:=OS.get_environment("APEX_BENCH_OUTPUT")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	if OS.get_environment("APEX_BENCH_SCREEN")=="1":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+".png")
	print("VIEW_BENCH_PASS ",sporting)
	quit()
