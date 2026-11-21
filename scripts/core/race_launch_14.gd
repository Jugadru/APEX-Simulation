extends RefCounted
## Improvement 14: deterministic, bounded launch-phase pace cost.
## Applied only to the first eight simulated seconds; no extra RNG draws.
## Not an FIA telemetry calibration. No movement impulse or position teleport.

const PHASE_SECONDS: float = 8.0

static func pace_cost(car: Dictionary, elapsed_s: float, wetness: float) -> float:
	if elapsed_s >= PHASE_SECONDS or elapsed_s < 0.0:
		return 0.0
	# Slower reaction has the strongest effect during the initial 1.4 seconds.
	var reaction: float = clampf((1.4 - elapsed_s) / 1.4, 0.0, 1.0)
	# Traction penalty decays continuously as the cars accelerate.
	var traction: float = clampf(1.0 - elapsed_s / PHASE_SECONDS, 0.0, 1.0)
	var driver_skill: float = clampf(float(car.get("skill", 80.0)), 50.0, 100.0)
	var car_rating: float = clampf(float(car.get("car_rating", 80.0)), 50.0, 100.0)
	var grip: float = clampf(wetness, 0.0, 1.0)
	# A small driver/car differential is causal but not a random grid lottery.
	var reaction_cost: float = (16.0 - (driver_skill - 50.0) * 0.12) * reaction
	var traction_cost: float = (25.0 - (car_rating - 50.0) * 0.13) * traction
	# Wet launch increases traction difficulty; existing wet-tyre physics
	# continues to own sustained race pace after the start.
	return maxf(0.0, reaction_cost + traction_cost * (1.0 + grip * 0.45))
