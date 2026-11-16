extends SceneTree
## Silverstone 0.20s integration: two first scheduled stops must occur exactly at projected laps.
const Race = preload("res://scripts/race_engine.gd")
const Planner = preload("res://scripts/core/race_pre_race_strategy_06495.gd")
func _initialize() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for row in season["tracks"]:
		if str(row.get("code","")) == "GBR": track = row
	var sim = Race.new(season["teams"],"Ferrari",6403,{},track,{})
	sim.configure_weather("Seco")
	var output: Dictionary = Planner.generate(sim)
	var expected: Dictionary = {}
	for plan in output["plans"]:
		var booking: int = int(plan["stints"][0]["to"])
		expected[int(plan["id"])] = {"lap":booking,"compound":str(plan["stints"][1]["compound"])}
		if not sim.schedule_pit(int(plan["id"]),str(plan["stints"][1]["compound"]),booking):
			printerr("PRE_RACE_REAL_PITS_FAIL schedule")
			quit(1)
			return
	sim.running = true
	var steps: int = 0
	while not sim.finished and steps < 14000 and int(sim.lap) < 21:
		sim.step(0.20)
		steps += 1
	if int(sim.lap) < 21:
		printerr("PRE_RACE_REAL_PITS_FAIL did not reach V21")
		quit(2)
		return
	var counted: Dictionary = {}
	for stop in sim.pit_history:
		var id: int = int(stop.get("car_id",-1))
		if not expected.has(id) or counted.has(id): continue
		counted[id] = true
		if int(stop.get("lap",-1)) != int(expected[id]["lap"]) or str(stop.get("new_tire","")) != str(expected[id]["compound"]):
			printerr("PRE_RACE_REAL_PITS_FAIL wrong pit at V%d" % int(stop.get("lap",-1)))
			quit(3)
			return
	if counted.size()!=2:
		printerr("PRE_RACE_REAL_PITS_FAIL only %d services recorded" % counted.size())
		quit(4)
		return
	print("PRE_RACE_REAL_PITS_PASS Silverstone V%d, 2 stops on booked laps V%d & V%d, correct compounds, %d native ticks" % [int(sim.lap),int(expected[expected.keys()[0]]["lap"]),int(expected[expected.keys()[1]]["lap"]),steps])
	quit(0)
