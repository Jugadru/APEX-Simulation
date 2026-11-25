extends RefCounted
## Optional local OS speech. No downloaded voices, voice cloning or sporting state.
## Audio is never required for delivery; the visible radio remains authoritative.
var enabled: bool = false
var volume: int = 70
var queue: Array[Dictionary] = []
var voices: Array[Dictionary] = []
var speaking_priority: int = 5
var initialized: bool = false

func available() -> bool:
	if not initialized:
		initialized = true
		if DisplayServer.get_name() != "headless":
			voices = DisplayServer.tts_get_voices()
	return not voices.is_empty()

func set_enabled(value: bool) -> bool:
	enabled = value and available()
	if not enabled:
		stop()
	return enabled

func stop() -> void:
	queue.clear()
	speaking_priority = 5
	if enabled or (initialized and not voices.is_empty()):
		DisplayServer.tts_stop()

func enqueue(packet: Dictionary, speed: float = 1.0) -> void:
	if not enabled or str(packet.get("sender", "")) not in ["PILOTO", "ENGENHEIRO"]:
		return
	var priority: int = int(packet.get("priority", 3))
	if speed >= 10.0 and priority > 1:
		return
	if str(packet.get("text", "")).is_empty():
		return
	if priority <= 1:
		for i in range(queue.size() - 1, -1, -1):
			if int(queue[i].get("priority", 3)) > priority:
				queue.remove_at(i)
		if speaking_priority > priority and DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()
	if queue.size() >= 8:
		return
	var entry: Dictionary = packet.duplicate(true)
	entry["audio_deadline_ms"] = Time.get_ticks_msec() + 10000
	queue.append(entry)
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 3)) < int(b.get("priority", 3)) if int(a.get("priority", 3)) != int(b.get("priority", 3)) else int(a.get("message_id", 0)) < int(b.get("message_id", 0)))

func pump(speed: float) -> void:
	if not enabled or DisplayServer.tts_is_speaking():
		return
	speaking_priority = 5
	while not queue.is_empty():
		var p: Dictionary = queue.pop_front()
		if Time.get_ticks_msec() > int(p.get("audio_deadline_ms", 0)) or (speed >= 10.0 and int(p.get("priority", 3)) > 1):
			continue
		var words: String = str(p.get("text", ""))
		var locale: String = str(p.get("locale", "en"))
		var matches: Array[Dictionary] = []
		for voice in voices:
			if str(voice.get("language", "")).to_lower().begins_with(locale):
				matches.append(voice)
		if matches.is_empty():
			# Avoid speaking Portuguese in an English-only voice, or vice versa.
			continue
		var index: int = posmod(str(p.get("voice_profile_id", "")).hash(), matches.size())
		var voice_id: String = str(matches[index].get("id", ""))
		if voice_id.is_empty():
			continue
		speaking_priority = int(p.get("priority", 3))
		DisplayServer.tts_speak(words, voice_id, volume, 1.0, 1.0, int(p.get("message_id", 0)), false)
		break
