extends SceneTree
## v0.6.6.9.6: ledger is passive, bounded, auditable and replay-safe.
const Ledger = preload("res://scripts/core/race_pitwall_prediction_06696.gd")
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("PITWALL_LEDGER_06696_FAIL: " + label)

func _fixture_car() -> Dictionary:
	return {"id":1, "name":"Apex Pilot", "team":"A", "position":6,
		"progress":4.95, "laps_done":4, "stops":0, "finished":false,
		"pit_target":"Médio", "pit_order_source":"ordem_imediata",
		"pace":"Normal", "tire":"Macio", "wear":69.0,
		"last_lap":97.0, "track_wear_factor":0.8}

func _run() -> void:
	var ledger = Ledger.new()
	var car: Dictionary = _fixture_car()
	var other: Dictionary = {"id":2, "team":"B", "name":"Opponent",
		"progress":5.12, "last_lap":96.0, "finished":false}
	var grid: Array = [car, other]
	var advice: Dictionary = {"forecast_3":0.32, "forecast_6":0.45}
	var weather: Dictionary = {"wetness_factor":0.20}
	var specs: Dictionary = {
		"Macio":{"wear":3.2, "delta":-0.4, "cliff":75.0},
		"Médio":{"wear":2.2, "delta":0.0, "cliff":80.0}}
	var before: PackedByteArray = var_to_bytes([car, other, advice, weather, specs])
	ledger.capture_entry(car, grid, advice, weather, specs,
		{"Estrategista":2, "Engenheiro":3}, 21.8, 96.0, 0.075, 482, 95.6)
	var first: Dictionary = ledger.snapshot()[0]
	check(ledger.snapshot().size() == 1 and int(first["tick"]) == 482,
		"forecast captured with original tick before outcome")
	check(int(first["strategist_level"]) == 2 and int(first["engineer_level"]) == 3,
		"staff proficiency recorded without random correction")
	check(not bool(first["pit_verified"]) and not first.has("actual_position"),
		"no actual outcome fabricated at prediction time")
	check(before == var_to_bytes([car, other, advice, weather, specs]),
		"observer does not mutate input data")
	var outcome: Dictionary = {"car_id":1, "stop":1, "lap":5,
		"position_after":8, "total":31.4, "wait":1.2,
		"incident_delay":2.0, "incident":"Porca travada", "training_saved":0.5}
	ledger.observe_exit(outcome, 96.0, 0.075)
	var stop: Dictionary = ledger.snapshot()[0]
	check(bool(stop["pit_verified"]) and int(stop["actual_position"]) == 8,
		"real history resolves only matching confirmed pit")
	check(is_equal_approx(float(stop["actual_net_loss_s"]), 24.2),
		"measured net pit loss uses correct track fraction")
	check(str(stop["reasons"]).contains("fila") and str(stop["reasons"]).contains("Porca"),
		"verified queue and service incident attribution")
	var observed: Dictionary = car.duplicate(true)
	observed["stops"] = 1
	observed["tire"] = "Médio"
	for completed in range(6, 11):
		observed["laps_done"] = completed
		observed["last_lap"] = 95.5 + float(completed - 6) * 0.2
		observed["wear"] = float(completed - 5) * 2.3
		ledger.observe_lap(observed, {"wetness_factor":0.27 + 0.01 * float(completed - 6)})
	var finished: Dictionary = ledger.snapshot()[0]
	check(str(finished["status"]) == "COMPLETE" and int(finished["laps_observed"]) == 5,
		"five unique completed laps resolve horizon")
	check(bool(finished["weather_verified"]) and is_equal_approx(float(finished["actual_water_3"]), 0.29),
		"weather compared against real lap three observation")
	check(finished.has("wear_error_5") and finished.has("pace_error_5"),
		"five-lap tyre and pace estimates compared to measured outcomes")
	ledger.observe_lap(observed, {"wetness_factor":0.99})
	check(int(ledger.snapshot()[0]["laps_observed"]) == 5,
		"duplicate lap does not alter finished record")
	var leaked: Array = ledger.snapshot()
	leaked[0]["status"] = "FALSIFIED"
	check(str(ledger.snapshot()[0]["status"]) == "COMPLETE", "immutable snapshot boundary")
	check(int(ledger.summary()["verified_pits"]) == 1, "accuracy summary uses verified pits only")
	var interrupted = Ledger.new()
	interrupted.capture_entry(car, grid, advice, weather, specs, {}, 21.8, 96.0, 0.075, 482, 95.6)
	interrupted.observe_exit(outcome, 96.0, 0.075)
	observed["laps_done"] = 6
	observed["stops"] = 2
	interrupted.observe_lap(observed, weather)
	check(str(interrupted.snapshot()[0]["status"]) == "INTERRUPTED",
		"second stop does not masquerade as five-lap tyre validation")
	var unresolved = Ledger.new()
	unresolved.capture_entry(car, grid, advice, weather, specs, {}, 21.8, 96.0, 0.075, 482, 95.6)
	unresolved.close_unfinished()
	check(str(unresolved.snapshot()[0]["status"]) == "UNVERIFIABLE"
		and int(unresolved.summary()["verified_pits"]) == 0,
		"unfinished forecasts never scored as wrong or correct")
	var learning = Ledger.new()
	for n in range(3):
		learning.capture_entry(car, grid, advice, weather, specs,
			{"Estrategista":2}, 21.8, 96.0, 0.075, n + 1, float(n))
		var actual: Dictionary = outcome.duplicate(true)
		actual["total"] = 31.4 + float(n)
		learning.observe_exit(actual, 96.0, 0.075)
	learning.capture_entry(car, grid, advice, weather, specs,
		{"Estrategista":2}, 21.8, 96.0, 0.075, 12, 123.0)
	check(int(learning.snapshot()[-1]["calibration_samples"]) >= 3
		and float(learning.snapshot()[-1]["predicted_net_loss_s"]) > 21.8,
		"only observed prior outcomes calibrate subsequent forecast")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = season["tracks"][0]
	var a = Race.new(season["teams"], "Ferrari", 696, {}, track, {})
	var b = Race.new(season["teams"], "Ferrari", 696, {}, track, {})
	check(not Codec.fields(a, Codec.EXCLUDED).has("prediction_ledger")
		and not Codec.fields(a, Codec.EXCLUDED).has("prediction_staff"),
		"new observer excluded from historical sporting checkpoint schema")
	var id: int = int(a.player_cars()[0]["id"])
	var tire: String = str(a.available_pit_compounds()[0])
	a.order_pit(id, tire)
	b.order_pit(id, tire)
	a.running = true
	b.running = true
	for tick in range(750):
		a.step(0.2)
		b.step(0.2)
		if tick % 35 == 0:
			a.get_prediction_ledger("Ferrari")
			a.get_prediction_summary("Ferrari")
	check(a.get_state_snapshot() == b.get_state_snapshot(),
		"extra ledger reads cannot alter deterministic live sporting state")
	check(Codec.sporting_hash(a, {}) == Codec.sporting_hash(b, {}),
		"sporting replay hash unchanged by observer reads")
	check(a.get_prediction_ledger("Ferrari").size() >= 1,
		"real engine creates ledger entry for committed player pit")
	check(a.get_pit_history("Ferrari").size() == b.get_pit_history("Ferrari").size(),
		"real engine pit records remain identical")
	if failures.is_empty():
		print("PITWALL_LEDGER_06696_PASS %d checks" % checks)
	quit(0 if failures.is_empty() else 1)
