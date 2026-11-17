extends SceneTree
## Separate Godot processes: write mode, exit, relaunch and read it via real HUD.
const Modes = preload("res://scripts/apex_hud_rebroadcast_0668.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var phase: String = OS.get_environment("APEX_PREF_PHASE")
 if phase == "write":
  var result: Error = Modes.save_mode(2)
  assert(result == OK and Modes.load_mode() == 2)
  print("HUD_06681_RESTART_WRITE_PASS mode=FULL")
  quit(0)
  return
 if phase != "read":
  printerr("FAIL: APEX_PREF_PHASE must be write or read")
  quit(2)
  return
 var host=load("res://scenes/main.tscn").instantiate()
 root.add_child(host)
 await process_frame
 var hud=host.race_hud_0620
 var ok: bool = hud != null and int(hud.hud_mode)==2 and int(hud.hud_mode_picker.selected)==2
 assert(Modes.save_mode(1) == OK)
 if not ok:
  printerr("HUD_06681_RESTART_FAIL: new process lost persisted mode")
  quit(1)
  return
 print("HUD_06681_RESTART_READ_PASS mode=FULL restored_default=COMPACT")
 quit(0)
