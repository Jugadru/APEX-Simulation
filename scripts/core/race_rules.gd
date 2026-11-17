extends RefCounted
## APEX Core 2 is the only active race engine from v0.5.4.3 onward.
## Gameplay coefficients are approximate and subject to telemetry calibration.

const PROFILE_CORE2 := "core2"
const PACES := {
	"Conservar": {"delta": 0.34, "wear": 0.78},
	"Normal": {"delta": 0.0, "wear": 1.0},
	"Atacar": {"delta": -0.34, "wear": 1.34}
}

static func track_severity(track: Dictionary) -> float:
	var length: float = float(track.get("lap_km", 5.0))
	return clampf(1.0 + (5.0 - length) * 0.055, 0.84, 1.16)

static func display_name() -> String:
	return "APEX Core 2"
