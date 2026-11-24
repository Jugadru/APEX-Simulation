extends SceneTree
## v0.6.6.9.17.2 — acceptance is REAL positions, not lines of code.
const Race = preload("res://scripts/race_engine.gd")
const Start = preload("res://scripts/core/race_start_competitive_0669172.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")

var failures: Array[String] = []
var checks: int = 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("COMPETITIVE_START_09172_FAIL " + description)

func track(season: Dictionary, code: String) -> Dictionary:
	for t in season["tracks"]:
		if str(t.get("code", "")) == code: return t
	return {}

func ranks(race) -> Dictionary:
	var result: Dictionary = {}
	var order: Array = race.get_sorted()
	for i in range(order.size()): result[int(order[i].id)] = i + 1
	return result

func run_case(season: Dictionary, venue: Dictionary, climate: String,
		seed: int, enabled: bool) -> Dictionary:
	var race = Race.new(season["teams"], "Ferrari", seed, {}, venue, {}, enabled)
	race.merge_traffic_enabled = false # Historical 025 baseline, not the 026 acceptance.
	race.configure_weather(climate)
	race.running = true
	var initial := ranks(race)
	var at18: Dictionary = {}
	var at60: Dictionary = {}
	var at120: Dictionary = {}
	for tick in range(240):
		race.step(0.5)
		if tick == 35: at18 = ranks(race)
		if tick == 119: at60 = ranks(race)
		if tick == 239: at120 = ranks(race)
	var passes: int = 0
	var attempts: int = 0
	for car in race.cars:
		passes += int(car.get("combat_passes",0))
		attempts += int(car.get("combat_attempts",0))
	var changed_initial: int = 0
	for id in initial:
		if at120[id] != initial[id]: changed_initial += 1
	return {"grid":initial,"at18":at18,"at60":at60,"at120":at120,
		"passes":passes,"attempts":attempts,
		"changed_from_initial":changed_initial,"rank_hash":JSON.stringify(at120)}

func differences(a: Dictionary, b: Dictionary) -> int:
	var total := 0
	for id in a:
		if a[id] != b[id]: total += 1
	return total

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var season: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/season_2012.json"))
	var gbr: Dictionary = track(season, "GBR")
	var mon: Dictionary = track(season, "MON")
	check(not gbr.is_empty() and not mon.is_empty(),"2012 Silverstone and Monaco exist")
	if gbr.is_empty() or mon.is_empty():
		_finish()
		return
	var nominal = Race.new(season["teams"],"Ferrari",6617,{},gbr,{})
	var legacy = Race.new(season["teams"],"Ferrari",6617,{},gbr,{},false)
	var narrow = Race.new(season["teams"],"Ferrari",6617,{},mon,{})
	var monza_grid = Race.new(season["teams"],"Ferrari",6617,{},track(season, "ITA"),{})
	var spa_grid = Race.new(season["teams"],"Ferrari",6617,{},track(season, "BEL"),{})
	check(nominal.cars.size()==24 and legacy.cars.size()==24
		and narrow.cars.size()==24,"exact 2012 24-car grid")
	var by_grid: Dictionary = {}
	for car in nominal.cars:
		var pos: int = int(car.grid)
		by_grid[pos] = car
		check(pos >= 1 and pos <= 24,"correct grid slot")
	check(by_grid.size()==24,"all 24 distinct slots")
	check(absf(float(by_grid[1].race_lane) - float(by_grid[2].race_lane)) > Space.WIDTH,
		"Silverstone starts in two physically separated corridors")
	check(float(by_grid[2].progress) < float(by_grid[1].progress)
		and float(by_grid[3].progress) < float(by_grid[2].progress),
		"stagger is longitudinal, not a position teleport")
	check(float(by_grid[3].race_lane) == float(by_grid[1].race_lane),
		"same grid column retained every two slots")
	for ca in nominal.cars:
		for cb in nominal.cars:
			if int(ca.id) >= int(cb.id): continue
			var distance: float = absf(float(ca.progress) - float(cb.progress)) \
				* float(nominal.space_profile.length)
			if absf(float(ca.race_lane)-float(cb.race_lane)) < Space.WIDTH:
				check(distance >= Space.LENGTH - 0.00001,
					"initial same-corridor cars have >= one body length clearance")
	check(not Codec.capture(nominal)["engine"].has("competitive_start_enabled"),
		"new sporting revision gate is not serialized in saves")
	check(float(nominal.cars[0].progress) >= float(legacy.cars[0].progress),
		"new grid preserves poleman's starting line")
	check(absf(float(narrow.cars[0].race_lane)) < 0.001
		and absf(float(spa_grid.cars[0].race_lane)) < 0.001,
		"Monaco/Spa narrow opening uses safe old grid spacing")
	check(absf(float(monza_grid.cars[0].race_lane)) > 2.90,
		"Monza keeps staggered grid until safe chicane convergence")

	var first = Race.new(season["teams"],"Ferrari",6617,{},gbr,{})
	var recording = Replay.new()
	recording.attach(first)
	check(recording.recorded_simulation_revision == Replay.SIMULATION_REVISION
		and Replay.SIMULATION_REVISION == "028_racing_line_v1",
		"new race uses revision 028")
	for i in range(120):
		check(recording.step_tick(),"028 can simulate deterministic tick")
	var imported = Replay.new()
	check(imported.load_data(recording.export_data()) and imported.seek(recording.end_tick)
		and imported.first_divergence < 0,
		"028 archived replay verifies every sporting hash")
	var former = Replay.new()
	former.attach(Race.new(season["teams"],"Ferrari",6617,{},gbr,{},false))
	former.recorded_simulation_revision = Replay.PRE_COMPETITIVE_START_SIMULATION_REVISION
	former.legacy_competitive_start = true
	former.race.competitive_start_enabled = false
	former.checkpoints = [former.checkpoint()]
	for i in range(120):
		check(former.step_tick(),"024 legacy race tick")
	var old_playback = Replay.new()
	check(old_playback.load_data(former.export_data())
		and old_playback.legacy_competitive_start
		and not old_playback.legacy_start20
		and old_playback.seek(former.end_tick)
		and old_playback.first_divergence < 0,
		"024 first-corner archive stays byte-faithful with original grid and rules")

	var reports: Array = []
	var scenarios_with_new_position := 0
	var scenarios_with_pass := 0
	var scenarios_where_start_is_different := 0
	for code in ["GBR","MON","ITA","BEL"]:
		var venue: Dictionary = track(season,code)
		for climate in ["Seco","Chuva intensa"]:
			var before := run_case(season,venue,climate,6617,false)
			var after := run_case(season,venue,climate,6617,true)
			var at18 := differences(before.at18,after.at18)
			var at60 := differences(before.at60,after.at60)
			var at120 := differences(before.at120,after.at120)
			if at18 > 0 or at60 > 0 or at120 > 0:
				scenarios_where_start_is_different += 1
			if int(after.changed_from_initial) > 0:
				scenarios_with_new_position += 1
			if int(after.passes) > 0:
				scenarios_with_pass += 1
			check(int(after.passes) <= 24,
				"%s %s: no unrealistic pass inflation in two minutes (%d)" % [code,climate,int(after.passes)])
			if climate == "Chuva intensa":
				check(int(after.passes) <= 4,
					"%s wet start: conservative racecraft, <=4 true passes in first 120s" % code)
			var report := {"track":code,"climate":climate,"rank_difference_vs_9171_18":at18,
				"rank_difference_vs_9171_60":at60,
				"rank_difference_vs_9171_120":at120,
				"changed_initial_rank":after.changed_from_initial,
				"passes_old":before.passes,"passes_new":after.passes,
				"attempts_old":before.attempts,"attempts_new":after.attempts}
			reports.append(report)
			print("COMPETITIVE_START_09172_CASE ", JSON.stringify(report))
	check(scenarios_where_start_is_different >= 2,
		"at least two full-field racing scenarios change classification, not just a single circuit")
	check(scenarios_with_new_position > 0,
		"at least one race has genuine changes against its grid")
	check(scenarios_with_pass > 0,
		"at least one 24-car race records a genuine overtaking (not only cosmetic)")
	print("COMPETITIVE_START_09172_REPORT ",JSON.stringify({
		"cases":reports,"real_rank_differences":scenarios_where_start_is_different,
		"races_with_grid_changes":scenarios_with_new_position,
		"races_with_real_passes":scenarios_with_pass,"failures":failures}))
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("COMPETITIVE_START_09172_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
