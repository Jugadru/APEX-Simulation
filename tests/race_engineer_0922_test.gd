extends SceneTree
const Bus = preload("res://scripts/presentation/race_communication_0922.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const Career = preload("res://scripts/core/race_engineer_career_0922.gd")
const Audio = preload("res://scripts/presentation/race_radio_audio_0922.gd")
var failures: Array[String] = []
var checks: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("ENGINEER_0922_FAIL ", label)
func run() -> void:
	var b = Bus.new()
	check(Bus.is_system("Modo automático ativado"), "PT settings silence")
	check(Bus.is_system("Auto mode activated"), "EN settings silence")
	check(Bus.is_system("STAFF | controle individual: Manual."), "control event silence")
	check(Bus.is_system("Alonso: controle de box IA. Ordem manual agendada permanece válida.", "strategy"), "pit mode silence")
	check(not Bus.is_system("Box this lap.", "radio"), "real orders remain")
	var car: Dictionary = {"id": 5, "wear": 20.0, "tire": "Médio", "pit_scheduled_lap": 21}
	var wet: Dictionary = {"wetness_factor": .8}
	var dry: Dictionary = {"wetness_factor": 0.0}
	check(Bus.diagnose(car, wet).cause == "WET_MISMATCH", "wet contextual diagnosis")
	check(Bus.diagnose(car, dry).cause == "UNKNOWN", "uncertain diagnosis")
	check(Bus.answer("estrategia", car, wet).contains("21"), "manual booking visible")
	for kind in Bus.ERROR_WORDS:
		car["driver_error_0921"] = {"mode":"RECOVERY","kind":kind}
		check(Bus.diagnose(car, dry).advice == Bus.ERROR_WORDS[kind], "six types " + str(kind))
	car.erase("driver_error_0921")
	var before: Dictionary = car.duplicate(true)
	b.observe(car, wet, 20.0)
	check(car == before, "observation pure")
	check(b.drain(20.0).size() == 1, "context emitted")
	b.observe(car, wet, 22.0)
	check(b.drain(22.0).is_empty(), "same condition not repeated")
	b.reset()
	check(b.offer(5,"INFO","Information",3,0.0), "queue info")
	check(b.offer(6,"RAIN","Rain risk",1,0.0), "queue urgent")
	var batch: Array = b.drain(0.0)
	check(batch.size()==2 and int(batch[0].priority)==1, "priority order")
	check(not b.offer(5,"INFO","Information",3,1.0), "cooldown")
	b.offer(5,"EXPIRED","Old news",3,1.0)
	check(b.drain(50.0).is_empty(), "expiry")
	for i in range(50):
		b.offer(5,"INFO","Information",3,100.0 + i * 20.0)
		b.drain(100.0 + i * 20.0)
	check(b.history[5].size() == Bus.MAX_HISTORY, "bounded memory")
	check(b.history[6].size() == 1, "independent memories")
	check(not bool(b.history[5][-1].command_authorized), "no commands")
	b.reset()
	var racer: Dictionary = {"id": 5, "team": "Ferrari", "position": 4, "driver_soul": {"pressure": .1, "confidence": .8}}
	var rival: Dictionary = {"id": 1, "team": "Red Bull", "name": "Vettel"}
	var pass_event: Dictionary = {"type": "pass", "event_id": 120, "time": 100.0, "message": "ULTRAPASSAGEM CONFIRMADA | Vettel consolidou P3."}
	b.on_pass(racer, pass_event, {"engineer_radio_style": "DEADPAN"})
	var dialogue: Array = b.drain(100.0)
	check(dialogue.size() == 2, "banter paired")
	if dialogue.size() == 2:
		check(dialogue[0].conversation_id == dialogue[1].conversation_id and dialogue[0].sender == "PILOTO" and dialogue[1].sender == "ENGENHEIRO", "conversation order")
		check(dialogue[0].voice_profile_id != dialogue[1].voice_profile_id, "distinct voice profiles")
	b.on_rival_pass(racer, rival, pass_event, 100.0, {"engineer_radio_style": "DEADPAN"})
	var rivals: Array = b.drain(100.0)
	check(rivals.size() == 1 and str(rivals[0].text).contains("Vettel") and str(rivals[0].text).contains("P3"), "verified nearby rival pass")
	b.on_rival_pass(racer, rival, pass_event, 130.0)
	check(b.drain(130.0).is_empty(), "stale event rejected")
	var hot: Dictionary = {"id": 8, "wear": 15.0, "tire": "Médio", "tyre_surface_c": 130.0}
	b.observe(hot, dry, 140.0, {"Engenheiro":3})
	check(b.drain(140.0).is_empty(), "sustained evidence required")
	b.observe(hot, dry, 142.0, {"Engenheiro":3})
	check(b.drain(142.0).size() == 1, "competence changes communication latency")
	hot["tyre_surface_c"] = 95.0
	b.observe(hot, dry, 144.0, {"Engenheiro":3})
	check(b.drain(144.0).size() == 1, "condition follow-up")
	var team: Dictionary = {"staff_roster":{"Engenheiro":{"id":"eng_c","name":"Davi Amaral","skill":91}},"staff_soul":{}}
	var staff: Dictionary = Career.staff_context(team, {"Engenheiro":3})
	check(staff.engineer_radio_style == "DEADPAN" and staff.engineer_contract_id == "eng_c", "contract voice mapping")
	check(Career.settle(team, staff, [racer], {5:{"followups":2,"exchanges":1}}, 1, 1), "career bond saved")
	check(int(Career.read_bonds(team).get("eng_c|5", 0)) == 53, "career pair value")
	check(not Career.settle(team, staff, [racer], {5:{"followups":2}}, 1, 1), "career settlement idempotent")
	check(Career.pair_key({"engineer_contract_id":"eng_b"}, racer) != Career.pair_key(staff, racer), "contract identity isolation")
	var c = Commentary.new()
	c.reset(42)
	c.configure_engineer(team, {"Engenheiro":3})
	c.add_team_question(20.0, "Pneus?", "Driver", "Pass confirmed. Build the gap now.", 5)
	check(c.communication.history[5].size() == 2, "legacy consultations share packet history")
	check(str(c.lines[-1].context_0922.voice_profile_id).contains("eng_c"), "contract linked delivery")
	check(c.formatted(2,5).contains("Ultrapassagem confirmada"), "Portuguese subtitle")
	c.radio_subtitles = false
	check(not c.formatted(2,5).contains("Ultrapassagem confirmada"), "subtitle setting")
	var audio = Audio.new()
	if DisplayServer.get_name() == "headless":
		check(not audio.set_enabled(true), "headless speech unavailable without error")
	audio.enqueue({"sender":"ENGENHEIRO","text":"Test","priority":3})
	check(audio.queue.is_empty(), "disabled audio never queues")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = data.tracks[0]
	var track_code: String = OS.get_environment("APEX_ENGINEER_TRACK")
	for item in data.tracks:
		if str(item.get("code", "")) == track_code:
			track = item
			break
	var climate: String = OS.get_environment("APEX_ENGINEER_CLIMATE")
	if climate.is_empty():
		climate = "Seco"
	var seed: int = int(OS.get_environment("APEX_ENGINEER_SEED"))
	if seed == 0:
		seed = 42
	var ticks: int = maxi(240, int(OS.get_environment("APEX_ENGINEER_TICKS")))
	var a = Race.new(data.teams, "Ferrari", seed, {}, track, {})
	var reference = Race.new(data.teams, "Ferrari", seed, {}, track, {})
	a.configure_weather(climate)
	reference.configure_weather(climate)
	a.running = true
	reference.running = true
	var commentary = Commentary.new()
	commentary.reset(seed)
	var driver: Dictionary = a.player_cars()[0]
	var player_id: int = int(driver.id)
	driver["pit_scheduled_lap"] = 21
	reference.player_cars()[0]["pit_scheduled_lap"] = 21
	check(not commentary._event_line({"type":"strategy","message":"Modo automático ativado","driver_id":player_id,"priority":75,"time":0.0},a,"Ferrari"), "real dispatcher suppresses system")
	var engine_us: int = 0
	var reference_us: int = 0
	var observer_us: int = 0
	for i in range(ticks):
		var start: int = Time.get_ticks_usec()
		a.step(.2)
		engine_us += Time.get_ticks_usec() - start
		start = Time.get_ticks_usec()
		reference.step(.2)
		reference_us += Time.get_ticks_usec() - start
		if i % 3 == 0:
			start = Time.get_ticks_usec()
			commentary.ingest(a,"Ferrari")
			observer_us += Time.get_ticks_usec() - start
	check(Codec.sporting_hash(a,{}) == Codec.sporting_hash(reference,{}), "presentation sporting hash parity")
	check(a.rng.state == reference.rng.state, "RNG parity")
	check(int(driver.pit_scheduled_lap) == 21, "BOX V21")
	print("ENGINEER_0922_REPORT ", JSON.stringify({"checks":checks,"failures":failures,"track":str(track.get("code","")),"climate":climate,"seed":seed,"ticks":ticks,"engine_us":engine_us,"reference_us":reference_us,"observer_us":observer_us,"observer_overhead_percent":100.0 * float(observer_us) / maxf(1.0,float(engine_us))}))
	if failures.is_empty():
		print("ENGINEER_0922_PASS")
	quit(0 if failures.is_empty() else 1)
