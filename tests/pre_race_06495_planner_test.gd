extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Planner = preload("res://scripts/core/race_pre_race_strategy_06495.gd")
const Tyres = preload("res://scripts/core/race_tyres_2012.gd")
var issues: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, description: String) -> void:
	if not ok:
		issues.append(description)
		printerr("PRE_RACE_06495_FAIL " + description)
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var british: Dictionary = {}
	for t in season["tracks"]:
		if str(t.get("code","")) == "GBR":
			british = t
	check(not british.is_empty(),"Silverstone catalog")
	if british.is_empty():
		quit(2)
		return
	var sim = Race.new(season["teams"],"Ferrari",6403,{},british,{})
	sim.configure_weather("Seco")
	var snapshot: String = JSON.stringify(sim.get_state_snapshot())
	var result: Dictionary = Planner.generate(sim)
	check(result.get("valid",false),"plans generated")
	check(result.get("plans",[]).size() == 2,"two drivers")
	var options: Array = Tyres.available(Tyres.catalog(),"GBR")
	for plan in result.get("plans",[]):
		check(bool(plan.get("valid",false)),"valid plan " + str(plan.get("name","?")))
		if not bool(plan.get("valid",false)):
			continue
		var stints: Array = plan["stints"]
		var total: int = 0
		var used: Array = []
		for block in stints:
			check(options.has(str(block["compound"])),"legal dry compound")
			check(float(block["wear_end"]) <= 86.0001,"safe projected wear")
			check(int(block["from"])==total+1,"stints contiguous")
			total += int(block["laps"])
			check(int(block["to"])==total,"stint end correct")
			if not used.has(str(block["compound"])):
				used.append(str(block["compound"]))
		check(total==52,"52 laps covered")
		check(used.size()==2,"two dry compounds nominated")
		check(stints.size()<=5,"4 or fewer stops")
	check(JSON.stringify(sim.get_state_snapshot())==snapshot,"prediction read only")
	if result["plans"].size()==2 and result["plans"][0].get("valid",false) and result["plans"][1].get("valid",false):
		check(int(result["plans"][0]["stints"][0]["to"]) != int(result["plans"][1]["stints"][0]["to"]),"first stop overlap avoided when safe")
	# Wet races: no fictional dry order automatically placed.
	sim.configure_weather("Chuva intensa")
	var wet: Dictionary = Planner.generate(sim)
	check(wet.get("plans",[]).size()==2,"wet state previews")
	for plan in wet.get("plans",[]):
		check(not bool(plan.get("valid",true)),"wet plans are advisory only")
	if issues.is_empty():
		print("PRE_RACE_06495_PASS Silverstone dry 52 laps, two drivers, safe stints, read-only, wet restriction")
	quit(0 if issues.is_empty() else 1)
