extends SceneTree
## Imported replay seeks are isolated from a live host and HUD presentation.
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
 var host=load("res://scenes/main.tscn").instantiate()
 root.add_child(host)
 await process_frame
 host.set_process(false)
 host.seed_picker.value=660
 host.replay_recording_enabled = true
 host._start_race()
 var live = host.replay_session
 var hud = host.race_hud_0620
 for tick in range(400):
  assert(live.step_tick(),live.error)
  if tick % 40 == 0:
   hud._change_hud_mode(int(tick / 40) % 3)
   hud.refresh_hud()
 var live_checkpoint: Dictionary = Codec.capture(host.race)
 var live_hash: String = Codec.sporting_hash(host.race,live.policy)
 var live_tick: int = live.tick
 var archive: Dictionary=live.export_data()
 var playback=Replay.new()
 assert(playback.load_data(archive),playback.error)
 assert(playback.seek(150),playback.error)
 assert(playback.tick==150)
 hud._change_hud_mode(1)
 hud.refresh_hud()
 assert(playback.seek(320),playback.error)
 assert(playback.seek(0),playback.error)
 assert(live.tick==live_tick)
 assert(Codec.capture(host.race)==live_checkpoint, "Imported replay changed live sporting state")
 assert(Codec.sporting_hash(host.race,live.policy)==live_hash, "Replay/GUI changed live sporting hash")
 print("HUD_06681_REPLAY_ISOLATION_PASS live_ticks=",live_tick," seek=150/320/0 live_hash=",live_hash)
 quit(0)
