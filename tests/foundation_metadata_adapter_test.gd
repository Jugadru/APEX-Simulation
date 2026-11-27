extends SceneTree
## Compare the exported metadata against the real native session loader.
const Settings = preload("res://scripts/apex_session_settings.gd")
const REPORT = "res://ci-results/foundation-core2-metadata.json"
class Host extends RefCounted:
	var season_title: String = ""
	var teams: Array = []
	var season_tracks: Array = []
	var selected_team: String = ""
	var selected_track_index: int = 0

var failures: Array[String] = []
var checks: int = 0

func ck(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures.append(detail)
		printerr("APEX_FOUNDATION_METADATA_FAIL ", detail)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(REPORT))
	ck(report is Dictionary, "export is present and parseable")
	if not report is Dictionary:
		quit(2)
		return
	var body: Dictionary = report.get("body", {})
	ck(str(body.get("contract", "")) == "core2-metadata.v1", "contract version")
	ck(str(body.get("scope", "")) == "CORE2_METADATA_READ_ONLY", "scope")
	ck(body.get("runtime_applied", true) == false and body.get("execution_authorized", true) == false, "no application")
	var host := Host.new()
	Settings._load_season_data(host)
	var catalog: Dictionary = body.get("catalog", {})
	var teams: Array = catalog.get("teams", [])
	var drivers: Array = catalog.get("drivers", [])
	var circuits: Array = catalog.get("circuits", [])
	ck(host.season_title == str(int(catalog.get("season", 0))) and host.season_title == "2012", "season")
	ck(host.teams.size() == 12 and teams.size() == 12, "12 teams")
	ck(drivers.size() == 24, "24 drivers")
	ck(host.season_tracks.size() == 20 and circuits.size() == 20, "20 tracks")
	if not failures.is_empty():
		quit(2)
		return
	for i in range(12):
		var native_team: Dictionary = host.teams[i]
		var row: Dictionary = teams[i]
		ck(int(row.get("index", -1)) == i and row.get("name") == native_team.get("name"), "team %d" % i)
		var native_drivers: Array = native_team.get("drivers", [])
		ck(native_drivers.size() == 2, "driver slots %d" % i)
		if native_drivers.size() != 2:
			quit(2)
			return
		for slot in range(2):
			var driver: Dictionary = drivers[i * 2 + slot]
			ck(int(driver.get("team_index", -1)) == i and int(driver.get("slot", -1)) == slot and driver.get("name") == native_drivers[slot].get("name"), "driver %d/%d" % [i, slot])
	for i in range(20):
		var native_track: Dictionary = host.season_tracks[i]
		var row: Dictionary = circuits[i]
		ck(int(row.get("index", -1)) == i and row.get("code") == native_track.get("code") and row.get("name") == native_track.get("name") and row.get("country") == native_track.get("country") and int(row.get("laps", -1)) == int(native_track.get("laps", 0)), "track %d" % i)
	var sources: Array = body.get("sources", [])
	var expected: Array[String] = ["data/season_2012.json", "data/teams.json"]
	ck(sources.size() == expected.size(), "source coverage")
	if sources.size() == expected.size():
		for i in range(expected.size()):
			var row: Dictionary = sources[i]
			ck(row.get("path") == expected[i] and row.get("sha256") == FileAccess.get_sha256("res://" + expected[i]), "source hash %d" % i)
	if failures.is_empty():
		print("APEX_FOUNDATION_METADATA_PASS checks=%d teams=12 drivers=24 circuits=20" % checks)
		quit(0)
	else:
		quit(2)
