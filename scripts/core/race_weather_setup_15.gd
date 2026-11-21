extends RefCounted
## Improvement 15: deterministic pre-race wet/dry setup trade-offs.
## Models three independent, continuous controls; no RNG or car mutation.
## Values are abstract engineering settings, not official FIA measurements.

const COMPONENTS := ["wing", "brake", "suspension"]

static func valid(settings: Dictionary) -> bool:
	if settings.size() != COMPONENTS.size():
		return false
	for key in COMPONENTS:
		if not settings.has(key):
			return false
		if typeof(settings[key]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		var value: float = float(settings[key])
		if not is_finite(value) or value < -1.0 or value > 1.0:
			return false
	return true

static func neutral() -> Dictionary:
	return {"wing": 0.0, "brake": 0.0, "suspension": 0.0}

static func evaluate(settings: Dictionary, weather: Dictionary) -> Dictionary:
	# Invalid/absent setups are neutral for backwards compatibility with saves.
	var setup: Dictionary = settings if valid(settings) else neutral()
	var wing: float = float(setup["wing"])
	var brake: float = float(setup["brake"])
	var suspension: float = float(setup["suspension"])
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var lateral: float = clampf(float(weather.get("surface_lateral_load", 1.0)), 0.65, 1.45)
	var traction: float = clampf(float(weather.get("surface_traction", 1.0)), 0.65, 1.45)
	var grip: float = clampf(float(weather.get("grip_factor", 1.0)), 0.55, 1.2)
	# Larger wings add aero grip at corner load and cost time on straights.
	var drag_cost: float = 0.14 * wing
	var corner_gain: float = -0.23 * wing * lateral * (1.0 + 0.45 * wet)
	# Rearward braking bias stabilizes a wet braking event but compromises
	# dry stopping performance. No magic default gain from neutral.
	var braking_cost: float = (0.13 * brake * (1.0 - wet)
		- 0.16 * brake * wet * (1.15 - grip * 0.15))
	# Softer suspension increases mechanical traction on a wet or low-grip
	# surface, at the expense of sharper dry high-load corner response.
	var mechanical_cost: float = (0.14 * suspension * lateral * (1.0 - wet)
		- 0.20 * suspension * traction * wet)
	# Continuous tyre load cost: downforce slightly increases load, while
	# compliant suspension lowers wet wheelspin/abrasion. Always bounded.
	var wear_scale: float = clampf(1.0 + wing * 0.012 * lateral
		+ brake * 0.010 * wet - suspension * 0.024 * wet * traction
		+ suspension * 0.011 * (1.0 - wet) * lateral, 0.92, 1.08)
	return {
		"pace_delta_s": clampf(drag_cost + corner_gain + braking_cost + mechanical_cost, -0.55, 0.55),
		"wear_scale": wear_scale,
		"aero_drag_s": drag_cost,
		"aero_corner_s": corner_gain,
		"brake_s": braking_cost,
		"mechanical_s": mechanical_cost,
	}
