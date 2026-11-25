extends SceneTree
const Bus = preload("res://scripts/presentation/race_communication_0922.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
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
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var a = Race.new(data.teams, "Ferrari", 42, {}, data.tracks[0], {})
	var reference = Race.new(data.teams, "Ferrari", 42, {}, data.tracks[0], {})
	a.configure_weather("Seco")
	reference.configure_weather("Seco")
	a.running = true
	reference.running = true
	var commentary = Commentary.new()
	commentary.reset(42)
	var driver: Dictionary = a.player_cars()[0]
	var player_id: int = int(driver.id)
	driver["pit_scheduled_lap"] = 21
	reference.player_cars()[0]["pit_scheduled_lap"] = 21
	check(not commentary._event_line({"type":"strategy","message":"Modo automático ativado","driver_id":player_id,"priority":75,"time":0.0},a,"Ferrari"), "real dispatcher suppresses system")
	for i in range(240):
		a.step(.2)
		reference.step(.2)
		if i % 3 == 0:
			commentary.ingest(a,"Ferrari")
	check(Codec.sporting_hash(a,{}) == Codec.sporting_hash(reference,{}), "presentation sporting hash parity")
	check(a.rng.state == reference.rng.state, "RNG parity")
	check(int(driver.pit_scheduled_lap) == 21, "BOX V21")
	print("ENGINEER_0922_REPORT ", JSON.stringify({"checks":checks,"failures":failures}))
	if failures.is_empty():
		print("ENGINEER_0922_PASS")
	quit(0 if failures.is_empty() else 1)
