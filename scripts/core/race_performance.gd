extends RefCounted
## Pure pace and tyre calculations. No RNG and no mutation of car state.
const Rules = preload("res://scripts/core/race_rules.gd")
const WetPhysics = preload("res://scripts/core/race_wet_physics.gd")
const TyreThermal = preload("res://scripts/core/race_tyre_thermal.gd")
const WeatherSetup15 = preload("res://scripts/core/race_weather_setup_15.gd")
const RaceLaunch14 = preload("res://scripts/core/race_launch_14.gd")
const RaceStart066911 = preload("res://scripts/core/race_start_intelligence_066911.gd")

static func evaluate(car: Dictionary, context: Dictionary) -> Dictionary:
	var gap: float = float(context.get("gap", 999.0))
	var current_lap: int = int(context.get("lap", 0))
	var race_laps: int = maxi(1, int(context.get("race_laps", 44)))
	var base_lap: float = float(context.get("base_lap", 105.0))
	var upgrades: Dictionary = context.get("upgrades", {})
	var ours: bool = bool(context.get("player_car", false))
	var pace: Dictionary = Rules.PACES[str(car["pace"])]
	var tyre_specs: Dictionary = context.get("tyre_specs", {})
	var tyre: Dictionary = tyre_specs.get(str(car["tire"]), {})
	if tyre.is_empty():
		# Explicit fallback for corrupted/legacy save data; valid new races
		# always use one of the two nominated 2012 dry compounds.
		tyre = {"delta": 0.0, "wear": 2.8, "cliff": 65.0}
	var chassis: float = float(upgrades.get("Chassi", 0)) if ours else 0.0
	var gain: float = 0.0
	if ours:
		gain = float(upgrades.get("Motor", 0)) * 0.13 + float(upgrades.get("Asa", 0)) * 0.11 + chassis * 0.06
	else:
		var rival_data: Dictionary = context.get("rival_upgrades", {})
		var rival_name: String = str(car.get("team", ""))
		if rival_data.has(rival_name):
			var upgrades_for_team: Dictionary = rival_data[rival_name]
			gain = float(upgrades_for_team.get("Motor", 0)) * 0.12 + float(upgrades_for_team.get("Asa", 0)) * 0.10 + float(upgrades_for_team.get("Chassi", 0)) * 0.07
		else:
			gain = float(context.get("rival_development_bonus", 0.0))
	var cliff: float = float(tyre["cliff"])
	var wear: float = float(car["wear"])
	var penalty: float = 0.11 * pow(wear / 35.0, 1.55) + pow(maxf(0.0, wear - cliff), 1.60) * 0.06
	var traffic: float = 0.0
	if gap < 0.9:
		traffic += 0.22
	elif gap < 1.8:
		traffic += 0.10
	var weather: Dictionary = context.get("weather", {})
	var rain_wetness: float = float(weather.get("wetness_factor", 0.0))
	var wet_tyre: Dictionary = WetPhysics.modifier(str(car.get("tire", "Médio")), rain_wetness)
	# Local DRS-zone pace bonus. ~0.35-0.55s gain over a typical activation
	# window, not a 3.4s benefit across the whole lap. Gameplay calibration.
	var drs: float = -3.40 if bool(context.get("drs_active", false)) else 0.0
	# Power-limited 2012 KERS: timing, duration and output change by mode.
	# All gains are time-local, integrated into forward progress every tick.
	# At full power the 6.67s budget is worth ~0.4-0.5s over a full lap.
	var power_kw: float = clampf(float(context.get("kers_power_kw", 0.0)), 0.0, 60.0)
	var mode_name: String = str(context.get("kers_mode", "Equilibrado"))
	var mode_efficiency: float = 0.64 if mode_name == "Economizar" else (0.90 if mode_name == "Equilibrado" else 1.12)
	var kers_bonus: float = -6.55 * (power_kw / 60.0) * mode_efficiency
	var fuel: float = -1.25 * clampf(float(car["laps_done"]) / maxf(float(race_laps), 1.0), 0.0, 1.0)
	var tyre_heat: float = float(car.get("tyre_heat", 0.0))
	var wear_factor: float = float(tyre["wear"]) * float(pace["wear"]) * (1.0 - chassis * 0.045)
	var trapped_air: float = clampf((1.8 - gap) / 1.8, 0.0, 1.0)
	var pace_heat: float = 0.27 if str(car["pace"]) == "Atacar" else (-0.21 if str(car["pace"]) == "Conservar" else 0.04)
	# Wet asphalt cools tyres; combined with the wet compound wear curve this
	# prevents identical thermal behavior on dry and soaked circuits.
	# Original APEX balance coefficient, not a physical tyre-temperature model.
	# 0.6.4.3: an intermediate/wet car can run through wetter asphalt to
	# cool its tyres when the racing line dries. Approximation only: the Apex
	# does not simulate a lateral lane-choice input or an actual heat sensor.
	var tire_is_wet: bool = str(car.get("tire", "")) in ["Intermediário", "Chuva"]
	var off_line_wetness: float = clampf(float(weather.get("off_line_water_mm", 0.0)) / 5.0, 0.0, 1.0)
	var cooling_water: float = maxf(rain_wetness, off_line_wetness * 0.65) if tire_is_wet else rain_wetness
	var cooling: float = cooling_water * (0.14 if tire_is_wet else 0.08)
	var heat_goal: float = clampf(0.16 + pace_heat + trapped_air * 0.21 - cooling, 0.0, 1.0)
	tyre_heat = lerpf(tyre_heat, heat_goal, 0.035)
	if car.has("tyre_surface_c"):
		penalty += float(car.get("thermal_time_penalty", 0.0))
	else:
		penalty += maxf(0.0, tyre_heat - 0.38) * 2.2
	traffic += trapped_air * 0.13
	var severity: float = float(car.get("track_wear_factor", context.get("tyre_track_severity", 1.0)))
	var thermal_wear: float = float(car.get("thermal_wear_scale", 1.0)) if car.has("tyre_surface_c") else (1.0 + maxf(0.0, tyre_heat - 0.40) * 0.55)
	var abrasion: float = float(weather.get("surface_abrasion", 1.0))
	wear_factor *= severity * thermal_wear * abrasion * float(wet_tyre["wear_multiplier"])
	var crossover: Dictionary = TyreThermal.slick_inter_context(str(car.get("tire", "Médio")), weather)
	wear_factor *= float(crossover.get("wear_scale", 1.0))
	var rain_penalty: float = WetPhysics.weather_time_penalty(rain_wetness, float(weather.get("rain_intensity", 0.0)))
	# Pre-race setup responds to the authoritative track state without RNG.
	var setup_effect: Dictionary = WeatherSetup15.evaluate(car.get("race_setup_15", {}), weather)
	wear_factor *= float(setup_effect["wear_scale"])
	var track_grip: float = float(weather.get("grip_factor", 1.0))
	var grip_cost: float = clampf((1.0 - track_grip) * 2.0, -0.35, 0.75)
	var target: float = base_lap + 1.55 - gain - (float(car["car_rating"]) - 80.0) * 0.058 - (float(car["skill"]) - 80.0) * 0.036 + float(tyre["delta"]) + float(pace["delta"]) + penalty + traffic + drs + kers_bonus + fuel + rain_penalty + float(wet_tyre["penalty"]) + float(crossover.get("extra_penalty", 0.0)) + grip_cost
	# Improvement 14: launch is a transient traction/reaction cost on actual pace.
	# No RNG, grid-place bonus, or permanent effects on the lap time model.
	if bool(context.get("launch_enabled", true)):
		if bool(context.get("race_start_intelligence_enabled", false)):
			target += RaceStart066911.pace_cost(car, float(context.get("clock", RaceStart066911.PHASE_SECONDS)), weather,
				float(context.get("launch_space_clearance", 1.0)))
		else:
			# Replay 021 and older must retain Improvement 14 byte-for-byte.
			target += RaceLaunch14.pace_cost(car, float(context.get("clock", RaceLaunch14.PHASE_SECONDS)), rain_wetness)
	target += float(setup_effect["pace_delta_s"])
	target = clampf(target, maxf(58.0, base_lap * 0.80), maxf(205.0, base_lap * 2.20))
	return {"target": target, "wear_factor": wear_factor, "heat": tyre_heat,
		"traffic": traffic, "drs": drs, "kers": kers_bonus, "fuel": fuel, "gain": gain, "penalty": penalty,
		"rain_penalty": rain_penalty, "wet_tyre_penalty": float(wet_tyre["penalty"])}

static func wear_after(wear: float, wear_factor: float, dt: float, target: float) -> float:
	return minf(100.0, wear + wear_factor * dt / target)
