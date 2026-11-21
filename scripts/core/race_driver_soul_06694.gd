extends RefCounted
## APEX v0.6.6.9.4 — Driver Soul 3.0.
## Builds on Soul 2.0: lap-grounded emotions, real requests and a bounded
## overtaking commitment adjustment. No RNG, artificial speed or pit orders.
## All personality attributes are fictional gameplay traits, not FIA telemetry.
const Soul2 = preload("res://scripts/core/race_driver_soul_0647.gd")
const VERSION := "3.0"

static func initial(car: Dictionary) -> Dictionary:
	var soul: Dictionary = Soul2.initial(car)
	soul["version"] = VERSION
	soul["racing_intent"] = "OBSERVAR"
	soul["intent_reason"] = "Aguardando dados de corrida"
	return soul

static func update(car: Dictionary, weather: Dictionary, teammate: Dictionary = {}) -> Dictionary:
	var old_soul: Dictionary = car.get("driver_soul", {})
	var previous_lap: int = int(old_soul.get("last_lap", 0))
	var previous_request: int = int(old_soul.get("request_seq", 0))
	# Keep Soul 2.0's bounded emotional history and realistic request gates.
	Soul2.update(car, weather, teammate)
	var lap: int = int(car.get("laps_done", 0))
	if lap <= previous_lap or bool(car.get("finished", false)):
		return {}
	var soul: Dictionary = (car.get("driver_soul", {}) as Dictionary).duplicate(true)
	var pressure: float = clampf(float(soul.get("pressure", 0.15)), 0.0, 1.0)
	var confidence: float = clampf(float(soul.get("confidence", 0.55)), 0.0, 1.0)
	var focus: float = clampf(float(soul.get("focus", 0.85)), 0.0, 1.0)
	var initiative: float = clampf(float(soul.get("initiative", 0.55)), 0.0, 1.0)
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var perceived: float = clampf(float(soul.get("perceived_wear", wear)), 0.0, 100.0)
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var intent: String = "MANTER"
	var reason: String = "Ritmo estavel, sem risco adicional"
	if wear >= 78.0 or perceived >= 82.0:
		intent = "GERIR_PNEUS"
		reason = "Desgaste medido %.0f%%, percebido %.0f%%" % [wear, perceived]
	elif wet >= 0.55 and pressure > 0.35:
		intent = "CAUTELA"
		reason = "Pista %.0f%% molhada e pressao %.0f%%" % [wet * 100.0, pressure * 100.0]
	elif confidence > 0.61 and focus > 0.73 and initiative >= 0.58 and pressure < 0.49:
		intent = "ATACAR"
		reason = "Confianca %.0f%% e foco %.0f%%" % [confidence * 100.0, focus * 100.0]
	elif pressure > 0.51 or focus < 0.70:
		intent = "CAUTELA"
		reason = "Pressao %.0f%% e foco %.0f%%" % [pressure * 100.0, focus * 100.0]
	soul["version"] = VERSION
	soul["racing_intent"] = intent
	soul["intent_reason"] = reason
	car["driver_soul"] = soul
	# Actual lap-grounded requests are emitted once; messages are never used
	# as covert pit/pace commands. Existing radio cooldown still applies.
	if int(soul.get("request_seq", 0)) <= previous_request:
		return {}
	var request: Dictionary = soul.get("request", {})
	if request.is_empty() or bool(request.get("answered", false)):
		return {}
	return {"kind": str(request.get("kind", "")), "lap": lap,
		"message": "RADIO FICTICIO | %s: %s" % [str(car.get("name", "Piloto")), str(request.get("message", ""))],
		"reason": str(request.get("reason", "")), "request_id": int(request.get("id", 0))}

static func attack_bias(car: Dictionary, weather: Dictionary) -> float:
	# Positive values demand a larger genuine lap-time advantage to attack.
	# No speed/grip coefficient is modified. This is read-only and deterministic.
	var soul: Dictionary = car.get("driver_soul", {})
	if str(soul.get("version", "")) != VERSION:
		return 0.0
	var confidence: float = clampf(float(soul.get("confidence", 0.55)), 0.0, 1.0)
	var pressure: float = clampf(float(soul.get("pressure", 0.15)), 0.0, 1.0)
	var focus: float = clampf(float(soul.get("focus", 0.85)), 0.0, 1.0)
	var initiative: float = clampf(float(soul.get("initiative", 0.55)), 0.0, 1.0)
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var perceived: float = clampf(float(soul.get("perceived_wear", wear)), 0.0, 100.0)
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	return clampf((0.56 - confidence) * 0.13 +
			(pressure - 0.35) * 0.11 +
			(0.75 - focus) * 0.09 +
			(0.55 - initiative) * 0.075 +
			maxf(0.0, perceived - wear) * 0.0022 +
			wet * pressure * 0.045,
			-0.085, 0.16)

static func summary(car: Dictionary) -> String:
	var soul: Dictionary = car.get("driver_soul", {})
	return Soul2.summary(car).replace("SOUL 2.0", "SOUL 3.0") + " · %s" % str(soul.get("racing_intent", "MANTER"))
