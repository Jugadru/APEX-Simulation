extends RefCounted
## Pure cross-over tyre performance, no RNG; race_wetness is 0..1.
## Pace penalties in seconds per lap; invented balance values, not FIA data.
const WET_NAMES := ["Intermediário", "Chuva"]

static func modifier(compound: String, race_wetness: float) -> Dictionary:
    var w: float = clampf(race_wetness, 0.0, 1.0)
    if compound == "Intermediário":
        # Light / medium rain: intermediates are quickest. Above the cross-over,
        # their loss rises smoothly instead of adding ~15-23s/lap as in 0.5.5.0.
        # These are APEX balance parameters, not historical lap-time measurements.
        var inter_dry_cost: float = 5.0 * pow(maxf(0.0, 1.0 - w / 0.24), 1.25)
        var inter_flood_cost: float = 5.0 * pow(maxf(0.0, (w - 0.55) / 0.45), 1.55)
        return {"penalty": inter_dry_cost + inter_flood_cost, "wear_multiplier": 1.0 + 1.3 * maxf(0.0, 1.0 - w / 0.25)}
    if compound == "Chuva":
        # Full wets gain only a modest edge on a flooded track. On a merely
        # damp track they lose time, encouraging an intermediate switch.
        var wet_dry_cost: float = 8.0 * pow(maxf(0.0, 1.0 - w / 0.74), 1.1)
        var wet_flood_cost: float = 0.8 * maxf(0.0, (w - 0.92) / 0.08)
        return {"penalty": wet_dry_cost + wet_flood_cost, "wear_multiplier": 1.0 + 2.0 * maxf(0.0, 1.0 - w / 0.48)}
    # A slick becomes dangerous as standing water grows (aquaplaning proxy).
    return {"penalty": 4.0 * w + 75.0 * w * w, "wear_multiplier": 1.0 - 0.45 * w}

static func weather_time_penalty(w: float, rain: float) -> float:
    return clampf(w, 0.0, 1.0) * 10.0 + clampf(rain, 0.0, 1.0) * 1.5

static func weather_incident_risk(compound: String, w: float) -> float:
    if compound == "Chuva":
        return 0.002 * w
    if compound == "Intermediário":
        return maxf(0.0, w - 0.65) * 0.023
    return pow(clampf(w, 0.0, 1.0), 2.0) * 0.08
