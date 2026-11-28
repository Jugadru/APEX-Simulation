extends SceneTree
## Revision-specific A/B, deterministic archive and full-distance validation.
const O = preload("res://scripts/core/race_overtaking_intelligence_066912.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
const Merge = preload("res://scripts/core/race_merge_traffic_0669174.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:
		if failures.size()<30: failures.append(label)
		printerr("073_VALIDATION_FAIL ",label)
func session_for(data: Dictionary, track: Dictionary, climate: String, seed: int, revision: String, record: bool):
	var race = Race.new(data.teams,"Ferrari",seed,{},track,{})
	race.configure_weather(climate)
	var session = Replay.new()
	session.attach(race,{}, {},record)
	session.recorded_simulation_revision=revision
	session.racecraft_audit_enabled=false
	return session

func drive(session, ticks: int, stop_at_v21: bool=false) -> Dictionary:
	var race = session.race
	var actor: int = int(race.player_cars()[0].id)
	var initial_stops: int = int(race.player_cars()[0].stops)
	var saw_v4: bool = false
	var pit_lap: int = -1
	var overlaps: int = 0
	var reverse: int = 0
	var stationary: int = 0
	var samples: int = 0
	var reasons: Dictionary = {}
	var times: Array[float] = []
	var memory_peak: int = 0
	var timed_ticks: int = 0
	var timed_us: int = 0
	var rapid: int = 0
	var last_dir: Dictionary = {}
	var last_tick: Dictionary = {}
	for tick in range(ticks):
		if race.finished: break
		var before: Dictionary = {}
		for c in race.cars: before[c.id]=c.duplicate(false)
		var start: int = Time.get_ticks_usec()
		if not session.step_tick():
			check(false,"tick rejected");break
		var elapsed: int = Time.get_ticks_usec()-start
		if tick>=120:
			timed_ticks+=1;timed_us+=elapsed
			if tick%5==0: times.append(float(elapsed))
		if tick%100==0: memory_peak=maxi(memory_peak,int(Performance.get_monitor(Performance.MEMORY_STATIC)))
		var active: Array = []
		for c in race.cars:
			var id: int=int(c.id)
			var old: Dictionary=before[id]
			var plan: Dictionary=c.get(O.PREPARATION_KEY,{})
			if not plan.is_empty():
				samples+=1
				var reason: String=str(plan.reason)
				reasons[reason]=int(reasons.get(reason,0))+1
			if session.recorded_simulation_revision==Replay.SIMULATION_REVISION:
				check(not c.has(O.PREPARATION_KEY),"legacy state changed")
			if race.clock<24.0 or not Space.active(c) or not Space.active(old):
				last_dir.erase(id);last_tick.erase(id);continue
			active.append(c)
			var delta: float=float(c.progress)-float(old.progress)
			if delta < -0.00000001: reverse+=1
			if delta <= 0.00000001: stationary+=1
			var lane_delta: float=float(c.race_lane)-float(old.race_lane)
			if absf(lane_delta)>0.025:
				var direction: float=signf(lane_delta)
				if last_dir.has(id) and float(last_dir[id])!=direction and tick-int(last_tick[id])<=10: rapid+=1
				last_dir[id]=direction;last_tick[id]=tick
		for i in range(active.size()):
			for j in range(i+1,active.size()):
				var gap: float=absf(Merge.relative_gap(float(active[i].progress),float(active[j].progress),float(race.space_profile.length)))
				if gap<6.39999 and absf(float(active[i].race_lane)-float(active[j].race_lane))<2.94999: overlaps+=1
		if stop_at_v21:
			var player: Dictionary=race.player_cars()[0]
			var lap: int=int(floor(maxf(0.0,float(player.progress))))+1
			if lap==4: saw_v4=true
			if int(player.stops)>initial_stops:
				pit_lap=lap
				check(saw_v4 and lap==21 and int(player.pit_scheduled_lap)==0,"manual pit must execute on V21")
				break
			if tick>=3 and int(player.pit_scheduled_lap)!=21:
				check(false,"manual V21 lost");break
			if bool(player.finished) or lap>21: break
	var attempts: int=0
	var passes: int=0
	var finished: int=0
	for c in race.cars:
		attempts+=int(c.get("combat_attempts",0))
		passes+=int(c.get("combat_passes",0))
		if bool(c.finished): finished+=1
	times.sort()
	var p95: float=times[int(floor(0.95*float(times.size()-1)))] if not times.is_empty() else 0.0
	return {"ticks":session.tick,"hash":Codec.sporting_hash(race,session.policy),"samples":samples,"reasons":reasons,"overlaps":overlaps,"reverse":reverse,"stationary":stationary,"rapid_reversals":rapid,"attempts":attempts,"passes":passes,"finished":race.finished,"finished_cars":finished,"pit_lap":pit_lap,"mean_tick_us":float(timed_us)/maxi(1,timed_ticks),"p95_sample_us":p95,"peak_static_bytes_sampled":memory_peak}

func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var code: String=OS.get_environment("APEX_073_TRACK")
	var climate: String=OS.get_environment("APEX_073_CLIMATE")
	var seed: int=int(OS.get_environment("APEX_073_SEED"))
	var mode: String=OS.get_environment("APEX_073_MODE")
	var track: Dictionary={}
	for t in data.tracks:
		if str(t.code)==code: track=t;break
	if track.is_empty() or seed<=0 or climate.is_empty():
		printerr("073_VALIDATION_FAIL invalid matrix inputs");quit(1);return
	var baseline = session_for(data,track,climate,seed,Replay.SIMULATION_REVISION,false)
	var candidate = session_for(data,track,climate,seed,Replay.OVERTAKING_PREPARATION_SIMULATION_REVISION,false)
	if mode=="v21":
		var actor: int=int(candidate.race.player_cars()[0].id)
		var compounds: Array=candidate.race.available_pit_compounds()
		var compound: String="Chuva" if compounds.has("Chuva") else str(compounds[0])
		check(candidate.enqueue("schedule_pit",[actor,compound,21],3),"V21 enqueue")
		var result: Dictionary=drive(candidate,26000,true)
		check(int(result.pit_lap)==21,"V21 actually reached")
		check(int(result.samples)>0 and int(result.reverse)==0,"candidate active without reverse progress")
		print("073_V21_REPORT ",JSON.stringify(result))
	else:
		var full: bool=mode=="full"
		var ticks: int=45000 if full else 1800
		var old: Dictionary=drive(baseline,ticks)
		var new: Dictionary=drive(candidate,ticks)
		check(int(new.samples)>0,"046 preparation actually active")
		check(int(new.reverse)==0,"no reverse progress")
		check(int(new.overlaps)<=int(old.overlaps),"overlap regression")
		check(int(new.stationary)<=int(old.stationary)+maxi(2,ceili(float(old.stationary)*0.10)),"stationary regression")
		check(int(new.rapid_reversals)<=int(old.rapid_reversals)+maxi(3,ceili(float(old.rapid_reversals)*0.10)),"rapid steering regression")
		if full:
			check(bool(old.finished) and bool(new.finished) and int(new.finished_cars)==24,"full race to flag")
		else:
			var rec = session_for(data,track,climate,seed,Replay.OVERTAKING_PREPARATION_SIMULATION_REVISION,true)
			var live = session_for(data,track,climate,seed,Replay.OVERTAKING_PREPARATION_SIMULATION_REVISION,false)
			var actor: int=int(rec.race.player_cars()[0].id)
			for session in [rec,live]:
				check(session.enqueue("set_pace",[actor,"Conservar"],135),"pace command")
				check(session.enqueue("set_pace",[actor,"Atacar"],235),"pace command")
			for i in range(330):
				if not rec.step_tick() or not live.step_tick():
					check(false,"record/live tick");break
			var expected: String=Codec.sporting_hash(rec.race,rec.policy)
			check(expected==Codec.sporting_hash(live.race,live.policy),"record/live equivalence")
			var archive=Replay.new()
			var loaded: bool=archive.load_data(rec.export_data())
			check(loaded,"046 archive import")
			if loaded:
				check(archive.seek(330) and archive.seek(150) and archive.seek(330) and archive.first_divergence<0,"046 seek roundtrip")
				check(Codec.sporting_hash(archive.race,archive.policy)==expected,"046 archive sporting hash")
		print("073_AB_REPORT ",JSON.stringify({"track":code,"climate":climate,"seed":seed,"mode":mode,"041":old,"046":new,"mean_ratio":float(new.mean_tick_us)/maxf(1.0,float(old.mean_tick_us)),"timing":"advisory shared runner, no FPS claim"}))
	if failures.is_empty(): print("OVERTAKING_PREPARATION_073_VALIDATION_PASS")
	quit(0 if failures.is_empty() else 1)
