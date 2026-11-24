extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
var failures: Array[String]=[]
var checks: int=0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		printerr("COMPETITIVE_TRAFFIC_09174_FAIL ",label)
func _initialize() -> void: call_deferred("run")
func case_run(teams: Array,track: Dictionary,seed_value: int,climate: String,modern: bool) -> Dictionary:
	var race=Race.new(teams,"Ferrari",seed_value,{},track,{})
	race.merge_traffic_enabled=modern
	race.configure_weather(climate)
	race.running=true
	var previous: Dictionary={}
	var stops: Dictionary={}
	var ranks: Dictionary={}
	var max_stopped: int=0
	var stopped_samples: int=0
	var reversals: int=0
	var all_stopped: int=0
	var alongside: int=0
	for car in race.cars:
		previous[int(car.id)]=float(car.progress)
	for tick in range(600):
		race.step(0.2)
		var moving: int=0
		var active: int=0
		for car in race.cars:
			var id: int=int(car.id)
			var delta: float=float(car.progress)-float(previous[id])
			previous[id]=float(car.progress)
			if bool(car.finished) or float(car.pit_left)>0.0: continue
			active+=1
			if delta < -0.00000001: reversals+=1
			if delta>0.00000001: moving+=1
			if tick>=15:
				if delta<=0.00000001:
					stops[id]=int(stops.get(id,0))+1
					stopped_samples+=1
					max_stopped=maxi(max_stopped,int(stops[id]))
				else: stops[id]=0
		if tick>=15 and active>0 and moving==0: all_stopped+=1
		# Measure actual sporting adjacent occupancy, not the visual pose.
		for i in range(race.cars.size()):
			var ca: Dictionary=race.cars[i]
			if bool(ca.finished) or float(ca.pit_left)>0.0: continue
			for j in range(i+1,race.cars.size()):
				var cb: Dictionary=race.cars[j]
				if bool(cb.finished) or float(cb.pit_left)>0.0: continue
				var gap: float=absf(fposmod(float(ca.progress)-float(cb.progress)+0.5,1.0)-0.5)*float(race.space_profile.length)
				if gap<6.4 and absf(float(ca.race_lane)-float(cb.race_lane))>=2.94: alongside+=1
		if tick in [89,299,599]:
			var row: Array=[]
			for car in race.get_sorted(): row.append(int(car.id))
			ranks[str(tick+1)]=row
	var passes: int=0
	var attempts: int=0
	for car in race.cars:
		passes+=int(car.get("combat_passes",0))
		attempts+=int(car.get("combat_attempts",0))
	return {"passes":passes,"attempts":attempts,"max_stopped_ticks":max_stopped,"stopped_samples":stopped_samples,"alongside_samples":alongside,"reversals":reversals,"all_stopped_ticks":all_stopped,"ranks":ranks,"hash":Codec.sporting_hash(race,{})}
func run() -> void:
	var seed_value: int=int(OS.get_environment("APEX_TRAFFIC_SEED")) if OS.has_environment("APEX_TRAFFIC_SEED") else 42
	var season: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var cases: Array=[]
	# Isolated unit fixture: a genuine overlap cannot be squeezed; an early
	# proposed attack is cancelled and only the trailing side lifts.
	var base: Dictionary={"commit":true,"defense":true}
	check(not bool(Merge.refine(base,15.0,-2.0,2.0,6.4,2.95).commit),"abort early attack at narrowing")
	check(bool(Merge.refine(base,3.0,-2.0,2.0,6.4,2.95).commit),"preserve occupied duel")
	var intents: Dictionary={1:{"lane":-2.0,"next":0.104},2:{"lane":2.0,"next":0.100}}
	Merge.queue([{"id":1,"progress":0.1},{"id":2,"progress":0.096}],intents,{1:true,2:true},1000.0,6.4,2.95)
	check(is_equal_approx(float(intents[1].next),0.104),"leader unchanged")
	check(float(intents[2].next)>0.096 and float(intents[2].next)<0.100,"trailing car yields without forced stop")
	for track in season.tracks:
		if str(track.code) not in ["GBR","MON","ITA","BEL"]: continue
		for climate in ["Seco","Chuva intensa"]:
			var before: Dictionary=case_run(season.teams,track,seed_value,climate,false)
			var after: Dictionary=case_run(season.teams,track,seed_value,climate,true)
			var repeated: Dictionary=case_run(season.teams,track,seed_value,climate,true)
			var label: String="%s/%s/%d" % [track.code,climate,seed_value]
			check(after.hash==repeated.hash and after.ranks==repeated.ranks,label+" deterministic")
			check(int(after.reversals)==0,label+" no reversals")
			check(int(after.all_stopped_ticks)==0,label+" no field deadlock")
			check(int(after.passes)<=24,label+" no inflated passes")
			if climate=="Chuva intensa": check(int(after.passes)<=4,label+" wet conservative")
			check(int(after.max_stopped_ticks)<=int(before.max_stopped_ticks)+2,label+" no extended stationary regression")
			cases.append({"track":track.code,"climate":climate,"seed":seed_value,"before":before,"after":after})
			print("COMPETITIVE_TRAFFIC_09174_CASE ",JSON.stringify(cases.back()))
	check(cases.size()==8,"all eight scenarios executed")
	# Historical 025 archive generated under the unchanged rule path.
	var old=Race.new(season.teams,"Ferrari",seed_value,{},season.tracks[0],{})
	var rec=Replay.new()
	rec.attach(old)
	rec.recorded_simulation_revision=Replay.PRE_MERGE_TRAFFIC_SIMULATION_REVISION
	for i in range(120): check(rec.step_tick(),"025 tick")
	var playback=Replay.new()
	check(playback.load_data(rec.export_data()) and playback.seek(rec.end_tick) and playback.first_divergence<0,"025 archive hashes")
	print("COMPETITIVE_TRAFFIC_09174_REPORT ",JSON.stringify({"seed":seed_value,"checks":checks,"cases":cases.size(),"failures":failures}))
	if failures.is_empty(): print("COMPETITIVE_TRAFFIC_09174_PASS")
	quit(0 if failures.is_empty() else 1)
