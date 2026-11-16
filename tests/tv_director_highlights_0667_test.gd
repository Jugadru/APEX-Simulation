extends SceneTree
## Tests editorial highlights without modifying the physics/AI/race RNG.
const Director = preload("res://scripts/tv_director.gd")

class FakeRace:
	extends RefCounted
	var team_name: String = "Ferrari"
	var events: Array = []
	var order: Array = [
		{"id": 4, "team": "Ferrari", "interval": 0.0, "progress": 2.500, "pit_left": 0.0},
		{"id": 9, "team": "Mercedes", "interval": 0.42, "progress": 2.497, "pit_left": 0.0},
		{"id": 11, "team": "McLaren", "interval": 5.0, "progress": 2.420, "pit_left": 0.0}
	]
	func get_sorted() -> Array:
		return order

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	if not condition:
		printerr("TV_0667_FAIL: " + message)
	return condition

func _run() -> void:
	var result: Dictionary = {}
	var race := FakeRace.new()
	var director = Director.new()
	if not _check(director.select(race, 9, 0.0) == 9, "initial battle"): quit(1); return
	raced_event(race, 1, 2.0, "pass", 11, "Ultrapassagem confirmada", 50)
	director.screen_clock = 1.0
	if not _check(director.select(race, 9, 2.0) == 11, "pass must preempt ordinary held battle"): quit(1); return
	if not _check(director.camera_style in ["battle", "trackside", "corner", "helicopter"] and director.priority == 111, "pass is a factual camera priority"): quit(1); return
	if not _check(director.reason == "Ultrapassagem confirmada" and director._pending_highlights.is_empty(), "pass delivered once"): quit(1); return
	result["pass_preempts_battle"] = true
	# A generic radio message mentioning PIT is not a real pit service.
	raced_event(race, 2, 3.0, "radio", 11, "PIT pode ser uma boa opção", 200)
	director.screen_clock = 1.5
	if not _check(director.select(race, 9, 3.0) == 11 and director._pending_highlights.is_empty(), "no invented pit from radio text"): quit(1); return
	# Real pit event is held, delivered later; generic radio was never queued.
	raced_event(race, 3, 4.0, "pit", 4, "Entrada real nos boxes", 95)
	director.select(race, 9, 4.0)
	if not _check(director._pending_highlights.size() == 1, "held highlight must not be discarded"): quit(1); return
	director.screen_clock = 12.0
	if not _check(director.select(race, 9, 4.1) == 4 and director.camera_style == "pit", "deferred pit is aired on next cut"): quit(1); return
	result["deferred_pit"] = true
	# Event with same car and category within 15 simulated seconds is suppressed.
	raced_event(race, 4, 5.0, "double_stack", 4, "Dupla parada", 125)
	director.select(race, 9, 5.0)
	if not _check(director._pending_highlights.is_empty(), "deduplicate pit group"): quit(1); return
	result["deduplication"] = true
	# New high-priority incident interrupts a lower-priority pit shot.
	raced_event(race, 5, 6.0, "incident", 9, "Rodada confirmada", 10)
	director.screen_clock = 12.4
	if not _check(director.select(race, 9, 6.0) == 9 and director.priority == 126, "incident must interrupt a pit shot"): quit(1); return
	result["incident_preempts_pit"] = true
	# Manual hold is respected even with urgent events.
	director.override_focus(4, 6.0)
	raced_event(race, 6, 7.0, "lead", 11, "Novo líder", 100)
	director.screen_clock = 13.0
	if not _check(director.select(race, 9, 7.0) == 4 and director._pending_highlights.size() == 1, "manual override respected"): quit(1); return
	# A rewind clears future events/holds and any pending stale highlights.
	raced_event(race, 7, 8.0, "pit_failure", 11, "Problema na parada", 120)
	director.screen_clock = 14.0
	director.select(race, 9, 8.0)
	raced_event(race, 8, 9.0, "pass", 4, "Troca de posição", 120)
	director.select(race, 9, 9.0)
	raced_event(race, 9, 10.0, "pass", 11, "Troca de posição", 120)
	director.select(race, 9, 10.0)
	if not _check(director._pending_highlights.size() > 0, "pending before rewind"): quit(1); return
	raced_event(race, 10, 11.0, "incident", 11, "Incidente", 120)
	director.select(race, 9, 11.0)
	# The real replay resets its event list and IDs on seek.
	race.events = []
	director.screen_clock = 15.0
	director.select(race, 9, 1.0)
	if not _check(director._pending_highlights.is_empty() and director._seen_event_id == 0 and director.manual_until == 0.0, "rewind must clear editorial state"): quit(1); return
	result["rewind_clears_highlights"] = true
	# Duplicate old event IDs must not get treated as another incident.
	raced_event(race, 1, 2.0, "pass", 11, "Replayed pass", 70)
	director.screen_clock = 30.0
	if not _check(director.select(race, 9, 2.0) == 11, "replayed event after rewind"): quit(1); return
	var other := FakeRace.new()
	other.events = []
	director.screen_clock = 40.0
	director.select(other, 9, 0.0)
	if not _check(director._seen_event_id == 0 and director._pending_highlights.is_empty(), "new race resets queue"): quit(1); return
	result["new_session_reset"] = true
	# Even in a large jump (32x), only fresh real events can be played.
	raced_event(other, 1, 10.0, "pass", 4, "Old event", 70)
	director.select(other, 9, 80.0)
	if not _check(director._pending_highlights.is_empty(), "stale highlight must expire"): quit(1); return
	raced_event(other, 2, 88.0, "lead", 4, "Fresh leader", 90)
	director.screen_clock = 50.0
	director.select(other, 9, 90.0)
	if not _check(director.reason == "Fresh leader", "fresh highlight after accelerated sim"): quit(1); return
	result["time_bounded"] = true
	# No telemetry changes and no game simulation RNG consumed by this test.
	print("TV_DIRECTOR_HIGHLIGHTS_0667_PASS ", JSON.stringify(result))
	quit(0)

func raced_event(race: FakeRace, eid: int, at: float, kind: String, car: int, message: String, event_priority: int) -> void:
	race.events.append({"event_id": eid, "time": at, "type": kind, "driver_id": car, "message": message, "priority": event_priority})
