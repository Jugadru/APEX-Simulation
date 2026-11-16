extends SceneTree
## Native 0.20-s race simulation: early laps must never turn a future order into a live pit.
const Race = preload("res://scripts/race_engine.gd")
const Planner = preload("res://scripts/core/race_pre_race_strategy_06495.gd")
func _initialize() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for item in season["tracks"]:
		if str(item.get("code",""))=="GBR":
			track=item
	var sim = Race.new(season["teams"],"Ferrari",6403,{},track,{})
	sim.configure_weather("Seco")
	var plan: Dictionary = Planner.generate(sim)
	if not bool(plan.get("valid",false)):
		printerr("PRE_RACE_FIRST_LAPS_FAIL no plan")
		quit(1)
		return
	var bookings: Array = []
	for item in plan["plans"]:
		var first: Dictionary = item["stints"][0]
		var second: Dictionary = item["stints"][1]
		var id: int = int(item["id"])
		var lap: int = int(first["to"])
		if not sim.schedule_pit(id,str(second["compound"]),lap):
			printerr("PRE_RACE_FIRST_LAPS_FAIL could not schedule")
			quit(2)
			return
		bookings.append({"id":id,"lap":lap})
	sim.running = true
	var steps: int = 0
	while steps < 12000 and int(sim.lap) < 5:
		sim.step(0.20)
		steps += 1
	if int(sim.lap) < 5:
		printerr("PRE_RACE_FIRST_LAPS_FAIL insufficient laps after %d steps" % steps)
		quit(3)
		return
	for b in bookings:
		var found: bool = false
		for c in sim.player_cars():
			if int(c["id"]) == int(b["id"]):
				found = true
				if int(c.get("pit_scheduled_lap",0)) != int(b["lap"]) or int(c.get("stops",0)) != 0 or bool(c.get("pit_request",false)):
					printerr("PRE_RACE_FIRST_LAPS_FAIL premature pit")
					quit(4)
					return
		if not found:
			printerr("PRE_RACE_FIRST_LAPS_FAIL missing car")
			quit(5)
			return
	print("PRE_RACE_FIRST_LAPS_PASS Silverstone step=0.20, V%d, two booked plans retained, 0 premature pits, steps=%d" % [int(sim.lap),steps])
	quit(0)
