extends SceneTree
const P = preload("res://scripts/core/race_powertrain_070.gd")
const L = preload("res://scripts/core/race_longitudinal_069.gd")
const Kers = preload("res://scripts/core/race_kers_2012.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failed+=1
		printerr("POWERTRAIN_070_FAIL ",label)
func run() -> void:
	check(is_equal_approx(P.power_kw(300.0,16000.0),502.6548245743669),"SI power")
	check(is_equal_approx(P.torque_nm(13000.0),310.0) and is_equal_approx(P.torque_nm(14500.0),315.0),"torque curve")
	check(P.torque_nm(18001.0)==0.0,"rev limiter")
	check(P.raw_rpm(30.0,1)>P.raw_rpm(30.0,2),"ratio to rpm")
	var steady: Dictionary = P.advance({"gear":1},30.0,1.0,0.2)
	var half: Dictionary = P.advance({"gear":1},30.0,0.5,0.2)
	var coast: Dictionary = P.advance({"gear":1},30.0,0.0,0.2)
	check(is_equal_approx(float(half.wheel_force_n)*2.0,float(steady.wheel_force_n)) and float(coast.wheel_force_n)==0.0,"throttle affects force")
	check(is_equal_approx(float(steady.uncut_accel_mps2),(float(steady.uncut_wheel_force_n)-float(steady.road_load_n))/P.REFERENCE_MASS_KG),"net force to acceleration")
	var shift: Dictionary = P.advance({"gear":1},36.0,1.0,0.02)
	check(int(shift.gear)==2 and is_equal_approx(float(shift.shift_remaining_s),0.04) and float(shift.wheel_force_n)==0.0,"shift interruption across ticks")
	var resume: Dictionary = P.advance(shift,36.0,1.0,0.1)
	check(int(resume.gear)==2 and is_equal_approx(float(resume.shift_cut_s),0.04) and float(resume.wheel_force_n)>0.0,"resume delivery")
	var down: Dictionary = P.advance({"gear":4},25.0,0.0,0.2)
	check(int(down.gear)==3 and float(down.wheel_force_n)==0.0,"downshift while braking")
	var over: Dictionary = P.advance({"gear":7},110.0,1.0,0.2)
	check(int(over.gear)==7 and float(over.rpm)==18000.0 and float(over.wheel_force_n)==0.0,"limiter no eighth gear")
	check(float(P.settle(steady,10.0).rpm)<float(steady.rpm),"rpm follows solved speed")
	check(is_equal_approx(P.aerodynamic_drag_n(80.0),4.0*P.aerodynamic_drag_n(40.0)),"drag scales with speed squared")
	check(is_equal_approx(P.aerodynamic_drag_n(80.0),0.48*80.0*80.0),"reference drag retained")
	check(P.aerodynamic_drag_n(80.0,{"drs_active":true})<P.aerodynamic_drag_n(80.0),"authorized DRS reduces drag")
	check(P.aerodynamic_drag_n(80.0,{"tow_fraction":0.014})<P.aerodynamic_drag_n(80.0),"existing tow reduces drag")
	var kers_car := {"team":"Ferrari","pit_left":0.0}
	Kers.initial_state(kers_car)
	kers_car.kers_mode="Atacar"
	check(Kers.apply(kers_car,0.15,1.0,0.2,{}),"existing KERS authorizes current tick")
	var reservoir_after: float = float(kers_car.kers_remaining_kj)
	var free: Dictionary = P.advance({"gear":7},80.0,1.0,0.2)
	var boost: Dictionary = P.advance({"gear":7},80.0,1.0,0.2,P.REFERENCE_MASS_KG,{"kers_power_kw":float(kers_car.kers_power_kw)})
	var drs: Dictionary = P.advance({"gear":7},80.0,1.0,0.2,P.REFERENCE_MASS_KG,{"drs_active":true})
	check(float(boost.kers_power_kw)==60.0 and float(boost.total_power_kw)>float(boost.v8_power_kw),"KERS adds shaft power")
	check(float(boost.uncut_accel_mps2)>float(free.uncut_accel_mps2) and float(drs.uncut_accel_mps2)>float(free.uncut_accel_mps2),"boost and reduced drag affect force limit")
	check(is_equal_approx(float(boost.kers_energy_offer_kj),12.0) and is_equal_approx(float(boost.total_energy_offer_kj),float(boost.total_power_kw)*0.2),"energy in kJ")
	check(is_equal_approx(reservoir_after,388.0) and float(kers_car.kers_remaining_kj)==reservoir_after,"single authoritative energy debit")
	var cut_boost: Dictionary = P.advance({"gear":1},36.0,1.0,0.02,P.REFERENCE_MASS_KG,{"kers_power_kw":100.0})
	check(float(cut_boost.kers_allocated_kw)==60.0 and float(cut_boost.kers_energy_offer_kj)==0.0,"KERS cap and shift cut")
	var brake_boost: Dictionary = P.advance({"gear":7},80.0,0.0,0.2,P.REFERENCE_MASS_KG,{"kers_power_kw":60.0})
	check(float(brake_boost.kers_energy_offer_kj)==0.0,"no boost delivery under braking")
	var exhausted := {"team":"Ferrari","pit_left":0.0}
	Kers.initial_state(exhausted)
	exhausted.kers_remaining_kj=0.0
	check(not Kers.apply(exhausted,0.15,1.0,0.2,{}) and float(exhausted.kers_power_kw)==0.0,"exhausted source offers no power")
	var curve := {"legacy_factor":1.0,"load":0.0,"mean":0.0,"ahead_load":0.0}
	var car := {"tire":"Médio","wear":0.0}
	car[L.KEY]=36.0
	car[P.KEY]={"gear":1}
	var dry := {"grip_factor":1.0,"wetness_factor":0.0}
	var base_move: Dictionary = L.propose(car,curve,70.0,6000.0,0.2,dry)
	curve[P.KEY]=true
	var drive_move: Dictionary = L.propose(car,curve,70.0,6000.0,0.2,dry)
	check(float(drive_move.distance_m)<float(base_move.distance_m) and drive_move.has(P.KEY),"shift cut changes real proposal at 200ms")
	check(not base_move.has(P.KEY),"041 proposal unchanged")
	car[L.KEY]=80.0
	car[P.KEY]={"gear":7}
	var free_move: Dictionary = L.propose(car,curve,60.0,6000.0,0.2,dry)
	curve["power_delivery_070"]={"kers_power_kw":60.0}
	var boost_move: Dictionary = L.propose(car,curve,60.0,6000.0,0.2,dry)
	curve["power_delivery_070"]={"drs_active":true}
	var drs_move: Dictionary = L.propose(car,curve,60.0,6000.0,0.2,dry)
	check(float(boost_move.distance_m)>float(free_move.distance_m) and float(drs_move.distance_m)>float(free_move.distance_m),"KERS and DRS change actual proposed displacement at fixed pace")
	check(float(boost_move.speed_mps)<=100.0 and float(drs_move.speed_mps)<=100.0,"target and safety bounds remain")
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
		for race in [a,b,old]: race.configure_weather(climate)
		var rec = Replay.new()
		var live = Replay.new()
		var legacy = Replay.new()
		rec.attach(a)
		live.attach(b,{}, {},false)
		legacy.attach(old,{}, {},false)
		rec.recorded_simulation_revision=Replay.GEARBOX_EXPERIMENTAL_SIMULATION_REVISION
		live.recorded_simulation_revision=Replay.GEARBOX_EXPERIMENTAL_SIMULATION_REVISION
		var actor: int = int(a.player_cars()[0].id)
		for session in [rec,live,legacy]:
			check(session.enqueue("schedule_pit",[actor,session.race.available_pit_compounds()[0],21],3),"manual pit")
		var samples: int = 0
		var changed: bool = false
		var shifts: int = 0
		var kers_samples: int = 0
		for tick in range(330):
			if not (rec.step_tick() and live.step_tick() and legacy.step_tick()):
				check(false,"tick");break
			check(Codec.sporting_hash(a,rec.policy)==Codec.sporting_hash(b,live.policy),"recording isolation 042")
			check(a.rng.state==b.rng.state,"RNG isolation 042")
			for i in range(a.cars.size()):
				var c: Dictionary = a.cars[i]
				var historical: Dictionary = old.cars[i]
				check(not historical.has(P.KEY),"041 no gearbox state")
				if float(a.clock)<24.0:
					check(not c.has(P.KEY) and is_equal_approx(float(c.progress),float(historical.progress)),"launch parity")
				if c.has(P.KEY):
					var drive: Dictionary = c[P.KEY]
					samples+=1
					check(int(drive.gear)>=1 and int(drive.gear)<=7 and is_finite(float(drive.rpm)) and float(drive.rpm)>=P.IDLE_RPM and float(drive.rpm)<=P.LIMIT_RPM,"bounded gear and RPM")
					check(is_finite(float(drive.power_kw)) and float(drive.power_kw)>=0.0,"finite power")
					if float(drive.shift_cut_s)>0.0: shifts+=1
					if float(drive.kers_allocated_kw)>0.0: kers_samples+=1
					check(float(drive.kers_energy_offer_kj)>=0.0 and float(drive.kers_energy_offer_kj)<=60.0*Replay.STEP+0.000001,"KERS offer bounded")
					check(float(c.kers_used_lap_kj)<=Kers.ENERGY_PER_LAP_KJ+0.000001,"existing lap energy limit")
					check(is_equal_approx(float(drive.total_power_kw),float(drive.v8_power_kw)+float(drive.kers_power_kw)),"power sum")
					check(is_finite(float(drive.aero_drag_n)) and float(drive.aero_drag_n)>=0.0,"finite drag")
				if absf(float(c.progress)-float(historical.progress))>0.000001: changed=true
		check(samples>0,"042 active")
		check(int(a.player_cars()[0].pit_scheduled_lap)==21,"manual V21 retained")
		var archive = Replay.new()
		check(archive.load_data(rec.export_data()) and archive.seek(330) and archive.seek(150) and archive.seek(330),"042 archive and seek")
		check(archive.first_divergence<0,"042 determinism")
		print("POWERTRAIN_070_CASE ",JSON.stringify({"track":code,"climate":climate,"samples":samples,"shifts":shifts,"kers_samples":kers_samples,"progress_changed":changed,"ticks":rec.tick}))
	if failed==0: print("POWERTRAIN_070_PASS checks=%d" % checks)
	quit(0 if failed==0 else 1)
