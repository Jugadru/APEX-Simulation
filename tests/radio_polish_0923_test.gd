extends SceneTree
const Audio = preload("res://scripts/presentation/race_radio_audio_0922.gd")
const Commentary = preload("res://scripts/apex_commentary.gd")

class FakeAudio extends Audio:
	var wall_ms: int = 100
	var active: bool = false
	var stop_calls: int = 0
	var spoken: Array[Dictionary] = []
	var installed: Array[Dictionary] = [
		{"id":"en-z","language":"en_US"}, {"id":"pt-a","language":"pt-BR"}, {"id":"en-a","language":"en-GB"}
	]
	func _now_ms() -> int:
		return wall_ms
	func _load_voices() -> Array[Dictionary]:
		return installed.duplicate(true)
	func _speaking() -> bool:
		return active
	func _stop_backend() -> void:
		stop_calls += 1
		active = false
	func _speak(words: String, voice_id: String, utterance_id: int) -> void:
		spoken.append({"words":words,"voice":voice_id,"id":utterance_id})
		active = true

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("RADIO_POLISH_0923_FAIL ", label)

func packet(id: int, priority: int = 3, locale: String = "en", expires: float = 100.0) -> Dictionary:
	return {"message_id":id,"priority":priority,"locale":locale,"expires":expires,
		"sender":"ENGENHEIRO","text":"Original message","speech_text":"Speech %d" % id,
		"voice_profile_id":"fixture_engineer"}

func run() -> void:
	var a = FakeAudio.new()
	check(a.set_enabled(true), "available voices")
	for id in range(8):
		a.enqueue(packet(id))
	check(a.queue.size() == 8, "bounded queue")
	a.enqueue(packet(8))
	check(a.queue.size() == 8 and a.queue[-1].message_id == 7, "equal priority retains earlier message")
	a.enqueue(packet(9,2))
	check(a.queue.size() == 8 and a.queue[0].message_id == 9 and a.queue[-1].message_id == 6, "higher priority evicts worst")
	a.wall_ms += 10001
	a.enqueue(packet(10))
	check(a.queue.size() == 1 and a.queue[0].message_id == 10, "wall expiry frees capacity")
	a.enqueue(packet(11,1,"en",2.0),1.0,3.0)
	check(a.queue.size() == 1, "expired sporting packet cannot evict")
	a.pump(1.0,1.0)
	check(a.spoken.size() == 1 and a.spoken[-1].id == 10 and a.spoken[-1].words == "Speech 10", "speech text and ID delivered")
	var stops: int = a.stop_calls
	a.enqueue(packet(12,1,"fr"),1.0,1.0)
	check(a.active and a.stop_calls == stops and a.queue.is_empty(), "missing language cannot interrupt")
	a.enqueue(packet(13,1,"pt"),1.0,1.0)
	check(not a.active and a.stop_calls == stops+1, "urgent interrupt")
	a.pump(1.0,1.0)
	check(a.spoken[-1].id == 13 and a.spoken[-1].voice == "pt-a", "Portuguese voice")
	a.enqueue(packet(14,3),1.0,1.0)
	a.pump(16.0,1.0)
	check(a.active and a.queue.is_empty() and a.spoken[-1].id == 13, "fast speed retains active urgent and removes queued common")
	a.active = false
	a.enqueue(packet(15,3))
	a.pump(1.0)
	stops = a.stop_calls
	a.enqueue(packet(16,1),32.0)
	check(not a.active and a.stop_calls == stops+1, "fast transition stops active common")
	a.pump(32.0)
	check(a.spoken[-1].id == 16, "urgent speech at 32x")
	a.stop()
	a.enqueue(packet(17,2,"en",2.0),1.0,1.0)
	a.pump(1.0,3.0)
	check(a.queue.is_empty() and a.spoken[-1].id == 16, "race-time expiry on consumption")
	var p: Dictionary = packet(18)
	var expected: String = a._voice_for(p)
	a.voices.reverse()
	check(a._voice_for(p) == expected, "voice choice stable despite OS enumeration order")
	check(a._voice_for(packet(19,2,"pt_BR")) == "pt-a", "locale normalization")
	a.set_enabled(false)
	a.enqueue(packet(20))
	check(a.queue.is_empty() and not a.enabled, "disabled never queues")
	a.installed.clear()
	a.voices.clear()
	check(not a.set_enabled(true), "no voices fallback")
	a.installed.append({"id":"en-local","language":"en-US"})
	check(a.set_enabled(true), "explicit retry discovers voices")
	var c = Commentary.new()
	c.radio_audio = a
	c.reset(923)
	c.suppress_radio_audio = true
	c._push(5.0,"ENGENHEIRO","Copy.",true,"engineer_reply",5)
	check(c.lines.size() == 1 and a.queue.is_empty(), "historical radio text retained without speech")
	c.suppress_radio_audio = false
	c._push(6.0,"ENGENHEIRO","Copy.",true,"engineer_reply",5)
	check(c.lines.size() == 2 and a.queue.size() == 1, "fresh radio resumes speech")
	c.reset(923)
	check(a.queue.is_empty() and not a.active, "session reset clears speech")
	print("RADIO_POLISH_0923_REPORT ", JSON.stringify({"checks":checks,"failures":failures,"backend":"deterministic fixture, not audible playback"}))
	if failures.is_empty():
		print("RADIO_POLISH_0923_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
