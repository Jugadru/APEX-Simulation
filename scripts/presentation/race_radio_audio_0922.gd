extends RefCounted
## Optional local OS speech. No downloaded voices, voice cloning or sporting state.
## Audio is never required for delivery; the visible radio remains authoritative.
const MAX_QUEUE: int = 8
const AUDIO_TTL_MS: int = 10000
var enabled: bool = false
var volume: int = 70
var queue: Array[Dictionary] = []
var voices: Array[Dictionary] = []
var speaking_priority: int = 5
var initialized: bool = false

# Small backend seam for deterministic queue tests. Production still uses only
# Godot's local DisplayServer speech and the monotonic wall clock.
func _now_ms() -> int:
	return Time.get_ticks_msec()

func _load_voices() -> Array[Dictionary]:
	if DisplayServer.get_name() == "headless":
		return []
	return DisplayServer.tts_get_voices()

func _speaking() -> bool:
	return DisplayServer.tts_is_speaking()

func _stop_backend() -> void:
	DisplayServer.tts_stop()

func _speak(words: String, voice_id: String, utterance_id: int) -> void:
	DisplayServer.tts_speak(words, voice_id, volume, 1.0, 1.0, utterance_id, false)

func available() -> bool:
	if not initialized:
		initialized = true
		voices = _load_voices()
	return not voices.is_empty()

func set_enabled(value: bool) -> bool:
	# Allow an explicit retry after voices become available on the OS.
	if value and voices.is_empty():
		initialized = false
	enabled = value and available()
	if not enabled:
		stop()
	return enabled

func stop() -> void:
	queue.clear()
	speaking_priority = 5
	if initialized and not voices.is_empty():
		_stop_backend()

func _voice_for(packet: Dictionary) -> String:
	var locale: String = str(packet.get("locale", "en")).strip_edges().to_lower().replace("_", "-")
	if locale.is_empty():
		return ""
	var matches: Array[String] = []
	for voice in voices:
		var language: String = str(voice.get("language", "")).to_lower().replace("_", "-")
		var id: String = str(voice.get("id", ""))
		if not id.is_empty() and (language == locale or language.begins_with(locale + "-")):
			matches.append(id)
	if matches.is_empty():
		return ""
	matches.sort()
	return matches[posmod(str(packet.get("voice_profile_id", "")).hash(), matches.size())]

func _expired(packet: Dictionary, wall_ms: int, race_clock: float) -> bool:
	return wall_ms > int(packet.get("audio_deadline_ms", wall_ms)) or (
		race_clock >= 0.0 and packet.has("expires") and race_clock > float(packet.expires))

func _prune(speed: float, race_clock: float, wall_ms: int) -> void:
	for i in range(queue.size() - 1, -1, -1):
		if _expired(queue[i], wall_ms, race_clock) or (speed >= 10.0 and int(queue[i].get("priority", 3)) > 1):
			queue.remove_at(i)

func _prioritize(speed: float) -> void:
	# A low-priority utterance already in progress must not carry across a
	# high-speed transition. Critical speech is allowed to finish.
	if speed >= 10.0 and speaking_priority > 1 and _speaking():
		_stop_backend()
		speaking_priority = 5

func enqueue(packet: Dictionary, speed: float = 1.0, race_clock: float = -1.0) -> void:
	if not enabled or str(packet.get("sender", "")) not in ["PILOTO", "ENGENHEIRO"]:
		return
	var wall_ms: int = _now_ms()
	_prune(speed, race_clock, wall_ms)
	_prioritize(speed)
	var priority: int = int(packet.get("priority", 3))
	if speed >= 10.0 and priority > 1:
		return
	var words: String = str(packet.get("speech_text", packet.get("text", ""))).strip_edges()
	if words.is_empty() or _expired(packet, wall_ms, race_clock):
		return
	# An unavailable voice cannot evict or interrupt an audible message.
	var voice_id: String = _voice_for(packet)
	if voice_id.is_empty():
		return
	if priority <= 1:
		for i in range(queue.size() - 1, -1, -1):
			if int(queue[i].get("priority", 3)) > priority:
				queue.remove_at(i)
		if speaking_priority > priority and _speaking():
			_stop_backend()
			speaking_priority = 5
	if queue.size() >= MAX_QUEUE:
		# The queue is sorted by priority and message id. Prefer the existing
		# earlier message on ties; admit a genuinely more urgent new one.
		if int(queue[-1].get("priority", 3)) <= priority:
			return
		queue.pop_back()
	var entry: Dictionary = packet.duplicate(true)
	entry["audio_deadline_ms"] = wall_ms + AUDIO_TTL_MS
	entry["audio_voice_id"] = voice_id
	entry["audio_words"] = words
	queue.append(entry)
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 3)) < int(b.get("priority", 3)) if int(a.get("priority", 3)) != int(b.get("priority", 3)) else int(a.get("message_id", 0)) < int(b.get("message_id", 0)))

func pump(speed: float, race_clock: float = -1.0) -> void:
	if not enabled:
		return
	_prune(speed, race_clock, _now_ms())
	_prioritize(speed)
	if _speaking():
		return
	speaking_priority = 5
	if queue.is_empty():
		return
	var p: Dictionary = queue.pop_front()
	speaking_priority = int(p.get("priority", 3))
	_speak(str(p.audio_words), str(p.audio_voice_id), int(p.get("message_id", 0)))
