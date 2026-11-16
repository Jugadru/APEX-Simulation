extends RefCounted
## v0.5.8.0 — Approximate two-lane clearance for resolved overtaking duels.
## Distances are schematic metres, NOT a car-body physics/collision solver.
## Pure and deterministic: equal inputs always produce equal outcomes.

const CAR_WIDTH_M := 2.0
const MIN_SIDE_CLEARANCE_M := 0.45
# Effective manoeuvring room for gameplay, NOT surveyed circuit widths.
# Narrow layouts therefore require more caution during sustained duels.
const GAMEPLAY_WIDTH_M := {"MON": 7.2, "HUN": 7.9, "SIN": 7.3, "EUR": 8.1, "JPN": 8.6}

static func evaluate(attacker: Dictionary, defender: Dictionary, track: Dictionary) -> Dictionary:
    var code: String = str(track.get("code", ""))
    var width_m: float = clampf(float(track.get("race_width_m", GAMEPLAY_WIDTH_M.get(code, 9.0))), 4.5, 18.0)
    var default_narrowing: float = 0.16 if GAMEPLAY_WIDTH_M.has(code) else 0.02
    var narrowing: float = clampf(float(track.get("corner_convergence", default_narrowing)), 0.0, 1.0)
    var usable_m: float = width_m * (1.0 - narrowing * 0.40)
    var attempt: int = int(attacker.get("combat_attempts", 1))
    var side: String = "inside" if attempt % 2 == 1 else "outside"
    # A defender may occupy additional road while protecting a line.
    var aggression: float = clampf(float(defender.get("defense_aggression", 50.0)), 0.0, 100.0)
    var squeeze_m: float = maxf(0.0, aggression - 55.0) * 0.029
    var available_m: float = (usable_m - CAR_WIDTH_M) * 0.5 - squeeze_m
    var required_m: float = CAR_WIDTH_M + MIN_SIDE_CLEARANCE_M
    var margin_m: float = available_m - required_m
    if margin_m >= 0.0:
        return {"outcome": "clear", "side": side, "margin_m": margin_m, "attacker_loss_s": 0.0, "defender_loss_s": 0.0}
    # Drivers with better awareness or less risk appetite back out of a
    # narrowing gap. Contact needs BOTH poor judgement and little space.
    var risk: float = clampf(float(attacker.get("risk_tolerance", 50.0)), 0.0, 100.0)
    var awareness: float = clampf(float(attacker.get("spatial_awareness", 80.0)), 0.0, 100.0)
    var insists: bool = risk > 74.0 and awareness < 70.0 and margin_m < -0.35
    if insists:
        var loss: float = clampf(1.4 + absf(margin_m) * 0.65, 1.4, 4.0)
        return {"outcome": "contact", "side": side, "margin_m": margin_m, "attacker_loss_s": loss, "defender_loss_s": loss * 0.45}
    return {"outcome": "yield", "side": side, "margin_m": margin_m, "attacker_loss_s": 0.35, "defender_loss_s": 0.0}
