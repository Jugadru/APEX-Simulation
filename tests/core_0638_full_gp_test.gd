extends SceneTree
const RaceScript = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, explanation: String) -> void:
	if not ok:
		failures.append(explanation)
		printerr("APEX 0638 FULL GP FAILURE: ", explanation)
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var code: String = "BRA"
	var wet_mode: String = "Seco"
	var manual: bool = true
	var options: PackedStringArray = OS.get_cmdline_user_args()
	if options.size() > 0:
		code = options[0]
	if options.size() > 1:
		wet_mode = options[1]
	if options.size() > 2:
		manual = options[2] == "manual"
	var target: Dictionary = {}
	for track in season["tracks"]:
		if str(track["code"]) == code:
			target = track
	check(not target.is_empty(), "track available")
	if target.is_empty():
		quit(1)
		return
	var race = RaceScript.new(season["teams"], "Ferrari", 321, {"Motor":1, "Asa":1, "Chassi":1}, target, {"Agilidade":1, "Precisão":1})
	race.configure_weather(wet_mode)
	var player: Array = race.player_cars()
	var alonso_id: int = int(player[0]["id"])
	var massa_id: int = int(player[1]["id"])
	for entry in player:
		if str(entry["name"]).contains("Alonso"):
			alonso_id = int(entry["id"])
		elif str(entry["name"]).contains("Massa"):
			massa_id = int(entry["id"])
	if manual:
		check(race.schedule_pit(alonso_id, "Duro" if code == "BRA" else str(race.available_pit_compounds()[1]), 23), "Alonso scheduled pit 23")
		check(race.schedule_pit(massa_id, "Duro" if code == "BRA" else str(race.available_pit_compounds()[1]), 25), "Massa scheduled pit 25")
	else:
		for entry in player:
			race.set_pit_control_mode(int(entry["id"]), "IA")
	race.running = true
	var steps: int = 0
	var second_orders: bool = false
	var scanned: bool = false
	while not race.finished and steps < 16000:
		race.step(4.0)
		steps += 1
		if manual and not scanned and race.lap >= 5:
			scanned = true
			for c in race.player_cars():
				if int(c["id"]) == alonso_id:
					check(int(c.get("pit_scheduled_lap", -1)) == 23, "V23 not fired early")
		if manual and not second_orders and race.lap >= 30:
			second_orders = true
			check(race.schedule_pit(alonso_id, "Médio" if code == "BRA" else str(race.available_pit_compounds()[0]), 48), "Alonso scheduled pit 48")
			check(race.schedule_pit(massa_id, "Médio" if code == "BRA" else str(race.available_pit_compounds()[0]), 50), "Massa scheduled pit 50")
	check(race.finished, "race finished")
	check(race.finish_results_validated, "finish results generated")
	var ordered: Array = race.get_sorted()
	check(ordered.size() == 24, "24 cars classified")
	var lead: Dictionary = ordered[0]
	var validated_laps: int = 0
	var lapped_cars: int = 0
	var suspicious_laps: int = 0
	for i in range(ordered.size()):
		var car: Dictionary = ordered[i]
		check(int(car["position"]) == i+1, "position ordinal " + str(car["name"]))
		check(float(car["best_lap"]) > float(target["base_lap"]) * 0.70, "best lap plausible " + str(car["name"]))
		check(int(car["finish_laps"]) > 0, "finish lap exists " + str(car["name"]))
		if int(car["finish_laps"]) == int(lead["finish_laps"]) and float(car["finish_time"]) >= 0.0:
			validated_laps += 1
			check(absf(float(car["gap"]) - (float(car["finish_time"]) - float(lead["finish_time"]))) <= 0.02, "finish gap equals timing")
		else:
			lapped_cars += 1
			suspicious_laps += int(car.get("invalid_lap_count", 0))
	check(validated_laps > 1, "at least two finish on lead lap")
	var history: Array = race.get_pit_history("Ferrari")
	if manual:
		for cid in [alonso_id, massa_id]:
			var expected: Array = [23,48] if cid == alonso_id else [25,50]
			var observed: Array = []
			for entry in history:
				if int(entry["car_id"]) == cid:
					observed.append(int(entry["lap"]))
			check(observed == expected, "manual stops exact for " + str(cid) + " expected " + str(expected) + " got " + str(observed))
	var npos: int = 0
	var nsoul: int = 0
	var nreal: int = 0
	for e in race.telemetry.event_history:
		if str(e["type"]) == "position_gain":
			npos += 1
		if str(e["type"]) == "pass":
			nreal += 1
		if str(e["type"]) == "wear":
			nsoul += 1
	var invalid: int = 0
	for car in ordered:
		invalid += int(car.get("invalid_lap_count", 0))
	print("APEX_0638_FULL ", JSON.stringify({"code":code,"weather":wet_mode,"manual":manual,"steps":steps,"time":race.clock,"winner":lead["name"],"lead_lap":lead["finish_laps"],"finish_lap_count":validated_laps,"lapped":lapped_cars,"pits_all":race.pit_history.size(),"pits_ferrari":history.size(),"record_rejected":invalid,"ontrack_passes":nreal,"nonpass_gains":npos,"tyre_warnings":nsoul,"p2_gap":ordered[1]["gap"],"p2_gap_label":ordered[1]["gap_label"],"errors":failures.size()}))
	if failures.is_empty():
		print("APEX 0638 FULL GP TEST PASS")
		quit(0)
	else:
		print("APEX 0638 FULL GP TEST FAILED ", failures)
		quit(1)
