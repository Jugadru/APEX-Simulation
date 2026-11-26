extends SceneTree
## Read-only comparison: actual 9.17.1 Core 2 with Start 2.0 enabled
## versus the *same build* using its previous 9.11 start path.
## Do not use cross-version hashes as a metric of "better racing".
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const TRACKS := ["GBR","MON","ITA","BEL"]
const CLIMATES := ["Seco","Chuva intensa"]
const DT := 0.5
const TICKS := 240 # 120 simulated seconds
const SAMPLE_TICKS := [36, 70, 140, 239] # 18s, 35.5s, 70.5s, 120s

func _initialize() -> void: call_deferred("_run")

func _capture(race) -> Dictionary:
	var ranks: Dictionary = {}
	var order: Array = race.get_sorted()
	for i in range(order.size()):
		ranks[str(int(order[i].get("id",-1)))] = i+1
	var sum_progress := 0.0
	var blocked := 0
	var attempts := 0
	var passing := 0
	var min_progress := INF
	var max_progress := -INF
	for c in race.cars:
		var p: float = float(c.get("progress",0.0))
		sum_progress += p
		min_progress = minf(min_progress,p)
		max_progress = maxf(max_progress,p)
		if bool(c.get("race_space_blocked",false)): blocked += 1
		attempts += int(c.get("combat_attempts",0))
		passing += int(c.get("combat_passes",0))
	var events_pass := 0
	for event in race.telemetry.event_history:
		if str(event.get("type","")) == "pass": events_pass += 1
	return {"ranks":ranks,"sum_progress":snappedf(sum_progress,0.00000001),
		"leader":snappedf(max_progress,0.00000001),
		"last":snappedf(min_progress,0.00000001),
		"blocked":blocked,"attempts":attempts,
		"passes":passing,"pass_events":events_pass,
		"hash":Codec.sporting_hash(race,{})}

func _trial(season: Dictionary, track: Dictionary, climate: String,
		enable_start20: bool) -> Dictionary:
	var race = Race.new(season["teams"],"Ferrari",6617,{},track,{})
	race.configure_weather(climate)
	race.race_start20_enabled = enable_start20
	race.running = true
	var first_grid: Dictionary = {}
	for c in race.cars: first_grid[str(int(c.id))] = int(c.grid)
	var output: Dictionary = {"grid":first_grid,"samples":{}}
	for tick in range(TICKS):
		race.step(DT)
		if tick in SAMPLE_TICKS:
			output["samples"][str(tick)] = _capture(race)
	return output

func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var result: Array[Dictionary] = []
	var failures: Array[String] = []
	for code in TRACKS:
		var track: Dictionary = {}
		for t in season["tracks"]:
			if str(t.get("code","")) == code: track = t
		if track.is_empty():
			failures.append(code+": missing track")
			continue
		for climate in CLIMATES:
			var baseline := _trial(season,track,climate,false)
			var active := _trial(season,track,climate,true)
			var samples: Array[Dictionary] = []
			if baseline.grid != active.grid: failures.append(code+": unequal grid")
			for t in SAMPLE_TICKS:
				var a: Dictionary=baseline.samples[str(t)]
				var b: Dictionary=active.samples[str(t)]
				var changes: int = 0
				for id in a.ranks:
					if a.ranks[id] != b.ranks[id]: changes += 1
				samples.append({"time_s":(t+1)*DT,
					"changed_ranks_between_modes":changes,
					"sum_progress_delta_laps":snappedf(float(b.sum_progress)-float(a.sum_progress),0.00000001),
					"passes_baseline":a.passes,"passes_start20":b.passes,
					"attempts_baseline":a.attempts,"attempts_start20":b.attempts,
					"blocking_baseline":a.blocked,"blocking_start20":b.blocked})
			result.append({"track":code,"climate":climate,"samples":samples})
			print("APEX_START_IMPACT_CASE ",JSON.stringify(result[-1]))
	var status: String = "PASS" if failures.is_empty() else "FAIL"
	print("APEX_START_IMPACT_REPORT ",JSON.stringify({"status":status,
		"cases":result.size(),"errors":failures,"results":result,
		"scope":"Same sporting build and seed; 9.17 start module on vs 9.11 only; not a separate 9.9 binary"}))
	quit(0 if failures.is_empty() else 1)
