extends SceneTree
## v0.6.4.9.6: cenários determinísticos e integração nativa sem novos pits manuais.
const Layer = preload("res://scripts/core/race_lap_reassessment_06496.gd")
const Race = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []
func chk(value: bool, name: String) -> void:
	if not value:
		failures.append(name)
		printerr("FAIL_06496 " + name)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var own: Dictionary = {"id":1,"name":"Piloto A","team":"Ferrari","laps_done":12,
		"stops":0,"stint_laps":12,"progress":12.0,"wear":50.0,"tire":"Médio",
		"last_lap":99.0,"pit_request":false,"pit_left":0.0,"pit_scheduled_lap":0,
		"lap_strategy_adjusted_stint_06496":-999}
	var rival: Dictionary = {"id":2,"name":"Rival","team":"McLaren","laps_done":12,
		"progress":12.009,"last_lap":100.2,"pit_left":0.0}
	var dry: Dictionary = {"wetness_factor":0.0}
	var baseline: Dictionary = {"pit_now":true,"compound":"Duro","planned_pit_lap":13,
		"life_laps":5.0,"forecast_3":0.0,"forecast_6":0.0,"critical":false}
	var avail: Array = ["Médio","Duro","Intermediário","Chuva"]
	var src: String = JSON.stringify([own,rival,baseline,dry])
	var r: Dictionary = Layer.assess(own,[own,rival],baseline,dry,100.0,20.0,52,avail)
	chk(r["action"]=="ESTENDER" and r["executable"],"safe overcut +1")
	chk(JSON.stringify([own,rival,baseline,dry])==src,"pure assessment")
	var booked: Dictionary = own.duplicate(true)
	booked["pit_scheduled_lap"] = 21
	r = Layer.assess(booked,[booked,rival],baseline,dry,100.0,20.0,52,avail)
	chk(r["action"]=="ORDEM PROTEGIDA" and not r["executable"],"V21 protected")
	var wet: Dictionary = {"wetness_factor":0.78}
	r = Layer.assess(own,[own,rival],baseline,wet,100.0,20.0,52,avail)
	chk(not r["executable"],"rain blocks extending")
	var critical: Dictionary = baseline.duplicate(true)
	critical["critical"] = true
	r = Layer.assess(own,[own,rival],critical,dry,100.0,20.0,52,avail)
	chk(not r["executable"],"critical tyre blocks extending")
	var teammate: Dictionary = rival.duplicate(true)
	teammate["team"]="Ferrari"
	teammate["pit_request"]=true
	r = Layer.assess(own,[own,teammate],baseline,dry,100.0,20.0,52,avail)
	chk(not r["executable"],"teammate pit blocks extension")
	var already: Dictionary = own.duplicate(true)
	already["lap_strategy_adjusted_stint_06496"]=0
	r = Layer.assess(already,[already,rival],baseline,dry,100.0,20.0,52,avail)
	chk(not r["executable"],"only once per stint")
	var early_car: Dictionary = own.duplicate(true)
	early_car["last_lap"]=101.5
	early_car["wear"]=55.0
	rival["last_lap"]=100.3
	var early_plan: Dictionary = baseline.duplicate(true)
	early_plan["pit_now"]=false
	early_plan["planned_pit_lap"]=14
	r = Layer.assess(early_car,[early_car,rival],early_plan,dry,100.0,20.0,52,avail)
	chk(r["action"]=="ANTECIPAR" and r["executable"],"safe undercut in dry window")
	early_plan["planned_pit_lap"]=18
	r = Layer.assess(early_car,[early_car,rival],early_plan,dry,100.0,20.0,52,avail)
	chk(not r["executable"],"no early pit outside one-lap window")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for tr in season["tracks"]:
		if str(tr.get("code",""))=="GBR":
			track=tr
			break
	var sim = Race.new(season["teams"],"Ferrari",6403,{},track,{})
	sim.configure_weather("Seco")
	sim.running = true
	var players: Array = sim.player_cars()
	var first: Dictionary = players[0]
	var id: int = int(first["id"])
	chk(sim.schedule_pit(id,sim.available_pit_compounds()[1],21),"manual schedule V21")
	var rng_before: int = sim.rng.state
	for i in range(40):
		sim.step(4.0)
	chk(sim.rng.state != rng_before,"native progress")
	chk(int(first["pit_scheduled_lap"])==21 and not bool(first["pit_request"]),"V21 not advanced")
	chk(int(first.get("laps_done",0)) >= 1,"real lap advanced")
	var reviews: Array = first.get("lap_strategy_history_06496",[])
	chk(reviews.size() >= 1 and reviews.size() <= 16,"bounded per lap history")
	chk(int(first.get("lap_strategy_06496",{}).get("lap",-1))==int(first["laps_done"]),"latest lap review")
	var answer: Dictionary = sim.get_engineer_advice(id)
	chk(answer.has("lap_review_06496"),"engineer advice exposes read-only review")
	var current: String = JSON.stringify([first.get("pit_scheduled_lap",0),first.get("pit_request",false),sim.rng.state])
	for i in range(5):
		sim.get_engineer_advice(id)
	chk(current==JSON.stringify([first.get("pit_scheduled_lap",0),first.get("pit_request",false),sim.rng.state]),"reading advice does not change race")
	var prior: int = reviews.size()
	sim.get_engineer_advice(id)
	chk((first.get("lap_strategy_history_06496",[]) as Array).size()==prior,"no duplicate review from UI polling")
	if failures.is_empty():
		print("APEX_06496_PASS safe early/extend, rain, booked V21, critical, teammate, one stint, native 0.2s, read-only, bounded")
	quit(0 if failures.is_empty() else 1)
