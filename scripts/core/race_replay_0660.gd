extends RefCounted
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const RacecraftAudit = preload("res://scripts/core/racecraft_audit_0662.gd")
const Engineer = preload("res://scripts/core/race_engineer_0639.gd")
const STEP := 0.20
# A replay is tied to the exact sporting rules, not only its Godot runtime.
const SIMULATION_REVISION := "06688_grip_aware_defense"
const CHECKPOINT_TICKS := 300
const MAX_CHECKPOINTS := 9
# 0666: at most four compressed, RAM-only seek anchors. Never serialized.
const MAX_HOT_SEEK_CHECKPOINTS := 4
const MAX_HOT_SEEK_BYTES := 12 * 1024 * 1024
const MAX_TICKS := 400000
# 0663: checkpoints stay fully faithful, but only their in-memory representation
# is compressed. The exported APEX_REPLAY_0660 format remains unchanged.
const CHECKPOINT_CODEC := FileAccess.COMPRESSION_ZSTD
const MAX_STATE_BYTES := 128 * 1024 * 1024
const METHODS := {"set_pace": 2, "set_kers_mode": 2, "set_pit_control_mode": 2, "schedule_pit": 3, "cancel_scheduled_pit": 1, "order_pit": 2, "driver_control": 2, "annotation":4}
var race
var tick: int = 0
var accumulator: float = 0.0
# Presentation-only diagnostic. True when requested acceleration exceeds UI CPU budget.
var cpu_limited: bool = false
var commands: Array = []
var cursor: int = 0
var sequence: int = 0
var applying: bool = false
var playback: bool = false
var policy: Dictionary = {"modes": {}, "fingerprints": {}, "staff": {}}
var checkpoints: Array = []
var hot_seek_checkpoints: Array = []
# 0665: checkpoint coverage keeps the initial and latest anchors.
var hashes: PackedStringArray = []
var end_tick: int = 0
var first_divergence: int = -1
var error: String = ""
# Diagnostic-only sidecar. Excluded from checkpoints, serialized traces and sporting hashes.
var racecraft_audit_enabled: bool = true
var racecraft_audit = RacecraftAudit.new()

func attach(engine, modes: Dictionary = {}, staff: Dictionary = {}) -> void:
	race = engine
	race.command_session = weakref(self)
	policy = {"modes": modes.duplicate(true), "fingerprints": {}, "staff": staff.duplicate(true)}
	checkpoints = [checkpoint()]
	hot_seek_checkpoints.clear()
	racecraft_audit.reset(race, 0)

func checkpoint() -> Dictionary:
	return {"tick": tick, "cursor": cursor, "state": Codec.capture(race), "policy": policy.duplicate(true)}

func _packed_checkpoint(legacy: Dictionary) -> Dictionary:
	# Public checkpoint() and external replay archives keep the legacy shape.
	var raw: PackedByteArray = var_to_bytes(legacy.state)
	var compressed: PackedByteArray = raw.compress(CHECKPOINT_CODEC)
	if compressed.is_empty():
		return legacy
	return {"tick": int(legacy.tick), "cursor": int(legacy.cursor),
		"state_bytes": raw.size(), "packed_state": compressed,
		"policy": legacy.policy}

func _checkpoint_state(cp: Dictionary) -> Dictionary:
	if cp.has("state"):
		return cp.state
	if not cp.has_all(["state_bytes", "packed_state"]) or not cp.packed_state is PackedByteArray:
		return {}
	var size: int = int(cp.state_bytes)
	if size <= 0 or size > MAX_STATE_BYTES:
		return {}
	var raw: PackedByteArray = cp.packed_state.decompress(size, CHECKPOINT_CODEC)
	if raw.size() != size:
		return {}
	var decoded: Variant = bytes_to_var(raw)
	return decoded if decoded is Dictionary else {}

func _export_checkpoints() -> Array:
	var result: Array = []
	for cp in checkpoints:
		var state: Dictionary = _checkpoint_state(cp)
		if state.is_empty():
			return []
		result.append({"tick": int(cp.tick), "cursor": int(cp.cursor),
			"state": state.duplicate(true), "policy": cp.policy.duplicate(true)})
	return result

func valid_command(method: String, args: Array) -> bool:
	if not METHODS.has(method) or args.size() != METHODS[method] or typeof(args[0]) != TYPE_INT: return false
	var car: Dictionary = {}
	for c in race.player_cars():
		if int(c.id) == args[0]: car = c
	if car.is_empty() or bool(car.finished): return false
	match method:
		"annotation": return args[1] in ["engineer_command", "engineer_question"] and typeof(args[2]) == TYPE_STRING and args[2].length() < 2000 and typeof(args[3]) == TYPE_INT
		"set_pace": return args[1] in ["Conservar", "Normal", "Atacar"]
		"set_kers_mode": return args[1] in race.RaceKers2012.MODES
		"set_pit_control_mode": return args[1] in ["IA", "Manual"]
		"driver_control": return args[1] in ["Manual", "Assistido", "Automático"]
		"order_pit": return args[1] in race.available_pit_compounds()
		"schedule_pit": return args[1] in race.available_pit_compounds() and typeof(args[2]) == TYPE_INT and args[2] >= race._next_pit_entry_lap(car) and args[2] < race.lap_count
	return true

func enqueue(method: String, args: Array, at_tick: int = -1, origin: String = "Manual") -> bool:
	if playback or race.finished or not valid_command(method,args): return false
	var target: int = tick + 1 if at_tick < 0 else at_tick
	if target <= tick or target > MAX_TICKS: return false
	# Maintenance 0667.1: two UI clicks may enqueue before the next physics tick.
	# Reject a second *pending* manual reservation for the same team/lap, or an
	# overwrite for the same driver, before either order reaches RaceEngine.
	# This is recording-only validation: imported historical commands continue
	# to replay unchanged, preserving the APEX_REPLAY_0660 archive contract.
	if method == "schedule_pit":
		for i in range(cursor, commands.size()):
			var pending: Dictionary = commands[i]
			if str(pending.get("type", "")) != "schedule_pit": continue
			if int(pending.get("actor", -1)) == int(args[0]): return false
			if int((pending.get("payload", []) as Array)[2]) == int(args[2]): return false
	sequence += 1
	commands.append({"tick": target, "sequence": sequence, "actor": int(args[0]), "type": method, "payload": args.duplicate(true), "origin": origin})
	commands.sort_custom(func(a,b): return a.tick < b.tick or (a.tick == b.tick and a.sequence < b.sequence))
	return true

func advance(delta: float, speed: float, observer: Callable = Callable(), frame_budget_us: int = 0, max_backlog_steps: int = 0) -> int:
	if not race.running or race.finished or first_divergence >= 0: return 0
	if not is_finite(delta) or not is_finite(speed) or delta < 0 or speed < 0: return 0
	# 066723: In the high-speed *interactive* mode, keep frame work finite.
	# Backlog clamping slows effective wall-clock acceleration under CPU load;
	# it never advances or skips a sporting tick. With no budget (replay/tests),
	# the historic stepping behavior remains unchanged.
	if max_backlog_steps > 0:
		var requested: float = accumulator + delta * speed
		var bound: float = STEP * float(max_backlog_steps)
		cpu_limited = requested > bound + 0.000001
		accumulator = minf(requested, bound)
	else:
		cpu_limited = false
		accumulator += delta * speed
	var count := 0
	var started: int = Time.get_ticks_usec() if frame_budget_us > 0 else 0
	while accumulator + 0.000000001 >= STEP and count < 16 and not race.finished:
		if count > 0 and frame_budget_us > 0 and Time.get_ticks_usec() - started >= frame_budget_us:
			break
		if playback and tick >= end_tick:
			race.running = false
			break
		if not step_tick(): break
		if not playback and observer.is_valid(): observer.call(race)
		accumulator = maxf(0.0, accumulator - STEP)
		count += 1
	return count

func autonomy() -> void:
	var weather: Dictionary = race.weather_snapshot()
	var wet_bucket := int(float(weather.get("wetness_factor",0.0))*5.0)
	for car in race.player_cars():
		var id: int = car.id
		if car.finished or str(policy.modes.get(id,"Manual")) == "Manual": continue
		var fingerprint := "%d/%d/%s/%d" % [int(car.laps_done),wet_bucket,str(car.tire),int(float(car.wear)/15.0)]
		if str(policy.fingerprints.get(id,"")) == fingerprint: continue
		policy.fingerprints[id] = fingerprint
		var decision: Dictionary = Engineer.evaluate(car,race.get_engineer_advice(id),weather,policy.staff,race.lap_count)
		var old_pace: String = car.pace
		var old_kers: String = car.kers_mode
		race.set_pace(id,str(decision.pace))
		race.set_kers_mode(id,str(decision.kers))
		if old_pace != car.pace or old_kers != car.kers_mode:
			race._event("strategy",id,"STAFF | %s: ritmo %s, KERS %s (%s)." % [car.name,car.pace,car.kers_mode,decision.get("reason","decisao automatica")],46)

func step_tick() -> bool:
	if tick >= MAX_TICKS:
		error = "Limite de gravação atingido (400000 ticks). Exporte o replay."
		race.running = false
		return false
	applying = true
	# Keep the UI cache warm without allowing it to seed sporting decisions.
	var ui_cache: Dictionary = race._engineer_advice_cache
	race._engineer_advice_cache = {}
	while cursor < commands.size() and int(commands[cursor].tick) == tick + 1:
		var c: Dictionary = commands[cursor]
		ui_cache.clear()
		if c.type == "driver_control":
			policy.modes[int(c.actor)] = str(c.payload[1])
			policy.fingerprints.erase(int(c.actor))
			race.set_pit_control_mode(int(c.actor),"IA" if c.payload[1] == "Automático" else "Manual")
			race._event("strategy",int(c.actor),"STAFF | controle individual: %s." % str(c.payload[1]),45)
		elif c.type == "annotation": race._event(c.payload[1],c.actor,c.payload[2],c.payload[3])
		else: race.callv(c.type,c.payload)
		cursor += 1
	autonomy()
	race.running = true
	race.step(STEP)
	autonomy()
	if (tick+1) % 5 == 0: radio_tick()
	race._engineer_advice_cache = ui_cache
	applying = false
	tick += 1
	var value := Codec.sporting_hash(race,policy)
	if playback:
		if tick > hashes.size() or value != hashes[tick-1]:
			first_divergence = tick
			error = "Replay divergente no tick %d." % tick
			race.running = false
			return false
	else:
		hashes.append(value)
		end_tick = tick
		if tick % CHECKPOINT_TICKS == 0:
			checkpoints.append(_packed_checkpoint(checkpoint()))
			if checkpoints.size() > MAX_CHECKPOINTS:
				# Keep both race start and the most recent checkpoint.
				# Among interior anchors, remove the one whose loss adds
				# the least cumulative seek distance over the race timeline:
				# delta(sum(gap^2)) = 2 * gap_left * gap_right.
				# Equal costs remove the oldest candidate first. The archive
				# schema and serialized snapshots are NOT modified.
				var remove_index: int = 1
				var remove_cost: int = 9223372036854775807
				for i in range(1, checkpoints.size() - 1):
					var gap_left: int = int(checkpoints[i].tick) - int(checkpoints[i - 1].tick)
					var gap_right: int = int(checkpoints[i + 1].tick) - int(checkpoints[i].tick)
					var cost: int = gap_left * gap_right
					if cost < remove_cost:
						remove_index = i
						remove_cost = cost
				checkpoints.remove_at(remove_index)
	if racecraft_audit_enabled: racecraft_audit.observe(race, tick)
	return true

func racecraft_report() -> Dictionary:
	return racecraft_audit.summary()

# 0666: retain the diagnostic observer as part of the *session-only* cache.
# Merely resetting it at a hot position would silently change Racecraft Audit
# coverage when the user scrubs back and forth. The observer never enters the
# sporting hash, a public checkpoint, or an exported replay file.
func _hot_audit_snapshot() -> Dictionary:
	return {"start_tick": racecraft_audit.start_tick,
		"last_tick": racecraft_audit.last_tick,
		"last_event_id": racecraft_audit.last_event_id,
		"counts": racecraft_audit.counts.duplicate(true),
		"per_driver": racecraft_audit.per_driver.duplicate(true),
		"per_condition": racecraft_audit.per_condition.duplicate(true),
		"recent_samples": racecraft_audit.recent_samples.duplicate(true),
		"previous_states": racecraft_audit.previous_states.duplicate(true),
		"track_code": racecraft_audit.track_code}

func _restore_hot_audit(audit: Dictionary) -> void:
	racecraft_audit.start_tick = int(audit.start_tick)
	racecraft_audit.last_tick = int(audit.last_tick)
	racecraft_audit.last_event_id = int(audit.last_event_id)
	racecraft_audit.counts = audit.counts.duplicate(true)
	racecraft_audit.per_driver = audit.per_driver.duplicate(true)
	racecraft_audit.per_condition = audit.per_condition.duplicate(true)
	racecraft_audit.recent_samples = audit.recent_samples.duplicate(true)
	racecraft_audit.previous_states = audit.previous_states.duplicate(true)
	racecraft_audit.track_code = str(audit.track_code)

func _remember_hot_seek() -> void:
	if not playback or tick <= 0 or tick > end_tick:
		return
	# Existing permanent checkpoints need no second copy in RAM.
	for cp in checkpoints:
		if int(cp.tick) == tick:
			return
	for i in range(hot_seek_checkpoints.size()):
		if int(hot_seek_checkpoints[i].tick) == tick:
			var previous: Dictionary = hot_seek_checkpoints[i]
			hot_seek_checkpoints.remove_at(i)
			hot_seek_checkpoints.append(previous)
			return
	var packed: Dictionary = _packed_checkpoint(checkpoint())
	# Enforce a hard aggregate compressed-byte budget; do not cache raw states.
	if not packed.has("packed_state") or not packed.packed_state is PackedByteArray:
		return
	if packed.packed_state.size() > MAX_HOT_SEEK_BYTES:
		return
	packed["audit"] = _hot_audit_snapshot()
	hot_seek_checkpoints.append(packed)
	var total_bytes: int = 0
	for cp in hot_seek_checkpoints:
		total_bytes += cp.packed_state.size()
	while hot_seek_checkpoints.size() > MAX_HOT_SEEK_CHECKPOINTS or total_bytes > MAX_HOT_SEEK_BYTES:
		var evicted: Dictionary = hot_seek_checkpoints.pop_front()
		total_bytes -= evicted.packed_state.size()

func seek(target: int) -> bool:
	if not playback or target < 0 or target > end_tick: return false
	var chosen: Dictionary = checkpoints[0]
	var hot: bool = false
	for cp in checkpoints:
		if int(cp.tick) <= target and int(cp.tick) >= int(chosen.tick):
			chosen = cp
	for cp in hot_seek_checkpoints:
		if int(cp.tick) <= target and int(cp.tick) > int(chosen.tick):
			chosen = cp
			hot = true
	# Sequential navigation can reuse the already verified engine state,
	# avoiding a restore/replay of hundreds of ticks. A failed replay never
	# qualifies as a hot source. No shortcut skips per-tick sporting hashes.
	var use_current: bool = race != null and first_divergence < 0 and tick <= target and tick >= int(chosen.tick)
	if not use_current:
		var restored = Codec.restore(_checkpoint_state(chosen))
		if restored == null:
			return fail("Checkpoint incompatível.")
		race = restored
		race.command_session = weakref(self)
		tick = int(chosen.tick)
		cursor = int(chosen.cursor)
		policy = chosen.policy.duplicate(true)
	if tick > 0 and Codec.sporting_hash(race, policy) != hashes[tick - 1]:
		first_divergence = tick
		return fail("Checkpoint divergente no tick %d." % tick)
	accumulator = 0.0
	first_divergence = -1
	error = ""
	if not use_current:
		if hot:
			_restore_hot_audit(chosen.audit)
		else:
			racecraft_audit.reset(race, tick)
	while tick < target:
		if not step_tick(): return false
	race.running = false
	_remember_hot_seek()
	return true

func export_data() -> Dictionary:
	# Restore the original v0662 public schema for old save/replay consumers.
	var legacy: Array = _export_checkpoints()
	if legacy.is_empty():
		return {}
	return {"format":"APEX_REPLAY_0660", "simulation_revision": SIMULATION_REVISION, "runtime":Engine.get_version_info().string, "step":STEP, "end_tick":end_tick, "commands":commands.duplicate(true), "hashes":hashes.duplicate(), "checkpoints":legacy}

# 0664 Replay Session Fork 1.0: only for locally recorded sessions.
# The in-memory replay is copied from the recorder's *packed* checkpoints;
# no public replay archive or full telemetry snapshot is materialized.
# File imports continue through load_data() and its full validation.
func load_live_session(recorded) -> bool:
	if recorded == null or recorded.race == null:
		return fail("Sessão de replay inexistente.")
	# The HUD can be asked to watch an already-open local replay too.
	# Its validated hashes/checkpoints are forked without a public re-export.
	if recorded.end_tick < 0 or recorded.end_tick > MAX_TICKS or recorded.hashes.size() != recorded.end_tick:
		return fail("Duração/hashes inválidos na gravação ao vivo.")
	if recorded.checkpoints.is_empty() or not recorded.checkpoints[0] is Dictionary:
		return fail("Checkpoint inicial não encontrado.")
	if int(recorded.checkpoints[0].get("tick", -1)) != 0 or int(recorded.checkpoints[0].get("cursor", -1)) != 0:
		return fail("Checkpoint inicial inválido.")
	# Copy commands and policies, including packed byte arrays. Never share
	# writable containers with the live recorder or alter its state/clock.
	hot_seek_checkpoints.clear()
	# Force source transition to restore from its own tick-zero checkpoint.
	# Without invalidation, a reused Replay controller at tick 0 could
	# accidentally reuse the previous recording's engine state.
	race = null
	tick = 0
	cursor = 0
	first_divergence = -1
	commands = recorded.commands.duplicate(true)
	hashes = recorded.hashes.duplicate()
	checkpoints = recorded.checkpoints.duplicate(true)
	end_tick = recorded.end_tick
	playback = true
	if not seek(0):
		# No half-initialized playback should be exposed to the HUD.
		playback = false
		commands.clear()
		hashes.clear()
		checkpoints.clear()
		end_tick = 0
		return false
	return true

func load_data(data: Dictionary) -> bool:
	# Validate before touching this session; caller creates a fresh controller.
	# v0.6.6.0 recordings have different physics and must not be replayed under
	# v0.6.6.1 rules: silently accepting them would mislabel desync as corruption.
	if data.get("simulation_revision", "") != SIMULATION_REVISION:
		error = "Replay de outra revisão da simulação. Use a versão que o gravou."
		return false
	if data.get("format") != "APEX_REPLAY_0660" or data.get("runtime") != Engine.get_version_info().string or data.get("step") != STEP:
		error="Replay incompatível com esta versão/runtime."
		return false
	if not data.get("checkpoints") is Array or data.checkpoints.is_empty() or not data.get("commands") is Array or not data.get("hashes") is PackedStringArray:
		error="Replay inválido: estrutura incompleta."
		return false
	if typeof(data.get("end_tick")) != TYPE_INT or data.end_tick < 0 or data.end_tick > MAX_TICKS or data.hashes.size()!=data.end_tick:
		error="Replay inválido: duração/hashes."
		return false
	var last_tick := 0
	var last_seq := 0
	for c in data.commands:
		if not c is Dictionary or not c.has_all(["tick","sequence","actor","type","payload","origin"]): return fail("Comando incompleto.")
		if not METHODS.has(c.type) or not c.payload is Array or c.payload.size()!=METHODS[c.type] or typeof(c.tick)!=TYPE_INT or typeof(c.sequence)!=TYPE_INT: return fail("Comando inválido.")
		if c.tick<last_tick or c.tick<1 or c.tick>MAX_TICKS or (c.tick==last_tick and c.sequence<=last_seq): return fail("Ordem de comandos inválida.")
		if typeof(c.actor)!=TYPE_INT or typeof(c.payload[0])!=TYPE_INT or c.actor!=c.payload[0] or typeof(c.origin)!=TYPE_STRING: return fail("Ator inválido.")
		if c.type in ["set_pace","set_kers_mode","set_pit_control_mode","schedule_pit","order_pit","driver_control","annotation"] and typeof(c.payload[1])!=TYPE_STRING:return fail("Parâmetro inválido.")
		if c.type=="schedule_pit" and typeof(c.payload[2])!=TYPE_INT:return fail("Volta inválida.")
		if c.type=="annotation" and (typeof(c.payload[2])!=TYPE_STRING or typeof(c.payload[3])!=TYPE_INT):return fail("Anotação inválida.")
		last_tick=c.tick;last_seq=c.sequence
	for cp in data.checkpoints:
		if not cp is Dictionary or not cp.has_all(["tick","cursor","state","policy"]) or not cp.state is Dictionary or not cp.policy is Dictionary: return fail("Checkpoint inválido.")
		if typeof(cp.tick)!=TYPE_INT or cp.tick<0 or cp.tick>data.end_tick or typeof(cp.cursor)!=TYPE_INT or cp.cursor<0 or cp.cursor>data.commands.size(): return fail("Posição de checkpoint inválida.")
		if not cp.policy.has_all(["modes","fingerprints","staff"]) or not cp.policy.modes is Dictionary or not cp.policy.fingerprints is Dictionary or not cp.policy.staff is Dictionary or Codec.restore(cp.state)==null: return fail("Estado incompatível.")
		var consumed:=0
		for c in data.commands:
			if c.tick<=cp.tick:consumed+=1
		if consumed!=cp.cursor:return fail("Cursor de checkpoint inválido.")
	if data.checkpoints[0].tick!=0 or data.checkpoints[0].cursor!=0: return fail("Checkpoint inicial ausente.")
	hot_seek_checkpoints.clear()
	race = null
	tick = 0
	cursor = 0
	first_divergence = -1
	commands=data.commands.duplicate(true);hashes=data.hashes.duplicate()
	checkpoints = [data.checkpoints[0].duplicate(true)]
	for i in range(1, data.checkpoints.size()):
		checkpoints.append(_packed_checkpoint(data.checkpoints[i].duplicate(true)))
	end_tick=data.end_tick
	playback=true
	return seek(0)

func fail(message: String) -> bool:
	error=message
	return false

func save_file(path: String) -> bool:
	var body := var_to_bytes(export_data())
	var envelope := {"magic":"APEX_REPLAY_0660", "sha256":Codec.digest(body), "body":body}
	var f := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null: return fail("Não foi possível gravar o replay.")
	f.store_var(envelope,false);f.close()
	if DirAccess.rename_absolute(path+".tmp",path)!=OK: return fail("Não foi possível concluir a gravação.")
	return true

func load_file(path: String) -> bool:
	var f := FileAccess.open(path,FileAccess.READ)
	if f==null: return fail("Arquivo de replay não encontrado.")
	if f.get_length()>256*1024*1024: return fail("Replay excede 256 MiB.")
	var envelope: Variant = f.get_var(false)
	if not envelope is Dictionary or envelope.get("magic")!="APEX_REPLAY_0660" or not envelope.get("body") is PackedByteArray: return fail("Arquivo de replay inválido.")
	if Codec.digest(envelope.body)!=envelope.get("sha256"): return fail("Checksum do replay inválido.")
	var data: Variant=bytes_to_var(envelope.body)
	if not data is Dictionary: return fail("Conteúdo do replay inválido.")
	return load_data(data)

func radio_tick() -> void:
	const Intel=preload("res://scripts/core/race_pitwall_intelligence_0640.gd")
	const E2=preload("res://scripts/core/race_engineer_0645.gd")
	const E3=preload("res://scripts/core/race_engineer_0646.gd")
	if not policy.has("radio"):policy.radio={}
	var players:Array=race.player_cars()
	for car in players:
		if car.finished or int(car.laps_done)<1:continue
		var mate:Dictionary={}
		for other in players:
			if other.id!=car.id:mate=other
		var advice:Dictionary=race.get_engineer_advice(int(car.id))
		var weather:Dictionary=race.weather_snapshot()
		var base:Dictionary=Engineer.evaluate(car,advice,weather,policy.staff,race.lap_count)
		base=E2.enrich(car,Intel.enrich(car,base,advice,weather,mate,race.pit_loss),advice)
		var report:Dictionary=E3.assess(car,base,advice,weather,mate,policy.staff,race.available_pit_compounds(),race.lap_count,race.pit_loss,race.base_lap,race._next_pit_entry_lap(car))
		var key:String=report.get("radio_key_3","")
		var previous:Dictionary=policy.radio.get(int(car.id),{"key":"","lap":-100})
		if key!=previous.key and not key.is_empty() and int(car.laps_done)-int(previous.lap)>=4:
			policy.radio[int(car.id)]={"key":key,"lap":int(car.laps_done)}
			race._event("engineer_strategy",int(car.id),"RACE ENGINEER 3.0 (SIMULAÇÃO) | %s: %s %s" % [car.name,report.get("alert",""),report.get("action","")],66)
