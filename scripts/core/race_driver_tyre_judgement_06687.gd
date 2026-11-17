extends RefCounted
## Driver Dynamics 2.0 (0.6.6.8.7): fictitious driver opinion anchored in real lap timing.
## This is a READ-ONLY presentation component. No RNG, car writes or pit orders.
## A best-versus-last-lap gap can include traffic, weather, fuel or driving; it is
## NEVER presented as a causal measurement of tyre degradation.

static func assess(car: Dictionary, soul: Dictionary = {}) -> Dictionary:
    var stint: int = int(car.get("stint_laps", 0))
    var lap: int = int(car.get("laps_done", 0))
    var best: float = float(car.get("best_lap", 0.0))
    var last: float = float(car.get("last_lap", 0.0))
    var pit_exit: int = int(car.get("last_pit_exit_lap", -100))
    var valid: bool = lap >= 3 and stint >= 3 and lap - pit_exit >= 2 \
        and best >= 25.0 and best <= 500.0 and last >= 25.0 and last <= 500.0 \
        and last + 0.01 >= best and not bool(car.get("finished", false)) \
        and not bool(car.get("pit_request", false)) and float(car.get("pit_left", 0.0)) <= 0.0
    if not valid:
        return {"valid": false, "state": "sem_amostra", "reason": "Sem voltas comparáveis neste stint."}
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var heat: float = clampf(float(car.get("tyre_heat", 0.0)), 0.0, 1.0)
    var risk: float = clampf(float(car.get("risk_tolerance", 55.0)), 0.0, 100.0)
    var initiative: float = clampf(float(soul.get("initiative", 0.5)), 0.0, 1.0)
    var sensed: float = clampf(float(soul.get("perceived_wear", wear)), 0.0, 100.0)
    var delta: float = maxf(0.0, last - best)
    # A more tolerant/initiative-taking driver waits for a larger sustained loss
    # before *asking* for a review. This never changes the car's performance.
    var loss_threshold: float = maxf(1.10, best * 0.012) + (risk - 55.0) * 0.012 \
        + (initiative - 0.5) * 0.16
    loss_threshold = clampf(loss_threshold, 0.80, 2.60)
    var stable_threshold: float = maxf(0.55, best * 0.006)
    var state: String = "monitorar"
    if wear >= 38.0 and delta >= loss_threshold:
        state = "perda_ritmo"
    elif wear >= 18.0 and wear <= 65.0 and heat < 0.66 \
            and delta <= stable_threshold \
            and (sensed <= wear - 3.0 or risk >= 55.0 or initiative >= 0.60):
        state = "stint_estavel"
    return {"valid": true, "state": state, "delta_s": delta,
        "threshold_s": loss_threshold, "stable_threshold_s": stable_threshold,
        "last_s": last, "best_s": best, "measured_wear": wear,
        "felt_wear": sensed, "risk_tolerance": risk, "initiative": initiative,
        "reason": "Diferença entre última e melhor volta (não prova desgaste)."}
