extends SceneTree
## Architecture regression: presentation extraction must preserve exact text.
const Formatter = preload("res://scripts/presentation/race_standings_text.gd")
const Race = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("STANDINGS_REFACTOR_FAIL " + message)
	quit(1)

func _legacy(order: Array, completed: bool, limit: int, race) -> String:
	var output := ""
	for i in range(mini(limit, order.size())):
		var c: Dictionary = order[i]
		var gap := (str(c.get("gap_label", "")) if completed
			else ("LÍDER" if i == 0 else "+%.1fs" % float(c["gap"])))
		output += "%02d  %-18s  %-5s %s\n" % [
			i + 1, c["name"], race.tyre_code(str(c["tire"])), gap]
	return output

func _run() -> void:
	var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not season is Dictionary:
		_fail("Missing original season fixture")
		return
	var race = Race.new(season["teams"], "Ferrari", 51551, {}, season["tracks"][0], {})
	var original_hash: String = str(race.cars.hash())
	for completed in [false, true]:
		race.finished = completed
		for count in [-1, 0, 1, 3, 24, 99]:
			var sorted: Array = race.get_sorted()
			var expected: String = _legacy(sorted, completed, count, race)
			var actual: String = race.standings_text(count)
			var direct: String = Formatter.format(sorted, completed, count, Callable(race, "tyre_code"))
			if actual != expected or direct != expected:
				_fail("Text differs from original for finished=%s limit=%d" % [completed, count])
				return
	# Explicitly verify that formatting doesn't modify sorting or cars.
	if str(race.cars.hash()) != original_hash:
		_fail("Formatting mutated sporting car data")
		return
	if race.standings_text() != _legacy(race.get_sorted(), true, 24, race):
		_fail("Default public API changed")
		return
	print("STANDINGS_REFACTOR_PASS")
	quit(0)
