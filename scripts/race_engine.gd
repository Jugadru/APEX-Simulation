extends RefCounted
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")

const TelemetryScript = preload("res://scripts/apex_telemetry.gd")
const RaceStandingsText = preload("res://scripts/presentation/race_standings_text.gd")
const Rules = preload("res://scripts/core/race_rules.gd")
const RacePerformance = preload("res://scripts/core/race_performance.gd")
const RaceStart066911 = preload("res://scripts/core/race_start_intelligence_066911.gd")
const RaceStart066917 = preload("res://scripts/core/race_start_spatial_066917.gd")
const CompetitiveStart = preload("res://scripts/core/race_start_competitive_0669172.gd")
const RacingLine = preload("res://scripts/core/race_racing_line_091710.gd")
const RaceSpace = preload("res://scripts/core/race_space_0655.gd")
const OVERTAKING_SIM_REVISION := "023_overtaking_intelligence_v1"
const START20_SIM_REVISION := "024_race_start_spatial_v1"
const COMPETITIVE_SIM_REVISION := "025_competitive_grid_start_v1"
const MERGE_TRAFFIC_SIM_REVISION := "026_competitive_traffic_v1"
const TRAFFIC_HOTFIX_SIM_REVISION := "027_race_traffic_hotfix_v1"
const RACING_LINE_SIM_REVISION := "028_racing_line_v1"
const FOLLOWING_SIM_REVISION := "029_racing_line_following_v1"
const PASS_COMPLETION_SIM_REVISION := "030_racing_line_completion_v1"
const PassCompletion = preload("res://scripts/core/race_pass_completion_091710.gd")
var pass_completion_enabled: bool = true
var following_enabled: bool = true
var racing_line_enabled: bool = true
var racing_line_profile: Dictionary = {}
var traffic_hotfix_enabled: bool = true
var merge_traffic_enabled: bool = true
var command_session: WeakRef
var space_profile: Dictionary = {}
# Session-only replay compatibility: older sporting traces use pre-9.3 traffic logic.
var driver_traffic_enabled: bool = true
# Excluded from checkpoints; old replays must keep their Soul 2.0 sporting rules.
var driver_soul3_enabled: bool = true
# v9.7 changes only same-garage arbitration; legacy 017 replay remains on its old rule.
var pit_coordination2_enabled: bool = true
# v9.7.1: sporting rules for new sessions; 018 and earlier recordings disable
# only this preventive decision, leaving the physical 018 FIFO untouched.
var pit_queue_prevention_enabled: bool = true
# Session-only sporting revision gate: archived 019 replays keep the previous forecast.
var wet_strategy_intelligence_enabled: bool = true
# Session-only revision 021 switch. Archived races keep the old sporting decisions.
var strategy_staff_intelligence_enabled: bool = true
# Session-only replay gate: 021 and earlier keep Improvement 14 launch physics.
var race_start_intelligence_enabled: bool = true
# Session-only replay gate: 023 and earlier retain their original first-turn pace.
var race_start20_enabled: bool = true
# Session-only sporting switch; excluded from saves but replay revision-gated.
var competitive_start_enabled: bool = true
# v9.12 is session-only; old replay revisions retain original tactical calls.
var overtaking_intelligence_enabled: bool = true
const Combat = preload("res://scripts/core/race_combat.gd")
const Strategy = preload("res://scripts/core/race_strategy.gd")
const RaceIntelligence = preload("res://scripts/core/race_intelligence_0645.gd")
const PitWallStrategy3 = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const PredictionLedger06696 = preload("res://scripts/core/race_pitwall_prediction_06696.gd")
const LapStrategy06496 = preload("res://scripts/core/race_lap_reassessment_06496.gd")
const TeamPitCoordinator06497 = preload("res://scripts/core/race_team_pit_coordination_06497.gd")
const DriverSoul = preload("res://scripts/core/race_driver_soul_0647.gd")
const DriverSoul3 = preload("res://scripts/core/race_driver_soul_06694.gd")
const TeamRadioAdvice = preload("res://scripts/core/race_team_radio_advice_06689.gd")
const AIDirector = preload("res://scripts/core/race_ai_director.gd")
const DriverFeedback = preload("res://scripts/core/race_driver_feedback.gd")
const EngineerReply = preload("res://scripts/core/race_engineer_reply.gd")
const PitMath = preload("res://scripts/core/race_pit_math.gd")
const PitLane = preload("res://scripts/core/race_pit_lane.gd")
const PitCoordination2 = preload("res://scripts/core/race_pit_coordination_06697.gd")
const DoubleStackCoordinator = preload("res://scripts/core/race_double_stack_coordinator_06492.gd")
const Tyres2012 = preload("res://scripts/core/race_tyres_2012.gd")
const TyreRules2012 = preload("res://scripts/core/race_tyre_regulations_2012.gd")
const WeatherCore = preload("res://scripts/core/race_weather.gd")
const WetStrategy06698 = preload("res://scripts/core/race_wet_strategy_intelligence_06698.gd")
const StrategyStaff066910 = preload("res://scripts/core/race_strategy_staff_intelligence_066910.gd")
const WetPhysics = preload("res://scripts/core/race_wet_physics.gd")
const RaceKers2012 = preload("res://scripts/core/race_kers_2012.gd")
const RaceDrs2012 = preload("res://scripts/core/race_drs_2012.gd")
const TrackDynamics = preload("res://scripts/core/race_track_dynamics.gd")
const WeatherSetup15 = preload("res://scripts/core/race_weather_setup_15.gd")
const TyreThermal = preload("res://scripts/core/race_tyre_thermal.gd")
## Continuous race simulator with track-dependent parameters.
## Coefficients are experimental gameplay balancing, not official FIA telemetry.
# Legacy classic simulation removed; archive v0.5.4.2 separately.

# Public aliases retained for the HUD, old tests and future plugin APIs.
const PACES = Rules.PACES
const POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
# The pit-lane starts BEFORE the finish line and rejoins AFTER it.
# Both ends belong to the same continuous lap progression.
const PIT_ENTRY_FRACTION: float = 0.950
const PIT_EXIT_FRACTION: float = 0.025
const PIT_TRACK_FRACTION: float = 1.0 - PIT_ENTRY_FRACTION + PIT_EXIT_FRACTION
# These service limits match the stop segment in pit_complex_3d.gd.
# Full pit-loss time and the approved entry/exit spline stay unchanged.
const PIT_QUEUE_PHASE: float = 0.31
const PIT_SERVICE_BEGIN: float = 0.43
const PIT_SERVICE_END: float = 0.57
# Rare game-balance events; explicitly not calibrated to official FIA incident data.
const PIT_GUN_FAILURE_CHANCE: float = 0.040
const PIT_UNSAFE_RELEASE_CHANCE: float = 0.012
# Per-level gameplay bonuses; not official historical F1 pit-crew telemetry.
const CREW_SERVICE_SAVE_PER_LEVEL: float = 0.28
const CREW_DOCK_SAVE_PER_LEVEL: float = 0.18
const CREW_FAULT_REDUCTION_PER_LEVEL: float = 0.24
const CREW_UNSAFE_REDUCTION_PER_LEVEL: float = 0.20

var teams: Array = []
var cars: Array = []
var team_name := "Ferrari"
var team_upgrades: Dictionary = {"Motor": 0, "Asa": 0, "Chassi": 0}
var crew_levels: Dictionary = {"Agilidade": 0, "Precisão": 0, "Coordenação": 0}
var track: Dictionary = {}
var track_name := "Spa-Francorchamps"
var lap_count := 44
var lap_km := 7.004
var race_km := 308.176
var pit_loss := 21.8
var base_lap := 105.0
var clock := 0.0
var lap := 0
var running := false
var finished := false
var events: Array = []
var telemetry
var simulation_profile := Rules.PROFILE_CORE2
var tyre_catalog: Dictionary = {}
var tyre_track_profile: Dictionary = {}
var tyre_specs: Dictionary = {}
var race_wet_declared: bool = false
var weather
var track_dynamics
var weather_mode: String = "Automático"
var weather_phase: String = ""
var _next_event_id: int = 1
var rng := RandomNumberGenerator.new()
var tick_counter := 0
var leader_id := -1
var first_finish_at := -1.0
# Immutable finish crossing order; do not encode time in fictional progress.
var finish_results_validated: bool = false
# Small progressive rival investment, based on championship round (gameplay only).
var rival_development_bonus: float = 0.0
var rival_upgrades: Dictionary = {}

func set_rival_development(levels: Dictionary) -> void:
	# A new season owns individual upgrades; pre-existing round bonus is fallback
	# only for legacy standalone tests without career R&D data.
	rival_upgrades = levels.duplicate(true)

func set_championship_round(round_index: int) -> void:
	# Do not turn a standalone GP into a career progression scenario.
	rival_development_bonus = clampf(float(maxi(0, round_index)) * 0.032, 0.0, 0.62)
var _last_ranks: Dictionary = {}
# One crew/stall per team. A second car must wait for the first to finish.
var pit_crew_owner: Dictionary = {} # team name -> car id
# Stable, seed-driven incidents (same seed produces the same outcomes).
var pit_incidents_enabled: bool = true
# Test-only overrides keyed by car id; not wired to the player HUD.
# Example: {7: {"service_fault": "Porca travada", "service_delay": 5.0, "release_delay": 3.0}}
var pit_incident_test_overrides: Dictionary = {}
# Race-specific, immutable snapshots recorded at pit exit.
# Historical reports read this list, not the transient HUD/radio log.
var pit_history: Array[Dictionary] = []
# Read-only strategy analysis cached between lap/weather/wear changes.
var _engineer_advice_cache: Dictionary = {}
# Session-only observer. Excluded from sporting checkpoints and hashes.
var prediction_ledger = PredictionLedger06696.new()
var prediction_staff: Dictionary = {}
# Captured from the team before the GP and carried in replay policy (no live Garage dependency).
var strategy_staff_profile: Dictionary = {}

func _init(teams_data: Array, player_team: String, seed_value: int, levels: Dictionary, track_payload: Dictionary = {}, trained_crew: Dictionary = {}, competitive_grid: bool = true) -> void:
	teams = teams_data
	team_name = player_team
	competitive_start_enabled = competitive_grid
	team_upgrades = levels.duplicate(true)
	for part in crew_levels.keys():
		crew_levels[part] = clampi(int(trained_crew.get(part, 0)), 0, 3)
	rng.seed = seed_value
	weather = WeatherCore.new()
	weather.setup(track_payload, seed_value, weather_mode)
	weather_phase = str(weather.snapshot().get("track_state", "Seca"))
	tyre_catalog = Tyres2012.catalog()
	tyre_specs = tyre_catalog.get("compounds", {}).duplicate(true)
	_set_track(track_payload)
	track_dynamics = TrackDynamics.new()
	track_dynamics.setup(track, weather.snapshot())
	weather.state.merge(track_dynamics.snapshot(weather.snapshot()), true)
	space_profile = RaceSpace.profile(track)
	racing_line_profile = RacingLine.build(track)
	_start_grid()
	# After the grid exists, initialize the observer without touching RNG or car physics.
	telemetry = TelemetryScript.new()
	telemetry.reset(cars, track, seed_value, clock)
	for prior_event in events:
		telemetry.record_event(prior_event)

func _set_track(payload: Dictionary) -> void:
	track = payload.duplicate(true)
	track_name = str(track.get("name", track_name))
	lap_count = int(track.get("laps", lap_count))
	lap_km = float(track.get("lap_km", lap_km))
	race_km = float(track.get("race_km", lap_km * float(lap_count)))
	pit_loss = float(track.get("pit_loss", pit_loss))
	base_lap = float(track.get("base_lap", base_lap))
	tyre_track_profile = Tyres2012.track_profile(tyre_catalog, str(track.get("code", "BEL")))

func _start_grid() -> void:
	var entries: Array = []
	var idx := 0
	for team in teams:
		for driver in team["drivers"]:
			var car_rating: float = float(team["car"])
			var skill: float = float(driver["skill"])
			entries.append({
				"name": driver["name"],
				"skill": int(skill),
				"car_rating": int(car_rating),
				"team": team["name"],
				"color": team["color"],
				"qualifying": base_lap + 1.1 - (car_rating - 80.0) * 0.10 - (skill - 80.0) * 0.06 + rng.randf_range(-0.36, 0.36),
				"id": idx
			})
			idx += 1
	entries.sort_custom(func(a, b): return float(a["qualifying"]) < float(b["qualifying"]))
	# Grid columns require a full-width opening AND enough safe space at
	# the first pinch. Monaco closes almost to a single lane; Spa pinches
	# immediately. Monza retains sufficient separate corridors before the
	# chicane, which the authoritative solver then narrows safely in motion.
	var first_sector_min_lane: float = RaceSpace.MAX_LANE
	var opening_min_lane: float = RaceSpace.MAX_LANE
	for segment in range(17):
		var clear_lane: float = RaceSpace.lane_limit(track, float(segment) * 0.01, space_profile)
		first_sector_min_lane = minf(first_sector_min_lane, clear_lane)
		if segment <= 4:
			opening_min_lane = minf(opening_min_lane, clear_lane)
	var grid_lane_limit: float = opening_min_lane if first_sector_min_lane >= 2.05 else 0.0
	for i in range(entries.size()):
		var driver: Dictionary = entries[i]
		var grid_pose: Dictionary = CompetitiveStart.slot(i, float(space_profile.length), grid_lane_limit) if competitive_start_enabled else {"progress": -maxf(0.0018, 6.6 / float(space_profile.length)) * float(i), "lane": 0.0}
		var compound := "Médio" if rng.randf() < 0.78 else ("Macio" if rng.randf() < 0.52 else "Duro")
		# Preserve the existing RNG stream while picking legal Core 2 tyres.
		var nominated: Array = available_pit_compounds()
		compound = str(nominated[1]) if (i + 1) % 4 == 0 else str(nominated[0])
		cars.append({
			"id": driver["id"], "name": driver["name"], "team": driver["team"],
			"color": driver["color"], "skill": driver["skill"], "car_rating": driver["car_rating"],
			"grid": i + 1, "race_lane":float(grid_pose.lane), "progress": float(grid_pose.progress), "laps_done": 0,
			"pace": "Normal", "tire": compound, "wear": 0.0, "stint_laps": 0,
			"race_setup_15": WeatherSetup15.neutral(),
			"tyre_heat": 0.0, "attack_charge": 0.0, "track_wear_factor": tyre_severity() * (1.0 + float((int(driver["id"]) % 7) - 3) * 0.022),
			"combat_state": Combat.CLEAR, "combat_target_id": -1, "combat_duel_time": 0.0,
			"combat_cooldown": 0.0, "combat_attempts": 0, "combat_passes": 0,
			"combat_pass_pending": false, "combat_contacts": 0, "combat_hesitation_s": 0.0,
			"combat_last_side": "", "combat_last_margin_m": 0.0,
			# Neutral game-only behavioural defaults; not assertions about real drivers.
			"spatial_awareness": clampf(float(driver["skill"]) + float((int(driver["id"]) * 7) % 11 - 5), 55.0, 98.0),
			"risk_tolerance": float(45 + (int(driver["id"]) * 13) % 27),
			"defense_aggression": float(45 + (int(driver["id"]) * 17) % 20),
			"pit_scheduled_lap": 0, "pit_order_source": "", "pit_control_mode": "Manual",
			"team_yield_to_id": -1, "team_yield_ticks": 0,
			"pit_request": false, "pit_target": str(nominated[1]) if compound == str(nominated[0]) else str(nominated[0]), "pit_left": 0.0,
			"pit_total": 0.0, "pit_phase": 0.0, "pit_from": 0.0, "pit_to": 0.0,
			"pit_service_total": 0.0, "pit_service_elapsed": 0.0,
			"pit_nominal_total": 0.0, "pit_dock_total": 0.0,
			"pit_service_complete": false, "pit_old_tire": "", "pit_last_service": -1.0,
			"pit_stage": "none", "pit_stage_elapsed": 0.0, "pit_active_elapsed": 0.0,
			"pit_wait": 0.0, "pit_last_wait": 0.0, "pit_last_total": 0.0,
			"pit_service_delay": 0.0, "pit_release_delay": 0.0, "pit_extra_elapsed": 0.0,
			"pit_last_extra": 0.0, "pit_incident_type": "", "pit_last_incident": "",
			"pit_entered_at": 0.0, "pit_entry_position": 0,
			"stops": 0, "last_lap": 0.0, "best_lap": 9999.0,
			"lap_started": 0.0, "finished": false, "interval": 0.0,
            "finish_time": -1.0, "finish_laps": 0, "classified_no_finish": false,
            "gap_label": "", "interval_label": "", "invalid_lap_count": 0,
            "wear_warning_stage": 0, "last_pit_exit_lap": -100,
			"gap": 0.0, "position": i + 1, "used_tires": [compound],
			"tyre_rule_violation": false, "disqualified": false,
			"tyre_rule_warning_sent": false,
			"status_icon": "", "ai_plan": {}, "last_engineer_advice_lap": -99,
			"lap_strategy_06496": {}, "lap_strategy_history_06496": [],
			"lap_strategy_adjusted_stint_06496": -999,
			"driver_radio_last_lap": -100, "driver_radio_last_kind": ""
		})
		TyreThermal.reset(cars[-1], weather_snapshot())
		RaceKers2012.initial_state(cars[-1])
		RaceDrs2012.initial_state(cars[-1])
		cars[-1]["driver_soul"] = DriverSoul3.initial(cars[-1])
		_last_ranks[driver["id"]] = i + 1
	leader_id = int(cars[0]["id"])
	_event("grid", -1, "GRID 2012: %d carros em %s. %d voltas / %.3f km." % [cars.size(), track_name, lap_count, race_km], 10)

## Configurable only before green flag; no mutation of a live Grand Prix.
func configure_pre_race_setup(car_id: int, settings: Dictionary) -> bool:
	if running or finished or clock > 0.0 or not WeatherSetup15.valid(settings):
		return false
	for car in cars:
		if int(car.get("id", -1)) == car_id and str(car.get("team", "")) == team_name:
			car["race_setup_15"] = settings.duplicate(true)
			return true
	return false

func available_pit_compounds() -> Array:
	# Exactly two nominated 2012 slicks plus both all-weather tyres.
	return Tyres2012.available(tyre_catalog, str(track.get("code", "BEL"))) + ["Intermediário", "Chuva"]

func configure_weather(profile: String) -> void:
	# Called at grid setup; no RNG consumed, so race/box seeds remain stable.
	if not WeatherCore.PROFILES.has(profile):
		return
	weather_mode = profile
	weather.setup(track, int(rng.seed), profile)
	weather_phase = str(weather.snapshot().get("track_state", "Seca"))
	track_dynamics.setup(track, weather.snapshot())
	weather.state.merge(track_dynamics.snapshot(weather.snapshot()), true)
	# A wet start chooses the appropriate rain tyre before lap 1.
	if clock <= 0.001:
		race_wet_declared = false
		var level: float = float(weather.snapshot().get("wetness_factor", 0.0))
		if level >= 0.17:
			race_wet_declared = true
		var start_compound: String = "Chuva" if level >= 0.66 else ("Intermediário" if level >= 0.16 else "")
		if start_compound != "":
			for car in cars:
				car["tire"] = start_compound
				car["used_tires"] = [start_compound]
				car["pit_target"] = str(Tyres2012.available(tyre_catalog, str(track.get("code", "BEL")))[0])
				TyreThermal.reset(car, weather_snapshot())

func weather_snapshot() -> Dictionary:
	return weather.snapshot() if weather != null else {}


func _team_pit_busy(car: Dictionary) -> bool:
	for teammate in cars:
		if int(teammate["id"]) == int(car["id"]) or str(teammate["team"]) != str(car["team"]):
			continue
		if bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.001:
			return true
	return false

func _build_strategy_plan(car: Dictionary, teammate_busy: bool = false) -> Dictionary:
	var perf_started := Perf.begin() if Perf.enabled else 0
	# Planning happens at lap boundaries or on-demand for the engineer.
	# Weather planning uses current observations only on sporting revision 020.
	# Staff calibration is intentionally neutral here: prediction_staff is an
	# observer excluded from replay checkpoints and cannot affect sporting AI.
	var observed: Dictionary = weather_snapshot()
	var forecast_3: Dictionary = WetStrategy06698.forecast(observed, 3.0 * base_lap,
		str(track.get("code", "")), 1) if wet_strategy_intelligence_enabled else weather.forecast(clock, 3.0 * base_lap)
	var forecast_6: Dictionary = WetStrategy06698.forecast(observed, 6.0 * base_lap,
		str(track.get("code", "")), 1) if wet_strategy_intelligence_enabled else weather.forecast(clock, 6.0 * base_lap)
	var base: Dictionary = AIDirector.plan(car, lap_count, available_pit_compounds(), tyre_specs,
		observed, forecast_3, forecast_6, pit_loss, teammate_busy)
	var perf_result_6: Dictionary = RaceIntelligence.refine(car, cars, base, observed, pit_loss, base_lap, lap_count)
	if wet_strategy_intelligence_enabled:
		perf_result_6 = WetStrategy06698.review_plan(car, perf_result_6, observed, forecast_3, forecast_6)
	if Perf.enabled: Perf.end(&"strategy.plan",perf_started)
	return perf_result_6

func _strategy_staff_report(car: Dictionary, proposal: Dictionary) -> Dictionary:
	if not strategy_staff_intelligence_enabled or str(car.get("team", "")) != team_name:
		return {}
	var teammate: Dictionary = {}
	for other in cars:
		if int(other.get("id", -1)) != int(car.get("id", -1)) \
				and str(other.get("team", "")) == str(car.get("team", "")):
			teammate = other
			break
	return StrategyStaff066910.assess(car, teammate, cars, proposal, weather_snapshot(),
		strategy_staff_profile, available_pit_compounds(), pit_loss, base_lap,
		lap_count, _next_pit_entry_lap(car))

func get_engineer_advice(car_id: int) -> Dictionary:
	for car in cars:
		if int(car.get("id", -1)) != car_id:
			continue
		var weather_data: Dictionary = weather_snapshot()
		var fingerprint: String = "%d|%s|%d|%d|%s|%d|%d|%d" % [
			int(car.get("laps_done", 0)), weather_phase,
			int(float(car.get("wear", 0.0)) / 5.0),
			int(float(weather_data.get("wetness", 0.0)) / 10.0),
			str(car.get("tire", "")), int(bool(car.get("pit_request", false))),
			int(float(car.get("pit_left", 0.0)) > 0.0), int(_team_pit_busy(car))]
		fingerprint += "|%d|%d" % [int(clock / 10.0), int(car.get("pit_scheduled_lap", 0))]
		var cached: Dictionary = _engineer_advice_cache.get(car_id, {})
		if str(cached.get("key", "")) == fingerprint:
			var previous_plan: Dictionary = cached.get("plan", {})
			return previous_plan.duplicate(true)
		var result: Dictionary = _build_strategy_plan(car, _team_pit_busy(car))
		var staff_report: Dictionary = _strategy_staff_report(car, result)
		if not staff_report.is_empty():
			result["staff_strategy_066910"] = staff_report
		# Snapshot calculado exclusivamente na passagem pela linha: a consulta
		# da HUD não recalcula nem cria ordens.
		var review: Dictionary = car.get("lap_strategy_06496", {})
		if int(review.get("lap", -1)) == int(car.get("laps_done", 0)):
			result["lap_review_06496"] = review.duplicate(true)
		_engineer_advice_cache[car_id] = {"key": fingerprint, "plan": result.duplicate(true)}
		return result
	return {}

func tyre_spec(name: String) -> Dictionary:
	return Tyres2012.compound(tyre_catalog, name)

func tyre_code(name: String) -> String:
	return str(tyre_spec(name).get("code", name))

func tyre_severity() -> float:
	# v0.6.3.8 rebalanced stint length after 8-GP testing: preserve
	# relative track severity; lower absolute wear, shared by AI + physics.
	return float(tyre_track_profile.get("severity", 1.0)) * 0.80

func get_state_snapshot() -> Dictionary:
	# Read-only boundary for HUD/radio/integrations. Never leak mutable cars.
	var entries: Array = []
	for car in get_sorted():
		entries.append(car.duplicate(true))
	return {"time": clock, "lap": lap, "lap_count": lap_count,
		"track": track.duplicate(true), "profile": simulation_profile,
		"available_tires": available_pit_compounds(), "tyre_track_severity": tyre_severity(),
		"running": running, "finished": finished,
		"cars": entries, "pit_history": get_pit_history(),
		"recent_events": events.duplicate(true), "weather": weather_snapshot()}

func get_sorted() -> Array:
	var order := cars.duplicate()
	if finished:
		order.sort_custom(func(a, b):
			if bool(a.get("disqualified", false)) != bool(b.get("disqualified", false)):
				return not bool(a.get("disqualified", false))
			if int(a.get("finish_laps", 0)) != int(b.get("finish_laps", 0)):
				return int(a.get("finish_laps", 0)) > int(b.get("finish_laps", 0))
			var ta: float = float(a.get("finish_time", -1.0))
			var tb: float = float(b.get("finish_time", -1.0))
			if ta >= 0.0 and tb >= 0.0:
				return ta < tb
			if ta >= 0.0 or tb >= 0.0:
				return ta >= 0.0
			return float(a["progress"]) > float(b["progress"]))
	else:
		order.sort_custom(func(a, b): return float(a["progress"]) > float(b["progress"]))
	return order

func player_cars() -> Array:
	var output: Array = []
	for car in cars:
		if car["team"] == team_name:
			output.append(car)
	return output

func set_kers_mode(car_id: int, mode: String) -> void:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		command_session.get_ref().enqueue("set_kers_mode", [car_id, mode])
		return

	if not RaceKers2012.MODES.has(mode):
		return
	for car in player_cars():
		if int(car["id"]) == car_id and bool(car.get("kers_equipped", false)):
			car["kers_mode"] = mode
			return

func get_race_control_status(car_id: int) -> Dictionary:
	for car in cars:
		if int(car["id"]) == car_id:
			return {"kers_equipped": bool(car.get("kers_equipped", false)),
				"kers_remaining_kj": float(car.get("kers_remaining_kj", 0.0)),
				"kers_used_lap_kj": float(car.get("kers_used_lap_kj", 0.0)),
				"kers_mode": str(car.get("kers_mode", "Equilibrado")),
				"kers_active": bool(car.get("kers_active", false)),
				"kers_power_kw": float(car.get("kers_power_kw", 0.0)),
				"kers_gain_lap_s": float(car.get("kers_gain_lap_s", 0.0)),
				"drs_gain_lap_s": float(car.get("drs_gain_lap_s", 0.0)),
				"drs_active": bool(car.get("drs_active", false)),
				"drs_eligible": bool(car.get("drs_eligible", false)),
				"drs_detection_gap": float(car.get("drs_detection_gap", 999.0)),
				"drs_track_enabled": bool(weather_snapshot().get("drs_allowed", true))}
	return {}

func set_pace(car_id: int, pace_name: String) -> void:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		command_session.get_ref().enqueue("set_pace", [car_id, pace_name])
		return

	if not PACES.has(pace_name):
		return
	for car in cars:
		if int(car["id"]) == car_id and car["team"] == team_name:
			car["pace"] = pace_name
			return

# 066810: Explicit player-approved short-lived non-defence against a teammate.
# A live request is recorded by Replay; there are no AI-issued team orders.
func team_yield_eligible(leader_id: int, chasing_id: int) -> bool:
	if leader_id == chasing_id or finished:
		return false
	var leader: Dictionary = {}
	var chasing: Dictionary = {}
	for c in player_cars():
		if int(c.id) == leader_id:
			leader = c
		elif int(c.id) == chasing_id:
			chasing = c
	if leader.is_empty() or chasing.is_empty():
		return false
	if int(leader.get("team_yield_ticks", 0)) > 0:
		return false
	var assessment: Dictionary = TeamRadioAdvice.evaluate(chasing, leader, weather_snapshot())
	return bool(assessment.get("valid", false)) and str(assessment.get("state", "")) == "avaliar_passagem" \
		and int(assessment.get("chasing_id", -1)) == chasing_id \
		and int(assessment.get("leading_id", -1)) == leader_id

func authorize_team_yield(leader_id: int, chasing_id: int) -> bool:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		return command_session.get_ref().enqueue("authorize_team_yield", [leader_id, chasing_id])
	if not team_yield_eligible(leader_id, chasing_id):
		return false
	for c in player_cars():
		if int(c.id) == leader_id:
			c["team_yield_to_id"] = chasing_id
			c["team_yield_ticks"] = 75 # 75 * 0.2s = 15 seconds.
			_event("strategy", leader_id, "EQUIPE | %s autorizado a não defender agressivamente de %s por até 15s; passagem não garantida." % [str(c.name), str(chasing_id)], 75)
			return true
	return false

func cancel_team_yield(leader_id: int) -> bool:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		return command_session.get_ref().enqueue("cancel_team_yield", [leader_id])
	for c in player_cars():
		if int(c.id) == leader_id and int(c.get("team_yield_ticks", 0)) > 0:
			c["team_yield_ticks"] = 0
			c["team_yield_to_id"] = -1
			_event("strategy", leader_id, "EQUIPE | autorização de passagem cancelada pelo jogador.", 58)
			return true
	return false

func _next_pit_entry_lap(car: Dictionary) -> int:
	var progress: float = maxf(0.0, float(car.get("progress", 0.0)))
	var current: int = int(floor(progress)) + 1
	if fposmod(progress, 1.0) >= PIT_ENTRY_FRACTION:
		return current + 1
	return current

# Record the staff's advice/confirmed player order before any pit mutation.
# This is advisory-only; all commands still flow through existing gates.
func _prediction_offer(car: Dictionary, target: String, target_lap: int,
		source: String, analysis: Dictionary = {}) -> void:
	if str(car.get("team", "")) != team_name or not available_pit_compounds().has(target):
		return
	if target_lap <= 0 or target_lap >= lap_count:
		return
	var facts: Dictionary = analysis if not analysis.is_empty() else _build_strategy_plan(car, _team_pit_busy(car))
	prediction_ledger.capture_decision(car, cars, facts, weather_snapshot(),
		tyre_specs, prediction_staff, pit_loss, base_lap, PIT_TRACK_FRACTION,
		tick_counter, clock, target_lap, target, source)

func schedule_pit(car_id: int, target: String, target_lap: int) -> bool:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		return command_session.get_ref().enqueue("schedule_pit", [car_id, target, target_lap])

	# Future orders are stored separately from the immediate entry request.
	# A plan for lap 21 can NEVER authorize a stop on lap 4.
	if not available_pit_compounds().has(target):
		return false
	for car in player_cars():
		if int(car["id"]) != car_id:
			continue
		if bool(car.get("finished", false)) or bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0:
			return false
		if target_lap < _next_pit_entry_lap(car) or target_lap >= lap_count:
			_event("radio", car_id, "BOX: volta %d indisponível. Próxima entrada possível: V%d." % [target_lap, _next_pit_entry_lap(car)], 50)
			return false
		_prediction_offer(car, target, target_lap, "agendamento_manual")
		car["pit_scheduled_lap"] = target_lap
		car["pit_target"] = target
		car["pit_order_source"] = "agendamento_manual"
		_engineer_advice_cache.erase(car_id)
		_event("strategy", car_id, "BOX AGENDADO | %s na volta %d para %s. Sem autorização para antecipar." % [str(car["name"]), target_lap, target], 75)
		return true
	return false

func cancel_scheduled_pit(car_id: int) -> bool:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		return command_session.get_ref().enqueue("cancel_scheduled_pit", [car_id])

	for car in player_cars():
		if int(car["id"]) == car_id and int(car.get("pit_scheduled_lap", 0)) > 0:
			var old_lap: int = int(car["pit_scheduled_lap"])
			prediction_ledger.cancel_decision(car_id, old_lap)
			car["pit_scheduled_lap"] = 0
			car["pit_order_source"] = ""
			_engineer_advice_cache.erase(car_id)
			_event("strategy", car_id, "BOX CANCELADO | %s: agendamento V%d removido." % [str(car["name"]), old_lap], 48)
			return true
	return false

func set_pit_control_mode(car_id: int, mode: String) -> bool:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		return command_session.get_ref().enqueue("set_pit_control_mode", [car_id, mode])

	if mode not in ["Manual", "IA"]:
		return false
	for car in player_cars():
		if int(car["id"]) == car_id:
			car["pit_control_mode"] = mode
			_engineer_advice_cache.erase(car_id)
			_event("strategy", car_id, "%s: controle de box %s. Ordem manual agendada permanece válida." % [str(car["name"]), mode], 60)
			return true
	return false

func order_pit(car_id: int, target: String) -> void:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		command_session.get_ref().enqueue("order_pit", [car_id, target])
		return

	# An immediate command explicitly replaces a scheduled stop, if any.
	if not available_pit_compounds().has(target):
		return
	for car in player_cars():
		if int(car["id"]) == car_id:
			if bool(car.get("finished", false)) or float(car.get("pit_left", 0.0)) > 0.0 or bool(car.get("pit_request", false)) or _next_pit_entry_lap(car) >= lap_count:
				return
			var previous_schedule: int = int(car.get("pit_scheduled_lap", 0))
			if previous_schedule > 0:
				prediction_ledger.cancel_decision(car_id, previous_schedule)
			_prediction_offer(car, target, _next_pit_entry_lap(car), "ordem_imediata")
			car["pit_scheduled_lap"] = 0
			car["pit_request"] = true
			car["pit_target"] = target
			car["pit_order_source"] = "ordem_imediata"
			_engineer_advice_cache.erase(car_id)
			if previous_schedule > 0:
				_event("strategy", car_id, "BOX: agendamento V%d substituído por ordem imediata do jogador." % previous_schedule, 70)
			_event("radio", car_id, "%s: box solicitado na próxima entrada para %s." % [car["name"], target], 38)
			for teammate in cars:
				if int(teammate["id"]) != car_id and str(teammate["team"]) == str(car["team"]):
					if bool(teammate["pit_request"]) or float(teammate["pit_left"]) > 0.0:
						_event("radio", car_id, "ESTRATÉGIA: dupla chamada para %s. Possível DOUBLE STACK!" % car["team"], 84)
						break
			return

func step(sim_delta: float) -> void:
	var perf_started := Perf.begin() if Perf.enabled else 0
	if not running or finished:
		if Perf.enabled: Perf.end(&"race.step",perf_started)
		return
	var remaining := minf(4.0, maxf(0.0, sim_delta))
	while remaining > 0.0:
		var dt := minf(0.20, remaining)
		_advance(dt)
		remaining -= dt
	if Perf.enabled: Perf.end(&"race.step",perf_started)

func _advance(dt: float) -> void:
	clock += dt
	var current_weather: Dictionary = weather.advance(dt, clock, clampf(float(lap) / maxf(1.0, float(lap_count)), 0.0, 1.0))
	current_weather.merge(track_dynamics.advance(dt, current_weather, cars.size(), base_lap), true)
	# Keep the legacy weather/HUD/radio API intact; the original 0643 water
	# engine remains the sole source of rainfall, off-line water and forecast.
	weather.state.merge(current_weather, true)
	var phase: String = str(current_weather.get("track_state", "Seca"))
	if float(current_weather.get("wetness_factor", 0.0)) >= 0.17:
		race_wet_declared = true
	if phase != weather_phase:
		weather_phase = phase
		_event("weather", -1, "PISTA %s: água na linha %.2f mm, umidade residual %d%%, chuva %d%%." % [phase.to_upper(), float(current_weather.get("water_mm", 0.0)), int(current_weather.get("surface_moisture_percent", 0)), int(round(float(current_weather["rain_intensity"]) * 100.0))], 91)
	# A frozen snapshot prevents cars updated earlier in the loop from
	# influencing others through iteration order. Combat and pace see the
	# same positions at the start of every physics tick.
	var perf_snapshot := Perf.begin() if Perf.enabled else 0
	# A yield order expires after 15 simulated seconds or when the follower is
	# no longer behind. No effect on RNG, pit calls or driving speed.
	var by_team_id: Dictionary = {}
	for entry in cars:
		by_team_id[int(entry.id)] = entry
	for entry in cars:
		if int(entry.get("team_yield_ticks", 0)) <= 0:
			continue
		var target_id: int = int(entry.get("team_yield_to_id", -1))
		var mate: Dictionary = by_team_id.get(target_id, {})
		if mate.is_empty() or bool(entry.get("finished", false)) or bool(mate.get("finished", false)) \
				or str(mate.get("team", "")) != str(entry.get("team", "")) \
				or float(mate.get("progress", -1.0)) >= float(entry.get("progress", -1.0)):
			entry["team_yield_ticks"] = 0
			entry["team_yield_to_id"] = -1
		else:
			entry["team_yield_ticks"] = maxi(0, int(entry["team_yield_ticks"]) - 1)
			if int(entry["team_yield_ticks"]) == 0:
				entry["team_yield_to_id"] = -1
	var old_order: Array = []
	for entry in get_sorted():
		# 0.6.6.8.3: freeze the scalar sporting fields without deep-copying
		# histories, soul/strategy dictionaries or tyre arrays every tick.
		# RacePerformance.evaluate and RaceSpace.plan only read scalar fields;
		# TyreThermal.advance writes new scalar values to the live car, then
		# those same values are merged into this detached top-level view.
		# Never mutate nested members of old_order; deep copies remain
		# mandatory at the public get_state_snapshot/replay/save boundary.
		old_order.append(entry.duplicate(false))
	if Perf.enabled: Perf.end(&"race.snapshot",perf_snapshot)
	var gaps: Dictionary = {}
	for i in range(old_order.size()):
		var old_car: Dictionary = old_order[i]
		gaps[old_car["id"]] = 999.0 if i == 0 else maxf(0.0, (float(old_order[i - 1]["progress"]) - float(old_car["progress"])) * base_lap)
	# Replays recorded before Improvement 14 must retain their original physics.
	# Session metadata lives outside sporting state/checkpoints and has no RNG effect.
	var launch_legacy: bool = false
	var overtaking_rules: bool = overtaking_intelligence_enabled
	var start20_rules: bool = race_start20_enabled
	var competitive_rules: bool = competitive_start_enabled
	var merge_rules: bool = merge_traffic_enabled and competitive_rules
	var traffic_hotfix_rules: bool = traffic_hotfix_enabled
	var racing_line_rules: bool = racing_line_enabled
	var following_rules: bool = following_enabled and racing_line_enabled
	var completion_rules: bool = pass_completion_enabled and following_rules
	if command_session != null:
		var attached_session: Object = command_session.get_ref()
		if attached_session != null:
			launch_legacy = bool(attached_session.get("legacy_launch_physics"))
			var revision: String = str(attached_session.get("recorded_simulation_revision"))
			overtaking_rules = overtaking_rules and revision in [OVERTAKING_SIM_REVISION, START20_SIM_REVISION, COMPETITIVE_SIM_REVISION, MERGE_TRAFFIC_SIM_REVISION, TRAFFIC_HOTFIX_SIM_REVISION, RACING_LINE_SIM_REVISION, FOLLOWING_SIM_REVISION, PASS_COMPLETION_SIM_REVISION]
			start20_rules = start20_rules and revision in [START20_SIM_REVISION, COMPETITIVE_SIM_REVISION]
			competitive_rules = competitive_rules and revision in [COMPETITIVE_SIM_REVISION, MERGE_TRAFFIC_SIM_REVISION, TRAFFIC_HOTFIX_SIM_REVISION, RACING_LINE_SIM_REVISION, FOLLOWING_SIM_REVISION, PASS_COMPLETION_SIM_REVISION]
			merge_rules = merge_rules and revision in [MERGE_TRAFFIC_SIM_REVISION, TRAFFIC_HOTFIX_SIM_REVISION, RACING_LINE_SIM_REVISION, FOLLOWING_SIM_REVISION, PASS_COMPLETION_SIM_REVISION]
			traffic_hotfix_rules = traffic_hotfix_rules and revision in [TRAFFIC_HOTFIX_SIM_REVISION, RACING_LINE_SIM_REVISION, FOLLOWING_SIM_REVISION, PASS_COMPLETION_SIM_REVISION]
			racing_line_rules = racing_line_rules and revision in [RACING_LINE_SIM_REVISION, FOLLOWING_SIM_REVISION, PASS_COMPLETION_SIM_REVISION]
			following_rules = following_rules and revision in [FOLLOWING_SIM_REVISION, PASS_COMPLETION_SIM_REVISION]
			completion_rules = completion_rules and revision == PASS_COMPLETION_SIM_REVISION
	var launch_clearance: float = 1.0
	var launch_limit: float = RaceStart066917.CORNER_PHASE_SECONDS if start20_rules else RaceStart066911.PHASE_SECONDS
	if race_start_intelligence_enabled and clock < launch_limit:
		launch_clearance = RaceStart066911.first_sector_clearance(track, space_profile)
	var context: Dictionary = {"gap": 999.0, "lap": lap, "clock": clock, "launch_enabled": not launch_legacy,
		"race_start_intelligence_enabled": race_start_intelligence_enabled,
		"race_start20_enabled": start20_rules,
		"launch_space_clearance": launch_clearance,
		"launch_grid": old_order if start20_rules and clock < RaceStart066917.CORNER_PHASE_SECONDS else [],
		"launch_circuit_length": float(space_profile.get("length", 1000.0)),
		"race_laps": lap_count, "base_lap": base_lap,
		"upgrades": team_upgrades, "player_car": false, "track": track,
		"tyre_specs": tyre_specs, "tyre_track_severity": tyre_severity(),
		"rival_development_bonus": rival_development_bonus,
		"rival_upgrades": rival_upgrades, "weather": current_weather}
	var live_by_id: Dictionary = {}
	for actual in cars:
		live_by_id[int(actual["id"])] = actual
	var perf_pace := Perf.begin() if Perf.enabled else 0
	var pace_metrics: Dictionary = {}
	for old_car in old_order:
		if bool(old_car.get("finished", false)) or float(old_car.get("pit_left", 0.0)) > 0.0:
			continue
		context["gap"] = float(gaps.get(old_car["id"], 999.0))
		context["player_car"] = str(old_car["team"]) == team_name
		var live_car: Dictionary = live_by_id[int(old_car["id"])]
		var thermal_now: Dictionary = TyreThermal.advance(live_car, current_weather,
			track_dynamics.characteristics, dt, base_lap)
		old_car.merge(thermal_now, true)
		var old_progress: float = float(old_car["progress"])
		var projected_progress: float = old_progress + dt / maxf(1.0, base_lap)
		context["kers_active"] = RaceKers2012.apply(live_car, old_progress, float(context["gap"]), dt, track)
		context["kers_power_kw"] = float(live_car.get("kers_power_kw", 0.0))
		context["kers_mode"] = str(live_car.get("kers_mode", "Equilibrado"))
		context["drs_active"] = RaceDrs2012.update(live_car, old_progress, projected_progress,
			float(context["gap"]), track, current_weather)
		var metrics: Dictionary = RacePerformance.evaluate(old_car, context)
		if racing_line_rules and clock >= RacingLine.START_SECONDS and old_progress >= 0.0 and not racing_line_profile.is_empty():
			var line: Dictionary = RacingLine.sample(racing_line_profile, old_progress, float(current_weather.get("wetness_factor",0.0)), float(old_car.get("skill",80.0)))
			if following_rules:
				metrics["decision_pace"] = float(metrics.target)
				metrics["line_load"] = float(line.load)
				if completion_rules:
					# Tactical judgement separates sustained race pace from short energy bursts.
					metrics["decision_pace"] = float(metrics.target)-0.80*(float(metrics.drs)+float(metrics.kers))-float(metrics.traffic)
					# Retain braking/recovery, but temper schematic curvature gradients.
					line.pace_factor = lerpf(1.0,float(line.pace_factor),0.55)
			metrics.target = float(metrics.target)*float(line.pace_factor)
			# A pit-bound car retains existing pit approach behavior.
			var fraction: float = fposmod(old_progress,1.0)
			if fraction>0.04 and fraction<0.93:
				metrics["line_ratio"] = float(line.lane_ratio)
		pace_metrics[int(old_car["id"])] = metrics
	if Perf.enabled: Perf.end(&"race.pace_thermal_drs_kers",perf_pace)
	var perf_space := Perf.begin() if Perf.enabled else 0
	var space_plan := RaceSpace.plan(old_order,pace_metrics,dt,track,space_profile,current_weather,driver_traffic_enabled,driver_soul3_enabled,overtaking_rules,competitive_rules,clock,merge_rules,traffic_hotfix_rules,following_rules,completion_rules)
	if Perf.enabled: Perf.end(&"race.overtaking",perf_space)
	var defenders: Dictionary = {}
	for car in cars:
		if bool(car["finished"]):
			continue
		if float(car["pit_left"]) > 0.0:
			_advance_pit(car, dt)
			continue
		var metrics: Dictionary = pace_metrics.get(int(car["id"]), {})
		if metrics.is_empty():
			continue
		var target: float = float(metrics["target"])
		# Estimated per-lap time gain relative to the same car without active
		# KERS/DRS. Informational; progress still comes from the pace model.
		car["kers_gain_lap_s"] = float(car.get("kers_gain_lap_s", 0.0)) + dt * maxf(0.0, -float(metrics.get("kers", 0.0))) / maxf(1.0, target)
		car["drs_gain_lap_s"] = float(car.get("drs_gain_lap_s", 0.0)) + dt * maxf(0.0, -float(metrics.get("drs", 0.0))) / maxf(1.0, target)
		var wear: float = float(car["wear"])
		var prev: float = float(car["progress"])
		var contest: Dictionary = space_plan.get(int(car.id),{})
		if contest.is_empty(): continue
		car.merge(contest.states,true)
		var next: float = float(contest.progress)
		var ahead: Variant = null
		for old in old_order:
			if int(old.id)==int(car.get("combat_target_id",-1)):
				ahead=old
				break

		if int(contest.get("defender_id", -1)) >= 0:
			defenders[int(contest["defender_id"])] = true
		var battle_event: String = str(contest.get("event", ""))
		if battle_event == "attack" and ahead != null:
			_event("battle", int(car["id"]), "%s prepara ataque a %s!" % [str(car["name"]), str(ahead["name"])], 61)
		elif battle_event == "defend":
			_event("battle", int(car["id"]), "%s protege a linha antes do ataque." % str(car["name"]), 47)
		elif battle_event == "yield" and ahead != null:
			_event("battle", int(car["id"]), "%s retirou o ataque a %s: espaço insuficiente na curva." % [str(car["name"]), str(ahead["name"])], 53)
		elif battle_event == "contact" and ahead != null:
			var defender_id: int = int(ahead["id"])
			if live_by_id.has(defender_id):
				var opponent: Dictionary = live_by_id[defender_id]
				opponent["combat_contacts"] = int(opponent.get("combat_contacts", 0)) + 1
				# Deferred loss is accounted for after updating ALL cars this tick.
				defenders[defender_id] = float(contest.get("defender_loss_s", 0.0))
			_event("contact", int(car["id"]), "CONTATO LATERAL | %s e %s disputaram espaço na curva." % [str(car["name"]), str(ahead["name"])], 110)

		# A requested stop begins when the car reaches the pit entrance, not
		# when it has already crossed the finish line. This makes entrance and
		# exit physical positions coherent with the 3D pit-lane spline.
		var lap_number: int = int(floor(maxf(0.0, prev)))
		var entry_progress: float = float(lap_number) + PIT_ENTRY_FRACTION
		var exact_lap: int = lap_number + 1
		var scheduled_lap: int = int(car.get("pit_scheduled_lap", 0))
		var permitted_pit: bool = bool(car["pit_request"]) or (scheduled_lap > 0 and exact_lap == scheduled_lap)
		if permitted_pit and prev < entry_progress and next >= entry_progress and exact_lap < lap_count:
			# 06492: last safe chance to avoid an actual garage queue. Use live
			# tyre/climate state; never replace V21, immediate player or urgent calls.
			var diverted: bool = false
			if bool(car.get("pit_request", false)) and str(car.get("pit_order_source", "")) == "ia_estrategia":
				var teammate: Dictionary = {}
				for other in cars:
					if int(other.get("id", -1)) != int(car.get("id", -1)) and str(other.get("team", "")) == str(car.get("team", "")):
						teammate = other
						break
				if not teammate.is_empty():
					var projected_nominal: float = pit_loss + base_lap * PIT_TRACK_FRACTION
					var queue_s: float = DoubleStackCoordinator.estimated_queue(car, teammate, projected_nominal, PIT_QUEUE_PHASE)
					if queue_s >= DoubleStackCoordinator.QUEUE_MIN_S:
						var future_weather: Dictionary = WetStrategy06698.forecast(weather_snapshot(), base_lap * 3.0,
							str(track.get("code", "")), 1) if wet_strategy_intelligence_enabled else weather.forecast(clock, base_lap * 3.0)
						if DoubleStackCoordinator.should_stagger(car, teammate, car.get("ai_plan", {}), weather_snapshot(), future_weather, queue_s, exact_lap, lap_count):
							car["pit_request"] = false
							car["pit_order_source"] = ""
							car["pitwall49_held"] = true
							var revised: Dictionary = car.get("ai_plan", {}).duplicate(true)
							revised["pit_now"] = false
							revised["pitwall49_hold"] = true
							revised["reason"] = "garage ocupada; evitar fila na entrada"
							car["ai_plan"] = revised
							_engineer_advice_cache.erase(int(car["id"]))
							_event("strategy", int(car["id"]), "PIT WALL 3.0 | %s: evitar fila prevista ~%.1fs; manter na pista e reavaliar na próxima volta." % [str(car["name"]), queue_s], 67)
							diverted = true
			if not diverted:
				if scheduled_lap == exact_lap:
					_event("strategy", int(car["id"]), "BOX AGENDADO V%d | %s: executando na entrada correta, sem antecipação." % [exact_lap, str(car["name"])], 76)
				car["progress"] = entry_progress
				_begin_pit(car, entry_progress)
				continue
		car["progress"] = maxf(prev, next)
		car["wear"] = RacePerformance.wear_after(wear, float(metrics["wear_factor"]), dt, target)
		# The thermal module writes tyre_heat on the live car. The old Core2
		# heuristic is still returned for backwards compatibility only.
		_record_lap_cross(car, prev)
		# Safety net: an AI car must not circulate for laps at 100% tyre wear.
		# Normal decisions still happen at the lap line; this extra check is
		# deliberately rare and uses no RNG or changes to pit-lane timing.
		if (str(car["team"]) != team_name or str(car.get("pit_control_mode", "Manual")) == "IA") and not bool(car["pit_request"]) and int(car.get("pit_scheduled_lap", 0)) == 0 and not bool(car["finished"]) and float(car["wear"]) >= 93.0:
			_request_ai_pit(car, true)
		# The leader takes the chequered flag at the official distance. Once
		# that happens, lapped cars finish at their NEXT real line crossing.
		if int(car["laps_done"]) > maxi(0, int(floor(prev))) and (int(car["laps_done"]) >= lap_count or first_finish_at >= 0.0):
			_mark_finish(car)
	for car in cars:
		if defenders.has(int(car["id"])) and not bool(car.get("finished", false)) and float(car.get("pit_left", 0.0)) <= 0.0:
			var contact_loss: float = 0.0
			if typeof(defenders[int(car["id"])]) == TYPE_FLOAT:
				contact_loss = float(defenders[int(car["id"])])
			if contact_loss > 0.0:
				car["combat_hesitation_s"] = maxf(float(car.get("combat_hesitation_s", 0.0)), contact_loss)
			if str(car.get("combat_state", Combat.CLEAR)) in [Combat.CLEAR, Combat.CLOSING, Combat.RECOVERING]:
				car["combat_state"] = Combat.DEFENDING
	var ordered := get_sorted()
	var completed_passes: Dictionary = PassCompletion.observe(old_order,ordered,float(space_profile.length),dt) if completion_rules else {}
	var leader: Dictionary = ordered[0]
	var lead_prog := float(leader["progress"])
	lap = mini(lap_count, maxi(0, int(floor(lead_prog)) + 1))
	for i in range(ordered.size()):
		var car = ordered[i]
		car["position"] = i + 1
		car["gap"] = maxf(0.0, (lead_prog - float(car["progress"])) * base_lap)
		car["interval"] = 0.0 if i == 0 else maxf(0.0, (float(ordered[i - 1]["progress"]) - float(car["progress"])) * base_lap)
		var previous := int(_last_ranks.get(car["id"], i + 1))
		if completion_rules:
			car["combat_pass_pending"] = false
			var confirmed: int = int(completed_passes.get(car.id,0))
			if confirmed>0:
				car["combat_passes"] = int(car.get("combat_passes",0))+confirmed
				_event("pass", int(car.id), "ULTRAPASSAGEM CONFIRMADA | %s consolidou P%d." % [str(car.name),i+1],85)
				car["last_pass_event_at"] = clock
			elif i+1<previous and clock>5.0 and clock-float(car.get("last_pass_event_at",-100.0))>=6.0:
				_event("position_gain",int(car.id),"GANHO DE POSICAO | %s avancou para P%d." % [str(car.name),i+1],57)
				car["last_pass_event_at"] = clock
		elif i + 1 < previous and clock > 5.0:
			# Rank movement (pit/traffic) is not proof of a wheel-to-wheel pass.
			var on_track_pass: bool = bool(car.get("combat_pass_pending", false))
			if on_track_pass:
				car["combat_passes"] = int(car.get("combat_passes", 0)) + 1
				car["combat_pass_pending"] = false
			if clock - float(car.get("last_pass_event_at", -100.0)) >= 6.0:
				var event_kind: String = "pass" if on_track_pass else "position_gain"
				var event_prefix: String = "ULTRAPASSAGEM" if on_track_pass else "GANHO DE POSICAO (boxes/ritmo)"
				_event(event_kind, int(car["id"]), "%s | %s avançou para P%d." % [event_prefix, str(car["name"]), i + 1], 85 if on_track_pass else 57)
				car["last_pass_event_at"] = clock
		_last_ranks[car["id"]] = i + 1
	if int(leader["id"]) != leader_id and clock > 5.0:
		leader_id = int(leader["id"])
		_event("lead", leader_id, "%s assumiu a liderança em %s!" % [leader["name"], track_name], 100)
	tick_counter += 1
	if telemetry != null:
		telemetry.observe(cars, clock, dt)
		telemetry.record_weather(clock, current_weather)
	if first_finish_at >= 0.0 and (_all_finished() or clock - first_finish_at >= maxf(130.0, base_lap * 1.8)):
		# Timeout does not invent a finish-line crossing for cars still circulating.
		for car in cars:
			if not bool(car["finished"]):
				car["finished"] = true
				car["finish_laps"] = maxi(0, int(car["laps_done"]))
				car["classified_no_finish"] = true
				_event("classification", int(car["id"]), "%s: classificado sem cruzamento apos limite de encerramento." % str(car["name"]), 55)
		finished = true
		running = false
		prediction_ledger.close_unfinished()
		_finalize_classification()

func get_pit_crew_effects() -> Dictionary:
	return PitMath.crew_effects(crew_levels,
		CREW_SERVICE_SAVE_PER_LEVEL, CREW_DOCK_SAVE_PER_LEVEL,
		PIT_GUN_FAILURE_CHANCE, PIT_UNSAFE_RELEASE_CHANCE,
		CREW_FAULT_REDUCTION_PER_LEVEL, CREW_UNSAFE_REDUCTION_PER_LEVEL)

func _crew_bonus_for(car: Dictionary) -> Dictionary:
	# Only the player team's trained crew receives these bonuses.
	# AI teams retain the historical default gameplay tuning.
	if str(car["team"]) == team_name:
		return get_pit_crew_effects()
	return {"service_saving": 0.0, "dock_saving": 0.0,
		"fault_chance": PIT_GUN_FAILURE_CHANCE, "unsafe_chance": PIT_UNSAFE_RELEASE_CHANCE}

func _begin_pit(car: Dictionary, entry_progress: float) -> void:
	# Freeze the forecast at commitment, BEFORE mutations or RNG pit incidents.
	# Does not schedule, cancel or change the stop.
	prediction_ledger.capture_entry(car, cars, _build_strategy_plan(car, _team_pit_busy(car)),
		weather_snapshot(), tyre_specs, prediction_staff if str(car.get("team", "")) == team_name else {},
		pit_loss, base_lap, PIT_TRACK_FRACTION, tick_counter, clock)
	car["kers_active"] = false
	car["kers_power_kw"] = 0.0
	car["drs_active"] = false
	car["pit_request"] = false
	car["pit_scheduled_lap"] = 0
	car["pit_entered_at"] = clock
	car["pit_entry_position"] = int(car.get("position", 0))
	car["pit_from"] = entry_progress
	car["pit_to"] = floor(entry_progress) + 1.0 + PIT_EXIT_FRACTION
	# Base time is unchanged from v0.5.2.5. Only a genuine double-stack
	# adds waiting seconds to the actual elapsed pit time.
	var nominal: float = pit_loss + base_lap * PIT_TRACK_FRACTION + rng.randf_range(-0.6, 0.6)
	var benefits: Dictionary = _crew_bonus_for(car)
	# Keep approach and exit durations identical to the approved pit-lane
	# animation. Savings apply only to servicing and docking, not driving.
	var durations: Dictionary = PitMath.service_durations(nominal,
		PIT_SERVICE_BEGIN, PIT_SERVICE_END, PIT_QUEUE_PHASE, benefits)
	car["pit_nominal_total"] = nominal
	car["pit_service_total"] = float(durations["service_total"])
	car["pit_dock_total"] = float(durations["dock_total"])
	car["pit_total"] = float(durations["pit_total"])
	car["pit_left"] = float(car["pit_total"])
	car["pit_phase"] = 0.0
	car["pit_stage"] = "approach"
	car["pit_stage_elapsed"] = 0.0
	car["pit_active_elapsed"] = 0.0
	car["pit_wait"] = 0.0
	car["pit_old_tire"] = str(car["tire"])
	car["pit_service_elapsed"] = 0.0
	car["pit_service_complete"] = false
	car["pit_service_delay"] = 0.0
	car["pit_release_delay"] = 0.0
	car["pit_extra_elapsed"] = 0.0
	car["pit_incident_type"] = ""
	_roll_pit_incidents(car)
	car["stops"] = int(car["stops"]) + 1
	_event("pit", int(car["id"]), "BOX: %s entrando para %s." % [car["name"], car["pit_target"]], 85)

func _roll_pit_incidents(car: Dictionary) -> void:
	# Roll only at pit entry. With the same grid seed and choices, the outcome
	# repeats. The override exists exclusively for regression tests.
	if not pit_incidents_enabled:
		return
	var forced: Dictionary = pit_incident_test_overrides.get(int(car["id"]), {})
	if not forced.is_empty():
		pit_incident_test_overrides.erase(int(car["id"])) # test choice applies to first stop only
	if forced.has("service_fault"):
		car["pit_incident_type"] = str(forced["service_fault"])
		car["pit_service_delay"] = maxf(0.0, float(forced.get("service_delay", 0.0)))
	elif forced.is_empty() and rng.randf() < float(_crew_bonus_for(car)["fault_chance"]):
		if rng.randf() < 0.78:
			car["pit_incident_type"] = "Pistola pneumática"
			car["pit_service_delay"] = rng.randf_range(1.4, 3.6)
		else:
			car["pit_incident_type"] = "Porca travada"
			car["pit_service_delay"] = rng.randf_range(3.0, 7.0)
	if forced.has("release_delay"):
		car["pit_release_delay"] = maxf(0.0, float(forced["release_delay"]))
	elif forced.is_empty() and rng.randf() < float(_crew_bonus_for(car)["unsafe_chance"]):
		car["pit_release_delay"] = rng.randf_range(3.0, 5.5)
	if float(car["pit_release_delay"]) > 0.0:
		var existing: String = str(car["pit_incident_type"])
		car["pit_incident_type"] = (existing + " + " if existing != "" else "") + "Retenção de segurança"

func _start_pit_repair(car: Dictionary) -> void:
	car["pit_stage"] = "repair"
	car["pit_stage_elapsed"] = 0.0
	car["pit_phase"] = PIT_SERVICE_END - 0.005
	_event("pit_failure", int(car["id"]), "FALHA BOX | %s: %s, atraso +%.1fs." % [car["name"], str(car["pit_incident_type"]).split(" + ")[0], float(car["pit_service_delay"])], 105)

func _start_pit_safety_hold(car: Dictionary) -> void:
	car["pit_stage"] = "safety_hold"
	car["pit_stage_elapsed"] = 0.0
	car["pit_phase"] = PIT_SERVICE_END
	_event("unsafe_release", int(car["id"]), "SEGURANÇA BOX | %s: risco de liberação insegura; retido +%.1fs." % [car["name"], float(car["pit_release_delay"])], 112)

func _continue_pit_exit(car: Dictionary) -> void:
	_release_garage(car)
	car["pit_stage"] = "exit"
	car["pit_stage_elapsed"] = 0.0

func _stage_duration(car: Dictionary, stage: String) -> float:
	return PitLane.stage_duration(car, stage, PIT_QUEUE_PHASE, PIT_SERVICE_BEGIN, PIT_SERVICE_END)

func _garage_available(car: Dictionary) -> bool:
	var team: String = str(car["team"])
	if not pit_coordination2_enabled:
		# Exact v9.6 transition: preserve exported revision 017 replays.
		return not pit_crew_owner.has(team) or int(pit_crew_owner[team]) == int(car["id"])
	# The earlier physical garage arrival wins; car-array iteration is never
	# the tie-break. One crew remains exclusive until release/safety hold ends.
	return PitCoordination2.eligible(car, cars, pit_crew_owner, clock, PIT_QUEUE_PHASE)

func _acquire_garage(car: Dictionary) -> void:
	pit_crew_owner[str(car["team"])] = int(car["id"])
	if float(car["pit_wait"]) > 0.001:
		_event("double_stack", int(car["id"]), "%s: vaga liberada após %.1fs de espera." % [car["name"], float(car["pit_wait"])], 93)
	car["pit_stage"] = "dock"
	car["pit_stage_elapsed"] = 0.0

func _release_garage(car: Dictionary) -> void:
	var team: String = str(car["team"])
	if pit_crew_owner.has(team) and int(pit_crew_owner[team]) == int(car["id"]):
		pit_crew_owner.erase(team)

func _finish_service(car: Dictionary) -> void:
	car["pit_service_complete"] = true
	car["pit_last_service"] = float(car["pit_service_total"])
	car["tire"] = str(car["pit_target"])
	car["used_tires"].append(car["tire"])
	car["wear"] = 0.0
	car["stint_laps"] = 0
	# v0.6.4.9.1: allow at most one automatic double-stack hold per stint.
	# Rearm ONLY after genuine tyre service, not when a pit is requested,
	# scheduled or entered, so repeated evaluations cannot re-defer it.
	car["pitwall49_held"] = false
	car["wear_warning_stage"] = 0
	car["last_pit_exit_lap"] = int(car.get("laps_done", 0))
	# New set of tyres resets the optional Core 2 thermal/attack state.
	TyreThermal.reset(car, weather_snapshot())
	car["attack_charge"] = 0.0
	car["combat_state"] = Combat.CLEAR
	car["combat_target_id"] = -1
	car["combat_duel_time"] = 0.0
	car["combat_cooldown"] = 0.0
	car["combat_pass_pending"] = false
	car["kers_active"] = false
	car["drs_active"] = false
	_event("service", int(car["id"]), "%s: quatro pneus %s instalados em %.2fs." % [car["name"], car["tire"], float(car["pit_service_total"])], 58)
	if float(car["pit_release_delay"]) > 0.0:
		_start_pit_safety_hold(car)
	else:
		_continue_pit_exit(car)

func _advance_pit(car: Dictionary, dt: float) -> void:
	var perf_started := Perf.begin() if Perf.enabled else 0
	# Call the standalone state machine; engine still owns garages, incidents,
	# timestamps, radio events and completed pit-history records.
	var previous: float = float(car["progress"])
	PitLane.advance(self, car, dt, PIT_QUEUE_PHASE, PIT_SERVICE_BEGIN, PIT_SERVICE_END)
	if not bool(car["finished"]) and first_finish_at >= 0.0 and float(car["pit_left"]) <= 0.0 and int(car["laps_done"]) > int(floor(previous)):
		_mark_finish(car)
	if Perf.enabled: Perf.end(&"pit.advance",perf_started)

func _record_pit_history(car: Dictionary) -> void:
	# Exactly one immutable record per completed stop. A queued car is not
	# recorded until the service and departure have both finished.
	var expected: float = float(car["pit_nominal_total"])
	var measured: float = float(car["pit_last_total"])
	var live_rank := 0
	var ordered: Array = get_sorted()
	for i in range(ordered.size()):
		if int(ordered[i]["id"]) == int(car["id"]):
			live_rank = i + 1
			break
	pit_history.append({
		"car_id": int(car["id"]), "driver": str(car["name"]),
		"team": str(car["team"]), "lap": int(floor(float(car["pit_from"]))) + 1,
		"stop": int(car["stops"]), "track": track_name,
		"order_origin": str(car.get("pit_order_source", "desconhecida")),
		"entered_at": float(car["pit_entered_at"]), "exited_at": clock,
		"position_before": int(car["pit_entry_position"]), "position_after": live_rank,
		"old_tire": str(car["pit_old_tire"]), "new_tire": str(car["tire"]),
		"service": float(car["pit_last_service"]),
		"untrained_service": float(car["pit_nominal_total"]) * (PIT_SERVICE_END - PIT_SERVICE_BEGIN),
		"dock": float(car["pit_dock_total"]),
		"wait": float(car["pit_last_wait"]),
		"incident_delay": float(car["pit_last_extra"]),
		"incident": str(car["pit_last_incident"]),
		"nominal": expected, "total": measured,
		"training_saved": expected - float(car["pit_total"]),
		"net_vs_untrained": expected - measured,
		"crew_agility": int(crew_levels.get("Agilidade", 0)) if car["team"] == team_name else 0,
		"crew_coordination": int(crew_levels.get("Coordenação", 0)) if car["team"] == team_name else 0
	})
	prediction_ledger.observe_exit(pit_history[-1], base_lap, PIT_TRACK_FRACTION, cars)
	if telemetry != null:
		telemetry.record_pit(pit_history[-1])

func get_prediction_ledger(team_filter: String = "") -> Array:
	return prediction_ledger.snapshot(team_filter)

func get_prediction_summary(team_filter: String = "") -> Dictionary:
	return prediction_ledger.summary(team_filter)

func get_pit_history(team_filter: String = "") -> Array:
	var result: Array = []
	for item in pit_history:
		if team_filter.is_empty() or str(item["team"]) == team_filter:
			result.append(item.duplicate(true))
	return result

func get_pit_summary(team_filter: String = "") -> Dictionary:
	var count := 0
	var service_total := 0.0
	var total_time := 0.0
	var wait_total := 0.0
	var incident_total := 0.0
	var training_total := 0.0
	var net_total := 0.0
	var fastest := INF
	var incidents := 0
	for item in pit_history:
		if not team_filter.is_empty() and str(item["team"]) != team_filter:
			continue
		count += 1
		var service: float = float(item["service"])
		service_total += service
		total_time += float(item["total"])
		wait_total += float(item["wait"])
		incident_total += float(item["incident_delay"])
		training_total += float(item["training_saved"])
		net_total += float(item["net_vs_untrained"])
		fastest = minf(fastest, service)
		if float(item["incident_delay"]) > 0.001:
			incidents += 1
	return {
		"stops": count, "mean_service": service_total / float(count) if count > 0 else 0.0,
		"fastest_service": fastest if count > 0 else 0.0,
		"mean_total": total_time / float(count) if count > 0 else 0.0,
		"sum_pit_time": total_time, "sum_queue": wait_total,
		"sum_incidents": incident_total, "incidents": incidents,
		"sum_training_saving": training_total,
		"sum_net_vs_untrained": net_total
	}

func get_team_pit_comparison() -> Array:
	var names: Dictionary = {}
	for item in pit_history:
		names[str(item["team"])] = true
	var result: Array = []
	for team in names.keys():
		var summary: Dictionary = get_pit_summary(str(team))
		result.append({"team": str(team), "stops": int(summary["stops"]),
			"mean_service": float(summary["mean_service"]),
			"mean_total": float(summary["mean_total"])})
	result.sort_custom(func(a, b): return float(a["mean_service"]) < float(b["mean_service"]))
	return result

func get_pit_lane_snapshot() -> Dictionary:
	# Stable, defensive projection for future Pit Wall and race engineer tools.
	return PitLane.snapshot(cars, pit_crew_owner)

func get_team_pit_status(team: String) -> Dictionary:
	# Read-only UI snapshot, now with true queue order and service/release ETA.
	# Never advances pit state or sends a pit command.
	return PitCoordination2.status(team, cars, pit_crew_owner, clock, PIT_QUEUE_PHASE)

func _record_lap_cross(car: Dictionary, previous: float, choose_ai_strategy: bool = true) -> void:
	var before: int = maxi(0, int(floor(previous)))
	var after: int = maxi(0, int(floor(float(car["progress"]))))
	# A crossing must not count a lap twice, even if external code rewinds distance.
	if after <= before or after <= int(car.get("laps_done", 0)):
		return
	car["laps_done"] = after
	# KERS: renewed 400kJ deployment allowance on each completed lap.
	RaceKers2012.reset_lap(car)
	car["stint_laps"] = int(car["stint_laps"]) + 1
	var lap_time: float = clock - float(car["lap_started"])
	# A previous race used 2-4s pit/transient pseudo-laps as fastest laps.
	# Keep an auditable diagnostic without contaminating lap records/HUD.
	if lap_time >= base_lap * 0.70 and lap_time <= base_lap * 5.0:
		car["last_lap"] = lap_time
		car["best_lap"] = minf(float(car["best_lap"]), lap_time)
	else:
		car["invalid_lap_count"] = int(car.get("invalid_lap_count", 0)) + 1
		_event("timing_invalid", int(car["id"]), "TIMING | %s: passagem %.2fs ignorada no recorde (limite de plausibilidade)." % [str(car["name"]), lap_time], 29)
	car["lap_started"] = clock
	# Observed tyre/pace/weather series is orthogonal to the sporting state.
	prediction_ledger.observe_lap(car, weather_snapshot(), cars, base_lap)
	# Apex Soul 2.0 observes teammate pace and position once per completed lap.
	# No race order or timing/physics value is modified.
	var soul_teammate: Dictionary = {}
	for candidate in cars:
		if int(candidate.get("id", -1)) != int(car.get("id", -1)) and str(candidate.get("team", "")) == str(car.get("team", "")):
			soul_teammate = candidate
			break
	if driver_soul3_enabled:
		var soul3_radio: Dictionary = DriverSoul3.update(car, weather_snapshot(), soul_teammate)
		if str(car.get("team", "")) == team_name and not soul3_radio.is_empty():
			car["driver_radio_last_lap"] = int(soul3_radio["lap"])
			car["driver_radio_last_kind"] = "soul3_" + str(soul3_radio["kind"])
			_event("driver_radio", int(car["id"]), str(soul3_radio["message"]), 75)
	else:
		DriverSoul.update(car, weather_snapshot(), soul_teammate)
	# 0.6.4.9.6: uma análise por volta CONCLUÍDA, inclusive no manual.
	# Histórico é limitado; não há RNG nem pit executado pela leitura.
	if choose_ai_strategy and int(car.get("laps_done", 0)) < lap_count:
		var previous_review: Dictionary = car.get("lap_strategy_06496", {})
		var baseline: Dictionary = _build_strategy_plan(car, _team_pit_busy(car))
		var review: Dictionary = LapStrategy06496.assess(car, cars, baseline, weather_snapshot(),
			base_lap, pit_loss, lap_count, available_pit_compounds())
		car["lap_strategy_06496"] = review.duplicate(true)
		var history: Array = car.get("lap_strategy_history_06496", [])
		history.append({"lap": int(review["lap"]), "action": str(review["action"]),
			"reason": str(review["reason"]), "wear": float(review["wear"]),
			"planned_pit_lap": int(review["planned_pit_lap"])})
		while history.size() > 16:
			history.pop_front()
		car["lap_strategy_history_06496"] = history
		# Consultative suggestions also get a real issue-time record, even if ignored.
		if str(car.get("team", "")) == team_name and bool(baseline.get("pit_now", false)) \
				and int(car.get("pit_scheduled_lap", 0)) == 0 and not bool(car.get("pit_request", false)):
			_prediction_offer(car, str(baseline.get("compound", "")),
				_next_pit_entry_lap(car), "pitwall_advice", baseline)
		# Eventos só para mudanças de recomendação da equipe do usuário.
		if str(car.get("team", "")) == team_name and str(previous_review.get("action", "")) != str(review["action"]):
			_event("strategy_review", int(car["id"]),
				"ESTRATÉGIA POR VOLTA | V%d · %s: %s — %s" % [
					int(review["lap"]), str(car["name"]), str(review["action"]), str(review["reason"])], 43)
	if choose_ai_strategy:
		_on_lap_cross(car)

func _mark_finish(car: Dictionary) -> void:
	if bool(car.get("finished", false)):
		return
	car["finished"] = true
	car["finish_time"] = clock
	car["finish_laps"] = maxi(0, int(car.get("laps_done", 0)))
	if first_finish_at < 0.0:
		first_finish_at = clock
		_event("flag", int(car["id"]), "BANDEIRADA! %s venceu em %s!" % [str(car["name"]), track_name], 120)
	if not TyreRules2012.compliant(car.get("used_tires", []),
		Tyres2012.available(tyre_catalog, str(track.get("code", "BEL"))), race_wet_declared):
		car["tyre_rule_violation"] = true
		car["disqualified"] = true
		_event("regulation", int(car["id"]), "REGULAMENTO 2012 | %s desclassificado: ambos os pneus de seco nao usados." % str(car["name"]), 118)

func _finalize_classification() -> void:
	var ordered: Array = get_sorted()
	if ordered.is_empty():
		return
	var lead: Dictionary = ordered[0]
	var leader_laps: int = int(lead.get("finish_laps", 0))
	var leader_time: float = float(lead.get("finish_time", clock))
	for i in range(ordered.size()):
		var car: Dictionary = ordered[i]
		car["position"] = i + 1
		var laps_back: int = maxi(0, leader_laps - int(car.get("finish_laps", 0)))
		if i == 0:
			car["gap"] = 0.0
			car["gap_label"] = "LIDER"
		elif laps_back > 0:
			car["gap"] = float(laps_back) * base_lap # numeric compatibility only
			car["gap_label"] = "+%dv" % laps_back
		elif float(car.get("finish_time", -1.0)) >= 0.0:
			car["gap"] = maxf(0.0, float(car["finish_time"]) - leader_time)
			car["gap_label"] = "+%.2fs" % float(car["gap"])
		else:
			car["gap_label"] = "SC" # sem cruzamento registrado
		if i == 0:
			car["interval"] = 0.0
			car["interval_label"] = "—"
		else:
			var ahead: Dictionary = ordered[i - 1]
			var lap_diff: int = maxi(0, int(ahead.get("finish_laps", 0)) - int(car.get("finish_laps", 0)))
			if lap_diff > 0:
				car["interval"] = float(lap_diff) * base_lap
				car["interval_label"] = "+%dv" % lap_diff
			elif float(car.get("finish_time", -1.0)) >= 0.0 and float(ahead.get("finish_time", -1.0)) >= 0.0:
				car["interval"] = maxf(0.0, float(car["finish_time"]) - float(ahead["finish_time"]))
				car["interval_label"] = "+%.2fs" % float(car["interval"])
			else:
				car["interval_label"] = "SC"
		_last_ranks[int(car["id"])] = i + 1
	finish_results_validated = true

func _all_finished() -> bool:
	for car in cars:
		if not bool(car["finished"]):
			return false
	return true

func _request_ai_pit(car: Dictionary, urgent: bool = false) -> void:
	var perf_started := Perf.begin() if Perf.enabled else 0
	if (str(car["team"]) == team_name and str(car.get("pit_control_mode", "Manual")) != "IA") or bool(car["pit_request"]) or int(car.get("pit_scheduled_lap", 0)) > 0 or float(car.get("pit_left", 0.0)) > 0.0:
		if Perf.enabled: Perf.end(&"ai.pit_decision",perf_started)
		return
	var recommendation: Dictionary = _build_strategy_plan(car, _team_pit_busy(car))
	# 0.6.4.9.6: a IA pode mover SOMENTE uma janela seca e segura em 1 volta.
	# Uma análise antiga, a via de urgência, a fila do colega e ordens
	# explícitas não podem disparar modificações por este módulo.
	var review: Dictionary = car.get("lap_strategy_06496", {})
	if not urgent and int(review.get("lap", -1)) == int(car.get("laps_done", 0)) and bool(review.get("executable", false)) and bool(review.get("safe_window", false)) and not bool(review.get("protected", true)):
		var action: String = str(review.get("action", ""))
		if action == "ANTECIPAR" and not bool(recommendation.get("pit_now", false)) and int(recommendation.get("planned_pit_lap", 0)) == int(review.get("next_entry", 0)) + 1:
			recommendation["pit_now"] = true
			recommendation["reason"] = str(review.get("reason", "antecipação tática"))
			recommendation["tactic"] = "UNDERCUT +1V DE ANTECIPAÇÃO"
			car["lap_strategy_adjusted_stint_06496"] = int(car.get("stops", 0))
		elif action == "ESTENDER" and bool(recommendation.get("pit_now", false)) and not bool(recommendation.get("critical", false)) and not bool(recommendation.get("deferred", false)):
			recommendation["pit_now"] = false
			recommendation["deferred"] = true
			recommendation["reason"] = str(review.get("reason", "extensão tática"))
			recommendation["tactic"] = "OVERCUT +1V DE EXTENSÃO"
			car["lap_strategy_adjusted_stint_06496"] = int(car.get("stops", 0))
	# v0.6.4.9.7: compare BOTH independently planned windows BEFORE
	# either driver commits to a pit request, rather than only reacting when
	# the shared garage is already occupied. Strictly automatic, dry and
	# one shift per stint. All prior safety gates still apply afterward.
	if not urgent:
		var coordinated_mate: Dictionary = {}
		for other in cars:
			if int(other.get("id", -1)) != int(car.get("id", -1)) and str(other.get("team", "")) == str(car.get("team", "")):
				coordinated_mate = other
				break
		if not coordinated_mate.is_empty():
			var teammate_baseline: Dictionary = _build_strategy_plan(coordinated_mate, false)
			# Only estimate the crew's known dock/service occupation when both
			# independently planned windows end at the last legal pit entrance.
			# This does not predict future incidents or alter pit service timing.
			var garage_occupation_s: float = 0.0
			if (pit_queue_prevention_enabled
					and int(recommendation.get("planned_pit_lap", 0)) == lap_count - 1
					and int(teammate_baseline.get("planned_pit_lap", 0)) == lap_count - 1):
				var nominal: float = pit_loss + base_lap * PIT_TRACK_FRACTION
				var durations: Dictionary = PitMath.service_durations(nominal,
					PIT_SERVICE_BEGIN, PIT_SERVICE_END, PIT_QUEUE_PHASE, _crew_bonus_for(car))
				garage_occupation_s = float(durations["dock_total"]) + float(durations["service_total"])
			var coordinate: Dictionary = TeamPitCoordinator06497.assess(car, coordinated_mate,
				recommendation, teammate_baseline, weather_snapshot(), lap_count,
				_next_pit_entry_lap(car), team_name, available_pit_compounds(),
				pit_queue_prevention_enabled, garage_occupation_s, base_lap)
			car["team_pit_coord_06497"] = coordinate.duplicate(true)
			if bool(coordinate.get("executable", false)):
				if str(coordinate.get("decision", "")) == "ANTECIPAR":
					recommendation["pit_now"] = true
					recommendation["tactic"] = "EQUIPE: ANTECIPAR 1V (0.6.4.9.7)"
				elif str(coordinate.get("decision", "")) == "ADIAR" and bool(recommendation.get("pit_now", false)):
					recommendation["pit_now"] = false
					recommendation["deferred"] = true
					recommendation["tactic"] = "EQUIPE: ADIAR 1V (0.6.4.9.7)"
					car["pitwall49_held"] = true
				else:
					coordinate["executable"] = false
				if bool(coordinate.get("executable", false)):
					car["team_pit_adjusted_stint_06497"] = int(car.get("stops", 0))
					recommendation["reason"] = str(coordinate.get("reason", "Coordenação preventiva de boxes"))
					var coord_history: Array = car.get("team_pit_coord_history_06497", [])
					coord_history.append({"lap":int(car.get("laps_done", 0)),
						"decision":str(coordinate["decision"]), "reason":str(coordinate["reason"])})
					while coord_history.size() > 12:
						coord_history.pop_front()
					car["team_pit_coord_history_06497"] = coord_history
					_event("team_coordination", int(car.get("id", -1)),
						"PIT WALL EQUIPE | %s: %s" % [str(car.get("name", "Piloto")), str(coordinate["reason"])], 66)
	# Pit Wall 3.0: a single safe automatic deferral can prevent a double-stack.
	# Explicit bookings and critical/urgent stops never pass through this gate.
	if not urgent and bool(recommendation.get("pit_now", false)):
		var teammate: Dictionary = {}
		for other in cars:
			if int(other.get("id", -1)) != int(car.get("id", -1)) and str(other.get("team", "")) == str(car.get("team", "")):
				teammate = other
				break
		var planning: Dictionary = PitWallStrategy3.assess(car, teammate, cars, recommendation,
			weather_snapshot(), available_pit_compounds(), lap_count, pit_loss,
			base_lap, _next_pit_entry_lap(car))
		var staggered: Dictionary = PitWallStrategy3.auto_coordinate(car, teammate, planning, recommendation)
		if bool(staggered.get("pitwall49_hold", false)):
			car["pitwall49_held"] = true
			recommendation = staggered
			_event("strategy", int(car.get("id", -1)), "PIT WALL 3.0 | %s: aguardar uma volta por garagem ocupada; pneus/clima seguros." % str(car.get("name", "Piloto")), 60)
	# v9.10: strategy staff can defer ONE noncritical automatic stop by ONE
	# lap only when the existing Pit Wall predicts traffic now and clear air
	# one lap later. Manual orders, urgent calls and older replays are untouched.
	if not urgent and bool(recommendation.get("pit_now", false)):
		var staff_decision: Dictionary = _strategy_staff_report(car, recommendation)
		if not staff_decision.is_empty() and bool(strategy_staff_profile.get("active", false)):
			var applied: bool = bool(staff_decision.get("proposed_hold_one_lap", false)) \
				and str(car.get("pit_control_mode", "Manual")) == "IA"
			if applied:
				car["staff_strategy_hold_stint_066910"] = int(car.get("stops", 0))
				recommendation["pit_now"] = false
				recommendation["deferred"] = true
				recommendation["tactic"] = "ESTRATEGISTA: ADIAR +1V (v9.10)"
				recommendation["reason"] = str(staff_decision.get("reason", "retorno em ar livre"))
				_event("strategy_staff", int(car.get("id", -1)),
					"ESTRATEGISTA | %s: %s" % [str(car.get("name", "Piloto")),
						str(staff_decision.get("reason", ""))], 64)
			car["staff_strategy_last_066910"] = {
				"lap":int(car.get("laps_done", 0)),
				"stint":int(car.get("stops", 0)),
				"recommendation":str(staff_decision.get("recommendation", "")),
				"confidence":str(staff_decision.get("confidence", "")),
				"executed":applied}
	car["ai_plan"] = recommendation.duplicate(true)
	if not bool(recommendation.get("pit_now", false)) and not urgent:
		if Perf.enabled: Perf.end(&"ai.pit_decision",perf_started)
		return
	var target_tire: String = str(recommendation.get("compound", ""))
	# Keep the proved 0.5.5.2 wear protection as an independent safety net.
	if urgent and (int(recommendation.get("planned_pit_lap", 0)) == 0 or target_tire == ""):
		var guaranteed: String = Strategy.pit_choice(car, lap_count, available_pit_compounds(), tyre_specs,
			weather_snapshot(), pit_loss)
		if guaranteed != "":
			target_tire = guaranteed
	if not available_pit_compounds().has(target_tire) or target_tire == "":
		if Perf.enabled: Perf.end(&"ai.pit_decision",perf_started)
		return
	# No new pit order is possible at the final pit entrance.
	if lap_count - int(car.get("laps_done", 0)) < 2:
		if Perf.enabled: Perf.end(&"ai.pit_decision",perf_started)
		return
	_prediction_offer(car, target_tire, _next_pit_entry_lap(car),
		"ia_urgencia" if urgent else "ia_estrategia", recommendation)
	car["pit_request"] = true
	car["pit_target"] = target_tire
	car["pit_order_source"] = "ia_urgencia" if urgent else "ia_estrategia"
	_engineer_advice_cache.erase(int(car["id"]))
	var cause: String = "desgaste critico" if urgent or bool(recommendation.get("critical", false)) else str(recommendation.get("reason", "janela estrategica"))
	_event("strategy", int(car["id"]), "IA BOX | %s: %s, novo jogo %s (%d%% desgaste)." % [
		str(car["name"]), cause, target_tire, int(round(float(car.get("wear", 0.0))))], 48)
	if Perf.enabled: Perf.end(&"ai.pit_decision",perf_started)

func _on_lap_cross(car: Dictionary) -> void:
	if int(car["laps_done"]) >= lap_count:
		return
	# Early warning before a dry race ends. Only a manual driver can decide
	# whether to accept the disqualification risk or schedule the other slick.
	if (not race_wet_declared and not bool(car.get("tyre_rule_warning_sent", false))
			and str(car.get("team", "")) == team_name
			and str(car.get("pit_control_mode", "Manual")) == "Manual"
			and int(car["laps_done"]) >= lap_count - 5):
		var nominated: Array = Tyres2012.available(tyre_catalog, str(track.get("code", "BEL")))
		if not TyreRules2012.compliant(car.get("used_tires", []), nominated, false):
			car["tyre_rule_warning_sent"] = true
			_event("regulation", int(car["id"]), "REGULAMENTO 2012 | %s precisa utilizar ambos os compostos de seco para evitar desclassificacao." % str(car["name"]), 110)
	# Piloto comunica primeiro; engenheiro responde a partir dos dados atuais.
	# A resposta é informativa e nunca altera uma ordem, especialmente BOX V21.
	var pilot_spoke: bool = false
	if str(car.get("team", "")) == team_name:
		var radio_report: Dictionary = DriverFeedback.assess(car, weather_snapshot(), tyre_spec(str(car.get("tire", ""))))
		if not radio_report.is_empty():
			pilot_spoke = true
			car["driver_radio_last_lap"] = int(radio_report["lap"])
			car["driver_radio_last_kind"] = str(radio_report["kind"])
			_event("driver_radio", int(car["id"]), str(radio_report["message"]), 72)
			var reply: String = EngineerReply.compose(radio_report, car, weather_snapshot(),
				get_engineer_advice(int(car["id"])), available_pit_compounds())
			if reply != "":
				_event("engineer_reply", int(car["id"]), reply, 73)
	if car["team"] != team_name or str(car.get("pit_control_mode", "Manual")) == "IA":
		_request_ai_pit(car)
	else:
		# No modo Manual, a recomendação é consultiva, nunca uma ordem.
		# Evita duas respostas do engenheiro na mesma volta do rádio do piloto.
		var advice: Dictionary = get_engineer_advice(int(car["id"]))
		if not pilot_spoke and bool(advice.get("pit_now", false)) and int(car["laps_done"]) - int(car.get("last_engineer_advice_lap", -99)) >= 2:
			car["last_engineer_advice_lap"] = int(car["laps_done"])
			if int(car.get("pit_scheduled_lap", 0)) > 0:
				_event("radio", int(car["id"]), "ENGENHEIRO | %s: recomendo antecipar por %s, mas BOX V%d permanece. Altere manualmente se desejar." % [str(car["name"]), str(advice.get("reason", "desgaste")), int(car["pit_scheduled_lap"])], 75)
			else:
				_event("radio", int(car["id"]), "ENGENHEIRO | %s: recomendo box para %s. %s." % [
					str(car["name"]), str(advice.get("compound", "Médio")), str(advice.get("reason", "desgaste"))], 75)
	var error_risk: float = 0.001 if car["pace"] == "Conservar" else (0.007 if car["pace"] == "Atacar" else 0.002)
	error_risk += WetPhysics.weather_incident_risk(str(car["tire"]), float(weather_snapshot().get("wetness_factor", 0.0)))
	if rng.randf() < error_risk:
		var extra := rng.randf_range(1.5, 3.5)
		# Delaying forward motion (rather than rewinding across the finish line)
		# avoids a second 2-4-second pseudo-lap from the same crossing.
		car["combat_hesitation_s"] = float(car.get("combat_hesitation_s", 0.0)) + extra
		_event("incident", int(car["id"]), "ERRO: %s perdeu %.1fs em %s (tempo de recuperacao)." % [car["name"], extra, track_name], 115)
	if str(car["team"]) == team_name and str(car.get("pit_control_mode", "Manual")) == "Manual":
		var wear_now: float = float(car["wear"])
		var warning_stage: int = 3 if wear_now >= 98.0 else (2 if wear_now >= 90.0 else (1 if wear_now >= 75.0 else 0))
		if warning_stage > int(car.get("wear_warning_stage", 0)):
			car["wear_warning_stage"] = warning_stage
			var urgent_text: String = "LIMITE EXTREMO" if warning_stage == 3 else ("CRITICO" if warning_stage == 2 else "ATENCAO")
			_event("wear", int(car["id"]), "PNEUS %s | %s: %d%% de desgaste; box MANUAL, nenhuma parada sera feita sem sua ordem." % [urgent_text, str(car["name"]), int(round(wear_now))], 115 if warning_stage == 3 else 95)

func _event(kind: String, driver_id: int, message: String, priority: int) -> void:
	if command_session != null and command_session.get_ref() != null and not command_session.get_ref().applying:
		command_session.get_ref().enqueue("annotation", [driver_id, kind, message, priority])
		return
	var event: Dictionary = {"event_id": _next_event_id, "type": kind, "driver_id": driver_id, "message": message, "priority": priority, "time": clock}
	_next_event_id += 1
	events.append(event)
	# The radio keeps a short ring buffer. Telemetry retains the complete log.
	if telemetry != null:
		telemetry.record_event(event)
	if events.size() > 140:
		events.pop_front()

func standings_text(limit: int = 24) -> String:
	# Compatibility wrapper: old callers keep the same API and sorting contract.
	return RaceStandingsText.format(get_sorted(), finished, limit, Callable(self, "tyre_code"))
