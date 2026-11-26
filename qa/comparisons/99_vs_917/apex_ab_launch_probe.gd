extends SceneTree
## Identical 2012 Core 2 A/B measurement code injected in both Git checkouts.
## Never edits sporting state beyond the same weather setup and running flag.
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

func _initialize() -> void:
	call_deferred("_run")

func _positions(race) -> Dictionary:
	var ordered: Array = race.get_sorted()
	var ranks: Dictionary = {}
	for i in range(ordered.size()):
		ranks[str(int(ordered[i].get("id", -1)))] = i + 1
	return ranks

func _snapshot(race) -> Dictionary:
	var ranked: Dictionary = _positions(race)
	var cars: Array = []
	for car in race.cars:
		cars.append({"id":int(car.get("id", -1)),
			"grid":int(car.get("grid", -1)),
			"rank":int(ranked.get(str(int(car.get("id", -1))), -1)),
			"progress":snappedf(float(car.get("progress", 0.0)), 0.0000001),
			"lane":snappedf(float(car.get("race_lane", 0.0)), 0.0001),
			"speed_target":snappedf(float(car.get("current_pace_target", 0.0)), 0.0001)})
	cars.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
	return {"cars":cars,"clock":snappedf(float(race.clock), 0.00001)}

func _unsafe_pairs(race) -> int:
	var count: int = 0
	var length: float = float(race.space_profile.get("length", 1000.0))
	for i in range(race.cars.size()):
		var a: Dictionary = race.cars[i]
		for j in range(i + 1, race.cars.size()):
			var b: Dictionary = race.cars[j]
			if absf(float(a.get("progress", 0.0)) - float(b.get("progress", 0.0))) * length < 6.35 \
					and absf(float(a.get("race_lane", 0.0)) - float(b.get("race_lane", 0.0))) < 2.91:
				count += 1
	return count

func _simulate(teams: Array, track: Dictionary, climate: String, seed: int) -> Dictionary:
	var race = Race.new(teams, "Ferrari", seed, {}, track, {})
	race.configure_weather(climate)
	var original_grid: Dictionary = _positions(race)
	var first_rank: Dictionary = {}
	for car in race.cars: first_rank[str(int(car.get("id", -1)))] = int(car.get("grid", 0))
	race.running = true
	var stage: Dictionary = {}
	var unsafe_tick_samples: int = 0
	var max_unsafe_pairs: int = 0
	var no_forward_ticks: int = 0
	var last_progress: Dictionary = {}
	for car in race.cars:
		last_progress[str(int(car.get("id", -1)))] = float(car.get("progress", 0.0))
	for tick in range(90):
		race.step(0.2)
		var pair_count: int = _unsafe_pairs(race)
		if pair_count > 0:
			unsafe_tick_samples += 1
			max_unsafe_pairs = maxi(max_unsafe_pairs, pair_count)
		if tick >= 10:
			for car in race.cars:
				var ident: String = str(int(car.get("id", -1)))
				if float(car.get("progress", 0.0)) - float(last_progress.get(ident, -1.0)) < 0.00000001:
					no_forward_ticks += 1
				last_progress[ident] = float(car.get("progress", 0.0))
		if tick == 9: stage["2s"] = _snapshot(race)
		if tick == 39: stage["8s"] = _snapshot(race)
		if tick == 89: stage["18s"] = _snapshot(race)
	var ranking: Dictionary = _positions(race)
	var abs_movement: int = 0
	var gained: int = 0
	var biggest_gain: int = 0
	var biggest_loss: int = 0
	var changed_cars: int = 0
	for car in race.cars:
		var ident: String = str(int(car.get("id", -1)))
		var delta: int = int(first_rank[ident]) - int(ranking[ident])
		abs_movement += abs(delta)
		if delta > 0: gained += delta
		biggest_gain = maxi(biggest_gain, delta)
		biggest_loss = maxi(biggest_loss, -delta)
		if delta != 0: changed_cars += 1
	var events: Dictionary = {}
	for event in race.telemetry.event_history:
		var kind: String = str(event.get("type", ""))
		events[kind] = int(events.get(kind, 0)) + 1
	var violations: Array[String] = []
	if race.cars.size() != 24: violations.append("not_24_cars")
	if not is_equal_approx(float(race.clock), 18.0): violations.append("wrong_18s_window")
	if not race.running or race.finished: violations.append("invalid_start_state")
	for car in race.cars:
		if not is_finite(float(car.get("progress", -1.0))): violations.append("nonfinite_progress")
		if not is_finite(float(car.get("wear", -1.0))): violations.append("nonfinite_wear")
		if int(car.get("stops", 0)) > 0: violations.append("pit_during_first_18s")
	return {
		"track":str(track.get("code", "")),"weather":climate,"seed":seed,
		"cars":race.cars.size(),"grid":first_rank,"initial_ranks":original_grid,
		"stages":stage,"ranks":ranking,
		"abs_position_changes":abs_movement,"places_gained":gained,
		"changed_cars":changed_cars,"max_gain":biggest_gain,"max_loss":biggest_loss,
		"events":events,"unsafe_tick_samples":unsafe_tick_samples,
		"max_unsafe_pairs":max_unsafe_pairs,"no_forward_ticks":no_forward_ticks,
		"min_wetness":snappedf(float(race.weather_snapshot().get("wetness_factor", 0.0)), 0.0001),
		"hash":Codec.sporting_hash(race, {}),"violations":violations}

func _run() -> void:
	var season_value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not season_value is Dictionary:
		printerr("APEX_AB_START_FAIL season")
		quit(1)
		return
	var season: Dictionary = season_value
	var failures: Array[String] = []
	if season["teams"].size() != 12 or season["tracks"].size() != 20:
		failures.append("season_2012 roster != 12 teams / 20 tracks")
	var cases: Array = []
	var repeat_failures: int = 0
	for track in season["tracks"]:
		for weather in ["Seco", "Chuva intensa"]:
			var seed: int = 6617 + int(track.get("laps", 44)) * 3
			var result: Dictionary = _simulate(season["teams"], track, weather, seed)
			if not (result.get("violations", []) as Array).is_empty():
				failures.append(str(track.get("code","")) + "/" + weather + " " + str(result["violations"]))
			# Targeted repeat under identical input to test per-version determinism.
			if str(track.get("code","")) in ["GBR", "MON", "ITA", "BEL"]:
				var rerun: Dictionary = _simulate(season["teams"], track, weather, seed)
				if result != rerun:
					repeat_failures += 1
					failures.append(str(track.get("code","")) + "/" + weather + " repeat mismatch")
			cases.append(result)
	var report: Dictionary = {"status":"PASS" if failures.is_empty() else "FAIL",
		"case_count":cases.size(),"repeated_cases":8,"repeat_failures":repeat_failures,
		"failures":failures,"cases":cases,
		"scope":"20 tracks x 2 climates, 18 simulated seconds / 24 cars; 8 identical-seed repeats; schematic physics, headless"}
	var output: String = OS.get_environment("APEX_AB_OUTPUT")
	if output.is_empty():
		printerr("APEX_AB_START_FAIL missing output path")
		quit(1)
		return
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("APEX_AB_START_FAIL cannot write " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("APEX_AB_STARTS ", JSON.stringify({"status":report["status"],"cases":cases.size(),
		"repeat_failures":repeat_failures,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
