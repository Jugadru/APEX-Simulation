extends SceneTree
const Policy = preload("res://scripts/core/race_revision_policy_0923.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
# Literal membership oracle extracted from the pre-refactor engine at
# df376c718472d7323da560fcf4935ecaf62900b3. Do not derive it from Policy.REVISIONS.
const ORIGINAL_GATES := [
	[Policy.OVERTAKING, ["023_overtaking_intelligence_v1","024_race_start_spatial_v1","025_competitive_grid_start_v1","026_competitive_traffic_v1","027_race_traffic_hotfix_v1","028_racing_line_v1","029_racing_line_following_v1","030_racing_line_completion_v1","031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.START20, ["024_race_start_spatial_v1","025_competitive_grid_start_v1"]],
	[Policy.COMPETITIVE, ["025_competitive_grid_start_v1","026_competitive_traffic_v1","027_race_traffic_hotfix_v1","028_racing_line_v1","029_racing_line_following_v1","030_racing_line_completion_v1","031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.MERGE_TRAFFIC, ["026_competitive_traffic_v1","027_race_traffic_hotfix_v1","028_racing_line_v1","029_racing_line_following_v1","030_racing_line_completion_v1","031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.TRAFFIC_HOTFIX, ["027_race_traffic_hotfix_v1","028_racing_line_v1","029_racing_line_following_v1","030_racing_line_completion_v1","031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.RACING_LINE, ["028_racing_line_v1","029_racing_line_following_v1","030_racing_line_completion_v1","031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.FOLLOWING, ["029_racing_line_following_v1","030_racing_line_completion_v1","031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.PASS_COMPLETION, ["030_racing_line_completion_v1","031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.INDEPENDENT, ["031_independent_racecraft_v1","032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.AERO_WAKE, ["032_aero_wake_v1","033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.AERO_WAKE_CORRECTED, ["033_aero_wake_source_v2","034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.AERO_WAKE_STABILITY, ["034_aero_traffic_stability_v1","035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.AERO_WET_LINE, ["035_aero_wet_line_v1","036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.TACTICAL_COORDINATION, ["036_tactical_coordination_v1","037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.CORNER_BATTLE, ["037_corner_battle_v1","038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.DRIVER_TRAFFIC, ["038_driver_traffic_v2","039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.TRAFFIC_PACK, ["039_traffic_pack_v1","040_driver_error_recovery_v1"]],
	[Policy.DRIVER_ERROR, ["040_driver_error_recovery_v1"]],
]
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("REVISION_POLICY_0923_FAIL ", label)

func run() -> void:
	var revisions: Array = ORIGINAL_GATES[0][1].duplicate()
	revisions.append_array(["", "unknown", "041_future", "040", "040_driver_error_recovery_v1 ", "040_DRIVER_ERROR_RECOVERY_V1", "022_race_start_intelligence_v1", "021_strategy_staff_intelligence_v1", "015_weather_setup_v1", "066810_team_yield"])
	for revision in revisions:
		var mask: int = Policy.capability_mask(str(revision))
		var expected_mask: int = 0
		for gate in ORIGINAL_GATES:
			var expected: bool = revision in gate[1]
			verify(((mask & int(gate[0])) != 0) == expected, "original membership %s / %s" % [revision,str(gate[0])])
			if expected: expected_mask |= int(gate[0])
		verify(mask == expected_mask, "no extra capabilities " + str(revision))
	verify(Policy.REVISIONS.size() == 21, "21 exact revisions including experimental 043")
	verify(Policy.capability_mask(Replay.FUEL_EXPERIMENTAL_SIMULATION_REVISION) == (Policy.capability_mask(Replay.GEARBOX_EXPERIMENTAL_SIMULATION_REVISION) | Policy.FUEL), "043 adds fuel only")
	verify(Race.FUEL_SIM_REVISION == Replay.FUEL_EXPERIMENTAL_SIMULATION_REVISION, "043 exact revision")
	verify(Policy.capability_mask(Replay.GEARBOX_EXPERIMENTAL_SIMULATION_REVISION) == (Policy.capability_mask(Replay.SIMULATION_REVISION) | Policy.GEARBOX), "042 adds gearbox only")
	verify(Race.GEARBOX_SIM_REVISION == Replay.GEARBOX_EXPERIMENTAL_SIMULATION_REVISION and Replay.SIMULATION_REVISION == "041_longitudinal_physics_v1", "042 opt-in and 041 default")
	verify(Race.DRIVER_ERROR_SIM_REVISION == Replay.PRE_LONGITUDINAL_SIMULATION_REVISION and Replay.PRE_LONGITUDINAL_SIMULATION_REVISION == "040_driver_error_recovery_v1", "040 historical revision retained")
	verify(Race.LONGITUDINAL_SIM_REVISION == Replay.SIMULATION_REVISION and Replay.SIMULATION_REVISION == "041_longitudinal_physics_v1", "041 new sporting revision")
	verify(Policy.capability_mask(Replay.SIMULATION_REVISION) == (Policy.capability_mask(Replay.PRE_LONGITUDINAL_SIMULATION_REVISION) | Policy.LONGITUDINAL), "041 extends 040 only")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/apex_lab_track.json"))
	var race = Race.new(season.teams,"Ferrari",923,{},track,{})
	verify(race._traffic_pack_active() and race._driver_error_active(), "unattached live flags")
	var session = Replay.new()
	session.attach(race)
	var before: String = Codec.sporting_hash(race,session.policy)
	for revision in revisions:
		session.recorded_simulation_revision = str(revision)
		verify(race._traffic_pack_active() == (revision in ORIGINAL_GATES[16][1]), "real strategy gate " + str(revision))
		verify(race._driver_error_active() == (revision in ORIGINAL_GATES[17][1]), "real error gate " + str(revision))
	session.recorded_simulation_revision = Replay.SIMULATION_REVISION
	verify(race._traffic_pack_active() and race._driver_error_active(), "041 retains all prior driver capabilities")
	verify(before == Codec.sporting_hash(race,session.policy), "metadata queries never mutate sporting state")
	var flags: Array = ["traffic_pack_enabled","traffic_intelligence_enabled","corner_battle_enabled","tactical_coordination_enabled","aero_wet_line_stability","aero_wake_stability","aero_wake_enabled","independent_racecraft_enabled","pass_completion_enabled","following_enabled","racing_line_enabled","driver_traffic_enabled"]
	for flag in flags:
		race.set(flag,false)
		verify(not race._traffic_pack_active() and not race._driver_error_active(), "dependency disabled " + str(flag))
		race.set(flag,true)
	race.driver_error_enabled = false
	verify(race._traffic_pack_active() and not race._driver_error_active(), "driver error independent flag")
	race.driver_error_enabled = true
	race.command_session = null
	verify(race._traffic_pack_active() and race._driver_error_active(), "detached engine retains live flags")
	print("REVISION_POLICY_0923_REPORT ", JSON.stringify({"checks":checks,"failures":failures,"revisions":revisions.size(),"gates":ORIGINAL_GATES.size(),"oracle":"pre-refactor membership lists","sporting_revision":Replay.SIMULATION_REVISION}))
	if failures.is_empty():
		print("REVISION_POLICY_0923_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
