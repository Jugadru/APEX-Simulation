extends SceneTree
const Race=preload("res://scripts/race_engine.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var base:Dictionary={}
	for t in data.tracks:
		if t.code=="GBR":base=t.duplicate(true)
	for width in [4.2,8.8]:
		var track:=base.duplicate(true)
		track.race_width_m=width
		track.overtake_zones=[[0,1]]
		var a=Race.new(data.teams,"Ferrari",655,{},track,{})
		var b=Race.new(data.teams,"Ferrari",655,{},track,{})
		for race in [a,b]:
			race.cars=[race.cars[0],race.cars[1]]
			race.cars[0].progress=.20
			race.cars[1].progress=.20+14.0/float(race.space_profile.length)
			race.cars[0].skill=99
			race.cars[0].car_rating=99
			race.cars[1].skill=60
			race.cars[1].car_rating=60
			race.cars[1].defense_aggression=80
			race.cars[0].wear=0
			race.cars[1].wear=0
			race.cars[0].race_lane=0
			race.cars[1].race_lane=0
			race._last_ranks={int(race.cars[0].id):2,int(race.cars[1].id):1}
			race.running=true
		var passed:=false
		var defended:=false
		for i in range(500):
			var previous:float=a.cars[0].progress
			a.step(.2);b.step(.2)
			assert(JSON.stringify(a.cars)==JSON.stringify(b.cars),"headless deterministic field")
			assert(JSON.stringify(a.events)==JSON.stringify(b.events),"headless deterministic events")
			var x:Dictionary=a.cars[0]
			var y:Dictionary=a.cars[1]
			assert(float(x.progress)>=previous,"no reversing progress")
			if absf(float(x.progress)-float(y.progress))*float(a.space_profile.length)<Space.LENGTH-.0001:
				assert(absf(float(x.race_lane)-float(y.race_lane))>=Space.WIDTH-.00001,"authoritative overlap")
			if absf(float(y.race_lane))>.1:defended=true
			if float(x.progress)>float(y.progress):
				passed=true
				assert(x.position==1 and y.position==2,"ranking follows real crossing")
				assert(x.combat_passes==1,"one credited on-track pass")
				break
		assert(passed==(width>8),"pass only with room")
		if width>8:assert(defended,"engine defender must act")
		print("ENGINE_SPACE_CASE_PASS width=",width," passed=",passed," clock=",a.clock)
	print("SIM_ENGINE_PASS no rendering / narrow blocked / wide passed / defense / ranking / events / deterministic")
	quit()
