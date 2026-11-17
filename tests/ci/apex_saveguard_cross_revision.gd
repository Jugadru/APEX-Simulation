extends SceneTree
## APEX SaveGuard v1. Tests copies of baseline saves only. Never edits originals.
const Championship = preload("res://scripts/championship_2012.gd")
const Garage = preload("res://scripts/garage.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

var failures: Array[String] = []
var checks: int = 0
var observations: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func ck(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("APEX_SAVEGUARD_CHECK_FAIL ", description)

func copy_file(source: String, target: String) -> bool:
	return DirAccess.copy_absolute(source, target) == OK

func write_file(target: String, content: String) -> bool:
	var f: FileAccess = FileAccess.open(target, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(content)
	f.close()
	return true

func _run() -> void:
	var source_career: String = OS.get_environment("APEX_SAVEGUARD_CAREER")
	var source_garage: String = OS.get_environment("APEX_SAVEGUARD_GARAGE")
	var source_replay: String = OS.get_environment("APEX_SAVEGUARD_REPLAY")
	var expected_ticks: int = int(OS.get_environment("APEX_SAVEGUARD_TICKS"))
	for entry in [source_career, source_garage, source_replay]:
		if entry.is_empty() or not FileAccess.file_exists(entry):
			ck(false, "Missing baseline fixture")
			_end()
			return

	var original_hashes: Dictionary = {
		"career": FileAccess.get_sha256(source_career),
		"garage": FileAccess.get_sha256(source_garage),
		"replay": FileAccess.get_sha256(source_replay)
	}
	ck(original_hashes.values().all(func(h): return not str(h).is_empty()), "Fixture SHA256 recorded")

	# Career: 20 administrative seasons produced by baseline's own code.
	var historical = Championship.new(source_career)
	ck(historical.has_season(), "Baseline career opened by current code")
	if not historical.has_season():
		_end()
		return
	var historical_state: Dictionary = historical.state.duplicate(true)
	ck(int(historical_state.get("format", -1)) == 1, "Career schema 1 recognized")
	ck(int(historical_state.get("serial", -1)) == 20, "20th administrative championship serial preserved")
	ck(int(historical_state.get("round_index", -1)) == 20, "20th season completed all 20 rounds")
	ck((historical_state.get("results", []) as Array).size() == 20, "20 final season results preserved")
	ck((historical_state.get("drivers", {}) as Dictionary).size() == 24, "24 driver points retained")
	ck((historical_state.get("constructors", {}) as Dictionary).size() == 12, "12 constructor points retained")
	var career_work: String = ProjectSettings.globalize_path("user://saveguard_career_copy.json")
	var career_backup: String = career_work + ".saveguard.bak"
	ck(copy_file(source_career, career_work), "Career copied to isolated sandbox")
	ck(copy_file(career_work, career_backup), "Independent career backup created")
	var career = Championship.new(career_work)
	ck(career.has_season(), "Sandbox career opens")
	ck(career.save(), "Career atomic save on isolated copy")
	var career_after = Championship.new(career_work)
	ck(career_after.state == historical_state, "Career roundtrip preserves points, results and progress")
	ck(write_file(career_work, "{ invalid saveguard JSON"), "Can create intentionally malformed career")
	var bad_career = Championship.new(career_work)
	ck(not bad_career.has_season(), "Malformed career must be rejected")
	ck(copy_file(career_backup, career_work), "Career restored from isolated manual backup")
	ck(Championship.new(career_work).state == historical_state, "Career recovery retains original content")
	var altered_schema: Dictionary = historical_state.duplicate(true)
	altered_schema["format"] = 999
	ck(write_file(career_work, JSON.stringify(altered_schema)), "Inject unsupported career schema")
	ck(not Championship.new(career_work).has_season(), "Unsupported career schema rejected")
	ck(copy_file(career_backup, career_work), "Restore career after version mismatch")
	var tampered_round: Dictionary = historical_state.duplicate(true)
	tampered_round["round_index"] = 19
	ck(write_file(career_work, JSON.stringify(tampered_round)), "Inject inconsistent career round count")
	ck(not Championship.new(career_work).has_season(), "Invalid career round count rejected")
	ck(copy_file(career_backup, career_work), "Restore career after invalid round")
	observations["career"] = {"schema": 1, "final_serial": 20, "final_round": 20, "drivers": 24, "constructors": 12,
		"invalid_json_rejected": true, "unknown_schema_rejected": true, "round_mismatch_rejected": true,
		"backup_recovery": "manual sandbox copy (not automatic in game)"}

	# Garage: baseline migration fixture with budget, upgrades and staff state.
	var garage_work: String = ProjectSettings.globalize_path("user://saveguard_garage_copy.json")
	ck(copy_file(source_garage, garage_work), "Garage copied to isolated sandbox")
	var garage = Garage.new(garage_work)
	var ferrari: Dictionary = garage.get_team("Ferrari")
	ck(int(ferrari.get("budget", -1)) == 6500000, "Historic garage budget survives load")
	ck(int(ferrari.get("levels", {}).get("Asa", -1)) == 2, "Historic chassis/aero upgrades survive")
	ck(int(ferrari.get("staff_levels", {}).get("Engenheiro", -1)) == 2, "Historic engineer level survives")
	var roster_snapshot: Dictionary = ferrari.get("staff_roster", {}).duplicate(true)
	var inventory_exists: bool = ferrari.has("component_inventory")
	ck(inventory_exists, "Garage inventory migration available on loaded team")
	ferrari["budget"] = 6500123
	ck(garage.save(), "Updated garage saves with rollback backup")
	var garage_loaded = Garage.new(garage_work)
	ck(int(garage_loaded.get_team("Ferrari").get("budget", -1)) == 6500123, "Garage budget roundtrip")
	ck(garage_loaded.get_team("Ferrari").get("staff_roster", {}) == roster_snapshot, "Staff roster not lost during roundtrip")
	var internal_backup: String = garage_work + ".bak"
	ck(FileAccess.file_exists(internal_backup), "Garage .bak created by production save")
	var backup_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(internal_backup))
	ck(backup_json is Dictionary and (backup_json as Dictionary).has("Ferrari"), "Garage .bak contains historical team")
	var backup_budget: int = -1
	if backup_json is Dictionary and backup_json.has("Ferrari"):
		backup_budget = int(backup_json["Ferrari"].get("budget", -1))
	ck(backup_budget == 6500000, "Garage backup preserved previous budget")
	var backup_hash: String = FileAccess.get_sha256(internal_backup)
	ck(write_file(garage_work, "{corrupt"), "Can create intentionally invalid garage copy")
	var rejected_garage = Garage.new(garage_work)
	ck(rejected_garage.team_data.is_empty(), "Invalid garage JSON not deserialized")
	ck(FileAccess.get_file_as_string(garage_work) == "{corrupt", "Corrupted garage is not silently overwritten on load")
	ck(FileAccess.get_sha256(internal_backup) == backup_hash, "Garage .bak survives corrupt primary")
	ck(copy_file(internal_backup, garage_work), "Restore previous garage backup manually")
	ck(int(Garage.new(garage_work).get_team("Ferrari").get("budget", -1)) == 6500000,
		"Garage backup recovery restores safe prior budget")
	observations["garage"] = {"historic_budget": 6500000, "updated_budget": 6500123,
		"backup_budget": backup_budget, "engineer_level": 2, "aero_level": 2,
		"inventory_migrated": inventory_exists, "invalid_json_not_deserialized": true,
		"backup_recovery": "manual test copy; current game does NOT auto-restore .bak"}

	# Replay: real APEX_REPLAY_0660 binary archive produced by baseline.
	var replay = Replay.new()
	ck(replay.load_file(source_replay), "Baseline replay accepted by candidate revision")
	if replay.race == null:
		_end()
		return
	ck(replay.end_tick == expected_ticks, "Replay end tick preserved")
	ck(replay.seek(expected_ticks), "Entire baseline replay reproduces all sporting hashes")
	var replay_hash: String = Codec.sporting_hash(replay.race, replay.policy)
	ck(replay_hash == replay.hashes[-1], "Final sporting hash after replay playback")
	var replay_work: String = ProjectSettings.globalize_path("user://saveguard_corrupted.apexreplay")
	var valid_copy: String = ProjectSettings.globalize_path("user://saveguard_verified.apexreplay")
	ck(copy_file(source_replay, valid_copy), "Replay baseline backed up to sandbox")
	var reader: FileAccess = FileAccess.open(valid_copy, FileAccess.READ)
	if reader == null:
		ck(false, "Cannot read safe replay envelope")
		_end()
		return
	var envelope: Variant = reader.get_var(false)
	reader.close()
	if not envelope is Dictionary:
		ck(false, "Baseline replay envelope invalid")
		_end()
		return
	var corrupt_envelope: Dictionary = envelope.duplicate(true)
	corrupt_envelope["sha256"] = "invalid-checksum"
	var writer: FileAccess = FileAccess.open(replay_work, FileAccess.WRITE)
	if writer == null:
		ck(false, "Cannot open corrupted replay sandbox path")
		_end()
		return
	writer.store_var(corrupt_envelope, false)
	writer.close()
	var corrupt_replay = Replay.new()
	ck(not corrupt_replay.load_file(replay_work), "Replay with incorrect SHA256 rejected")
	ck(corrupt_replay.error.contains("Checksum"), "Replay rejection identifies checksum")
	var version_data: Dictionary = replay.export_data()
	version_data["simulation_revision"] = "another_physics_revision"
	var incompatible = Replay.new()
	ck(not incompatible.load_data(version_data), "Replay from unsupported physics revision rejected explicitly")
	ck(incompatible.error.contains("revisão"), "Incompatible revision has explicit explanation")
	ck(Replay.new().load_file(valid_copy), "Healthy replay preserved for recovery")
	observations["replay"] = {
		"archive": "APEX_REPLAY_0660", "ticks": expected_ticks, "sporting_hash": replay_hash,
		"hash_corruption_rejected": true, "other_simulation_revision_rejected": true,
		"backup_recovery": "sandbox copy only; no automatic restore claimed"
	}

	# Exact baseline files are immutable. Source copies are never opened WRITE.
	ck(FileAccess.get_sha256(source_career) == original_hashes["career"], "Baseline career unchanged")
	ck(FileAccess.get_sha256(source_garage) == original_hashes["garage"], "Baseline garage unchanged")
	ck(FileAccess.get_sha256(source_replay) == original_hashes["replay"], "Baseline replay unchanged")
	observations["source_sha256"] = original_hashes
	_end()

func _end() -> void:
	var result: Dictionary = {
		"status": "PASS" if failures.is_empty() else "FAIL",
		"test": "apex_saveguard_cross_revision",
		"checks": checks,
		"errors": failures,
		"observations": observations,
		"limits": [
			"Compatibility only between selected baseline and candidate commits, not all APEX releases",
			"Garage backup is not automatically restored by existing production code",
			"20 season fixture means administrative results, not 400 simulated races",
			"All corruption and restoration operations use sandbox copies; real user saves untouched"
		]
	}
	print("APEX_SAVEGUARD_RESULT ", JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
