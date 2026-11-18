extends SceneTree
## Team radio 06689: deterministic advice based on completed-lap evidence.
const Advice = preload("res://scripts/core/race_team_radio_advice_06689.gd")
const Race = preload("res://scripts/race_engine.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("TEAM_RADIO_06689_FAIL: " + message)
func car(id: int, pos: int, lap_time: float) -> Dictionary:
	return {"id": id, "team": "Ferrari", "name": "Piloto " + str(id), "position": pos,
		"interval": 0.75, "last_lap": lap_time, "laps_done": 8,
		"wear": 36.0, "tire": "Médio", "finished": false,
		"pit_request": false, "pit_left": 0.0, "pit_scheduled_lap": 0,
		"driver_soul": {"team_streak": 3}}
func run() -> void:
	var rear: Dictionary = car(11, 7, 98.9)
	var ahead: Dictionary = car(12, 6, 100.1)
	var dry := {"wetness_factor": 0.02}
	var before: PackedByteArray = var_to_bytes([rear, ahead, dry])
	var answer: Dictionary = Advice.evaluate(rear, ahead, dry)
	check(bool(answer.valid), "Comparable team cars")
	check(str(answer.state) == "avaliar_passagem", "Sustained pace edge requests review")
	check(absf(float(answer.pace_edge_s) - 1.2) < 0.001, "Pace edge derived from actual laps")
	check(float(answer.gap_s) == 0.75, "Gap from chasing car")
	check(int(answer.chasing_id) == 11 and int(answer.leading_id) == 12, "Direction and IDs")
	check(str(answer.driver).contains("1.20s"), "Pilot cites measured pace")
	check(str(answer.engineer).contains("nenhuma ordem"), "Explicitly consultation only")
	check(bool(answer.read_only), "Pure advice")
	check(var_to_bytes([rear, ahead, dry]) == before, "No race data mutation")
	check(Advice.evaluate(rear, ahead, dry) == answer, "Repeat deterministic")
	var leader: Dictionary = Advice.evaluate(ahead, rear, dry)
	check(leader.state == "avaliar_passagem", "Leader hears challenge from teammate")
	check(str(leader.driver).contains("atrás"), "Leader phrasing distinguishes direction")
	var weak: Dictionary = rear.duplicate(true)
	weak.driver_soul.team_streak = 1
	check(Advice.evaluate(weak, ahead, dry).state == "aguardar_confirmacao", "Require two laps evidence")
	weak.driver_soul.team_streak = 3
	weak.last_lap = 99.9
	check(Advice.evaluate(weak, ahead, dry).state == "manter_posicoes", "Do not exaggerate advantage")
	var far: Dictionary = rear.duplicate(true)
	far.interval = 2.1
	check(not Advice.evaluate(far, ahead, dry).valid, "Distant teammate is not adjacent passing")
	var wrong: Dictionary = ahead.duplicate(true)
	wrong.team = "McLaren"
	check(not Advice.evaluate(rear, wrong, dry).valid, "Never compare rival team")
	var positions: Dictionary = ahead.duplicate(true)
	positions.position = 2
	check(not Advice.evaluate(rear, positions, dry).valid, "Do not use gap of unrelated position")
	var weather: Dictionary = {"wetness_factor": 0.84}
	check(Advice.evaluate(rear, ahead, weather).state == "cautela_aderencia", "Worn slick caution in heavy rain")
	var wet_tyres: Dictionary = rear.duplicate(true)
	wet_tyres.tire = "Chuva"
	check(Advice.evaluate(wet_tyres, ahead, weather).state == "avaliar_passagem", "Wets with safe wear may ask for review")
	wet_tyres.wear = 75.0
	check(Advice.evaluate(wet_tyres, ahead, weather).state == "cautela_aderencia", "Worn wets still caution")
	var pits: Dictionary = rear.duplicate(true)
	pits.pit_request = true
	check(Advice.evaluate(pits, ahead, dry).state == "box_em_andamento", "Pit active takes precedence")
	var scheduled: Dictionary = rear.duplicate(true)
	scheduled.pit_scheduled_lap = 21
	var adv: Dictionary = Advice.evaluate(scheduled, ahead, dry)
	check(adv.state == "avaliar_passagem", "Booking does not silently prohibit radio request")
	check(str(adv.engineer).contains("V21") and str(adv.engineer).contains("permanece"), "Respect manual booking")
	check(scheduled.pit_scheduled_lap == 21 and not scheduled.pit_request, "V21 remains untouched")
	var no_time: Dictionary = rear.duplicate(true)
	no_time.last_lap = 0.0
	check(not Advice.evaluate(no_time, ahead, dry).valid, "No fake timing")
	var limited: Dictionary = rear.duplicate(true)
	limited.laps_done = 1
	check(not Advice.evaluate(limited, ahead, dry).valid, "Out lap is not evidence")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = (season.tracks as Array)[0]
	var engine = Race.new(season.teams, "Ferrari", 6689, {}, track, {})
	var a: Dictionary = engine.player_cars()[0]
	var b: Dictionary = engine.player_cars()[1]
	var sport_before: PackedByteArray = var_to_bytes(engine.get_state_snapshot())
	var irrelevant: Dictionary = Advice.evaluate(a, b, engine.weather_snapshot())
	check(bool(irrelevant.read_only), "Evaluates native race data safely")
	check(sport_before == var_to_bytes(engine.get_state_snapshot()), "No engine mutation from advisor")
	if failures == 0:
		print("TEAM_RADIO_06689_PASS checks=%d read_only=true V21=protected" % checks)
	quit(0 if failures == 0 else 1)
