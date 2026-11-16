extends RefCounted
## Race DRS rules: >=2 laps completed, gap <=1.0s at detection, dry race.
## Activation fractions are gameplay approximations, not surveyed 2012 FIA maps.
## AUSTRALIA had two activation zones with a shared detection point in 2012.
const MAX_GAP_S: float = 1.0
const MIN_LAPS_COMPLETED := 2

static func zones(track: Dictionary) -> Array:
	var explicit: Array = track.get("drs_zones", [])
	if not explicit.is_empty():
		return explicit
	var code: String = str(track.get("code", ""))
	if code == "AUS":
		return [{"detect": 0.06, "start": 0.10, "end": 0.22}, {"detect": 0.06, "start": 0.25, "end": 0.35}]
	if code == "MON":
		return [{"detect": 0.73, "start": 0.78, "end": 0.92}]
	if code == "BEL":
		return [{"detect": 0.18, "start": 0.22, "end": 0.35}]
	return [{"detect": 0.08, "start": 0.12, "end": 0.29}]

static func initial_state(car: Dictionary) -> void:
	car["drs_active"] = false
	car["drs_eligible"] = false
	car["drs_armed_lap"] = -1
	car["drs_armed_zones"] = []
	car["drs_detection_gap"] = 999.0

static func update(car: Dictionary, progress: float, projected: float, gap: float,
		track: Dictionary, weather: Dictionary) -> bool:
	car["drs_active"] = false
	car["drs_eligible"] = false
	var can_open: bool = bool(weather.get("drs_allowed", true)) and int(car.get("laps_done", 0)) >= MIN_LAPS_COMPLETED
	if not can_open or float(car.get("pit_left", 0.0)) > 0.0:
		car["drs_armed_zones"] = []
		return false
	var current_lap: int = int(floor(progress))
	var fraction: float = fposmod(progress, 1.0)
	var next_frac: float = fposmod(projected, 1.0)
	var crossed_lap: bool = int(floor(projected)) > current_lap
	if int(car.get("drs_armed_lap", -1)) != current_lap:
		car["drs_armed_zones"] = []
	var active_zone: int = -1
	var rules: Array = zones(track)
	for idx in range(rules.size()):
		var rule: Dictionary = rules[idx]
		var detection: float = float(rule.get("detect", 0.08))
		# A shared detection point may arm two windows (e.g. Melbourne).
		var crossing: bool = (fraction < detection and (next_frac >= detection or crossed_lap))
		if crossing and gap <= MAX_GAP_S and gap >= 0.0:
			car["drs_armed_lap"] = current_lap
			var armed: Array = car.get("drs_armed_zones", [])
			if not armed.has(idx):
				armed.append(idx)
			car["drs_armed_zones"] = armed
			car["drs_detection_gap"] = gap
		if int(car.get("drs_armed_lap", -1)) == current_lap and car.get("drs_armed_zones", []).has(idx):
			if fraction >= float(rule.get("start", 0.12)) and fraction <= float(rule.get("end", 0.29)):
				active_zone = idx
	# Only one active zone, no all-lap DRS bonus.
	car["drs_eligible"] = active_zone >= 0
	car["drs_active"] = active_zone >= 0
	return bool(car["drs_active"])
