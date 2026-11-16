extends RefCounted
## APEX v0.6.6.7 — TV highlights coverage with bounded event queue.
## Presentation only: no access to the simulation RNG or race mutations.
## Chooses focus car, optional rival car, and a camera style.

var mode := "Diretor TV"
var preset := "Ação"
var focus_id := -1
var secondary_focus_id := -1
var reason := "Líder"
var camera_zoom := 2.0
var camera_style := "helicopter"
var hold_until := 0.0
var manual_until := 0.0
var priority := 0
var last_event_time := -1.0
var shot_counter := 0
# Viewer-clock seconds are independent from the simulation's 1x/5x/32x.
# The scene controller advances this only while a running GP is visible.
var screen_clock: float = 0.0

# Highlights 0667: an ephemeral, strictly presentation-only editorial queue.
# The motor remains the exclusive source of events; no events are synthesized.
const MAX_PENDING_HIGHLIGHTS: int = 8
const HIGHLIGHT_FRESHNESS_S: float = 50.0
const REPEAT_GROUP_GAP_S: float = 15.0
var _seen_event_id: int = 0
var _observed_race_id: int = -1
var _observed_time: float = -1.0
var _recent_highlights: Dictionary = {}
var _pending_highlights: Array[Dictionary] = []

func _reset_coverage() -> void:
	_seen_event_id = 0
	_observed_time = -1.0
	_recent_highlights.clear()
	_pending_highlights.clear()
	# A replay rewind must not retain shots held for a future race moment.
	hold_until = 0.0
	manual_until = 0.0
	priority = 0

func _highlight_info(event: Dictionary) -> Dictionary:
	var kind: String = str(event.get("type", ""))
	match kind:
		"incident", "contact", "pit_failure", "unsafe_release":
			return {"score": 126, "style": "chase" if kind in ["incident", "contact"] else "pit", "group": kind}
		"lead":
			return {"score": 117, "style": "helicopter", "group": "lead"}
		"double_stack":
			return {"score": 114, "style": "pit", "group": "pit"}
		"pass":
			return {"score": 111, "style": "battle", "group": "pass"}
		"pit":
			return {"score": 99, "style": "pit", "group": "pit"}
		"pit_exit":
			return {"score": 88, "style": "pit", "group": "pit"}
		_:
			return {}

func _observe_highlights(engine, now: float) -> void:
	var race_identity: int = engine.get_instance_id()
	if race_identity != _observed_race_id or (_observed_time >= 0.0 and now + 0.01 < _observed_time):
		_reset_coverage()
		_observed_race_id = race_identity
	_observed_time = now
	# This event ring has at most 140 entries. Never scan the full telemetry
	# history in the camera presentation loop.
	for event in engine.events:
		var eid: int = int(event.get("event_id", 0))
		if eid <= _seen_event_id:
			continue
		_seen_event_id = eid
		var car_id: int = int(event.get("driver_id", -1))
		var at: float = float(event.get("time", 0.0))
		if car_id < 0 or at > now + 0.01 or now - at > HIGHLIGHT_FRESHNESS_S:
			continue
		var info: Dictionary = _highlight_info(event)
		if info.is_empty():
			continue
		var key: String = "%d:%s" % [car_id, str(info["group"])]
		if at - float(_recent_highlights.get(key, -1000.0)) < REPEAT_GROUP_GAP_S:
			continue
		_recent_highlights[key] = at
		var item: Dictionary = {
			"id": eid, "at": at, "driver_id": car_id,
			"message": str(event.get("message", "")),
			"score": int(info["score"]), "style": str(info["style"])
		}
		_pending_highlights.append(item)
	# Avoid showing an obsolete replay from an earlier scene after a long hold.
	for i in range(_pending_highlights.size() - 1, -1, -1):
		if now - float(_pending_highlights[i]["at"]) > HIGHLIGHT_FRESHNESS_S:
			_pending_highlights.remove_at(i)
	while _pending_highlights.size() > MAX_PENDING_HIGHLIGHTS:
		# Drop the least editorially important highlight; on ties the oldest.
		var worst: int = 0
		for i in range(1, _pending_highlights.size()):
			if int(_pending_highlights[i]["score"]) < int(_pending_highlights[worst]["score"]):
				worst = i
		_pending_highlights.remove_at(worst)

func select(engine, manual_id: int, now: float) -> int:
	var order: Array = engine.get_sorted()
	if order.is_empty():
		return -1
	if mode == "Livre":
		secondary_focus_id = -1
		camera_style = "overview"
		return -1
	if mode == "Seguir piloto":
		focus_id = manual_id
		secondary_focus_id = -1
		reason = "Seguindo piloto"
		camera_zoom = 2.15
		camera_style = "chase"
		return focus_id
	# Capture events even during a viewer-clock hold or a manual override.
	# They may be broadcast on the next eligible TV cut if still fresh.
	_observe_highlights(engine, now)
	if screen_clock < manual_until and focus_id >= 0:
		return focus_id

	var leader_id: int = int(order[0]["id"])
	var wanted := leader_id
	var wanted_secondary := -1
	var wanted_score := 12
	var wanted_zoom := 1.95
	var wanted_style := "helicopter"
	var wanted_reason := "Líder da prova"
	var wanted_gap: float = INF

	# Closest battles first.
	for i in range(1, order.size()):
		var behind: Dictionary = order[i]
		var ahead: Dictionary = order[i - 1]
		var gap := float(behind["interval"])
		if gap >= 0.12 and gap <= 1.45 and _battle_is_plausible(ahead, behind):
			var score := 48 + int((1.45 - gap) * 12.0)
			if i <= 5:
				score += 15
			if str(behind["team"]) == engine.team_name or str(ahead["team"]) == engine.team_name:
				score += 12
			if preset == "Transmissão" and i > 10:
				score -= 18
			if score > wanted_score:
				wanted = int(behind["id"])
				wanted_secondary = int(ahead["id"])
				wanted_score = score
				wanted_zoom = 2.35 if gap < 0.55 else 2.18
				wanted_style = "battle"
				wanted_reason = "Disputa P%d-P%d (%.1fs)" % [i, i + 1, gap]
				wanted_gap = gap

	# If the track is quiet, rotate a little between the leader and the
	# player's team. This is a camera-only choice, never a race decision.
	# The leader remains visible every third interval; real battles always win.
	if wanted_score == 12 and now >= 12.0:
		var player_cars: Array = []
		for car in order:
			if str(car.get("team", "")) == engine.team_name:
				player_cars.append(car)
		if not player_cars.is_empty():
			var phase: int = int(now / 13.0) % (player_cars.size() + 1)
			if phase > 0:
				wanted = int(player_cars[phase - 1]["id"])
				wanted_score = 20
				wanted_zoom = 2.05
				wanted_style = "helicopter"
				wanted_reason = "Acompanhando equipe"

	# 0667: choose the best *observed* highlight, not the last text that
	# happens to contain "PIT". Critical facts come from canonical event types.
	var selected_highlight: int = -1
	for i in range(_pending_highlights.size()):
		var item: Dictionary = _pending_highlights[i]
		var event_score: int = int(item["score"])
		if event_score > wanted_score:
			selected_highlight = i
			wanted = int(item["driver_id"])
			wanted_secondary = _neighbor_for(engine, wanted) if str(item["style"]) == "battle" else -1
			wanted_score = event_score
			wanted_zoom = 2.28 if str(item["style"]) == "battle" else 2.20
			wanted_style = str(item["style"])
			wanted_reason = str(item["message"])

	# Do not abruptly discard an ongoing shot for a less important notice.
	# A genuine pass, incident or pit emergency may interrupt an ordinary duel.
	if screen_clock < hold_until and focus_id >= 0:
		if selected_highlight < 0 or wanted_score < maxi(99, priority + 8):
			return focus_id
	if selected_highlight >= 0:
		_pending_highlights.remove_at(selected_highlight)

	focus_id = wanted
	secondary_focus_id = wanted_secondary
	priority = wanted_score
	reason = wanted_reason
	camera_zoom = wanted_zoom
	# Rotate broadcast angles even if the same battle remains the best story.
	# Otherwise close racing would keep the single 'battle' angle forever.
	# Close duels get low trackside/corner angles; a more distant duel gets
	# a wide establishing angle more often. A rare helicopter shot gives the
	# viewer context without dominating the transmission.
	var close_shots: Array[String] = ["battle", "trackside", "corner", "battle", "helicopter"]
	var medium_shots: Array[String] = ["battle", "helicopter", "trackside", "battle", "corner"]
	var calm_shots: Array[String] = ["chase", "trackside", "helicopter", "corner"]
	if wanted_style == "battle":
		camera_style = close_shots[shot_counter % close_shots.size()] if wanted_gap <= 0.65 else medium_shots[shot_counter % medium_shots.size()]
	elif wanted_style == "helicopter":
		camera_style = calm_shots[shot_counter % calm_shots.size()]
	else:
		camera_style = wanted_style
	shot_counter += 1
	hold_until = screen_clock + (9.0 if preset == "Ação" else 13.0)
	last_event_time = now
	return focus_id

func _battle_is_plausible(ahead: Dictionary, behind: Dictionary) -> bool:
	# A close interval alone can be misleading around pit stops and lap
	# boundaries. If both progress values are present, require a shared lap
	# segment; older test fixtures without progress remain supported.
	if float(ahead.get("pit_left", 0.0)) > 0.0 or float(behind.get("pit_left", 0.0)) > 0.0:
		return false
	if ahead.has("progress") and behind.has("progress"):
		return absf(float(ahead["progress"]) - float(behind["progress"])) <= 0.045
	return true


func _neighbor_for(engine, car_id: int) -> int:
	var order: Array = engine.get_sorted()
	for i in range(order.size()):
		if int(order[i]["id"]) != car_id:
			continue
		if i > 0:
			return int(order[i - 1]["id"])
		if i < order.size() - 1:
			return int(order[i + 1]["id"])
		break
	return -1

func override_focus(car_id: int, now: float) -> void:
	focus_id = car_id
	secondary_focus_id = -1
	camera_style = "chase"
	camera_zoom = 2.20
	manual_until = screen_clock + 18.0
	hold_until = manual_until
	reason = "Escolha manual"
