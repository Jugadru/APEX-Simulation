extends SceneTree
const Randomness = preload("res://scripts/core/race_randomness_068.gd")
const Driver = preload("res://scripts/core/race_driver_error_0921.gd")
const Weather = preload("res://scripts/core/race_weather.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("RACE_RANDOMNESS_068_FAIL ",label)

# Independent literal oracles copied from the pre-refactor main.
func old_driver(seed:int,id:int,tick:int,channel:int)->float:
	var x:int=posmod(seed,4294967296)
	x=(x ^ ((id*73856093)&0xffffffff) ^ ((tick*19349663)&0xffffffff) ^ ((channel*83492791)&0xffffffff))&0xffffffff
	# Two integer avalanche rounds: adjacent ticks/channels do not form
	# an affine sequence. Multiplication remains below signed 64-bit range.
	x=((x^(x>>16))*0x45d9f3b)&0xffffffff
	x=((x^(x>>16))*0x45d9f3b)&0xffffffff
	x=(x^(x>>16))&0xffffffff
	return float(x)/4294967296.0
func old_weather(initial_seed: int, code: String) -> int:
	# Fixed cross-platform mixing; independent of RNG used by cars and incidents.
	var value: int = posmod(initial_seed, 2147483647) + 1
	for i in range(code.length()):
		value = posmod(value * 131 + code.unicode_at(i) + 37, 2147483647)
	return maxi(1, value)

func make_session(data: Dictionary, climate: String, race_seed: int):
	var track: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/apex_lab_track.json"))
	track.laps = 4
	var race = Race.new(data.teams,"Ferrari",race_seed,{},track,{})
	race.configure_weather(climate)
	var session = Replay.new()
	session.attach(race)
	return session

func pit_contract(race) -> void:
	var car: Dictionary = race.player_cars()[0].duplicate(true)
	car["pit_incident_type"] = ""
	car["pit_service_delay"] = 0.0
	car["pit_release_delay"] = 0.0
	var actor: int = int(car.id)
	var previous: int = race.rng.state
	race.pit_incidents_enabled = false
	race._roll_pit_incidents(car)
	verify(race.rng.state == previous and car.pit_incident_type == "","disabled pit incidents consume no draws")
	race.pit_incidents_enabled = true
	race.pit_incident_test_overrides[actor] = {"service_fault":"fixture","service_delay":2.0,"release_delay":3.0}
	race._roll_pit_incidents(car)
	verify(race.rng.state == previous and car.pit_service_delay == 2.0 and car.pit_release_delay == 3.0,"forced incident consumes no draws")
	verify(not race.pit_incident_test_overrides.has(actor),"one-shot override removed")
	var control := RandomNumberGenerator.new()
	control.seed = race.rng.seed
	control.state = race.rng.state
	var bonus: Dictionary = race._crew_bonus_for(car)
	var seen_fault := false
	var seen_release := false
	for i in range(1024):
		car.pit_incident_type = ""
		car.pit_service_delay = 0.0
		car.pit_release_delay = 0.0
		var kind := ""
		var service := 0.0
		var release := 0.0
		if control.randf() < float(bonus.fault_chance):
			seen_fault = true
			if control.randf() < 0.78:
				kind = "Pistola pneumática"
				service = control.randf_range(1.4,3.6)
			else:
				kind = "Porca travada"
				service = control.randf_range(3.0,7.0)
		if control.randf() < float(bonus.unsafe_chance):
			seen_release = true
			release = control.randf_range(3.0,5.5)
			kind = (kind + " + " if not kind.is_empty() else "") + "Retenção de segurança"
		race._roll_pit_incidents(car)
		verify(race.rng.state == control.state and car.pit_incident_type == kind and car.pit_service_delay == service and car.pit_release_delay == release,"pit sequence exact %d" % i)
	verify(seen_fault and seen_release,"natural fault and release branches exercised")

func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var seeds: Array[int] = [0,1,42,-42,660,4294967338,-4294967338,9223372036854775807,-9223372036854775807]
	var weather := Weather.new()
	for race_seed in seeds:
		for track in data.tracks:
			verify(weather._weather_seed(race_seed,str(track.code)) == old_weather(race_seed,str(track.code)),"legacy weather seed exact")
		for actor in [0,1,12,24]:
			for t in [0,1,160,299,300,400000]:
				for channel in [1,2,3,99]:
					var expected: float = old_driver(race_seed,actor,t,channel)
					var actual: float = Driver.sample(race_seed,actor,t,channel)
					verify(var_to_bytes(expected)==var_to_bytes(actual) and actual>=0.0 and actual<1.0,"legacy driver sample exact")
	# Explicit little-endian encoding oracle, independent of encode_s64.
	var expected_key: PackedByteArray = "2a000000000000000c00000000000000a00000000000000001000000000000000100000000000000".hex_decode()
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(expected_key)
	var expected_u: float = float(digest.finish().decode_u32(0))/4294967296.0
	var u: float = Randomness.event_sample(42,12,160,1,1)
	verify(u==expected_u and u>=0.0 and u<1.0,"new fixed key format")
	verify(u==Randomness.event_sample(42,12,160,1,1),"repeat")
	verify(u!=Randomness.event_sample(4294967338,12,160,1,1),"high seed bits retained")
	verify(u!=Randomness.event_sample(-42,12,160,1,1),"negative seed")
	verify(u!=Randomness.event_sample(42,13,160,1,1),"actor key")
	verify(u!=Randomness.event_sample(42,12,161,1,1),"tick key")
	verify(u!=Randomness.event_sample(42,12,160,2,1),"domain key")
	verify(u!=Randomness.event_sample(42,12,160,1,2),"channel key")
	var pit = make_session(data,"Seco",660)
	pit_contract(pit.race)
	for climate in ["Seco","Chuva intensa"]:
		var a = make_session(data,climate,660)
		var b = make_session(data,climate,660)
		var actor: int = a.race.player_cars()[0].id
		verify(a.enqueue("set_pace",[actor,"Atacar"],3) and b.enqueue("set_pace",[actor,"Atacar"],3),"same command")
		verify(a.enqueue("order_pit",[actor,"Chuva" if climate=="Chuva intensa" else "Médio"],5) and b.enqueue("order_pit",[actor,"Chuva" if climate=="Chuva intensa" else "Médio"],5),"same pit command")
		for i in range(160):
			var before: int = b.race.rng.state
			var weather_before: String = Codec.digest(Codec.fields(b.race.weather))
			Randomness.event_sample(660,actor,i,Randomness.DOMAIN_MECHANICAL,1)
			Driver.sample(660,actor,i,Randomness.DRIVER_TRIGGER)
			b.race.weather.forecast(b.race.clock,60.0)
			verify(before==b.race.rng.state and weather_before==Codec.digest(Codec.fields(b.race.weather)),"queries do not mutate live RNG or weather")
			verify(a.step_tick() and b.step_tick(),"tick advances")
			verify(a.hashes[-1]==b.hashes[-1] and a.race.rng.state==b.race.rng.state,"observed/unobserved exact hash and RNG")
		var cp: Dictionary = Codec.capture(a.race)
		var restored = Codec.restore(cp)
		verify(restored!=null,"checkpoint restored")
		if restored != null:
			verify(Codec.digest(Codec.capture(restored))==Codec.digest(cp),"exact checkpoint bytes")
			var oracle := RandomNumberGenerator.new()
			oracle.seed = a.race.rng.seed
			oracle.state = a.race.rng.state
			for i in range(16):
				verify(restored.rng.randi()==oracle.randi(),"restored future sequential draw")
			verify(a.race.rng.state==cp.rng.state,"restore isolation")
		var replay = Replay.new()
		verify(replay.load_data(a.export_data()),"archive loads")
		verify(replay.seek(80) and replay.seek(160),"seek")
		verify(replay.race.rng.state==a.race.rng.state and Codec.sporting_hash(replay.race,replay.policy)==a.hashes[-1],"replay state exact")
	print("RACE_RANDOMNESS_068_REPORT ",JSON.stringify({"checks":checks,"failures":failures,"legacy_seed_cases":seeds.size(),"legacy_weather_tracks":data.tracks.size(),"pit_rolls":1024,"live_climates":2,"ticks_per_climate":160,"new_event_sampler_active_in_sport":false}))
	if failures.is_empty(): print("RACE_RANDOMNESS_068_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
