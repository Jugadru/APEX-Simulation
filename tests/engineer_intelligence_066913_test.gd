extends SceneTree
## 9.13: read-only engineer, safe pit gates, actual HUD and replay invariance.
const Intelligence = preload("res://scripts/core/race_engineer_intelligence_066913.gd")
const Engineer3 = preload("res://scripts/core/race_engineer_0646.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures.append(reason)
		printerr("ENGINEER_066913_FAIL " + reason)

func car() -> Dictionary:
	return {"id": 1, "name": "Piloto teste", "laps_done": 4,
		"position": 4, "interval": 0.80, "wear": 30.0,
		"tire": "Médio", "stint_laps": 4, "pit_scheduled_lap": 0,
		"pit_request": false, "pit_left": 0.0, "finished": false,
		"last_lap": 90.10, "best_lap": 89.90,
		"tyre_graining": 0.05, "tyre_blistering": 0.04,
		"pit_control_mode": "Manual"}

func advice() -> Dictionary:
	return {"pit_now":false, "compound":"Macio",
		"forecast_3":0.04, "life_laps":8.0,
		"planned_pit_lap":11, "traffic_risk":false,
		"rejoin_position":7, "rejoin_gap_s":1.1}

func _assessment(pilot: Dictionary, planner: Dictionary,
		weather: Dictionary = {"wetness_factor":0.03},
		mate: Dictionary = {}, staff: Dictionary = {"Engenheiro":2}) -> Dictionary:
	return Intelligence.evaluate(pilot, mate, planner, weather, staff, 50)

func _run() -> void:
	var pilot: Dictionary = car()
	var planner: Dictionary = advice()
	var weather: Dictionary = {"wetness_factor":0.03}
	var snapshot: PackedByteArray = var_to_bytes([pilot,planner,weather])
	var report: Dictionary = _assessment(pilot,planner,weather)
	check(report.get("version") == "0.6.6.9.13"
		and bool(report.get("read_only",false))
		and not bool(report.get("can_call_pit",true)),
		"consultative report cannot issue BOX")
	check(str(report.get("state","")) == "TRÁFEGO PRÓXIMO",
		"real close interval is only a traffic observation")
	check(_assessment(pilot,planner,weather) == report,
		"frozen observations yield identical engineer decision")
	check(var_to_bytes([pilot,planner,weather]) == snapshot,
		"engineer does not mutate observations")
	var no_gap: Dictionary = pilot.duplicate(true)
	no_gap.erase("interval")
	check(_assessment(no_gap,planner,weather).get("state") == "MONITORAR",
		"no fabricated gap for an unmeasured interval")
	var low_staff: Dictionary = _assessment(pilot,planner,weather,{},{"Engenheiro":0})
	var high_staff: Dictionary = _assessment(pilot,planner,weather,{},{"Engenheiro":3})
	check(low_staff.state == high_staff.state and low_staff.priority == high_staff.priority,
		"staff quality changes presentation, not observed facts or urgency")
	check(low_staff.style == "OBJETIVO" and high_staff.style == "ANALÍTICO",
		"staff profile changes engineer communication style")
	check(str(high_staff.basis).contains("graining") and
		not str(low_staff.basis).contains("graining"),
		"analytic engineer provides measured thermal context")
	var booked: Dictionary = pilot.duplicate(true)
	booked["pit_scheduled_lap"] = 21
	var storm: Dictionary = {"wetness_factor":0.83}
	var guarded: Dictionary = _assessment(booked,planner,storm,
		{"pit_scheduled_lap":21},{"Engenheiro":3})
	check(guarded.state == "BOX MANUAL PROTEGIDO"
		and str(guarded.radio).contains("V21")
		and not guarded.can_call_pit,
		"manual BOX V21 remains protected under 83 percent rain")
	check(str(guarded.team_note).contains("Companheiro"),
		"simultaneous teammate booking warns about potential garage conflict")
	var mismatched: Dictionary = _assessment(pilot,planner,storm)
	check(mismatched.state == "PNEU INCOMPATÍVEL" and mismatched.priority == 3,
		"slick on wet track produces caution but no automatic stop")
	var worn: Dictionary = pilot.duplicate(true)
	worn["wear"] = 89.0
	check(_assessment(worn,planner,weather).state == "DESGASTE ELEVADO",
		"measured high wear prioritized over routine traffic")
	var hot: Dictionary = pilot.duplicate(true)
	hot["tyre_graining"] = 0.42
	check(_assessment(hot,planner,weather).state == "SUPERFÍCIE DO PNEU",
		"real graining supports thermal advisory")
	var forecast: Dictionary = planner.duplicate(true)
	forecast["forecast_3"] = 0.49
	check(_assessment(pilot,forecast,weather).state == "TENDÊNCIA METEOROLÓGICA"
		and str(_assessment(pilot,forecast,weather).reason).contains("incerta"),
		"forecast is labelled uncertain, not mistaken for observation")
	var slow: Dictionary = pilot.duplicate(true)
	slow["interval"] = 4.0
	slow["last_lap"] = 93.0
	check(_assessment(slow,planner,weather).state == "PERDA DE RITMO OBSERVADA"
		and str(_assessment(slow,planner,weather).reason).contains("sem atribuição causal"),
		"pace comparison cannot invent a causal diagnosis")
	var blind: Dictionary = slow.duplicate(true)
	blind["best_lap"] = 0.0
	check(_assessment(blind,planner,weather).state == "MONITORAR"
		and _assessment(blind,planner,weather).confidence == "LIMITADA",
		"unconfirmed lap is not treated as measured pace loss")
	var done: Dictionary = pilot.duplicate(true)
	done["finished"] = true
	check(_assessment(done,planner,storm).state == "FINALIZADO",
		"finished car cannot receive racing orders")
	var in_pit: Dictionary = pilot.duplicate(true)
	in_pit["pit_request"] = true
	check(_assessment(in_pit,planner,weather).state == "BOX EM CURSO",
		"existing pit procedure takes precedence")
	var coordinated: Dictionary = planner.duplicate(true)
	coordinated["staff_strategy_066910"] = {"recommendation":"MANTER PLANO"}
	check(str(_assessment(pilot,coordinated).strategy_note).contains("MANTER PLANO"),
		"engineer faithfully attributes strategist advice without replacing it")

	var previous: Dictionary = {"can_call_pit":true}
	var base: Dictionary = Engineer3.assess(booked,previous,
		planner,storm,{},{"Engenheiro":3,"Estrategista":2},
		["Macio","Médio","Intermediário","Chuva"],50,22.0,90.0,5)
	check(base.engineer_version == "3.0"
		and not base.can_call_pit and str(base.pit_gate).contains("V21"),
		"original 3.0 pit gate is preserved with advisory extension")
	check(str(base.intelligence_066913.radio).contains("V21"),
		"radio consumes the same protected booking evidence")
	check(Engineer3.answer(base,"engenheiro").contains("ENGENHEIRO 9.13")
		and Engineer3.answer(base,"not_a_question").contains("desconhecida"),
		"new radio consultation is supported; unknown topics still rejected")
	check(Engineer3.answer(base,"plano").contains("V21"),
		"existing engineer questions keep original data")

	var season_data: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not season_data is Dictionary:
		check(false,"2012 season must be available")
		_finish()
		return
	var season: Dictionary = season_data
	var race = Race.new(season.teams,"Ferrari",6613,{},season.tracks[0],{})
	var own: Dictionary = race.player_cars()[0]
	var id: int = int(own["id"])
	check(race.player_cars().size() == 2 and race.cars.size() == 24,
		"real 2012 simulation exposes two player cars and 24 drivers")
	check(race.schedule_pit(id,str(race.available_pit_compounds()[1]),21),
		"real manual pit V21 accepted")
	race.configure_weather("Chuva intensa")
	var sport_before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
	var rng_before: int = race.rng.state
	var native: Dictionary = Engineer3.assess(own,previous,race.get_engineer_advice(id),
		race.weather_snapshot(),race.player_cars()[1],
		{"Engenheiro":3,"Estrategista":3},race.available_pit_compounds(),
		race.lap_count,race.pit_loss,race.base_lap,race._next_pit_entry_lap(own))
	check(int(own.pit_scheduled_lap) == 21 and not native.can_call_pit
		and str(native.intelligence_066913.radio).contains("V21"),
		"real wet simulation guards the player booking")
	check(sport_before == var_to_bytes(race.get_state_snapshot())
		and rng_before == race.rng.state,
		"read-only report does not change sporting state or RNG")
	var replay = Replay.new()
	replay.attach(race)
	check(replay.recorded_simulation_revision == Replay.SIMULATION_REVISION,
		"replay revision remains 023 because 9.13 is presentation-only")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	var hud = game.race_hud_0620
	hud._open_window("engineer")
	await process_frame
	hud._update_engineer_reports()
	check(hud.engineer_cards.size() == 2,
		"existing HUD still shows both engineer cards")
	for card in hud.engineer_cards:
		check(card.has("ask_intelligence")
			and str(card.evidence.text).contains("ENGENHEIRO 9.13"),
			"engineer intelligence appears in the HUD with its radio control")
	var active: Dictionary = game.race.player_cars()[0]
	var ui_id: int = int(active.id)
	var ui_rng: int = game.race.rng.state
	var ui_scheduled: int = int(active.get("pit_scheduled_lap",0))
	hud._engineer_ask(ui_id,"engenheiro")
	check(str(hud.engineer_radio_answers.get(ui_id,"")).contains("ENGENHEIRO 9.13"),
		"new engineer radio presents measured assessment")
	check(game.race.rng.state == ui_rng
		and int(active.get("pit_scheduled_lap",0)) == ui_scheduled
		and not bool(active.get("pit_request",false)),
		"new HUD radio sends no hidden race commands")
	game.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("ENGINEER_066913_PASS checks=%d read_only=true" % checks)
	else:
		for message in failures:
			printerr("FAIL: " + message)
	quit(0 if failures.is_empty() else 1)
