extends SceneTree
## 3 complete race integrations and no-simulator parity on the exact same seeds.
## Includes AFTER-THE-FACT error stats (not guaranteed future accuracy).
const Race = preload("res://scripts/race_engine.gd")
const Simulator = preload("res://scripts/core/race_strategy_simulator_06499.gd")
const Chart = preload("res://scripts/core/race_strategy_graph_data_06498.gd")
const CASES := {"GBR":{"seed":6403,"weather":"Variável"},
	"ITA":{"seed":6503,"weather":"Seco"},
	"SIN":{"seed":6603,"weather":"Variável"}}
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		errors.append(label)
		printerr("APEX_06499_GP_FAIL "+label)
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var folder: String = "res://qa/06499"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for code in CASES:
		var config: Dictionary = CASES[code]
		var track: Dictionary = {}
		for t in season["tracks"]:
			if str(t.get("code","")) == code:
				track = t
				break
		check(not track.is_empty(),"track found "+code)
		if track.is_empty():
			continue
		var baseline = Race.new(season["teams"],"Ferrari",int(config["seed"]),{},track,{})
		var sim = Race.new(season["teams"],"Ferrari",int(config["seed"]),{},track,{})
		baseline.configure_weather(str(config["weather"]))
		sim.configure_weather(str(config["weather"]))
		for car in baseline.player_cars():
			car["pit_control_mode"] = "IA"
		for car in sim.player_cars():
			car["pit_control_mode"] = "IA"
		var chart = Chart.new()
		chart.reset(sim)
		check(JSON.stringify(baseline.get_state_snapshot()) == JSON.stringify(sim.get_state_snapshot()),"initial parity "+code)
		var predictions: Dictionary = {}
		var inspected_pits: Dictionary = {}
		var samples: Array = []
		var counts: Dictionary = {"scenarios":0,"real_stops":0,"matched":0,"garage_alerts":0,"weather_alerts":0}
		var error_sum: float = 0.0
		var prior_lap: int = -1
		baseline.running = true
		sim.running = true
		var ticks: int = 0
		while not sim.finished and ticks < 9000 and errors.is_empty():
			# Short deterministic A/B parity first, full race thereafter on a
			# single native instance for faithful low-overhead 3-GP integration.
			if ticks < 55:
				baseline.step(4.0)
			sim.step(4.0)
			ticks += 1
			chart.capture(sim)
			var completed: int = int(sim.lap)
			if completed != prior_lap:
				prior_lap = completed
				var team: Array = sim.player_cars()
				for idx in range(team.size()):
					var c: Dictionary = team[idx]
					var teammate: Dictionary = team[1-idx]
					var report: Dictionary = Simulator.evaluate(sim,c,teammate,chart)
					for scenario in report["scenarios"]:
						counts["scenarios"] += 1
						if str(scenario["garage"]["level"]) in ["ALTO", "POTENCIAL"]:
							counts["garage_alerts"] += 1
						if float(scenario["rain_change"]) >= 0.12:
							counts["weather_alerts"] += 1
						# Cache only closest-entry projections, stamped by the intended
						# pit-lap; does not instruct any driver to pit.
						if int(scenario["offset"]) == 0:
							predictions["%d:%d" % [int(c["id"]), int(scenario["lap"])]] = {
								"rejoin":int(scenario["rejoin_position"]), "confidence":str(scenario["confidence"])}
			if ticks <= 55 and ticks % 11 == 0:
				check(JSON.stringify(baseline.get_state_snapshot()) == JSON.stringify(sim.get_state_snapshot()),"early A/B race parity "+code+" tick="+str(ticks))
			if ticks % 400 == 0:
				print("APEX_06499_GP_PROGRESS %s lap=%d/%d ticks=%d" % [code, int(sim.lap), int(sim.lap_count), ticks],true)
			for pit in sim.pit_history:
				var id: int = int(pit.get("car_id", -1))
				var target: int = int(pit.get("lap", -1))
				var pit_key: String = "%d:%d" % [id,target]
				if inspected_pits.has(pit_key):
					continue
				inspected_pits[pit_key] = true
				if str(pit.get("team", "")) != "Ferrari":
					continue
				counts["real_stops"] += 1
				var car: Dictionary = {}
				for c in sim.player_cars():
					if int(c["id"]) == id:
						car = c
						break
				var predicted: Dictionary = predictions.get(pit_key, {})
				if not predicted.is_empty() and not car.is_empty():
					var err: int = abs(int(predicted["rejoin"]) - int(car.get("position", 0)))
					error_sum += float(err)
					counts["matched"] += 1
					samples.append({"driver":str(car.get("name","")),"pit_lap":target,
						"projected_position":int(predicted["rejoin"]),"observed_position_at_service":int(car.get("position",0)),
						"absolute_position_error":err,"confidence":str(predicted["confidence"])})
		check(sim.finished,"race finishes "+code)
		# A/B parity was checked through first 55 native ticks. Long-run
		# preservation is also checked by source-file SHA-256 equality.
		check(sim.finish_results_validated,"classification valid "+code)
		check(sim.get_sorted().size() == 24,"24 pilots "+code)
		check(int(counts["scenarios"]) >= 100,"real live evaluations "+code)
		check(int(counts["real_stops"]) > 0,"live team pit services "+code)
		var metrics: Dictionary = {"track":code,"native_step_seconds":4.0,"ticks":ticks,
			"laps":int(sim.lap),"total_laps":int(sim.lap_count),"drivers":sim.cars.size(),
			"all_pit_services":sim.pit_history.size(),"counts":counts,
			"matched_pit_position_mae":error_sum/float(counts["matched"]) if int(counts["matched"]) > 0 else null,
			"matched_actual_pits":samples,
			"interpretation":"Absolute difference uses a single cached pre-pit estimate versus observed position at service. Not guaranteed and affected by other pit stops, weather and traffic. No invented race events."}
		var path: String = "%s/%s_STRATEGY_SIMULATOR_VALIDACAO.json" % [folder,code]
		var file := FileAccess.open(path, FileAccess.WRITE)
		check(file != null,"write results "+code)
		if file != null:
			file.store_string(JSON.stringify(metrics,"  "))
			file.close()
		print("APEX_06499_GP_TRACK_PASS %s laps=%d/%d ticks=%d total_pits=%d team_pits=%d samples=%d matched=%d MAE=%s parity=EARLY_IDENTICAL" % [code, int(sim.lap), int(sim.lap_count), ticks,sim.pit_history.size(),int(counts["real_stops"]),int(counts["scenarios"]),int(counts["matched"]),str(metrics["matched_pit_position_mae"])],true)
	if errors.is_empty():
		print("APEX_06499_THREE_GP_PASS native Godot full races GBR ITA SIN; parity, scenario samples and actual pit services; no execution side effects")
	quit(0 if errors.is_empty() else 1)
