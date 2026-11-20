extends SceneTree
## Driver Identity Pack 2012 — exact 24-person identity and source contract.
const Manager = preload("res://scripts/apex_portrait_manager.gd")
var checks := 0
var fails := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		printerr("DRIVER_IDENTITY_066811_FAIL: " + reason)
func run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/driver_identity_2012.json"))
	check(typeof(raw) == TYPE_DICTIONARY, "Manifest JSON")
	var entries: Array = raw.get("drivers", []) if typeof(raw) == TYPE_DICTIONARY else []
	check(entries.size() == 24, "24 2012 primary starters")
	var names: Dictionary = {}
	var numbers: Dictionary = {}
	var abbreviations: Dictionary = {}
	for item in entries:
		var name: String = str(item.get("name", ""))
		var number: int = int(item.get("number", 0))
		var source: String = str(item.get("source_file", ""))
		check(not name.is_empty() and not names.has(name), "Unique driver " + name)
		check(number > 0 and not numbers.has(number), "Unique 2012 number " + str(number))
		check(str(item.get("abbr", "")).length() == 3 and not abbreviations.has(item.get("abbr")), "Unique abbreviation " + name)
		check(str(item.get("country", "")).length() == 3, "Three letter country " + name)
		check(source.ends_with(", United States Grand Prix, Austin 2012.jpg"), "Named 2012 PERSON photograph " + name)
		check(not source.to_lower().contains("car.") and not source.to_lower().contains("chassis"), "Never a car-substitute photo " + name)
		check(str(item.get("photographer", "")) == "Gussisaurio", "Photographer credit " + name)
		check(str(item.get("license", "")) == "CC BY-SA 3.0", "Copying license " + name)
		names[name] = true
		numbers[number] = true
		abbreviations[item.get("abbr")] = true
	check(not numbers.has(13), "2012 grid omitted #13")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var seen := 0
	for team in season.teams:
		for driver in team.drivers:
			var name: String = str(driver.name)
			check(names.has(name), "Season driver identity exists: " + name)
			var found: bool = false
			for item in entries:
				if str(item.get("name", "")) == name:
					found = str(item.get("team", "")) == str(team.name)
					break
			check(found, "Team assignment preserved: " + name)
			seen += 1
	check(seen == 24, "24 team drivers matched without adding sports data")
	var manager = Manager.new()
	root.add_child(manager)
	await process_frame
	var alonso: Dictionary = manager.get_info("Fernando Alonso")
	check(int(alonso.get("number", 0)) == 5 and str(alonso.get("country", "")) == "ESP", "Alonso number and country")
	check(int(manager.get_info("Sebastian Vettel").get("number", 0)) == 1, "Vettel is #1")
	check(int(manager.get_info("Lewis Hamilton").get("number", 0)) == 4, "Hamilton is #4")
	check(manager.get_abbreviation("Michael Schumacher") == "MSC", "Schumacher official 2012 abbreviation MSC")
	check(manager.get_abbreviation("Pedro de la Rosa") == "DLR", "de la Rosa must not collide with Rosberg")
	check(manager.get_abbreviation("Nico Rosberg") == "ROS", "Rosberg official 2012 abbreviation ROS")
	check(manager.get_abbreviation("Kimi Räikkönen") == "RAI", "Räikkönen ASCII broadcast code")
	check(manager.get_abbreviation("Paul di Resta") == "DIR", "di Resta official 2012 abbreviation DIR")
	check(manager.get_abbreviation("Unknown Driver").is_empty(), "Uncatalogued driver preserves legacy fallback")
	check(manager.get_info("Unknown Driver").is_empty(), "Unknown faces not substituted")
	check(manager.get_photo("Unknown Driver") == null, "Never return a car as a missing driver's image")
	check(manager.get_source_url("Fernando Alonso").begins_with("https://commons.wikimedia.org/wiki/File:"), "Specific source permalink")
	check(manager.get_credit("Fernando Alonso").contains("Gussisaurio"), "Photo attribution")
	check(manager.get_credit("Fernando Alonso").contains("CC BY-SA 3.0"), "License displayed")
	check(manager.download_state == "idle", "No automatic internet download without user action")
	if fails == 0:
		print("DRIVER_IDENTITY_066811_PASS checks=%d entries=%d read_only=true" % [checks, entries.size()])
	quit(0 if fails == 0 else 1)
