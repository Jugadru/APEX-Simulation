extends SceneTree
const RaceScript = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
	call_deferred("_test")
func _test() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for entry in season["tracks"]:
		if str(entry["code"]) == "BRA":
			track = entry
			break
	var race = RaceScript.new(season["teams"], "Ferrari", 638, {}, track, {})
	race.configure_weather("Seco")
	var car: Dictionary = race.player_cars()[0]
	car["laps_done"] = 12
	car["wear"] = 92.0
	car["wear_warning_stage"] = 0
	var stops_before: int = int(car.get("stops", 0))
	race._on_lap_cross(car)
	var warning_count: int = 0
	for event in race.events:
		if str(event.get("type", "")) == "wear" and int(event.get("driver_id", -1)) == int(car["id"]):
			warning_count += 1
	var scheduled: int = int(car.get("pit_scheduled_lap", 0))
	var manual_unmodified: bool = scheduled == 0 and not bool(car.get("pit_request", false)) and int(car["stops"]) == stops_before
	var ok: bool = warning_count == 1 and manual_unmodified and int(car.get("wear_warning_stage", 0)) == 2
	print("APEX 0638 MANUAL WEAR WARNING ", "PASS" if ok else "FAIL", " warnings=", warning_count, " stage=", car.get("wear_warning_stage", -1), " no_auto_pit=", manual_unmodified)
	quit(0 if ok else 1)
