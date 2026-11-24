extends SceneTree
const Space=preload("res://scripts/core/race_space_0655.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
const Race=preload("res://scripts/race_engine.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
var failures: Array[String]=[]
var checks:=0
func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:
		failures.append(label)
		printerr("TRAFFIC_09177_FAIL ",label)
func car(id:int,p:float,lane:float)->Dictionary:
	return {"id":id,"progress":p,"race_lane":lane,"skill":80,"wear":0,"defense_aggression":50,"combat_state":"clear","combat_target_id":-1,"attack_charge":0}
func plan(cars:Array,modern:bool,metrics:Dictionary={})->Dictionary:
	if metrics.is_empty():
		for c in cars: metrics[c.id]={"target":100.0}
	return Space.plan(cars,metrics,0.2,{"race_width_m":4.2,"overtake_zones":[[0.,1.]]},{"length":1000.0},{},false,false,false,true,100.,true,modern)
func overlap(a:Dictionary,b:Dictionary,length:float)->bool:
	return absf(Merge.relative_gap(float(a.progress),float(b.progress),length))<Space.LENGTH-0.00001 and absf(float(a.race_lane)-float(b.race_lane))<Space.WIDTH-0.00001
func apply_plan(cars:Array,p:Dictionary)->void:
	for c in cars:
		c.progress=p[c.id].progress
		c.merge(p[c.id].states,true)
func fixture()->void:
	var pair=[car(0,0.2,0),car(1,1.2,2.95)]
	var before=plan(pair,false)
	var after=plan(pair,true)
	check(float(before[1].states.race_lane)<2.95,"reproduce 026 unsafe lateral convergence across laps")
	check(is_equal_approx(float(after[1].states.race_lane),2.95),"027 maintains occupied corridor across laps")
	check(is_equal_approx(float(after[1].progress),1.202),"classified leader receives full nominal displacement, no bonus")
	check(is_equal_approx(float(after[0].progress),0.2009),"physically tied lapped car yields once")
	var perm=pair.duplicate();perm.reverse()
	check(after==plan(perm,true),"independent of input order")
	var triple=[car(0,0.2,-2.95),car(1,0.2,0),car(2,0.2,2.95)]
	var old=plan(triple,false);var new=plan(triple,true)
	check(is_equal_approx(float(old[2].progress),0.200495),"reproduce 026 compound lift")
	check(is_equal_approx(float(new[2].progress),0.2009),"027 single yield instead of stacked braking")
	for tick in range(40):
		var p=plan(triple,true)
		for c in triple: check(float(p[c.id].progress)>=float(c.progress),"no backward impulse")
		apply_plan(triple,p)
		for i in range(triple.size()):
			for j in range(i+1,triple.size()): check(not overlap(triple[i],triple[j],1000.),"three-car corridor stays separated")
	var wrap=[car(0,1.999,0),car(1,1.001,2.95)]
	for tick in range(40):
		apply_plan(wrap,plan(wrap,true))
		check(not overlap(wrap[0],wrap[1],1000.),"wrapped lapped car lateral clearance")
	var blocked=[car(0,0.2,0),car(1,0.2064,0)]
	var b=plan(blocked,true,{0:{"target":50.},1:{"target":100.}})
	check(float(b[0].progress)<=float(b[1].progress)-0.0064+0.00000001,"real same-corridor block preserved")
	print("TRAFFIC_09177_FIXTURE ",JSON.stringify({"legacy_triple":old[2].progress,"candidate_triple":new[2].progress,"legacy_lapped_lane":before[1].states.race_lane,"candidate_lapped_lane":after[1].states.race_lane}))
func run_case(teams:Array,track:Dictionary,climate:String,seed_value:int,modern:bool,ticks:int)->Dictionary:
	var race=Race.new(teams,"Ferrari",seed_value,{},track,{})
	race.traffic_hotfix_enabled=modern
	race.racing_line_enabled=false
	race.configure_weather(climate)
	race.running=true
	var last:Dictionary={};var streak:Dictionary={}
	var stopped:=0;var longest:=0;var reversals:=0;var field_stop:=0;var overlaps:=0;var passes:=0
	var start:=Time.get_ticks_usec()
	for c in race.cars: last[c.id]=float(c.progress)
	for tick in range(ticks):
		race.step(0.2)
		var active:Array=[];var moving:=0
		for c in race.cars:
			var id:int=int(c.id);var delta:float=float(c.progress)-float(last[id]);last[id]=float(c.progress)
			if c.finished or float(c.pit_left)>0.0:
				streak[id]=0
				continue
			active.append(c)
			if delta>0.00000001: moving+=1
			if delta< -0.00000001: reversals+=1
			if tick>=15 and delta<=0.00000001:
				stopped+=1;streak[id]=int(streak.get(id,0))+1;longest=maxi(longest,int(streak[id]))
			else: streak[id]=0
		if tick>=15 and not active.is_empty() and moving==0: field_stop+=1
		if tick>=15:
			for i in range(active.size()):
				for j in range(i+1,active.size()):
					if overlap(active[i],active[j],float(race.space_profile.length)): overlaps+=1
	for c in race.cars: passes+=int(c.get("combat_passes",0))
	return {"hash":Codec.sporting_hash(race,{}),"stopped":stopped,"max_streak":longest,"field_stop":field_stop,"reversals":reversals,"overlaps":overlaps,"passes":passes,"elapsed_us":Time.get_ticks_usec()-start}
func run()->void:
	fixture()
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var seed_value:int=int(OS.get_environment("APEX_TRAFFIC_SEED")) if OS.has_environment("APEX_TRAFFIC_SEED") else 42
	var ticks:int=int(OS.get_environment("APEX_TRAFFIC_TICKS")) if OS.has_environment("APEX_TRAFFIC_TICKS") else 600
	var cases:=0
	for track in data.tracks:
		if str(track.code) not in ["GBR","MON","ITA","BEL"]: continue
		for climate in ["Seco","Chuva intensa"]:
			var before=run_case(data.teams,track,climate,seed_value,false,ticks)
			var after=run_case(data.teams,track,climate,seed_value,true,ticks)
			var again=run_case(data.teams,track,climate,seed_value,true,ticks)
			var label:String=str(track.code)+"/"+climate
			check(after.hash==again.hash,label+" deterministic")
			check(after.reversals==0 and after.field_stop==0,label+" no backwards / field freeze")
			check(after.stopped<=before.stopped and after.max_streak<=before.max_streak,label+" no stationary regression")
			check(after.overlaps<=before.overlaps,label+" no occupied body overlap regression")
			print("TRAFFIC_09177_CASE ",JSON.stringify({"track":track.code,"climate":climate,"seed":seed_value,"ticks":ticks,"before":before,"after":after}))
			cases+=1
	check(cases==8,"all scenarios")
	# Historical 026 rule path and new archives must remain independently replayable.
	for revision in [Replay.PRE_TRAFFIC_HOTFIX_SIMULATION_REVISION,Replay.PRE_RACING_LINE_SIMULATION_REVISION]:
		var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{}))
		rec.recorded_simulation_revision=revision
		for i in range(300): check(rec.step_tick(),revision+" tick")
		if revision==Replay.PRE_TRAFFIC_HOTFIX_SIMULATION_REVISION:
			check(rec.hashes[-1]=="c339b5c460cabed0a13827e4cde755ce974e260db0d6170aa93e422e67477dd6","matches independent 9.17.6 026 reference hash")
		var player=Replay.new()
		check(player.load_data(rec.export_data()) and player.seek(rec.end_tick) and player.first_divergence<0,revision+" replay archive")
	print("TRAFFIC_09177_REPORT ",JSON.stringify({"checks":checks,"cases":cases,"failures":failures}))
	if failures.is_empty(): print("TRAFFIC_09177_PASS")
	quit(0 if failures.is_empty() else 1)
