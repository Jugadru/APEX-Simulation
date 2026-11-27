extends SceneTree
const V = preload("res://scripts/core/race_vehicle_dynamics_072.gd")
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
		printerr("VEHICLE_DYNAMICS_072_FAIL ",label)
func run() -> void:
	var coast: Dictionary = V.phase(50.0,60.0,0.2,700.0,1400.0,0.0,10000.0)
	check(is_equal_approx(float(coast.speed_mps),49.6) and is_equal_approx(float(coast.distance_m),9.96),"coast SI and drag during shift")
	check(float(coast.drive_work_kj)==0.0 and float(coast.drive_force_n)==0.0,"coast no work")
	var cruise: Dictionary = V.phase(50.0,50.0,0.2,700.0,1400.0,8000.0,10000.0)
	check(is_equal_approx(float(cruise.speed_mps),50.0) and is_equal_approx(float(cruise.drive_force_n),1400.0),"cruise counteracts resistance")
	check(is_equal_approx(float(cruise.drive_work_kj),14.0/P.EFFICIENCY),"N*m /1000 / efficiency")
	var braking: Dictionary = V.phase(50.0,40.0,0.2,700.0,1400.0,8000.0,4200.0)
	check(is_equal_approx(float(braking.speed_mps),48.4) and float(braking.drive_force_n)==0.0 and float(braking.drive_work_kj)==0.0,"brake plus drag")
	var stopped: Dictionary = V.phase(1.0,0.0,1.0,700.0,1400.0,0.0,14000.0)
	check(float(stopped.speed_mps)==0.0 and float(stopped.distance_m)>=0.0 and float(stopped.distance_m)<1.0,"stop without reversing")
	var zero: Dictionary = V.phase(50.0,60.0,0.0,700.0,1400.0,8000.0,10000.0)
	check(float(zero.distance_m)==0.0 and float(zero.speed_mps)==50.0,"zero dt")
	var dry := {"grip_factor":1.0,"wetness_factor":0.0}
	var wet := {"grip_factor":0.70,"wetness_factor":1.0}
	var car := {"tire":"Médio","wear":0.0,"tyre_surface_c":95.0,"pace":"Normal"}
	car[L.KEY]=60.0
	car[P.KEY]={"gear":5}
	var curve := {"legacy_factor":1.0,"load":0.0,"mean":0.0,"ahead_load":0.0,"progress":0.1,"ahead_progress":0.11}
	curve[P.KEY]=true
	curve[F.KEY]=700.0
	curve[T.KEY]=true
	curve[V.KEY]=true
	curve["power_delivery_070"]={"kers_power_kw":60.0,"drs_active":false}
	var proposed: Dictionary = V.propose(car,curve,60.0,6000.0,0.2,dry)
	var state: Dictionary = proposed[V.KEY]
	check(float(state.drive_force_n)>0.0 and float(state.drive_force_n)<=float(state.drive_cap_n)+0.000001 and float(state.brake_force_n)==0.0,"bounded drive")
	var accepted: Dictionary = V.account(state,float(proposed.distance_m),float(proposed.speed_mps),0.2)
	var blocked: Dictionary = V.account(state,0.0,0.0,0.2)
	check(float(accepted.accepted_v8_kj)<=float(state.v8_offer_kj)+0.000001 and float(accepted.accepted_kers_kj)<=float(state.kers_offer_kj)+0.000001,"accepted energy bounded by offers")
	check(is_equal_approx(float(accepted.accepted_kers_kj)+float(accepted.unused_authorized_kers_kj),12.0),"KERS budget reconciled")
	check(bool(blocked.solver_limited) and float(blocked.accepted_v8_kj)==0.0 and float(blocked.accepted_kers_kj)==0.0,"no positive work on blocked movement")
	var conserve: Dictionary = V.propose(car,curve,160.0,6000.0,0.2,dry)
	check(float(conserve.speed_mps)<float(proposed.speed_mps),"strategy target controls physical motion")
	var in_wet: Dictionary = V.propose(car,curve,60.0,6000.0,0.2,wet)
	check(float(in_wet[V.KEY].drive_cap_n)<float(state.drive_cap_n),"wet grip limits drive")
	curve[F.KEY]=800.0
	var heavy: Dictionary = V.propose(car,curve,60.0,6000.0,0.2,dry)
	check(float(heavy.speed_mps)<float(proposed.speed_mps),"fuel mass reduces acceleration")
	curve[F.KEY]=700.0
	car[P.KEY]={"gear":1,"shift_remaining_s":0.06}
	var shifted: Dictionary = V.propose(car,curve,60.0,6000.0,0.2,dry)
	check(float(shifted[V.KEY].shift_cut_s)>0.0 and float(shifted[V.KEY].shift_net_force_n)<0.0,"real deceleration during cut")
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
		rec.recorded_simulation_revision=Replay.VEHICLE_DYNAMICS_EXPERIMENTAL_SIMULATION_REVISION
		live.recorded_simulation_revision=Replay.VEHICLE_DYNAMICS_EXPERIMENTAL_SIMULATION_REVISION
		legacy.recorded_simulation_revision=Replay.TYRE_GRIP_EXPERIMENTAL_SIMULATION_REVISION
		var actor: int = int(a.player_cars()[0].id)
		for session in [rec,live,legacy]:
			check(session.enqueue("schedule_pit",[actor,session.race.available_pit_compounds()[0],21],3),"manual pit")
			check(session.enqueue("set_pace",[actor,"Conservar"],135),"conserve command")
			check(session.enqueue("set_pace",[actor,"Atacar"],235),"attack command")
		var samples: int = 0
		var kers_samples: int = 0
		var changed: bool = false
		var pace_seen: Dictionary = {}
		for tick in range(330):
			if not (rec.step_tick() and live.step_tick() and legacy.step_tick()):
				check(false,"tick");break
			check(Codec.sporting_hash(a,rec.policy)==Codec.sporting_hash(b,live.policy) and a.rng.state==b.rng.state,"045 recording determinism")
			for i in range(a.cars.size()):
				var c: Dictionary = a.cars[i]
				check(not old.cars[i].has(V.KEY),"044 state preserved")
				if not c.has(V.KEY): continue
				samples+=1
				var x: Dictionary = c[V.KEY]
				var fuel: Dictionary = c[F.KEY]
				check(c.has(T.KEY) and c.has(P.KEY),"grip gearbox preserved")
				check(is_finite(float(x.actual_ax_mps2)) and float(x.actual_distance_m)>=0.0 and float(x.drive_force_n)>=0.0 and float(x.brake_force_n)>=0.0,"finite forces and progress")
				check(float(x.accepted_v8_kj)>=0.0 and float(x.accepted_v8_kj)<=float(x.v8_offer_kj)+0.000001 and float(x.accepted_kers_kj)>=0.0 and float(x.accepted_kers_kj)<=float(x.kers_offer_kj)+0.000001,"bounded settled shaft work")
				check(is_equal_approx(float(x.fuel_burn_kg),float(fuel.last_burn_kg)) and is_equal_approx(float(x.mass_after_kg),float(fuel.mass_kg)) and float(x.mass_after_kg)<=float(x.mass_before_kg)+0.000001,"single fuel ledger")
				check(is_equal_approx(float(x.accepted_kers_kj)+float(x.unused_authorized_kers_kj),float(x.kers_allocated_kw)*Replay.STEP) and float(c.get("kers_used_lap_kj",0.0))<=400.000001,"KERS authorized")
				if float(x.accepted_kers_kj)>0.0: kers_samples+=1
				if int(c.id)==actor: pace_seen[str(x.pace_mode)]=true
				if absf(float(c.progress)-float(old.cars[i].progress))>0.000001: changed=true
		check(samples>0 and kers_samples>0 and changed,"045 real race integration")
		check(pace_seen.has("Conservar") and pace_seen.has("Atacar"),"strategy modes reach vehicle")
		check(int(a.player_cars()[0].pit_scheduled_lap)==21,"manual V21 retained")
		var archive = Replay.new()
		check(archive.load_data(rec.export_data()) and archive.seek(330) and archive.seek(150) and archive.seek(330) and archive.first_divergence<0,"045 replay seek")
		print("VEHICLE_DYNAMICS_072_CASE ",JSON.stringify({"track":code,"climate":climate,"samples":samples,"kers_samples":kers_samples,"progress_changed":changed,"paces":pace_seen,"ticks":rec.tick}))
		# Controlled fixture: existing DNF contract, no fabricated GP result.
		var victim: Dictionary = b.player_cars()[0]
		victim[F.KEY].remaining_kg=0.0000001
		check(live.step_tick() and bool(victim.get("fuel_dnf_0701",false)) and not victim.has(V.KEY) and float(victim.finish_time)<0.0,"045 fuel exhaustion")
		var stopped_progress: float = float(victim.progress)
		check(live.step_tick() and float(victim.progress)==stopped_progress,"DNF remains stopped")
	if failures==0: print("VEHICLE_DYNAMICS_072_PASS checks=%d" % checks)
	quit(0 if failures==0 else 1)
