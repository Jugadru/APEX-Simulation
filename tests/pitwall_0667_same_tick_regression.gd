extends SceneTree
# Regression for two manual pit bookings submitted before the same replay tick.
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("run")
func ck(condition: bool, reason: String) -> void:
    if not condition:
        failures.append(reason)
        printerr("PITWALL_SAME_TICK_FAIL ", reason)
func run() -> void:
    var game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    var team: Array = game.race.player_cars()
    ck(team.size()==2,"two teammates")
    if team.size()!=2: quit(2);return
    var car: Dictionary = team[0]
    var mate: Dictionary = team[1]
    var hud = game.race_hud_0620
    hud._open_window("pitwall3")
    await process_frame
    var id1: int = int(car["id"])
    var id2: int = int(mate["id"])
    var next_lap: int = game.race._next_pit_entry_lap(car)
    ck(game.replay_session.commands.is_empty(),"queue starts empty")
    hud._pitwall3_schedule(id1,0)
    ck(game.replay_session.commands.size()==1,"first command queued")
    ck(int(car.get("pit_scheduled_lap",0))==0,"first command still pending")
    var alt_lap: int = next_lap + 1
    var tyre: String = str(game.race.available_pit_compounds()[0])
    ck(not game.replay_session.enqueue("schedule_pit",[id1,tyre,alt_lap]),"same car cannot overwrite its own pending booking")
    hud._pitwall3_schedule(id2,0)
    ck(game.replay_session.commands.size()==1,"second same-lap booking refused while first is pending")
    ck(int(mate.get("pit_scheduled_lap",0))==0,"teammate remains unbooked")
    ck(game.replay_session.step_tick(),"first command applied")
    ck(int(car.get("pit_scheduled_lap",0))==next_lap,"first driver's schedule preserved")
    ck(int(mate.get("pit_scheduled_lap",0))==0,"teammate same-lap schedule rejected")
    hud._pitwall3_schedule(id2,0)
    ck(game.replay_session.commands.size()==1,"second same-lap booking remains blocked after tick")
    ck(game.race.schedule_pit(id2,tyre,alt_lap),"teammate can schedule a DIFFERENT lap")
    ck(game.replay_session.step_tick(),"different-lap teammate booking applied")
    ck(int(mate.get("pit_scheduled_lap",0))==alt_lap,"different-lap booking survives queue guard")
    var report: Dictionary = {"test":"pitwall_same_tick_pending_schedule","pass":failures.is_empty(),"first_lap":int(car.get("pit_scheduled_lap",0)),"mate_lap":int(mate.get("pit_scheduled_lap",0)),"queued_commands":game.replay_session.commands.size(),"errors":failures}
    print("PITWALL_SAME_TICK_RESULT ",JSON.stringify(report))
    quit(0 if failures.is_empty() else 1)
