extends SceneTree
const SeasonScript = preload("res://scripts/championship_2012.gd")
const TEST_PATH := "user://apex_0600_smoke_temporary.json"

func _initialize() -> void:
	call_deferred("run_test")

func fail(message: String) -> void:
	push_error("APEX 0600 SMOKE: " + message)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	quit(1)

func run_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if typeof(fixture) != TYPE_DICTIONARY:
		fail("Dados da temporada invalidos.")
		return
	var season = SeasonScript.new(TEST_PATH)
	if not season.start_new("Ferrari", 42, fixture["tracks"], fixture["teams"]):
		fail("Nao salvou temporada nova")
		return
	if season.is_complete() or str(season.next_round().get("code", "")) != str(fixture["tracks"][0]["code"]):
		fail("Proxima etapa incorreta")
		return
	var ranking: Array = []
	for team in fixture["teams"]:
		for driver in team["drivers"]:
			ranking.append({"name": str(driver["name"]), "team": str(team["name"]), "best_lap": 90.0, "stops": 1})
	if ranking.size() != 24:
		fail("Grid nao possui 24 pilotos")
		return
	var first: Dictionary = season.record_result(fixture["tracks"][0], ranking, 6000.0)
	if not bool(first.get("ok", false)):
		fail("Resultado do GP1 nao foi registrado: " + str(first))
		return
	if bool(season.record_result(fixture["tracks"][0], ranking, 6000.0).get("ok", false)):
		fail("GP1 contabilizado duas vezes")
		return
	var restored = SeasonScript.new(TEST_PATH)
	if int(restored.state.get("round_index", 0)) != 1 or int(restored.standings("drivers")[0]["points"]) != 25:
		fail("Salvamento/pontos nao foram recuperados")
		return
	if restored.round_seed() != 42 + 7919:
		fail("Semente nao foi avancada")
		return
	for i in range(1, fixture["tracks"].size()):
		if not bool(restored.record_result(fixture["tracks"][i], ranking, 6000.0).get("ok", false)):
			fail("Falha na etapa " + str(i + 1))
			return
	if not restored.is_complete() or restored.state["results"].size() != 20:
		fail("Finalizacao do campeonato incorreta")
		return
	if int(restored.standings("drivers")[0]["points"]) != 500:
		fail("Pontos acumulados incorretos")
		return
	if not restored.next_round().is_empty():
		fail("Retornou proxima etapa apos o fim")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("PASS 0600: 20 etapas, 24 pilotos, pontos 2012, retomada do save, sem GP duplicado")
	quit(0)
