extends SceneTree
## Execute: godot --headless --path . --script res://tests/core_0630_driver_radio_smoke_test.gd
const Feedback = preload("res://scripts/core/race_driver_feedback.gd")
const RaceScript = preload("res://scripts/race_engine.gd")
const CommentaryScript = preload("res://scripts/apex_commentary.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("APEX 0630 FALHA: " + message)
	quit(1)

func _run() -> void:
	var car: Dictionary = {"name": "Piloto de teste", "tire": "Médio", "wear": 83.0,
		"laps_done": 12, "stint_laps": 10, "driver_radio_last_lap": -100,
		"tyre_heat": 0.20, "position": 2, "interval": 3.3,
		"pit_left": 0.0, "finished": false, "pit_request": false}
	var dry: Dictionary = {"wetness_factor": 0.0}
	var spec: Dictionary = {"cliff": 76.0}
	var result: Dictionary = Feedback.assess(car, dry, spec)
	if str(result.get("kind", "")) != "aderencia":
		_fail("Pneu desgastado nao gerou radio")
		return
	if bool(car["pit_request"]):
		_fail("Radio alterou comando de box")
		return
	car["driver_radio_last_lap"] = 12
	if not Feedback.assess(car, dry, spec).is_empty():
		_fail("Falta cooldown de radio")
		return
	car["laps_done"] = 16
	var wet: Dictionary = {"wetness_factor": 0.82}
	result = Feedback.assess(car, wet, spec)
	if str(result.get("kind", "")) != "grip_molhado":
		_fail("Radio ignorou pneu seco em pista molhada")
		return
	car["tire"] = "Chuva"
	car["wear"] = 20.0
	result = Feedback.assess(car, dry, spec)
	if str(result.get("kind", "")) != "chuva_secando":
		_fail("Radio ignorou secagem da pista")
		return
	car["finished"] = true
	if not Feedback.assess(car, dry, spec).is_empty():
		_fail("Piloto finalizado nao deve reportar")
		return
	var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not (season is Dictionary):
		_fail("Dados da temporada ausentes")
		return
	var track: Dictionary = {}
	for entry in season["tracks"]:
		if str(entry.get("code", "")) == "BEL":
			track = entry
			break
	if track.is_empty():
		_fail("Spa nao encontrada")
		return
	var race = RaceScript.new(season["teams"], "Ferrari", 630, {}, track, {})
	race.configure_weather("Seco")
	var player: Dictionary = race.player_cars()[0]
	player["laps_done"] = 12
	player["stint_laps"] = 10
	player["wear"] = 84.0
	player["tyre_heat"] = 0.1
	player["interval"] = 4.0
	if not race.schedule_pit(int(player["id"]), "Médio", 21):
		_fail("Agendamento V21 falhou")
		return
	var before_events: int = race.events.size()
	race._on_lap_cross(player)
	if int(player.get("pit_scheduled_lap", 0)) != 21 or bool(player.get("pit_request", false)):
		_fail("Radio ou engenheiro antecipou box V21")
		return
	var seen: bool = false
	for i in range(before_events, race.events.size()):
		if str(race.events[i].get("type", "")) == "driver_radio":
			seen = true
			break
	if not seen:
		_fail("Evento driver_radio nao chegou ao motor")
		return
	var narrator = CommentaryScript.new()
	narrator.reset(630)
	narrator.ingest(race, "Ferrari")
	if not narrator.formatted(2).contains("RÁDIO FICTÍCIO"):
		_fail("Radio do piloto nao aparece no filtro da equipe")
		return
	if narrator.formatted(1).contains("RÁDIO FICTÍCIO"):
		_fail("Radio do piloto aparece indevidamente no filtro de transmissao")
		return
	print("APEX 0.6.3.0 RADIO PASS — factual, cooldown, pit manual V21 e filtros")
	quit(0)
