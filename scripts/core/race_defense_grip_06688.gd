extends RefCounted
## v0.6.6.8.8 — deterministic early defensive judgement in low grip.
## Only decides whether to defend BEFORE overlap, never changes pace, grip,
## race progress, pass impulses or the already-established defensive line.
## All values are gameplay approximations, not circuit physics measurements.

static func evaluate(defender: Dictionary, gap_m: float, weather: Dictionary) -> Dictionary:
    var aggression: float = clampf(float(defender.get("defense_aggression", 55.0)), 0.0, 100.0)
    var awareness: float = clampf(float(defender.get("spatial_awareness", 80.0)), 0.0, 100.0)
    var wear: float = clampf(float(defender.get("wear", 0.0)), 0.0, 100.0)
    var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
    # In the dry, original v0.6.6.8.7 early-defense behavior is unchanged.
    # With less grip, a worn tyre and poor spatial awareness reduce willingness
    # to make an aggressive early defensive move. This NEVER modifies speed.
    var caution: float = wet * (8.0 + maxf(0.0, wear - 40.0) * 0.30 +
            maxf(0.0, 85.0 - awareness) * 0.24)
    var effective: float = aggression - caution
    var early_window: bool = gap_m > 11.5 and gap_m < 36.0
    return {"early_move": early_window and effective >= 47.0,
        "effective_aggression": effective, "caution": caution,
        "wet": wet, "wear": wear, "awareness": awareness,
        "early_window": early_window}
