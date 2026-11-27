extends SceneTree
const F = preload("res://scripts/core/race_fuel_mass_0701.gd")
const L = preload("res://scripts/core/race_longitudinal_069.gd")
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
		printerr("FUEL_MASS_0701_FAIL ",label)
func run() -> void:
	check(is_equal_approx(F.fuel_for_energy_kg(500.0,0.30),500.0/12900.0),"500 kW x 1 s = 500 kJ, not 500 MJ")
	check(is_equal_approx(F.fuel_for_energy_kg(100.0,0.30),0.007751937984496124),"200 ms x 500 kW")
	check(is_equal_approx(F.shaft_work_kj(700.0,50.0,50.0,10.0,1000.0,1.0,0.0),10.0),"10000 J = 10 kJ")
	check(is_equal_approx(F.shaft_work_kj(700.0,50.0,50.0,10.0,1000.0,1.0,3.0),7.0),"KERS offsets shaft work")
	check(F.shaft_work_kj(700.0,50.0,40.0,10.0,1000.0,1.0,0.0)==0.0,"no negative fuel demand")
	var state: Dictionary = F.initial_state(53,90.0)
	var normal: Dictionary = F.advance(state,"Normal",0.2,100.0,50.0)
	var save: Dictionary = F.advance(state,"Conservar",0.2,100.0,50.0)
	var attack: Dictionary = F.advance(state,"Atacar",0.2,100.0,50.0)
	check(float(save.last_burn_kg)<float(normal.last_burn_kg) and float(normal.last_burn_kg)<float(attack.last_burn_kg),"pace efficiency")
	check(is_equal_approx(float(normal.remaining_kg)+float(normal.consumed_kg),float(state.initial_kg)) and float(normal.mass_kg)<float(state.mass_kg),"mass and fuel conservation")
	check(is_equal_approx(float(F.advance(state,"Normal",1.0,0.0,0.0).last_burn_kg),F.IDLE_KG_PER_S),"idle draw")
	var empty: Dictionary = state.duplicate()
	empty.remaining_kg=0.001
	empty=F.advance(empty,"Normal",0.2,100.0,0.0)
	check(bool(empty.exhausted) and float(empty.remaining_kg)==0.0 and float(empty.mass_kg)==F.DRY_MASS_KG,"depletion clamps zero")
	var car := {"tire":"Médio","wear":0.0}
	car[L.KEY]=60.0
	car[P.KEY]={"gear":5}
	var curve := {"legacy_factor":1.0,"load":0.0,"mean":0.0,"ahead_load":0.0}
	curve[P.KEY]=true
	curve[F.KEY]=650.0
	var weather := {"grip_factor":1.0,"wetness_factor":0.0}
	var light: Dictionary = L.propose(car,curve,60.0,6000.0,0.2,weather)
	curve[F.KEY]=800.0
	var heavy: Dictionary = L.propose(car,curve,60.0,6000.0,0.2,weather)
	check(float(light.speed_mps)>float(heavy.speed_mps),"light car accelerates more")
	var heavy_brake: Dictionary = L.propose(car,curve,150.0,6000.0,0.2,weather)
	curve[F.KEY]=650.0
	var light_brake: Dictionary = L.propose(car,curve,150.0,6000.0,0.2,weather)
	check(float(light_brake.speed_mps)<float(heavy_brake.speed_mps),"mass affects braking")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	for code in ["ITA","GBR"]:
		var track: Dictionary = {}
		for item in data.tracks:
			if item.code==code: track=item;break
		if track.is_empty(): check(false,"track missing");continue
		var climate: String = "Seco" if code=="ITA" else "Chuva intensa"
		var a = Race.new(data.teams,"Ferrari",42,{},track,{})
		var b = Race.new(data.teams,"Ferrari",42,{},track,{})
		var old = Race.new(data.teams,"Ferrari",42,{},track,{})
		for r in [a,b,old]: r.configure_weather(climate)
		var rec = Replay.new()
		var live = Replay.new()
		var legacy = Replay.new()
		rec.attach(a)
		live.attach(b,{}, {},false)
		legacy.attach(old,{}, {},false)
		rec.recorded_simulation_revision=Replay.FUEL_EXPERIMENTAL_SIMULATION_REVISION
		live.recorded_simulation_revision=Replay.FUEL_EXPERIMENTAL_SIMULATION_REVISION
		legacy.recorded_simulation_revision=Replay.GEARBOX_EXPERIMENTAL_SIMULATION_REVISION
		var actor: int = int(a.player_cars()[0].id)
		for session in [rec,live,legacy]:
			check(session.enqueue("schedule_pit",[actor,session.race.available_pit_compounds()[0],21],3),"manual pit")
		var previous_mass: Dictionary = {}
		for tick in range(330):
			if not (rec.step_tick() and live.step_tick() and legacy.step_tick()):
				check(false,"tick");break
			check(Codec.sporting_hash(a,rec.policy)==Codec.sporting_hash(b,live.policy) and a.rng.state==b.rng.state,"043 recording determinism")
			for i in range(a.cars.size()):
				var c: Dictionary = a.cars[i]
				check(not old.cars[i].has(F.KEY),"042 old state preserved")
				check(c.has(F.KEY),"043 per car ledger")
				if not c.has(F.KEY): continue
				var f: Dictionary = c[F.KEY]
				check(float(f.remaining_kg)>=0.0 and is_equal_approx(float(f.remaining_kg)+float(f.consumed_kg),float(f.initial_kg)),"fuel balance")
				check(float(f.mass_kg)<=float(previous_mass.get(c.id,INF)) and is_equal_approx(float(f.mass_kg),F.DRY_MASS_KG+float(f.remaining_kg)),"monotonic mass")
				previous_mass[c.id]=float(f.mass_kg)
		check(int(a.player_cars()[0].pit_scheduled_lap)==21,"manual order retained")
		var archive = Replay.new()
		check(archive.load_data(rec.export_data()) and archive.seek(330) and archive.seek(150) and archive.seek(330) and archive.first_divergence<0,"043 replay seek")
		print("FUEL_MASS_0701_CASE ",JSON.stringify({"track":code,"climate":climate,"fuel":a.player_cars()[0].get(F.KEY,{}),"ticks":rec.tick}))
		# Controlled fixture only: exhaust one car without pretending to run a GP.
		var victim: Dictionary = b.player_cars()[0]
		victim[F.KEY].remaining_kg=0.0000001
		check(live.step_tick() and bool(victim.get("fuel_dnf_0701",false)) and bool(victim.finished) and float(victim.finish_time)<0.0,"fuel DNF without fake finish")
		var stopped: float = float(victim.progress)
		check(live.step_tick() and float(victim.progress)==stopped,"retired car no longer moves")
	if failures==0: print("FUEL_MASS_0701_PASS checks=%d" % checks)
	quit(0 if failures==0 else 1)
