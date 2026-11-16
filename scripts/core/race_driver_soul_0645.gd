extends RefCounted
## Fictional race-local emotion. No RNG, physical multipliers or hidden orders.
static func initial(car: Dictionary) -> Dictionary:
	return {"confidence": 0.55, "pressure": 0.15, "focus": 0.85,
		"last_lap": int(car.get("laps_done", 0)), "position": int(car.get("position", 24)),
		"state": "CONCENTRADO", "cause": "Aguardando primeiras voltas", "history": []}

static func update(car: Dictionary, weather: Dictionary) -> void:
	var soul: Dictionary = (car.get("driver_soul", initial(car)) as Dictionary).duplicate(true)
	var lap: int = int(car.get("laps_done", 0))
	if lap <= int(soul.get("last_lap", 0)):
		return
	var position: int = int(car.get("position", 24))
	var change: int = int(soul.get("position", position)) - position
	var in_pit: bool = float(car.get("pit_left", 0.0)) > 0.0 or bool(car.get("pit_request", false))
	var close: bool = position > 1 and float(car.get("interval", 999.0)) < 1.4 and not in_pit
	var stress: float = 0.15 + (0.28 if close else 0.0) + float(weather.get("wetness_factor", 0.0)) * 0.25 + maxf(0.0, float(car.get("wear", 0.0)) - 65.0) / 100.0
	soul["pressure"] = clampf(lerpf(float(soul["pressure"]), stress, 0.3), 0.0, 1.0)
	soul["confidence"] = clampf(float(soul["confidence"]) + (clampf(float(change), -2.0, 2.0) * 0.025 if not in_pit else 0.0) + (0.55 - float(soul["confidence"])) * 0.04, 0.20, 0.90)
	soul["focus"] = clampf(0.92 - float(soul["pressure"]) * 0.25, 0.50, 0.95)
	var state: String = "SOB PRESSÃO" if float(soul["pressure"]) > 0.45 else ("CONFIANTE" if float(soul["confidence"]) > 0.65 else "CONCENTRADO")
	var cause: String = "Disputa próxima" if close else ("Pista molhada" if float(weather.get("wetness_factor", 0.0)) > 0.3 else ("Pneu desgastado" if float(car.get("wear", 0.0)) > 75.0 else "Ritmo e condições estáveis"))
	if state != str(soul["state"]) or cause != str(soul["cause"]):
		var history: Array = soul["history"]
		history.append("V%d · %s · %s" % [lap, state, cause])
		while history.size() > 8:
			history.pop_front()
	soul.merge({"last_lap": lap, "position": position, "state": state, "cause": cause}, true)
	car["driver_soul"] = soul

static func summary(car: Dictionary) -> String:
	var soul: Dictionary = car.get("driver_soul", initial(car))
	return "SOUL · %s · pressão %d%% · foco %d%% · %s" % [str(soul["state"]), int(float(soul["pressure"]) * 100), int(float(soul["focus"]) * 100), str(soul["cause"])]
