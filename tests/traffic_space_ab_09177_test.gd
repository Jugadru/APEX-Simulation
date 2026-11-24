extends SceneTree
const Base = preload("res://tests/legacy/traffic_space_baseline_09177.gd")
const Candidate = preload("res://scripts/core/race_space_0655.gd")
const Race = preload("res://scripts/race_engine.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var cases: Array = []
	for track in season.tracks:
		if str(track.code) not in ["MON","GBR","ITA","BEL"]: continue
		var race=Race.new(season.teams,"Ferrari",42,{},track,{})
		race.running=true
		for tick in range(100):
			race.step(0.2)
			if tick%4!=0: continue
			var cars: Array = race.cars.duplicate(true)
			var metrics: Dictionary = {}
			for c in cars: metrics[c.id]={"target":80.0+float(int(c.id)%11)*0.7}
			cases.append([cars,metrics,track,race.space_profile,{}])
	var checks:=0
	var results: Array=[]
	for repeat in range(4):
		var totals: Array=[0,0]
		for modern in [false,true]:
			for item in cases:
				var old: Dictionary={}
				var new: Dictionary={}
				for mode in ([0,1] if repeat%2==0 else [1,0]):
					var start:=Time.get_ticks_usec()
					if mode==0: old=Base.plan(item[0],item[1],0.2,item[2],item[3],item[4],true,true,true,true,20.0,true,modern)
					else: new=Candidate.plan(item[0],item[1],0.2,item[2],item[3],item[4],true,true,true,true,20.0,true,modern)
					totals[mode]+=Time.get_ticks_usec()-start
				if old!=new:
					printerr("TRAFFIC_SPACE_AB_09177_FAIL ",repeat," ",modern)
					quit(1)
					return
				checks+=1
		results.append(totals)
	print("TRAFFIC_SPACE_AB_09177_PASS ",JSON.stringify({"checks":checks,"snapshots":cases.size(),"paired_us":results}))
	quit()
