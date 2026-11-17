extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Original = preload("res://qa/core2_06686/reference_race_space_0655.gd")
const Optimized = preload("res://scripts/core/race_space_0655.gd")
const CODES = ["GBR", "BEL", "ITA", "SIN"]
const REPETITIONS := 5
const CALLS := 175
func _initialize() -> void: call_deferred("_run")
func _median(a: Array) -> float:
	var values: Array=a.duplicate()
	values.sort()
	return float(values[values.size()/2])
func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var results: Dictionary = {}
	var overall_original: Array = []
	var overall_optimized: Array = []
	for code in CODES:
		var track: Dictionary = {}
		for t in data.tracks:
			if str(t.code)==code: track=t
		var engine=Race.new(data.teams,"Ferrari",660,{},track,{})
		var order: Array = engine.get_sorted()
		var metrics: Dictionary = {}
		for car in order:
			metrics[int(car.id)]={"target":80.0 + float(int(car.id)%9)*0.24}
		var src: Dictionary = Original.plan(order,metrics,0.2,track,engine.space_profile,{})
		var dst: Dictionary = Optimized.plan(order,metrics,0.2,track,engine.space_profile,{})
		if src!=dst:
			push_error("06686 direct comparison mismatch on "+code)
			quit(1)
			return
		var oa: Array=[]
		var na: Array=[]
		for run in range(REPETITIONS):
			var t: int=Time.get_ticks_usec()
			if run%2==0:
				for j in range(CALLS): Original.plan(order,metrics,0.2,track,engine.space_profile,{})
				var original_us: int=Time.get_ticks_usec()-t
				t=Time.get_ticks_usec()
				for j in range(CALLS): Optimized.plan(order,metrics,0.2,track,engine.space_profile,{})
				var optimized_us: int=Time.get_ticks_usec()-t
				oa.append(float(original_us)/CALLS)
				na.append(float(optimized_us)/CALLS)
			else:
				for j in range(CALLS): Optimized.plan(order,metrics,0.2,track,engine.space_profile,{})
				var optimized_us: int=Time.get_ticks_usec()-t
				t=Time.get_ticks_usec()
				for j in range(CALLS): Original.plan(order,metrics,0.2,track,engine.space_profile,{})
				var original_us: int=Time.get_ticks_usec()-t
				oa.append(float(original_us)/CALLS)
				na.append(float(optimized_us)/CALLS)
		results[code]={"baseline_us":oa,"optimized_us":na,"median_base_us":_median(oa),"median_new_us":_median(na)}
		overall_original.append(_median(oa))
		overall_optimized.append(_median(na))
		print("CORE2_06686_BENCH "+JSON.stringify({"track":code,"median_base_us":_median(oa),"median_new_us":_median(na)}))
	results["summary"]={"median_of_track_medians_base_us":_median(overall_original),"median_of_track_medians_new_us":_median(overall_optimized)}
	var dest: String=OS.get_environment("APEX_06686_BENCH")
	if not dest.is_empty():
		var f=FileAccess.open(dest,FileAccess.WRITE)
		if f!=null:
			f.store_string(JSON.stringify(results,"  "))
			f.close()
	print("CORE2_06686_BENCH_PASS "+JSON.stringify(results["summary"]))
	quit(0)
