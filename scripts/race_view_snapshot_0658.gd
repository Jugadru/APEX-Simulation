extends RefCounted
## Detached presentation contract. Sporting histories and mutable containers never cross it.
## Consumers: TrackMap, ApexMiniMap, Track3D and BattleMotion; HUD data still uses RaceEngine.
const FIELDS := ["id", "name", "team", "color", "grid", "position", "progress", "finished",
	"pit_left", "pit_stage", "pit_wait", "pit_phase", "pit_service_delay", "pit_stage_elapsed",
	"pit_release_delay", "pit_service_elapsed", "pit_service_total", "pit_target", "tire",
	"drs_active", "race_lane", "combat_target_id", "combat_state"]
const SMOOTH_SECONDS := 0.04
var frames: Array = []
var by_id: Dictionary = {}
var targets: Dictionary = {}
var previous_targets: Dictionary = {} # 066721: previous completed sporting tick, for smooth render
var revision: int = 0
var sampled_route_revision: int = -1

func reset() -> void:
	frames = []
	sampled_route_revision = -1
	by_id.clear()
	targets.clear()
	previous_targets.clear()
	revision += 1

func build(cars: Array, team: String, route: Object, delta: float, running: bool, tick_phase: float = -1.0) -> Array:
	var route_revision: int = route.geometry_revision() if route.has_method("geometry_revision") else -1
	var route_changed := route_revision != sampled_route_revision
	sampled_route_revision = route_revision
	var next: Array = []
	var next_by_id: Dictionary = {}
	var next_targets: Dictionary = {}
	var next_previous: Dictionary = {}
	# With an explicit tick phase the image is one tick behind the engine,
	# interpolated between two completed sporting snapshots (no prediction).
	# Legacy call sites may omit tick_phase and retain prior smoothing behavior.
	var blend := 1.0 - exp(-maxf(0.0, delta) / SMOOTH_SECONDS)
	for source: Dictionary in cars:
		var view: Dictionary = {}
		for key: String in FIELDS:
			if source.has(key): view[key] = source[key]
		var id := int(source.id)
		var old: Dictionary = by_id.get(id, {})
		var progress := float(source.progress)
		var prior_target: Dictionary = targets.get(id, {})
		var continuous := not old.is_empty() and not prior_target.is_empty()
		if continuous:
			continuous = str(source.get("pit_stage", "none")) == str(prior_target.stage) \
				and bool(source.get("finished", false)) == bool(prior_target.finished) \
				and progress >= float(prior_target.progress) and progress - float(old.progress) < 0.05
		var next_prior: Dictionary = previous_targets.get(id, prior_target)
		var new_tick: bool = not prior_target.is_empty() and (progress != float(prior_target.progress) \
			or source.get("race_lane") != prior_target.get("lane") \
			or source.get("pit_stage") != prior_target.get("stage"))
		if new_tick:
			next_prior = prior_target
		if not continuous:
			# Replays can seek backwards, finish or teleport into pit lane.
			# Never interpolate across these discontinuities.
			next_prior = {"progress": progress, "lane": source.get("race_lane")}
		next_previous[id] = next_prior
		if continuous and running and float(source.get("pit_left", 0)) <= 0.001:
			if tick_phase >= 0.0 and not next_prior.is_empty():
				var alpha: float = clampf(tick_phase, 0.0, 1.0)
				view.progress = lerpf(float(next_prior.progress), progress, alpha)
				if source.has("race_lane") and next_prior.get("lane") != null:
					view.race_lane = lerpf(float(next_prior.lane), float(source.race_lane), alpha)
			else:
				view.progress = lerpf(float(old.progress), progress, blend)
				if source.has("race_lane") and old.has("race_lane"):
					view.race_lane = lerpf(float(old.race_lane), float(source.race_lane), blend)
		elif continuous and not running and progress == float(prior_target.progress):
			# Pause freezes the displayed pose; resume continues from it, without a jump.
			view.progress = old.progress
			if source.get("race_lane") == prior_target.lane and old.has("race_lane"):
				view.race_lane = old.race_lane
		view["player"] = str(source.team) == team
		if not route_changed and not old.is_empty() and float(old.progress) == float(view.progress):
			view["route_point"] = old.route_point
			view["route_direction"] = old.route_direction
		else:
			view["route_point"] = route.point_on_track(float(view.progress))
			view["route_direction"] = route.direction_on_track(float(view.progress))
		next_targets[id] = {"progress":progress, "stage":source.get("pit_stage", "none"),
			"finished":source.get("finished", false), "lane":source.get("race_lane")}
		view.make_read_only()
		next.append(view)
		next_by_id[id] = view
	if next != frames: revision += 1
	next.make_read_only()
	frames = next
	by_id = next_by_id
	targets = next_targets
	previous_targets = next_previous
	return frames
