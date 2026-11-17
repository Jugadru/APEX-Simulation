extends SceneTree
const R=preload("res://scripts/race_engine.gd")
const P=preload("res://scripts/debug/apex_perf_trace_0657.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track:Dictionary={}
	for t in data.tracks:
		if t.code=="GBR":track=t
	var a=R.new(data.teams,"Ferrari",6557,{},track,{})
	var b=R.new(data.teams,"Ferrari",6557,{},track,{})
	a.configure_weather("Chuva intensa")
	b.configure_weather("Chuva intensa")
	a.running=true
	b.running=true
	for i in range(30):
		P.set_enabled(false)
		a.step(4)
		P.set_enabled(true)
		b.step(4)
		assert(a.rng.state==b.rng.state)
		assert(JSON.stringify(a.cars)==JSON.stringify(b.cars))
		assert(JSON.stringify(a.events)==JSON.stringify(b.events))
	P.set_enabled(false)
	print("PERF_RNG_PASS 120s heavy rain; per batch state/events/RNG identical OFF/ON")
	quit()
