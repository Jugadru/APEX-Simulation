extends SceneTree
## Integração: janela elegível realmente vira chamada IA, Manual e V21 não.
const Race = preload("res://scripts/race_engine.gd")
const Layer = preload("res://scripts/core/race_lap_reassessment_06496.gd")
var fails: Array[String] = []
func check(ok: bool, what: String) -> void:
	if not ok:
		printerr("AUTO_GATE_06496_FAIL " + what)
		fails.append(what)
func build():
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in season["tracks"]:
		if str(t.get("code","")) == "GBR":
			track = t
	var sim = Race.new(season["teams"],"Ferrari",6496,{},track,{})
	sim.configure_weather("Seco")
	var c: Dictionary = sim.player_cars()[0]
	c["pit_control_mode"] = "IA"
	c["progress"] = 16.0
	c["laps_done"] = 16
	c["stint_laps"] = 16
	c["wear"] = 50.0
	c["last_lap"] = float(sim.base_lap)+1.6
	for other in sim.cars:
		if int(other["id"]) != int(c["id"]):
			other["progress"] = 8.0
			other["last_lap"] = sim.base_lap
	var rival: Dictionary = sim.cars[3] if int(sim.cars[3]["id"]) != int(c["id"]) else sim.cars[4]
	rival["progress"] = 16.013
	rival["last_lap"] = float(sim.base_lap)
	var base_plan: Dictionary = sim._build_strategy_plan(c)
	check(not bool(base_plan.get("pit_now",false)) and int(base_plan.get("planned_pit_lap",0)) == 18, "baseline planned V18, no pit V17")
	var review: Dictionary = Layer.assess(c,sim.cars,base_plan,sim.weather_snapshot(),sim.base_lap,sim.pit_loss,sim.lap_count,sim.available_pit_compounds())
	check(str(review.get("action",""))=="ANTECIPAR" and bool(review.get("executable",false)), "safe re-evaluation elects early pit")
	c["lap_strategy_06496"] = review
	return {"sim":sim,"car":c}
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var test_case: Dictionary = build()
	var sim = test_case["sim"]
	var c: Dictionary = test_case["car"]
	sim._request_ai_pit(c)
	check(bool(c["pit_request"]),"automatic request issued")
	check(str(c["pit_order_source"])=="ia_estrategia","authority remains AI")
	check(int(c["lap_strategy_adjusted_stint_06496"])==0,"one adjustment per stint")
	check(str(c.get("ai_plan",{}).get("tactic","")).contains("UNDERCUT"),"why in AI plan")
	var manual_case: Dictionary = build()
	var manual_sim = manual_case["sim"]
	var manual_car: Dictionary = manual_case["car"]
	manual_car["pit_control_mode"]="Manual"
	manual_sim._request_ai_pit(manual_car)
	check(not bool(manual_car["pit_request"]),"manual never auto calls box")
	var booked_case: Dictionary = build()
	var booked_sim = booked_case["sim"]
	var booked_car: Dictionary = booked_case["car"]
	check(booked_sim.schedule_pit(int(booked_car["id"]),str(booked_car["pit_target"]),21),"manual V21 booking")
	booked_sim._request_ai_pit(booked_car)
	check(int(booked_car["pit_scheduled_lap"])==21 and not bool(booked_car["pit_request"]),"V21 not advanced")
	if fails.is_empty():
		print("AUTO_GATE_06496_PASS real strategy window V18 -> V17, AI only, Manual and V21 guarded")
	quit(0 if fails.is_empty() else 1)
