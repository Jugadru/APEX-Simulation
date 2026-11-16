extends SceneTree
func _initialize(): call_deferred("run")
func run():
    root.mode=Window.MODE_WINDOWED
    root.size=Vector2i(1440,810)
    var app=load("res://scenes/main.tscn").instantiate()
    root.add_child(app)
    for i in range(10): await process_frame
    app.set_process(false)
    for i in range(app.season_tracks.size()):
        if str(app.season_tracks[i].get("code", ""))=="ITA": app.selected_track_index=i;break
    app._start_race()
    app.race.running=false
    app._change_speed(0)
    var pit=app.world_view.pit_complex
    var mid:float=pit._slot_z(5)
    var target:Vector3=pit.to_global(Vector3(7.5,0,mid))
    var camera=app.world_view.camera_3d
    camera.global_position=pit.to_global(Vector3(-2,31,mid+34))
    camera.look_at(target)
    app.world_view.camera_mode_3d="free"
    for i in range(25): await process_frame
    await RenderingServer.frame_post_draw
    var img=root.get_texture().get_image()
    var dest="res://qa/pit_lane_066724/engineering_station_1440x810.png"
    assert(img.save_png(dest)==OK)
    print("PITLANE_CAPTURE_PASS ",dest)
    app._change_speed(5)
    app.race.running=true
    for i in range(100): app._process(1.0/60.0)
    app.race.running=false
    assert(app.render_mode==0)
    for i in range(10): await process_frame
    await RenderingServer.frame_post_draw
    var speed_capture:Image=root.get_texture().get_image()
    var speed_path:String="res://qa/pit_lane_066724/strategic_32x_actual_speed_1440x810.png"
    assert(speed_capture.save_png(speed_path)==OK)
    print("SPEED_32X_CAPTURE_PASS ",speed_path," actual_x=",app.effective_speed_x)
    quit(0)
