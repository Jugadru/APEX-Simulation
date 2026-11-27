extends SceneTree
## Directed actual Core 2 045 race, not the historical Next Engine fixture.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
func _initialize() -> void: call_deferred("run")
func fail(reason: String) -> void:
	printerr("VEHICLE_DYNAMICS_V21_072_FAIL ",reason)
	quit(1)
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for item in data.tracks:
		if item.code=="GBR": track=item;break
	if track.is_empty(): fail("Silverstone missing");return
	var race = Race.new(data.teams,"Ferrari",42,{},track,{})
	race.configure_weather("Chuva intensa")
	var session = Replay.new()
	session.attach(race,{}, {},false)
	session.recorded_simulation_revision=Replay.VEHICLE_DYNAMICS_EXPERIMENTAL_SIMULATION_REVISION
	session.racecraft_audit_enabled=false
	var car: Dictionary = race.player_cars()[0]
	var actor: int = int(car.id)
	var compounds: Array = race.available_pit_compounds()
	var target: String = "Chuva" if compounds.has("Chuva") else str(compounds[0])
	if not session.enqueue("schedule_pit",[actor,target,21],3): fail("order rejected");return
	var initial_stops: int = int(car.stops)
	var saw_v4: bool = false
	var saw_grip: bool = false
	var began: int = Time.get_ticks_usec()
	for i in range(26000):
		if not session.step_tick(): fail("tick rejected");return
		car=race.player_cars()[0]
		if car.has("vehicle_dynamics_072"): saw_grip=true
		var own_lap: int = int(floor(maxf(0.0,float(car.progress))))+1
		if int(car.stops)>initial_stops:
			if not saw_grip or not saw_v4 or own_lap!=21 or int(car.pit_scheduled_lap)!=0:
				fail("unexpected entry lap %d" % own_lap);return
			print("VEHICLE_DYNAMICS_V21_072_PASS ",JSON.stringify({"track":"GBR","initial_weather":"Chuva intensa","tick":session.tick,"entry_lap":own_lap,"elapsed_usec":Time.get_ticks_usec()-began,"cars":race.cars.size()}))
			quit(0);return
		if own_lap==4: saw_v4=true
		if i>=3 and int(car.pit_scheduled_lap)!=21:
			fail("manual order lost before V21");return
		if bool(car.finished) or own_lap>21: break
	fail("no real V21 pit entry within bounded continuous race")
