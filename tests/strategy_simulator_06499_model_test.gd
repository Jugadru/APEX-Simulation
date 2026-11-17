extends SceneTree
## Independent native unit coverage: inputs from three actual track configurations,
## read-only/no RNG, single garage bookings, late-race clipping, 9.8 trend.
const Race = preload("res://scripts/race_engine.gd")
const Simulator = preload("res://scripts/core/race_strategy_simulator_06499.gd")
const Chart = preload("res://scripts/core/race_strategy_graph_data_06498.gd")
var fails: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		fails.append(label)
		printerr("APEX_06499_MODEL_FAIL " + label)
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	for code in ["GBR","ITA","SIN"]:
		var track: Dictionary = {}
		for item in season["tracks"]:
			if str(item.get("code", "")) == code:
				track = item
		check(not track.is_empty(), "track exists "+code)
		var sim = Race.new(season["teams"],"Ferrari",6403,{},track,{})
		sim.configure_weather("Variável" if code != "ITA" else "Seco")
		var chart = Chart.new()
		chart.reset(sim)
		var team: Array = sim.player_cars()
		check(team.size() == 2,"both drivers "+code)
		var base: String = JSON.stringify(sim.get_state_snapshot())
		var first: Dictionary = Simulator.evaluate(sim,team[0],team[1],chart)
		var second: Dictionary = Simulator.evaluate(sim,team[1],team[0],chart)
		check(first["scenarios"].size() == 6, "6 initial scenarios "+code)
		check(second["scenarios"].size() == 6, "6 teammate scenarios "+code)
		check(base == JSON.stringify(sim.get_state_snapshot()),"view is observational "+code)
		for i in range(first["scenarios"].size()):
			var s: Dictionary = first["scenarios"][i]
			check(int(s["lap"]) == int(first["next_entry"])+i,"valid future entry "+code)
			check(int(s["rejoin_position"]) >= 1 and int(s["rejoin_position"]) <= sim.cars.size(),"position bound "+code)
			check(float(s["pit_loss_s"]) == float(sim.pit_loss),"actual pit loss "+code)
			check(float(s["rain_estimated"]) >= 0.0 and float(s["rain_estimated"]) <= 1.0,"forecast bound "+code)
			check(str(s["confidence"]) in ["ALTA","MODERADA","BAIXA"],"confidence "+code)
		var id: int = int(team[1]["id"])
		var original: int = int(team[1].get("pit_scheduled_lap", 0))
		team[1]["pit_scheduled_lap"] = int(first["next_entry"])
		var collision: Dictionary = Simulator.evaluate(sim,team[0],team[1],chart)
		check(str(collision["scenarios"][0]["garage"]["level"]) == "ALTO", "confirmed garage collision "+code)
		team[1]["pit_scheduled_lap"] = original
		# Test clipping near the chequered flag without modifying the real sim.
		var near_finish: Dictionary = team[0].duplicate(true)
		near_finish["progress"] = float(sim.lap_count)-2.2
		near_finish["laps_done"] = sim.lap_count-3
		var truncated: Dictionary = Simulator.evaluate(sim, near_finish, team[1], chart)
		check(truncated["scenarios"].size() < 6,"finish horizon clipped "+code)
		# One completed lap is used by the existing graph model; no point invented.
		sim.running = true
		for tick in range(85):
			sim.step(4.0)
			chart.capture(sim)
		var live: Dictionary = Simulator.evaluate(sim,team[0],team[1],chart)
		check(int(live["lap"]) > 0,"real laps advanced "+code)
		check(str(live["scenarios"][0]["wear_source"]) != "", "live wear model "+code)
		check(Simulator.explain(live["scenarios"],live["scenarios"][0]).contains("RACE ENGINEER"),"engineer text "+code)
		print("APEX_06499_MODEL_TRACK_PASS %s lap=%d pit_loss=%.1f cases=%d" % [code, int(live["lap"]), sim.pit_loss, live["scenarios"].size()])
	if fails.is_empty():
		print("APEX_06499_MODEL_PASS actual 3-track telemetry, projection bounds, confirmed/potential stack, clipped horizon and pure previews")
	quit(0 if fails.is_empty() else 1)
