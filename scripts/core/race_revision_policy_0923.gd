extends RefCounted
## Exact replay capability policy for the sporting revisions 023..040.
## No dependency on the engine, no state, no inference from numeric prefixes.
## Unknown/older revisions enable none of these features. Unattached live
## engines retain their independent flags; the caller applies those first.
const OVERTAKING_SIM_REVISION := "023_overtaking_intelligence_v1"
const START20_SIM_REVISION := "024_race_start_spatial_v1"
const COMPETITIVE_SIM_REVISION := "025_competitive_grid_start_v1"
const MERGE_TRAFFIC_SIM_REVISION := "026_competitive_traffic_v1"
const TRAFFIC_HOTFIX_SIM_REVISION := "027_race_traffic_hotfix_v1"
const RACING_LINE_SIM_REVISION := "028_racing_line_v1"
const FOLLOWING_SIM_REVISION := "029_racing_line_following_v1"
const PASS_COMPLETION_SIM_REVISION := "030_racing_line_completion_v1"
const INDEPENDENT_SIM_REVISION := "031_independent_racecraft_v1"
const AERO_WAKE_SIM_REVISION := "032_aero_wake_v1"
const AERO_WAKE_CORRECTED_SIM_REVISION := "033_aero_wake_source_v2"
const AERO_WAKE_STABILITY_SIM_REVISION := "034_aero_traffic_stability_v1"
const AERO_WET_LINE_SIM_REVISION := "035_aero_wet_line_v1"
const TACTICAL_COORDINATION_SIM_REVISION := "036_tactical_coordination_v1"
const CORNER_BATTLE_SIM_REVISION := "037_corner_battle_v1"
const DRIVER_TRAFFIC_SIM_REVISION := "038_driver_traffic_v2"
const TRAFFIC_PACK_SIM_REVISION := "039_traffic_pack_v1"
const DRIVER_ERROR_SIM_REVISION := "040_driver_error_recovery_v1"
const REVISIONS := [
	OVERTAKING_SIM_REVISION,
	START20_SIM_REVISION,
	COMPETITIVE_SIM_REVISION,
	MERGE_TRAFFIC_SIM_REVISION,
	TRAFFIC_HOTFIX_SIM_REVISION,
	RACING_LINE_SIM_REVISION,
	FOLLOWING_SIM_REVISION,
	PASS_COMPLETION_SIM_REVISION,
	INDEPENDENT_SIM_REVISION,
	AERO_WAKE_SIM_REVISION,
	AERO_WAKE_CORRECTED_SIM_REVISION,
	AERO_WAKE_STABILITY_SIM_REVISION,
	AERO_WET_LINE_SIM_REVISION,
	TACTICAL_COORDINATION_SIM_REVISION,
	CORNER_BATTLE_SIM_REVISION,
	DRIVER_TRAFFIC_SIM_REVISION,
	TRAFFIC_PACK_SIM_REVISION,
	DRIVER_ERROR_SIM_REVISION,
]
const OVERTAKING := 1 << 0
const START20 := 1 << 1
const COMPETITIVE := 1 << 2
const MERGE_TRAFFIC := 1 << 3
const TRAFFIC_HOTFIX := 1 << 4
const RACING_LINE := 1 << 5
const FOLLOWING := 1 << 6
const PASS_COMPLETION := 1 << 7
const INDEPENDENT := 1 << 8
const AERO_WAKE := 1 << 9
const AERO_WAKE_CORRECTED := 1 << 10
const AERO_WAKE_STABILITY := 1 << 11
const AERO_WET_LINE := 1 << 12
const TACTICAL_COORDINATION := 1 << 13
const CORNER_BATTLE := 1 << 14
const DRIVER_TRAFFIC := 1 << 15
const TRAFFIC_PACK := 1 << 16
const DRIVER_ERROR := 1 << 17

static func capability_mask(revision: String) -> int:
	var index: int = REVISIONS.find(revision)
	if index < 0:
		return 0
	# All listed gates are cumulative except the original start20 model,
	# which is used ONLY by 024 and 025, never by later revisions.
	var mask: int = (1 << (index + 1)) - 1
	if index > 2:
		mask &= ~START20
	return mask
