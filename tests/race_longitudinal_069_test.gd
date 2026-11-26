extends SceneTree
const P = preload("res://scripts/core/race_longitudinal_069.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("LONGITUDINAL_069_FAIL ",label)
func run() -> void:
	var up: Dictionary = P.integrate(20.0,60.0,8.0,20.0,0.2)
	check(is_equal_approx(float(up.speed_mps),21.6) and is_equal_approx(float(up.distance_m),4.16),"SI acceleration and trapezoid")
	var down: Dictionary = P.integrate(60.0,20.0,8.0,20.0,0.2)
	check(is_equal_approx(float(down.speed_mps),56.0) and is_equal_approx(float(down.distance_m),11.6),"SI braking")
	var cruise: Dictionary = P.integrate(20.0,21.0,10.0,20.0,0.2)
	check(is_equal_approx(float(cruise.speed_mps),21.0) and is_equal_approx(float(cruise.distance_m),4.15),"reach target then cruise")
	var half: Dictionary = P.integrate(20.0,60.0,8.0,20.0,0.1)
	var second: Dictionary = P.integrate(float(half.speed_mps),60.0,8.0,20.0,0.1)
	check(is_equal_approx(float(second.speed_mps),float(up.speed_mps)) and is_equal_approx(float(half.distance_m)+float(second.distance_m),float(up.distance_m)),"constant-rate chunk invariant")
	check(is_equal_approx(P.braking_cap(30.0,10.0,35.0),40.0),"braking distance relation")
	check(P.corner_speed(70.0,0.9,0.2)<P.corner_speed(70.0,0.1,0.2),"corner target lower than straight")
	check(is_equal_approx(P.braking_distance(40.0,30.0,10.0),35.0),"SI braking distance")
	check(P.braking_distance(20.0,30.0,10.0)==0.0,"no braking below target")
	var approach := {"progress":0.90,"mean":0.0,"corners":[{"apex":0.02,"severity":1.0}]}
	var dry_cap: float = P.apex_braking_cap(approach,100.0,1000.0,1.0,100.0)
	var wet_cap: float = P.apex_braking_cap(approach,100.0,1000.0,0.35,100.0)
	check(is_equal_approx(dry_cap,100.0) and wet_cap<dry_cap and wet_cap>76.0,"wet braking starts beyond 60m across finish line")
	approach.progress=0.02
	check(is_equal_approx(P.apex_braking_cap(approach,100.0,1000.0,0.35,100.0),76.0),"explicit apex target")
	approach.progress=0.03
	check(is_equal_approx(P.apex_braking_cap(approach,100.0,1000.0,0.35,100.0),100.0),"release apex constraint on exit")
	approach.progress=0.90
	approach["load"]=0.0
	approach["ahead_load"]=0.0
	approach["legacy_factor"]=1.0
	var wet_car := {"tire":"Médio","wear":0.0}
	wet_car[P.KEY]=100.0
	var wet_approach: Dictionary = P.propose(wet_car,approach,10.0,1000.0,0.2,{"grip_factor":0.7,"wetness_factor":0.8})
	check(float(wet_approach.speed_mps)<100.0,"actual proposal brakes before apex despite clear 60m preview")
	# Exit under the same schematic conditions: no instant jump to the
	# higher straight target, and lower grip reduces acceleration.
	approach.progress=0.10
	wet_car[P.KEY]=76.0
	var exit_dry: Dictionary = P.propose(wet_car,approach,10.0,1000.0,0.2,{"grip_factor":1.0,"wetness_factor":0.0})
	var exit_wet: Dictionary = P.propose(wet_car,approach,10.0,1000.0,0.2,{"grip_factor":0.7,"wetness_factor":0.8})
	check(float(exit_dry.speed_mps)>76.0 and float(exit_dry.speed_mps)<100.0,"progressive acceleration on exit")
	check(float(exit_wet.speed_mps)>76.0 and float(exit_wet.speed_mps)<float(exit_dry.speed_mps),"wet exit acceleration reduced")
	print("LONGITUDINAL_069_PROFILE ",JSON.stringify({"type":"controlled_fixture_not_track_telemetry","wet_approach":wet_approach,"apex_target_mps":76.0,"dry_exit":exit_dry,"wet_exit":exit_wet}))
	check(is_equal_approx(P.handover_speed(10.0,0.2),50.0),"handover uses actual last displacement")
	check(P.handover_speed(0.0,0.2)==0.0 and P.handover_speed(10.0,0.0)==0.0,"stationary handover")
	var dry := {"grip_factor":1.0,"wetness_factor":0.0}
	var wet := {"grip_factor":0.7,"wetness_factor":0.8}
	var slick := {"tire":"Médio","wear":0.0}
	var rain_tyre := {"tire":"Chuva","wear":0.0}
	check(P.grip(slick,wet)<P.grip(rain_tyre,wet) and P.grip(rain_tyre,wet)<P.grip(slick,dry),"conditional traction")
	check(float(P.rates(80.0,1.0).accel)<float(P.rates(20.0,1.0).accel),"acceleration tapers")
	# Separate equilibrium pace from transient grip. This is a factorial
	# diagnostic, not a claim that the old pace model is calibrated.
	var flat := {"legacy_factor":1.0,"load":0.0,"mean":0.0,"ahead_load":0.0}
	var probe_car := {"tire":"Médio","wear":0.0}
	probe_car[P.KEY]=30.0
	var fast_dry: Dictionary = P.propose(probe_car,flat,80.0,6000.0,0.2,dry)
	var fast_wet: Dictionary = P.propose(probe_car,flat,80.0,6000.0,0.2,wet)
	var slow_dry: Dictionary = P.propose(probe_car,flat,120.0,6000.0,0.2,dry)
	check(float(fast_wet.speed_mps)<float(fast_dry.speed_mps),"grip changes transient response at fixed pace")
	check(is_equal_approx(float(slow_dry.speed_mps),float(fast_dry.speed_mps)),"target pace not extra acceleration multiplier")
	print("LONGITUDINAL_069_GRIP_FACTORIAL ",JSON.stringify({"fast_dry":fast_dry,"fast_wet":fast_wet,"slow_dry":slow_dry}))
	check(P.settle(up,0.0,0.2,0.2)==0.0 and P.settle(up,2.0,0.2,0.2)==10.0,"safety overrides free-air speed")
	check(P.settle(up,float(up.distance_m),0.2,0.2)==float(up.speed_mps),"unrestricted end speed")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	for code in ["GBR","ITA"]:
		var track: Dictionary = {}
		for item in data.tracks:
			if item.code==code: track=item;break
		if track.is_empty(): check(false,"track exists");continue
		var climate: String = "Seco" if code=="ITA" else "Chuva intensa"
		var rec = Replay.new()
		var live = Replay.new()
		var former = Replay.new()
		var first = Race.new(data.teams,"Ferrari",42,{},track,{})
		var second_race = Race.new(data.teams,"Ferrari",42,{},track,{})
		var old = Race.new(data.teams,"Ferrari",42,{},track,{})
		for engine in [first,second_race,old]: engine.configure_weather(climate)
		rec.attach(first)
		live.attach(second_race,{}, {},false)
		former.attach(old)
		former.recorded_simulation_revision=Replay.PRE_LONGITUDINAL_SIMULATION_REVISION
		var actor: int = int(first.player_cars()[0].id)
		for session in [rec,live,former]:
			check(session.enqueue("schedule_pit",[actor,session.race.available_pit_compounds()[0],21],3),"manual V21")
			check(session.enqueue("set_pace",[actor,"Atacar"],130),"pace command")
		var active_ticks := 0
		var changed_progress := false
		var min_speed := P.MAX_MPS
		var max_speed := 0.0
		var handover_samples := 0
		var live_usec: int = 0
		var new_recorded_usec: int = 0
		var old_usec: int = 0
		var perf_ticks: int = 0
		for i in range(330):
			var before: Dictionary = {}
			for car in first.cars: before[int(car.id)]=float(car.progress)
			var started: int = Time.get_ticks_usec()
			var ok: bool = rec.step_tick()
			var new_elapsed: int = Time.get_ticks_usec()-started
			started = Time.get_ticks_usec()
			ok = live.step_tick() and ok
			var live_elapsed: int = Time.get_ticks_usec()-started
			started = Time.get_ticks_usec()
			ok = former.step_tick() and ok
			var old_elapsed: int = Time.get_ticks_usec()-started
			if float(first.clock)>=24.0:
				perf_ticks+=1
				new_recorded_usec+=new_elapsed
				live_usec+=live_elapsed
				old_usec+=old_elapsed
			check(ok,"three sessions advance")
			if not ok: break
			check(Codec.sporting_hash(first,rec.policy)==Codec.sporting_hash(second_race,live.policy),"recording isolation")
			check(first.rng.state==second_race.rng.state,"recording isolation RNG state")
			if float(first.clock)<24.0:
				check(first.rng.state==old.rng.state,"legacy launch RNG state")
				for car in first.cars:
					if car.has(P.KEY):
						handover_samples+=1
						check(is_equal_approx(float(car[P.KEY]),P.handover_speed((float(car.progress)-float(before[int(car.id)]))*float(first.lap_km)*1000.0,Replay.STEP)),"actual displacement handover state")
			for car in first.cars:
				check(float(car.progress)>=float(before[int(car.id)])-0.00000001,"nonnegative progress")
				if car.has(P.KEY):
					var speed: float = float(car[P.KEY])
					check(is_finite(speed) and speed>=0.0 and speed<=P.MAX_MPS,"bounded persisted speed")
					min_speed=minf(min_speed,speed)
					max_speed=maxf(max_speed,speed)
					active_ticks+=1
			for car in old.cars: check(not car.has(P.KEY),"040 no new sporting state")
			if float(first.clock)<24.0:
				for index in range(first.cars.size()):
					check(is_equal_approx(float(first.cars[index].progress),float(old.cars[index].progress)),"legacy launch progress parity")
				# The last legacy tick now contains the 041 handover seed.
				if float(first.clock)+Replay.STEP+0.0000001<24.0:
					check(rec.hashes[-1]==former.hashes[-1],"legacy launch parity before handover seed")
			if i>130 and absf(float(first.player_cars()[0].progress)-float(old.player_cars()[0].progress))>0.000001: changed_progress=true
		check(active_ticks>0 and changed_progress and max_speed>min_speed,"new physics actually affects progress")
		check(first.player_cars()[0].pit_scheduled_lap==21,"manual V21 preserved")
		check(first.rng.seed==old.rng.seed,"same initial seed (not post-divergence RNG equality)")
		check(handover_samples>0,"041 handover seed observed")
		var rng_before: int = first.rng.state
		var actual_car: Dictionary = first.player_cars()[0]
		var probe: Dictionary = P.propose(actual_car,flat,90.0,6000.0,0.2,dry)
		check(is_finite(float(probe.speed_mps)) and first.rng.state==rng_before,"longitudinal proposal leaves race RNG state untouched")
		print("LONGITUDINAL_069_TICK_OBSERVATION ",JSON.stringify({"track":code,"climate":climate,"seed":42,"cars":first.cars.size(),"post_launch_ticks":perf_ticks,"rev041_recorded_usec_per_tick":float(new_recorded_usec)/maxi(1,perf_ticks),"rev040_recorded_usec_per_tick":float(old_usec)/maxi(1,perf_ticks),"rev041_live_usec_per_tick":float(live_usec)/maxi(1,perf_ticks),"same_recording_mode":true,"sporting_outcomes_equivalent":false,"diagnostic_only":true}))
		var play = Replay.new()
		check(play.load_data(rec.export_data()) and play.seek(330) and play.seek(150) and play.seek(330),"041 replay and checkpoint seek")
		check(play.first_divergence<0,"041 replay deterministic")
		var legacy = Replay.new()
		check(legacy.load_data(former.export_data()) and legacy.seek(330) and legacy.seek(150) and legacy.seek(330),"040 still replays")
		print("LONGITUDINAL_069_CASE ",JSON.stringify({"track":code,"climate":climate,"ticks":rec.tick,"speed_samples":active_ticks,"min_mps":min_speed,"max_mps":max_speed,"progress_changed":changed_progress}))
		# Existing short scenarios remain unchanged. Observe an actual Monza
		# lap crossing in the unrecorded live session, not a target-time fixture.
		if code=="ITA":
			var timing_car: Dictionary = second_race.player_cars()[0]
			var start_lap: int = int(timing_car.laps_done)
			var start_clock: float = float(timing_car.lap_started)
			for step in range(900):
				if int(timing_car.laps_done)>start_lap: break
				if not live.step_tick(): break
				timing_car=second_race.player_cars()[0]
			check(int(timing_car.laps_done)>start_lap,"041 actual Monza lap crossing")
			check(is_equal_approx(float(timing_car.last_lap),float(second_race.clock)-start_clock),"041 lap time measured from actual crossing")
	if failures.is_empty(): print("LONGITUDINAL_069_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
