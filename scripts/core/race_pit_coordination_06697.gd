extends RefCounted
## APEX v0.6.6.9.7 — Pit Coordination 2.0 / pit-lane garage arbitration.
## Pure, deterministic and read-only: no RNG, no commands, no new race fields.
## The service duration and pit spline are still owned by the existing PitLane.
const EPSILON: float = 0.00001
const QUEUE_STAGES := ["approach", "queue"]
const OCCUPIED_STAGES := ["dock", "service", "repair", "safety_hold"]

static func approach_arrival_s(car: Dictionary, queue_phase: float) -> float:
	# Precomputed at the actual pit entry; independent of update/array order.
	return float(car.get("pit_entered_at", 0.0)) + maxf(0.0, float(car.get("pit_nominal_total", 0.0))) * queue_phase

static func _cedes_to(a: Dictionary, b: Dictionary, queue_phase: float) -> bool:
	# True when b has garage priority over a.
	var a_at: float = approach_arrival_s(a, queue_phase)
	var b_at: float = approach_arrival_s(b, queue_phase)
	if absf(a_at - b_at) > EPSILON:
		return b_at < a_at
	return int(b.get("id", -1)) < int(a.get("id", -1))

static func eligible(car: Dictionary, grid: Array, owners: Dictionary,
		now_s: float, queue_phase: float) -> bool:
	var team: String = str(car.get("team", ""))
	var id: int = int(car.get("id", -1))
	if id < 0 or team.is_empty() or str(car.get("pit_stage", "")) not in QUEUE_STAGES:
		return false
	if owners.has(team):
		return int(owners[team]) == id
	# A car that has not reached the garage cannot take a ticket yet.
	if approach_arrival_s(car, queue_phase) > now_s + EPSILON:
		return false
	for contender in grid:
		if str(contender.get("team", "")) != team or int(contender.get("id", -1)) == id:
			continue
		var stage: String = str(contender.get("pit_stage", "none"))
		if stage not in QUEUE_STAGES:
			continue
		# Approaching cars can already be due at the same tick boundary.
		# Considering them prevents loop order from deciding who takes the crew.
		if stage == "approach" and approach_arrival_s(contender, queue_phase) > now_s + EPSILON:
			continue
		if _cedes_to(car, contender, queue_phase):
			return false
	return true

static func remaining_occupation_s(owner: Dictionary) -> float:
	# Only stages holding the shared crew. Exit driving is NOT garage time.
	var stage: String = str(owner.get("pit_stage", "none"))
	var elapsed: float = maxf(0.0, float(owner.get("pit_stage_elapsed", 0.0)))
	var dock: float = maxf(0.0, float(owner.get("pit_dock_total", 0.0)))
	var service: float = maxf(0.0, float(owner.get("pit_service_total", 0.0)))
	var repair: float = maxf(0.0, float(owner.get("pit_service_delay", 0.0)))
	var safety: float = maxf(0.0, float(owner.get("pit_release_delay", 0.0)))
	match stage:
		"dock": return maxf(0.0, dock - elapsed) + service + repair + safety
		"service": return maxf(0.0, service - elapsed) + repair + safety
		"repair": return maxf(0.0, repair - elapsed) + safety
		"safety_hold": return maxf(0.0, safety - elapsed)
	return 0.0

static func status(team: String, grid: Array, owners: Dictionary, now_s: float,
		queue_phase: float) -> Dictionary:
	var owner_id: int = int(owners.get(team, -1))
	var owner: Dictionary = {}
	var queued: Array[Dictionary] = []
	for car in grid:
		if str(car.get("team", "")) != team:
			continue
		if int(car.get("id", -1)) == owner_id:
			owner = car
		if str(car.get("pit_stage", "")) == "queue":
			queued.append(car)
	queued.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _cedes_to(b, a, queue_phase))
	var remaining: float = remaining_occupation_s(owner)
	var waiting: Array = []
	for i in range(queued.size()):
		var car: Dictionary = queued[i]
		waiting.append({
			"id": int(car.get("id", -1)),
			"name": str(car.get("name", "Piloto")),
			"wait": maxf(0.0, float(car.get("pit_wait", 0.0))),
			"queue_position": i + 1,
			"arrival_s": approach_arrival_s(car, queue_phase),
			# Earliest plausible release assuming no unexpected future incident.
			"estimated_additional_wait_s": maxf(0.0, remaining)
		})
		remaining += maxf(0.0, float(car.get("pit_dock_total", 0.0))) + \
			maxf(0.0, float(car.get("pit_service_total", 0.0))) + \
			maxf(0.0, float(car.get("pit_service_delay", 0.0))) + \
			maxf(0.0, float(car.get("pit_release_delay", 0.0)))
	var release_held: bool = str(owner.get("pit_stage", "")) == "safety_hold"
	return {
		"version": "2.0", "team": team, "snapshot_s": now_s,
		"owner_id": owner_id, "owner_stage": str(owner.get("pit_stage", "none")),
		"remaining_occupation_s": remaining_occupation_s(owner),
		"release_held": release_held,
		"release_note": "retenção de segurança ativa (medida)" if release_held else \
			("serviço compartilhado em curso" if owner_id >= 0 else "garagem livre"),
		"waiting": waiting
	}
