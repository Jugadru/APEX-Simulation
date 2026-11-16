extends RefCounted
## v0.6.4.9.2: pre-entry coordination for two cars sharing a garage.
## Deterministic, advisory safety gate. No randomness, car mutation, or pit timing changes.
## Only optional IA strategy calls may be cancelled; player orders and urgent calls remain sovereign.

const QUEUE_MIN_S: float = 2.5
const SAFE_MAX_WEAR: float = 60.0
const SAFE_MIN_LIFE: float = 3.0

static func _remaining_occupancy(car: Dictionary, queue_phase: float) -> float:
    # Garage is occupied through service, repair and safety hold, but not exit.
    # Estimate remaining time to garage release using the real pit state machine.
    var stage: String = str(car.get("pit_stage", "none"))
    var elapsed: float = maxf(0.0, float(car.get("pit_stage_elapsed", 0.0)))
    var docking: float = maxf(0.0, float(car.get("pit_dock_total", 0.0)))
    var service: float = maxf(0.0, float(car.get("pit_service_total", 0.0)))
    var repair: float = maxf(0.0, float(car.get("pit_service_delay", 0.0)))
    var hold: float = maxf(0.0, float(car.get("pit_release_delay", 0.0)))
    match stage:
        "approach":
            return maxf(0.0, float(car.get("pit_nominal_total", 0.0)) * queue_phase - elapsed) + docking + service + repair + hold
        "dock":
            return maxf(0.0, docking - elapsed) + service + repair + hold
        "service":
            return maxf(0.0, service - elapsed) + repair + hold
        "repair":
            return maxf(0.0, repair - elapsed) + hold
        "safety_hold":
            return maxf(0.0, hold - elapsed)
    return 0.0

static func estimated_queue(car: Dictionary, teammate: Dictionary, inbound_nominal: float, queue_phase: float) -> float:
    if str(car.get("team", "")) != str(teammate.get("team", "")) or int(car.get("id", -1)) == int(teammate.get("id", -1)):
        return 0.0
    if float(teammate.get("pit_left", 0.0)) <= 0.001:
        return 0.0
    var garage_until_free: float = _remaining_occupancy(teammate, queue_phase)
    var approach: float = maxf(0.0, inbound_nominal * queue_phase)
    return maxf(0.0, garage_until_free - approach)

static func should_stagger(car: Dictionary, teammate: Dictionary, plan: Dictionary,
        weather_now: Dictionary, weather_future: Dictionary, candidate_wait: float,
        entry_lap: int, race_laps: int) -> bool:
    # A driver already committed to manual pit, a V21 booking or an urgent AI
    # call must NEVER be diverted by this optional coordination layer.
    if str(car.get("pit_order_source", "")) != "ia_estrategia" or not bool(car.get("pit_request", false)):
        return false
    if bool(car.get("pitwall49_held", false)) or bool(car.get("finished", false)):
        return false
    if int(car.get("pit_scheduled_lap", 0)) > 0 or float(car.get("pit_left", 0.0)) > 0.001:
        return false
    if str(car.get("team", "")) != str(teammate.get("team", "")) or int(car.get("id", -1)) == int(teammate.get("id", -1)):
        return false
    if candidate_wait < QUEUE_MIN_S or entry_lap + 1 >= race_laps:
        return false
    if bool(plan.get("critical", false)) or float(car.get("wear", 100.0)) >= SAFE_MAX_WEAR:
        return false
    if float(plan.get("life_laps", 0.0)) < SAFE_MIN_LIFE:
        return false
    if str(car.get("tire", "")) in ["Intermediário", "Chuva"]:
        return false
    # No postponement if a wet crossover is happening or even forecast soon.
    if float(weather_now.get("wetness_factor", 1.0)) >= 0.10 or float(weather_future.get("wetness_factor", 1.0)) >= 0.12:
        return false
    if float(weather_now.get("rain_intensity", 1.0)) >= 0.04:
        return false
    return true
