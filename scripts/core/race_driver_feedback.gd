extends RefCounted
## Apex 0.6.3.0: brief, fictional driver feedback generated from current race facts.
## Read-only decision: does NOT pit, change pace, change weather, or consume RNG.
## The message is a SIMULATED radio line, not a historical quote or recording.

const MIN_LAP: int = 2
const MESSAGE_COOLDOWN_LAPS: int = 4

static func assess(car: Dictionary, weather: Dictionary, tyre: Dictionary) -> Dictionary:
	if bool(car.get("finished", false)) or float(car.get("pit_left", 0.0)) > 0.0:
		return {}
	var lap: int = int(car.get("laps_done", 0))
	if lap < MIN_LAP or lap - int(car.get("driver_radio_last_lap", -100)) < MESSAGE_COOLDOWN_LAPS:
		return {}
	var compound: String = str(car.get("tire", ""))
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var wetness: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var heat: float = clampf(float(car.get("tyre_heat", 0.0)), 0.0, 1.0)
	var stint: int = int(car.get("stint_laps", 0))
	var cliff: float = float(tyre.get("cliff", 75.0))
	var driver: String = str(car.get("name", "Piloto"))
	# Priority: unsuitable compound, tyre cliff, temperature, then traffic.
	# Do not pretend to know exact degradation; it is the driver's sensation.
	var kind: String = ""
	var message: String = ""
	if compound not in ["Intermediário", "Chuva"] and wetness >= 0.38:
		kind = "grip_molhado"
		message = "A pista está escorregadia com estes pneus de seco. Precisamos avaliar a estratégia."
	elif compound == "Chuva" and wetness <= 0.10 and stint >= 2:
		kind = "chuva_secando"
		message = "A pista está secando. Os pneus de chuva já não parecem a melhor opção."
	elif compound == "Intermediário" and wetness <= 0.08 and stint >= 2:
		kind = "inter_secando"
		message = "Está praticamente seco aqui. Podemos avaliar pneus de seco."
	elif wear >= maxf(73.0, cliff - 4.0) and stint >= 2:
		kind = "aderencia"
		message = "Estou perdendo aderência. Podem verificar se está na hora de trocar os pneus?"
	elif heat >= 0.56 and stint >= 2:
		kind = "temperatura"
		message = "Os pneus estão aquecendo demais nas curvas. Estou tentando controlar a temperatura."
	elif int(car.get("position", 0)) > 1 and float(car.get("interval", 999.0)) <= 1.15 and stint >= 2:
		kind = "trafego"
		message = "Estou muito perto do carro da frente e perdendo rendimento no ar sujo."
	if kind.is_empty():
		return {}
	# Evita a mesma reclamação a cada quatro voltas consecutivas.
	# Se o problema mudou, o cooldown original continua valendo.
	if kind == str(car.get("driver_radio_last_kind", "")) and lap - int(car.get("driver_radio_last_lap", -100)) < 8:
		return {}
	return {"kind": kind, "lap": lap,
		"message": "RÁDIO FICTÍCIO | %s: %s" % [driver, message]}
