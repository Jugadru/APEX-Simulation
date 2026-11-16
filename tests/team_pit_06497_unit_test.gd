extends SceneTree
const Coord = preload("res://scripts/core/race_team_pit_coordination_06497.gd")
var fails: Array[String] = []

func ck(ok: bool, note: String) -> void:
    if not ok:
        fails.append(note)
        printerr("TEAM_06497_FAIL " + note)

func make_car(id: int, position: int) -> Dictionary:
    return {"id":id, "team":"Ferrari", "name":"Piloto " + str(id),
        "position":position, "laps_done":17, "stops":0,
        "stint_laps":15, "tire":"Médio", "pit_control_mode":"IA",
        "wear":44.0, "pit_request":false, "pit_left":0.0,
        "pit_scheduled_lap":0, "pitwall49_held":false,
        "lap_strategy_adjusted_stint_06496":-999,
        "team_pit_adjusted_stint_06497":-999, "finished":false}

func make_plan(pit_now: bool, stop: int) -> Dictionary:
    return {"pit_now":pit_now, "planned_pit_lap":stop,
        "compound":"Duro","life_laps":6.0, "critical":false,
        "forecast_3":0.0,"forecast_6":0.0}

func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var lead: Dictionary = make_car(1, 2)
    var second: Dictionary = make_car(2, 4)
    var dry: Dictionary = {"wetness_factor":0.0, "rain_intensity":0.0}
    var now: Dictionary = make_plan(false,19)
    var next: Dictionary = make_plan(true,19)
    var allowed: Array = ["Médio","Duro"]
    var before: String = JSON.stringify([lead,second,dry,now,next])
    var early: Dictionary = Coord.assess(second, lead, now, now, dry, 52, 18, "Ferrari", allowed)
    ck(bool(early["executable"]) and early["decision"] == "ANTECIPAR", "early +1 planning window")
    ck(early["target_lap"] == 19 and early["overlap"], "recognized future overlap")
    ck(not bool(Coord.assess(lead,second,now,now,dry,52,18,"Ferrari",allowed)["executable"]), "lead keeps priority")
    ck(JSON.stringify([lead,second,dry,now,next]) == before, "pure deterministic, no mutation")
    var hold: Dictionary = Coord.assess(second,lead,next,next,dry,52,19,"Ferrari",allowed)
    ck(bool(hold["executable"]) and hold["decision"] == "ADIAR", "last-moment safe deferral")
    var critical: Dictionary = next.duplicate(true)
    critical["critical"] = true
    ck(not Coord.assess(second,lead,critical,next,dry,52,19,"Ferrari",allowed)["executable"],"critical tyre blocked")
    var rain: Dictionary = {"wetness_factor":0.8,"rain_intensity":0.9}
    ck(not Coord.assess(second,lead,next,next,rain,52,19,"Ferrari",allowed)["executable"],"heavy rain blocked")
    var worn: Dictionary = second.duplicate(true)
    worn["wear"] = 82.0
    ck(not Coord.assess(worn,lead,next,next,dry,52,19,"Ferrari",allowed)["executable"],"high wear blocked")
    var manual: Dictionary = second.duplicate(true)
    manual["pit_control_mode"] = "Manual"
    ck(not Coord.assess(manual,lead,next,next,dry,52,19,"Ferrari",allowed)["executable"],"manual blocked")
    var booked: Dictionary = second.duplicate(true)
    booked["pit_scheduled_lap"] = 21
    ck(not Coord.assess(booked,lead,next,next,dry,52,19,"Ferrari",allowed)["executable"],"V21 preserved")
    var urgent: Dictionary = second.duplicate(true)
    urgent["pit_request"]=true
    urgent["pit_order_source"]="ia_urgencia"
    ck(not Coord.assess(urgent,lead,next,next,dry,52,19,"Ferrari",allowed)["executable"],"urgent pit preserved")
    var already: Dictionary = second.duplicate(true)
    already["team_pit_adjusted_stint_06497"] = 0
    ck(not Coord.assess(already,lead,next,next,dry,52,19,"Ferrari",allowed)["executable"],"once per stint")
    var again: Dictionary = second.duplicate(true)
    again["lap_strategy_adjusted_stint_06496"] = 0
    ck(not Coord.assess(again,lead,next,next,dry,52,19,"Ferrari",allowed)["executable"],"no stacked 06496 tactic")
    var next_stint: Dictionary = already.duplicate(true)
    next_stint["stops"] = 1
    ck(bool(Coord.assess(next_stint, lead, now, now, dry, 52, 18,"Ferrari",allowed)["executable"]), "new stint re-arms coordination")
    var other_team: Dictionary = lead.duplicate(true)
    other_team["team"]="McLaren"
    ck(not Coord.assess(second,other_team,next,next,dry,52,19,"Ferrari",allowed)["executable"],"other team not shared garage")
    var late: Dictionary = second.duplicate(true)
    late["laps_done"] = 50
    ck(not Coord.assess(late,lead,next,next,dry,52,51,"Ferrari",allowed)["executable"],"final lap cannot shift")
    if fails.is_empty():
        print("TEAM_06497_PASS 16 safety/strategy assertions, early, late, priority, manual, V21")
    quit(0 if fails.is_empty() else 1)
