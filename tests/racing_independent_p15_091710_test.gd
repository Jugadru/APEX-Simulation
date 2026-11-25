extends SceneTree
const Fixture=preload("res://tests/motion_fixture_09173.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
func _initialize():call_deferred("run")
func run():
 if DisplayServer.get_name()=="headless":printerr("P15_CAPTURE_NATIVE_REQUIRED");quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa/racing_independent_091710"))
 root.size=Vector2i(1920,1080)
 var host=load("res://scenes/main.tscn").instantiate()
 root.add_child(host)
 for i in range(10):await process_frame
 host.set_process(false)
 for revision in [Replay.PRE_INDEPENDENT_SIMULATION_REVISION,Replay.PRE_AERO_WAKE_SIMULATION_REVISION,Replay.PRE_WAKE_SOURCE_SIMULATION_REVISION,Replay.SIMULATION_REVISION]:
  for i in range(host.season_tracks.size()):
   if host.season_tracks[i].code=="ITA":host.selected_track_index=i
  Fixture.configure(host,"stock",42)
  host._start_race()
  host.replay_session.recorded_simulation_revision=revision
  host.race.running=true;host.sim_speed=16.0
  # Fast-forward actual sporting ticks, then exercise the native chase pipeline.
  for i in range(600):
   if not host.replay_session.step_tick():quit(1);return
   host._observe_live_tick(host.race)
  host.presentation_race=host.race
  host.world_view.occupation.clear()
  host.world_view.previous_nominal.clear()
  if host.replay_session.tick<600 or host.render_mode!=1:quit(1);return
  var p15:Dictionary=host.race.get_sorted()[14]
  host._focus_driver(int(p15.id));host.tv_shot_override="chase"
  host.sim_speed=1.0
  for i in range(30):host._process(.05)
  host.race.running=false;host._process(.016667)
  for i in range(5):await process_frame
  await RenderingServer.frame_post_draw
  var path="res://qa/racing_independent_091710/monza_"+revision.substr(0,3)+"_p15.png"
  var img:Image=root.get_texture().get_image()
  if img.is_empty() or img.save_png(path)!=OK:quit(1);return
  print("P15_CAPTURE ",path," tick=",host.replay_session.tick," focused=",host.focused_id," expected=",p15.id," camera=",host.world_view.camera_mode_3d)
  if host.focused_id!=int(p15.id):quit(1);return
 print("P15_CAPTURE_PASS");quit()
