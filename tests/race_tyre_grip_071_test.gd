extends SceneTree
const T = preload("res://scripts/core/race_tyre_grip_071.gd")
const L = preload("res://scripts/core/race_longitudinal_069.gd")
const F = preload("res://scripts/core/race_fuel_mass_0701.gd")
const P = preload("res://scripts/core/race_powertrain_070.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("TYRE_GRIP_071_FAIL ",label)
func run() -> void:
	var rest: Dictionary = T.wheel_loads(700.0,0.0,0.0,0.0)
	var braking: Dictionary = T.wheel_loads(700.0,-10.0,0.0,0.0)
	var accelerating: Dictionary = T.wheel_loads(700.0,10.0,0.0,0.0)
	check(is_equal_approx(float(rest.total_n),6867.0),"static weight in N")
	check(float(braking.front_n)>float(rest.front_n) and float(accelerating.rear_n)>float(rest.rear_n),"longitudinal transfer directions")
	check(is_equal_approx(float(braking.front_n)-float(rest.front_n),700.0*10.0*T.CG_HEIGHT_M/T.WHEELBASE_M),"longitudinal dimensional oracle")
	var left: Dictionary = T.wheel_loads(700.0,0.0,10.0,500.0)
	var right: Dictionary = T.wheel_loads(700.0,0.0,-10.0,500.0)
	check(float(left.fl_n)>float(left.fr_n) and is_equal_approx(float(left.fl_n),float(right.fr_n)),"lateral direction symmetry")
	check(is_equal_approx(float(left.fl_n)+float(left.fr_n)+float(left.rl_n)+float(left.rr_n),7367.0),"normal force conservation with downforce")
	var extreme: Dictionary = T.wheel_loads(800.0,-100.0,100.0,0.0)
	check(float(extreme.fl_n)>=0.0 and float(extreme.fr_n)>=0.0 and float(extreme.rl_n)>=0.0 and float(extreme.rr_n)>=0.0,"bounded nonnegative normal forces")
	check(T.tyre_force_n(2000.0,1.0)<2.0*T.tyre_force_n(1000.0,1.0),"sublinear load sensitivity")
	check(is_equal_approx(T.downforce_n(80.0,{}),4.0*T.downforce_n(40.0,{})),"downforce squared")
	check(T.downforce_n(80.0,{"drs_active":true})<T.downforce_n(80.0,{}) and T.downforce_n(80.0,{"dirty_fraction":0.02})<T.downforce_n(80.0,{}),"existing aero state reduces downforce")
	var dry := {"grip_factor":1.0,"wetness_factor":0.0}
	var wet := {"grip_factor":0.75,"wetness_factor":1.0}
	var car := {"tire":"Médio","wear":0.0,"tyre_surface_c":95.0}
	var straight: Dictionary = T.evaluate(car,dry,700.0,50.0,0.0,0.0,L.grip(car,dry),{})
	var curve_state: Dictionary = T.evaluate(car,dry,700.0,50.0,0.004,0.0,L.grip(car,dry),{})
	check(float(curve_state.accel_limit_mps2)<float(straight.accel_limit_mps2) and float(curve_state.brake_limit_mps2)<float(straight.brake_limit_mps2),"combined grip budget")
	check(float(curve_state.ay_mps2)==10.0,"v squared times curvature")
	var wet_slick: Dictionary = T.evaluate(car,wet,700.0,50.0,0.004,0.0,L.grip(car,wet),{})
	var rain_car := {"tire":"Chuva","wear":0.0,"tyre_surface_c":70.0}
	var wet_rain: Dictionary = T.evaluate(rain_car,wet,700.0,50.0,0.004,0.0,L.grip(rain_car,wet),{})
	check(float(wet_slick.mu)<float(wet_rain.mu) and float(wet_rain.mu)<float(straight.mu),"wet tyre crossover")
	var damaged := {"tire":"Médio","wear":90.0,"tyre_surface_c":130.0,"tyre_blistering":0.9}
	check(T.compound_grip(damaged,dry,L.grip(damaged,dry))<float(straight.mu),"wear temperature and blistering affect grip")
	check(T.wear_scale({"combined_utilization":1.0})>T.wear_scale({"combined_utilization":0.3}),"load-related wear")
	car[L.KEY]=70.0
	car[P.KEY]={"gear":7}
	var curve := {"legacy_factor":1.0,"load":0.9,"mean":0.0,"ahead_load":0.9,"progress":0.1}
	curve[P.KEY]=true
	curve[F.KEY]=700.0
	var old: Dictionary = L.propose(car,curve,60.0,6000.0,0.2,dry)
	curve[T.KEY]=true
	var fresh: Dictionary = L.propose(car,curve,60.0,6000.0,0.2,dry)
	check(fresh.has(T.KEY) and not old.has(T.KEY) and float(fresh.speed_mps)<float(old.speed_mps),"physical lateral cap affects proposed displacement")
	check(T.signed_curvature({"load":0.8,"progress":0.1,"corners":[{"apex":0.1,"severity":0.8,"direction":-1.0}]})<0.0,"signed schematic corner")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	for code in ["ITA","GBR"]:
		var track: Dictionary = {}
		for item in data.tracks:
			if item.code==code: track=item;break
		if track.is_empty(): check(false,"track missing");continue
		var climate: String = "Seco" if code=="ITA" else "Chuva intensa"
		var a = Race.new(data.teams,"Ferrari",42,{},track,{})
		var b = Race.new(data.teams,"Ferrari",42,{},track,{})
		var historical = Race.new(data.teams,"Ferrari",42,{},track,{})
		for r in [a,b,historical]: r.configure_weather(climate)
		var rec = Replay.new()
		var live = Replay.new()
		var legacy = Replay.new()
		rec.attach(a)
		live.attach(b,{}, {},false)
		legacy.attach(historical,{}, {},false)
		rec.recorded_simulation_revision=Replay.TYRE_GRIP_EXPERIMENTAL_SIMULATION_REVISION
		live.recorded_simulation_revision=Replay.TYRE_GRIP_EXPERIMENTAL_SIMULATION_REVISION
		legacy.recorded_simulation_revision=Replay.FUEL_EXPERIMENTAL_SIMULATION_REVISION
		var actor: int = int(a.player_cars()[0].id)
		for session in [rec,live,legacy]:
			check(session.enqueue("schedule_pit",[actor,session.race.available_pit_compounds()[0],21],3),"manual command")
		var samples: int = 0
		var curves: int = 0
		var changed: bool = false
		for tick in range(330):
			if not (rec.step_tick() and live.step_tick() and legacy.step_tick()):
				check(false,"tick");break
			check(Codec.sporting_hash(a,rec.policy)==Codec.sporting_hash(b,live.policy) and a.rng.state==b.rng.state,"044 recording determinism")
			for i in range(a.cars.size()):
				var c: Dictionary = a.cars[i]
				var h: Dictionary = historical.cars[i]
				check(not h.has(T.KEY),"043 old state")
				if not c.has(T.KEY): continue
				samples+=1
				var x: Dictionary = c[T.KEY]
				var loads: Dictionary = x.loads
				var sum_n: float = float(loads.fl_n)+float(loads.fr_n)+float(loads.rl_n)+float(loads.rr_n)
				check(is_equal_approx(sum_n,float(x.mass_kg)*T.G+float(x.downforce_n)) and float(loads.fl_n)>=0.0 and float(loads.fr_n)>=0.0 and float(loads.rl_n)>=0.0 and float(loads.rr_n)>=0.0,"four wheel load conservation")
				check(is_finite(float(x.combined_utilization)) and float(x.mu)>0.0 and float(x.accel_limit_mps2)>=0.0 and float(x.brake_limit_mps2)>=0.0,"finite grip envelope")
				check(c.has(F.KEY) and c.has(P.KEY),"fuel gearbox preserved")
				if absf(float(x.ay_mps2))>0.1: curves+=1
				if absf(float(c.progress)-float(h.progress))>0.000001: changed=true
		check(samples>0 and curves>0 and changed,"044 affects actual race")
		check(int(a.player_cars()[0].pit_scheduled_lap)==21,"V21 order retained")
		var archive = Replay.new()
		check(archive.load_data(rec.export_data()) and archive.seek(330) and archive.seek(150) and archive.seek(330) and archive.first_divergence<0,"044 replay seek")
		print("TYRE_GRIP_071_CASE ",JSON.stringify({"track":code,"climate":climate,"samples":samples,"curve_samples":curves,"progress_changed":changed,"ticks":rec.tick}))
	if failures==0: print("TYRE_GRIP_071_PASS checks=%d" % checks)
	quit(0 if failures==0 else 1)
