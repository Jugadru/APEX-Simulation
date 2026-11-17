extends RefCounted
## APEX 0.5.9.0: deterministic delegation of pace and KERS to the player's team.
## Pit execution/forecast stay inside the validated Core 2 RaceEngine.
## Staff are gameplay levels, not historical ratings of real 2012 professionals.

static func decide(car: Dictionary, advice: Dictionary, weather: Dictionary, staff: Dictionary, race_laps: int) -> Dictionary:
	var engineer: int = clampi(int(staff.get("Engenheiro", 0)), 0, 3)
	var strategist: int = clampi(int(staff.get("Estrategista", 0)), 0, 3)
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var water: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var forecast: float = clampf(float(advice.get("forecast_3", water)), 0.0, 1.0)
	var tyre: String = str(car.get("tire", "Médio"))
	var gap: float = float(car.get("interval", 999.0))
	var left: int = maxi(0, race_laps - int(car.get("laps_done", 0)))
	var window_start: int = int(advice.get("window_start", 0))
	var current_lap: int = int(car.get("laps_done", 0))
	var pit_soon: bool = bool(advice.get("pit_now", false)) or (window_start > 0 and window_start <= current_lap + 2)
	var slick: bool = tyre in ["Macio", "Médio", "Duro"]
	var mismatched_wet: bool = (slick and water >= 0.32) or (tyre == "Chuva" and water < 0.18)
	var pace: String = "Normal"
	var why: String = "ritmo equilibrado"
	if wear >= 78.0 or (mismatched_wet and water >= 0.45):
		pace = "Conservar"
		why = "proteger pneus/aderencia em condicoes criticas"
	elif engineer >= 1 and wear >= (73.0 - 3.0 * float(engineer)) and not pit_soon:
		pace = "Conservar"
		why = "poupar pneus antes da janela"
	elif strategist >= 2 and forecast > water + 0.16 and slick and wear >= 42.0:
		pace = "Conservar"
		why = "preparar troca com pista ficando molhada"
	elif left <= 2 and wear < 70.0 and water < 0.22:
		pace = "Atacar"
		why = "sprint final com pneus em bom estado"
	elif current_lap >= 1 and engineer >= 1 and gap <= 1.25 and wear < (48.0 + 4.0 * float(engineer)) and water < 0.28 and not pit_soon:
		pace = "Atacar"
		why = "tentar disputa no alcance do adversario"
	elif strategist >= 3 and pit_soon and wear < 62.0 and water < 0.22:
		pace = "Atacar"
		why = "aproveitar volta anterior a janela de box"
	var kers: String = "Equilibrado"
	if pace == "Conservar" or (wear > 80.0 and engineer >= 1):
		kers = "Economizar"
	elif pace == "Atacar" and engineer >= 1:
		kers = "Atacar"
	return {"pace": pace, "kers": kers, "reason": why}
