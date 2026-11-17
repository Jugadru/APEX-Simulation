extends SceneTree
## Validate HUD selector and Auto camera mapping at all six requested speeds.
## This is a headless UI policy test, NOT a graphical GPU test.
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize()->void: call_deferred("_run")
func _run()->void:
 var host = load("res://scenes/main.tscn").instantiate()
 root.add_child(host)
 await process_frame
 host.set_process(false)
 host._start_race()
 var hud = host.race_hud_0620
 var reference: String = Codec.sporting_hash(host.race,host.replay_session.policy)
 var results: Array=[]
 for mode in range(3):
  hud._change_hud_mode(mode)
  host._change_visual_setting(0)
  for index in range(6):
   host._change_speed(index)
   hud.refresh_hud()
   var expected: int = 0 if index>=3 else 1
   assert(host.render_mode == expected,"Auto 2D/3D policy violated")
   assert(hud.speed_label.selected == index)
   assert(hud.hud_mode == mode)
   results.append({"hud":mode,"speed_x":int(host.sim_speed),"view":"2D" if host.render_mode==0 else "3D"})
  host._change_visual_setting(1)
  host._change_speed(0)
  assert(host.render_mode==0,"Manual 2D must override Auto")
  host._change_visual_setting(2)
  host._change_speed(5)
  assert(host.render_mode==1,"Manual 3D must override Auto at 32x")
  assert(Codec.sporting_hash(host.race,host.replay_session.policy)==reference)
 host._change_visual_setting(0)
 host._change_speed(0)
 hud._change_hud_mode(1)
 print("HUD_06681_CAMERA_POLICY_PASS ",JSON.stringify({"combinations":results.size(),"policy":"Auto 3D at 1x/2x/5x, Auto 2D at 10x/16x/32x, manual override preserved","sporting_hash_unchanged":true}))
 quit(0)
