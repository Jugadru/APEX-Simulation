extends RefCounted
## Core 2: decisões determinísticas de IA para pneus de 2012.
## A decisão de SUBSTITUIR um jogo gasto é separada da escolha de COMPOSTO.
## Sem RNG nem mutação de carro. Coeficientes são balanceamento APEX.
const Rules = preload("res://scripts/core/race_rules.gd")
const WetPhysics = preload("res://scripts/core/race_wet_physics.gd")

const CRITICAL_WEAR: float = 92.0
const MIN_WEAR_FOR_PREDICTIVE_STOP: float = 54.0
const CLIFF_LOOKAHEAD_LAPS: float = 2.0
const WEATHER_MIN_STINT_LAPS: int = 2

static func pit_choice(car: Dictionary, lap_count: int, available_dry: Array, specs: Dictionary, weather: Dictionary = {}, pit_loss: float = 21.8) -> String:
    if available_dry.is_empty():
        return ""
    if bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0 or bool(car.get("finished", false)):
        return ""
    var dry: Array = []
    for name in available_dry:
        if str(name) not in ["Intermediário", "Chuva"]:
            dry.append(str(name))
    if dry.is_empty():
        return ""
    var remaining: int = lap_count - int(car.get("laps_done", 0))
    # A stop cannot be completed after the final pit entry.
    if remaining < 2:
        return ""
    var current: String = str(car.get("tire", dry[0]))
    var current_spec: Dictionary = specs.get(current, {})
    if current_spec.is_empty():
        return ""
    var wetness: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var pace_data: Dictionary = Rules.PACES.get(str(car.get("pace", "Normal")), Rules.PACES["Normal"])
    var pace_wear: float = float(pace_data["wear"])
    var severity: float = maxf(0.70, float(car.get("track_wear_factor", 1.0)))
    var wear_rate: float = _wear_per_lap(current, current_spec, wetness, pace_wear, severity)
    var cliff: float = float(current_spec.get("cliff", 75.0))
    var laps_to_cliff: float = maxf(0.0, (cliff - wear) / maxf(0.25, wear_rate))
    var stint_laps: int = int(car.get("stint_laps", 0))
    var horizon: int = mini(remaining, 8)

    # Fundamental fix: critical wear is independent of climate changes and
    # applies to slicks, inters and wets alike. A fresh set of the SAME tyre
    # may be the correct strategy while rain persists.
    var worn_out: bool = wear >= CRITICAL_WEAR
    var near_cliff: bool = wear >= MIN_WEAR_FOR_PREDICTIVE_STOP and laps_to_cliff <= CLIFF_LOOKAHEAD_LAPS
    if (worn_out or near_cliff) and stint_laps >= 1:
        var best: String = _best_fresh_compound(dry, specs, wetness, horizon, pace_wear, severity)
        if best != "":
            return best

    # Weather cross-over uses hysteresis and requires a worthwhile advantage
    # against pit loss. Avoid repeated swaps around a damp/wet threshold.
    var weather_target: String = _weather_target(current, wetness)
    if weather_target == "Duro":
        weather_target = _best_dry_compound(dry, specs, horizon, pace_wear, severity)
    if weather_target != "" and weather_target != current and stint_laps >= WEATHER_MIN_STINT_LAPS:
        var new_spec: Dictionary = specs.get(weather_target, {})
        if not new_spec.is_empty():
            var old_cost: float = float(current_spec.get("delta", 0.0)) + float(WetPhysics.modifier(current, wetness)["penalty"])
            var new_cost: float = float(new_spec.get("delta", 0.0)) + float(WetPhysics.modifier(weather_target, wetness)["penalty"])
            var expected_gain: float = (old_cost - new_cost) * float(mini(remaining, 18))
            if old_cost - new_cost >= 0.65 and expected_gain >= maxf(14.0, pit_loss * 0.70):
                return weather_target

    # Dry race tyre changes use the same life-to-cliff guard. Do not fall
    # through to a separate "wet tyres never pit" branch.
    var ideal: int = int(current_spec.get("ideal", 20))
    if current not in ["Intermediário", "Chuva"] and stint_laps >= maxi(3, ideal) and remaining >= 4:
        var candidate: String = _best_fresh_compound(dry, specs, wetness, horizon, pace_wear, severity)
        if candidate != "":
            return candidate
    return ""

static func _wear_per_lap(compound: String, spec: Dictionary, wetness: float, pace_wear: float, severity: float) -> float:
    var weather_factor: float = float(WetPhysics.modifier(compound, wetness)["wear_multiplier"])
    return maxf(0.25, float(spec.get("wear", 3.2)) * pace_wear * severity * weather_factor)

static func _best_fresh_compound(dry: Array, specs: Dictionary, wetness: float, horizon: int, pace_wear: float, severity: float) -> String:
    var choices: Array = dry.duplicate()
    if specs.has("Intermediário"):
        choices.append("Intermediário")
    if specs.has("Chuva"):
        choices.append("Chuva")
    var best: String = ""
    var best_score: float = INF
    for compound in choices:
        var name: String = str(compound)
        var spec: Dictionary = specs.get(name, {})
        if spec.is_empty():
            continue
        var rate: float = _wear_per_lap(name, spec, wetness, pace_wear, severity)
        # A fresh set must survive the near-term horizon; anticipate cliff.
        var mid_wear: float = minf(100.0, rate * float(horizon) * 0.5)
        var cliff: float = float(spec.get("cliff", 75.0))
        var degradation_penalty: float = 0.11 * pow(mid_wear / 35.0, 1.55) + pow(maxf(0.0, mid_wear - cliff), 1.60) * 0.06
        var score: float = float(spec.get("delta", 0.0)) + float(WetPhysics.modifier(name, wetness)["penalty"]) + degradation_penalty
        if score < best_score:
            best_score = score
            best = name
    return best

static func _best_dry_compound(dry: Array, specs: Dictionary, horizon: int, pace_wear: float, severity: float) -> String:
    var best: String = str(dry[0])
    var best_score: float = INF
    for compound in dry:
        var name: String = str(compound)
        var spec: Dictionary = specs.get(name, {})
        if spec.is_empty():
            continue
        var rate: float = _wear_per_lap(name, spec, 0.0, pace_wear, severity)
        var average_wear: float = minf(100.0, rate * float(horizon) * 0.5)
        var cliff: float = float(spec.get("cliff", 75.0))
        var score: float = float(spec.get("delta", 0.0)) + 0.11 * pow(average_wear / 35.0, 1.55) + pow(maxf(0.0, average_wear - cliff), 1.60) * 0.06
        if score < best_score:
            best_score = score
            best = name
    return best

static func _weather_target(current: String, wetness: float) -> String:
    # Hysteresis retains continuity near the crossover region.
    if current == "Chuva" and wetness >= 0.70:
        return "Chuva"
    if current == "Intermediário" and wetness >= 0.13 and wetness <= 0.80:
        return "Intermediário"
    if wetness >= 0.81:
        return "Chuva"
    if wetness >= 0.17:
        return "Intermediário"
    if wetness <= 0.10:
        return "Duro" # Caller maps this sentinel to a nominated slick.
    return current
