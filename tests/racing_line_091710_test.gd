extends SceneTree
const Line=preload("res://scripts/core/race_racing_line_091710.gd")
const Race=preload("res://scripts/race_engine.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
const Replay=preload("res://scripts/core/race_replay_0660.gd")
const Codec=preload("res://scripts/core/race_state_codec_0660.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
var failures:Array[String]=[]
var checks:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
	checks+=1
	if not ok:
		failures.append(label)
		printerr("RACING_LINE_091710_FAIL ",label)
func fixture():
	var profile:Dictionary=Line.build({"points":[[0.1,0.1],[0.9,0.1],[0.9,0.9],[0.1,0.9]]})
	check(profile.corners.size()==4,"four schematic corners")
	var corner:Dictionary=profile.corners[0]
	var apex:float=float(corner.apex)
	var entry:Dictionary=Line.sample(profile,apex-float(corner.brake_bins)*0.72/Line.SAMPLES,0,80)
	var middle:Dictionary=Line.sample(profile,apex,0,80)
	var exit:Dictionary=Line.sample(profile,apex+float(corner.exit_bins)*0.72/Line.SAMPLES,0,80)
	check(signf(float(entry.lane_ratio))==-float(corner.direction) and signf(float(middle.lane_ratio))==float(corner.direction) and signf(float(exit.lane_ratio))==-float(corner.direction),"outside-inside-outside")
	check(float(middle.pace_factor)>float(entry.pace_factor) and float(middle.pace_factor)>float(exit.pace_factor),"slower apex, exit recovery")
	check(float(Line.sample(profile,apex,1,80).pace_factor)>float(middle.pace_factor),"wet apex more conservative")
	var car:Dictionary={"id":1,"progress":0.2,"race_lane":0.0}
	var track:Dictionary={"race_width_m":8.8}
	var shape:Dictionary={"length":1000.0}
	var metrics:Dictionary={1:{"target":100.0,"line_ratio":0.5}}
	var p:Dictionary=Space.plan([car],metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true)
	check(is_equal_approx(float(p[1].states.race_lane_goal),1.475) and is_equal_approx(float(p[1].states.race_lane),0.36),"free air line applied with lateral rate limit")
	var rival:Dictionary={"id":2,"progress":0.201,"race_lane":2.95}
	metrics[2]={"target":100.0}
	p=Space.plan([car,rival],metrics,0.2,track,shape,{},false,false,false,false,30.0,true,true)
	check(absf(float(p[1].states.race_lane))<0.000001,"nearby rival prevents voluntary apex move")
func drive(data:Dictionary,track:Dictionary,wet:bool,modern:bool)->Dictionary:
	var race=Race.new(data.teams,"Ferrari",42,{},track,{})
	race.racing_line_enabled=modern
	race.configure_weather("Chuva intensa" if wet else "Seco")
	race.running=true
	var previous:Dictionary={}
	var stopped:=0;var reversals:=0;var overlaps:=0;var offcenter:=0;var field_stops:=0
	for c in race.cars: previous[c.id]=float(c.progress)
	for tick in range(600):
		race.step(0.2)
		var active:Array=[];var moving:=0
		for c in race.cars:
			var delta:float=float(c.progress)-float(previous[c.id]);previous[c.id]=float(c.progress)
			if bool(c.finished) or float(c.pit_left)>0.0: continue
			active.append(c)
			if delta>0.00000001: moving+=1
			if tick>=120:
				if delta<=0.00000001: stopped+=1
				if absf(float(c.race_lane))>0.1: offcenter+=1
			if delta< -0.00000001: reversals+=1
		if tick>=120:
			if not active.is_empty() and moving==0: field_stops+=1
			for i in range(active.size()):
				for j in range(i+1,active.size()):
					if absf(Merge.relative_gap(float(active[i].progress),float(active[j].progress),float(race.space_profile.length)))<Space.LENGTH-0.00001 and absf(float(active[i].race_lane)-float(active[j].race_lane))<Space.WIDTH-0.00001: overlaps+=1
	return {"hash":Codec.sporting_hash(race,{}),"stopped":stopped,"reversals":reversals,"overlaps":overlaps,"field_stops":field_stops,"offcenter":offcenter,"leader_progress":float(race.get_sorted()[0].progress)}
func run():
	fixture()
	if "--fixture-only" in OS.get_cmdline_user_args():
		print("RACING_LINE_FIXTURE ",JSON.stringify({"checks":checks,"failures":failures}))
		quit(0 if failures.is_empty() else 1)
		return
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	check(Line.build({}).is_empty(),"missing geometry safe")
	for track in data.tracks:
		var p:Dictionary=Line.build(track)
		check(not p.is_empty() and p.corners.size()>0,"valid profile "+str(track.code))
		if p.is_empty() or p.corners.is_empty(): continue
		var mean:=0.0
		for i in range(Line.SAMPLES):
			var dry:Dictionary=Line.sample(p,float(i)/Line.SAMPLES,0.0,80.0)
			var wet:Dictionary=Line.sample(p,float(i)/Line.SAMPLES,1.0,80.0)
			mean+=float(dry.pace_factor)
			check(absf(float(dry.lane_ratio))<=0.62 and absf(float(wet.lane_ratio))<=absf(float(dry.lane_ratio))+0.00000001 and float(dry.pace_factor)>0.90 and float(wet.pace_factor)<1.14,"bounded profile")
		check(absf(mean/Line.SAMPLES-1.0)<0.0000001,"normalized dry pace")
		check(Line.sample(p,0.0,0.0,80.0)==Line.sample(p,1.0,0.0,80.0),"wrap")
		var corner:Dictionary=p.corners.reduce(func(a,b):return a if a.severity>b.severity else b)
		var apex:Dictionary=Line.sample(p,float(corner.apex),0.0,80.0)
		check(signf(float(apex.lane_ratio))==float(corner.direction) and float(apex.load)>0.0,"apex inside")
		print("LINE_PROFILE ",track.code," corners=",p.corners.size()," strongest=",corner)
		if str(track.code) not in ["GBR","MON","ITA","BEL"]: continue
		for wet in [false,true]:
			var old=drive(data,track,wet,false)
			var now=drive(data,track,wet,true)
			var again=drive(data,track,wet,true)
			check(now.hash==again.hash,"deterministic "+str(track.code))
			check(now.reversals==0 and now.field_stops==0,"no reverse or deadlock")
			check(now.overlaps<=old.overlaps and now.stopped<=old.stopped+2,"traffic no regression")
			check(now.hash!=old.hash,"new sporting path exercised")
			print("LINE_CASE ",JSON.stringify({"track":track.code,"wet":wet,"old":old,"new":now}))
	for revision in [Replay.PRE_RACING_LINE_SIMULATION_REVISION,Replay.SIMULATION_REVISION]:
		var rec=Replay.new();rec.attach(Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{}))
		rec.recorded_simulation_revision=revision
		for i in range(350): check(rec.step_tick(),"record "+revision)
		if revision==Replay.PRE_RACING_LINE_SIMULATION_REVISION: check(rec.hashes[-1]=="3e3c822d5073c39851706db9130cf11be448da146eb49864f98b623d0c90742e","independent 027 hash")
		var playback=Replay.new()
		check(playback.load_data(rec.export_data()) and playback.seek(350) and playback.first_divergence<0,"archive "+revision)
		check(playback.seek(150) and playback.seek(350),"seek "+revision)
	print("RACING_LINE_091710_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
	if failures.is_empty(): print("RACING_LINE_091710_PASS")
	quit(0 if failures.is_empty() else 1)
