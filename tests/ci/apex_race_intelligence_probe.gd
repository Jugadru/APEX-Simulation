extends SceneTree
## APEX Race Intelligence Tester: 10-lap native simulation. No production edits.
## Uses actual RaceEngine, deterministic weather/seed, manual V7 or automatic mode.
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

const SCENARIOS := {
	"monza_dry_auto": {"track": "ITA", "weather": "Seco", "seed": 660, "control": "IA"},
	"silverstone_wet_auto": {"track": "GBR", "weather": "Chuva intensa", "seed": 661, "control": "IA"},
	"monza_manual_v7": {"track": "ITA", "weather": "Seco", "seed": 662, "control": "Manual"},
}
const RACE_LAPS := 10
const MAX_STEPS := 1000

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("APEX_RIT_FAIL ", message)
	quit(1)

func _run() -> void:
	var name: String = OS.get_environment("APEX_RIT_SCENARIO")
	if not SCENARIOS.has(name):
		_fail("Unknown or missing APEX_RIT_SCENARIO")
		return
	var config: Dictionary = SCENARIOS[name]
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not data is Dictionary:
		_fail("No 2012 season data")
		return
	var track: Dictionary = {}
	for item in data["tracks"]:
		if str(item.get("code", "")) == str(config["track"]):
			track = item.duplicate(true)
			break
	if track.is_empty():
		_fail("Missing track " + str(config["track"]))
		return
	track["laps"] = RACE_LAPS
	track["race_km"] = float(track["lap_km"]) * float(RACE_LAPS)
	var race = Race.new(data["teams"], "Ferrari", int(config["seed"]), {}, track, {})
	race.configure_weather(str(config["weather"]))
	if race.cars.size() != 24 or race.player_cars().size() != 2:
		_fail("Expected 24 cars and two Ferrari drivers")
		return
	var teammate: Dictionary = race.player_cars()[0]
	var manual_id: int = int(teammate["id"])
	var errors: Array[String] = []
	for car in race.player_cars():
		race.set_pit_control_mode(int(car["id"]), str(config["control"]))
	var schedule_ok: bool = true
	if name == "monza_manual_v7":
		schedule_ok = race.schedule_pit(manual_id, str(race.available_pit_compounds()[1]), 7)
		if not schedule_ok:
			errors.append("Manual V7 schedule rejected")
	race.running = true
	var steps: int = 0
	var max_stops_observed: int = 0
	var ai_plan_samples: int = 0
	var stopped_early: bool = false
	var rain_observed: bool = false
	var wetness_peak: float = 0.0
	var trace: Array = []
	while not race.finished and steps < MAX_STEPS:
		race.step(4.0)
		steps += 1
		var wetness: float = float(race.weather_snapshot().get("wetness_factor", 0.0))
		if wetness > 0.15:
			rain_observed = true
		wetness_peak = maxf(wetness_peak, wetness)
		for car in race.cars:
			max_stops_observed = maxi(max_stops_observed, int(car.get("stops", 0)))
			if not car.get("ai_plan", {}).is_empty():
				ai_plan_samples += 1
		if name == "monza_manual_v7" and int(teammate.get("laps_done", 0)) < 5:
			if bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.0:
				stopped_early = true
		if steps % 40 == 0:
			trace.append({
				"step": steps, "lap": race.lap, "clock": race.clock,
				"wetness_factor": wetness, "events": race.events.size(),
				"pits": race.get_pit_history().size()
			})
	var sorted: Array = race.get_sorted()
	var classified: int = 0
	var positions: Dictionary = {}
	var finished: bool = race.finished and race.finish_results_validated and sorted.size() == 24
	for car in sorted:
		if bool(car.get("finished", false)):
			classified += 1
		positions[int(car.get("position", -1))] = true
		if not is_finite(float(car.get("wear", 0.0))) or not is_finite(float(car.get("best_lap", 0.0))):
			errors.append("Non-finite wear or best lap")
		if float(car.get("wear", 0.0)) < -0.01 or float(car.get("wear", 0.0)) > 100.01:
			errors.append("Tyre wear outside [0,100]")
	if not finished or classified != 24 or positions.size() != 24:
		errors.append("Unfinished race or invalid 24-car classification")
	if max_stops_observed > RACE_LAPS:
		errors.append("More pit stops than racing laps")
	var manual_stops: Array = []
	var history: Array = race.get_pit_history()
	for stop in history:
		if int(stop.get("car_id", -1)) == manual_id:
			manual_stops.append(int(stop.get("lap", 0)))
		if int(stop.get("lap", 0)) < 1 or int(stop.get("lap", 0)) > RACE_LAPS:
			errors.append("Pit history contains impossible lap")
	if name == "monza_manual_v7":
		if stopped_early or manual_stops != [7]:
			errors.append("Manual V7 was changed or executed early")
		if int(teammate.get("stops", 0)) != 1:
			errors.append("Manual driver did not complete exactly one scheduled pit")
	if name == "silverstone_wet_auto" and not rain_observed:
		errors.append("Heavy rain scenario never became wet")
	var pass_events: int = 0
	var radio_events: int = 0
	for event in race.telemetry.event_history:
		if str(event.get("type", "")) == "pass":
			pass_events += 1
	for event in race.events:
		if str(event.get("type", "")) == "radio":
			radio_events += 1
	var recommendations: Array = []
	for car in race.player_cars():
		var advice: Dictionary = race.get_engineer_advice(int(car["id"]))
		recommendations.append({
			"driver_id": int(car["id"]),
			"pit_now": bool(advice.get("pit_now", false)),
			"planned_pit_lap": int(advice.get("planned_pit_lap", 0)),
			"compound": str(advice.get("compound", "")),
			"pit_control_mode": str(car.get("pit_control_mode", ""))
		})
	if errors.is_empty() and history.size() > 24:
		# Flag for review; not an asserted fault as safety stops are possible.
		trace.append({"warning": "More than one pit stop per driver on average"})
	var result: Dictionary = {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"scenario": name,
		"circuit": str(config["track"]),
		"seed": int(config["seed"]),
		"weather": str(config["weather"]),
		"control": str(config["control"]),
		"lap_count": RACE_LAPS,
		"finished": finished,
		"classified": classified,
		"steps": steps,
		"hash": Codec.sporting_hash(race, {}),
		"pits_total": history.size(),
		"manual_v7_pits": manual_stops if name == "monza_manual_v7" else [],
		"wetness_peak": snappedf(wetness_peak, 0.000001),
		"on_track_pass_events": pass_events,
		"radio_events": radio_events,
		"ai_plan_samples": ai_plan_samples,
		"max_stops_per_car": max_stops_observed,
		"recommendations_at_finish": recommendations,
		"trace": trace,
		"errors": errors,
		"notes": "10-lap deterministic probe; counts do not prove realism or AI skill"
	}
	print("APEX_RIT_RESULT ", JSON.stringify(result))
	quit(0 if errors.is_empty() else 1)
