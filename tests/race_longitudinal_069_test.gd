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
	var dry := {"grip_factor":1.0,"wetness_factor":0.0}
	var wet := {"grip_factor":0.7,"wetness_factor":0.8}
	var slick := {"tire":"Médio","wear":0.0}
	var rain_tyre := {"tire":"Chuva","wear":0.0}
	check(P.grip(slick,wet)<P.grip(rain_tyre,wet) and P.grip(rain_tyre,wet)<P.grip(slick,dry),"conditional traction")
	check(float(P.rates(80.0,1.0).accel)<float(P.rates(20.0,1.0).accel),"acceleration tapers")
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
		for i in range(330):
			var before: Dictionary = {}
			for car in first.cars: before[int(car.id)]=float(car.progress)
			var ok: bool = rec.step_tick() and live.step_tick() and former.step_tick()
			check(ok,"three sessions advance")
			if not ok: break
			check(Codec.sporting_hash(first,rec.policy)==Codec.sporting_hash(second_race,live.policy),"recording isolation")
			for car in first.cars:
				check(float(car.progress)>=float(before[int(car.id)])-0.00000001,"nonnegative progress")
				if car.has(P.KEY):
					var speed: float = float(car[P.KEY])
					check(is_finite(speed) and speed>=0.0 and speed<=P.MAX_MPS,"bounded persisted speed")
					min_speed=minf(min_speed,speed)
					max_speed=maxf(max_speed,speed)
					active_ticks+=1
			for car in old.cars: check(not car.has(P.KEY),"040 no new sporting state")
			if i<119: check(rec.hashes[-1]==former.hashes[-1],"legacy launch parity")
			if i>130 and absf(float(first.player_cars()[0].progress)-float(old.player_cars()[0].progress))>0.000001: changed_progress=true
		check(active_ticks>0 and changed_progress and max_speed>min_speed,"new physics actually affects progress")
		check(first.player_cars()[0].pit_scheduled_lap==21,"manual V21 preserved")
		check(first.rng.seed==old.rng.seed,"same seed; no new RNG call in longitudinal model")
		var play = Replay.new()
		check(play.load_data(rec.export_data()) and play.seek(330) and play.seek(150) and play.seek(330),"041 replay and checkpoint seek")
		check(play.first_divergence<0,"041 replay deterministic")
		var legacy = Replay.new()
		check(legacy.load_data(former.export_data()) and legacy.seek(330) and legacy.seek(150) and legacy.seek(330),"040 still replays")
		print("LONGITUDINAL_069_CASE ",JSON.stringify({"track":code,"climate":climate,"ticks":rec.tick,"speed_samples":active_ticks,"min_mps":min_speed,"max_mps":max_speed,"progress_changed":changed_progress}))
	if failures.is_empty(): print("LONGITUDINAL_069_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
