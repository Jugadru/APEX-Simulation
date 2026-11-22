extends RefCounted
## APEX v0.6.6.9.14 — Setup & Track Knowledge 1.0.
## Deterministic advisory derived ONLY from the existing 2012 race-track catalog
## and observed race/weather state. NOT a physics setup or telemetry measurement.
## Never issues commands, touches cars or changes replay/checkpoint state.

const TrackDynamics = preload("res://scripts/core/race_track_dynamics.gd")

static func assess(track: Dictionary, weather: Dictionary, car: Dictionary = {},
		staff: Dictionary = {}) -> Dictionary:
	var code: String = str(track.get("code", ""))
	var profile: Dictionary = TrackDynamics.profile_for(code)
	if code.is_empty() or profile.is_empty():
		return {"available":false, "version":"0.6.6.9.14", "read_only":true,
			"track_code":code, "reason":"Perfil de pista indisponível no catálogo 2012.",
			"briefing":"SETUP/PISTA: perfil indisponível; nenhuma configuração aplicada.",
			"can_apply":false, "limitations":"Sem dados: nenhuma recomendação especulativa."}
	var lateral: float = float(profile.get("lateral_load", 1.0))
	var traction: float = float(profile.get("traction", 1.0))
	var abrasion: float = float(profile.get("abrasion", 1.0))
	var drainage: float = float(profile.get("drainage", 1.0))
	var grip: float = float(profile.get("surface_grip", 1.0))
	var rubber: float = float(profile.get("rubber_deposition", 1.0))
	var wetness: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var tarmac_c: float = float(weather.get("track_c", -1.0))
	var staff_level: int = clampi(int(staff.get("Engenheiro", 0)), 0, 3)

	# Qualitative engineering heuristics, not an executable setup package.
	# A fast low-load circuit differs from a mechanical-grip street circuit.
	var aerodynamic: String = "EQUILIBRADA"
	var aero_reason: String = "Cargas laterais e tração não indicam extremos."
	if lateral >= 1.16 or traction >= 1.18:
		aerodynamic = "ALTA CARGA"
		aero_reason = "Prioridade de apoio em curvas ou tração; conferir custo nas retas."
	elif lateral <= 0.84 and traction < 1.18:
		aerodynamic = "BAIXA CARGA"
		aero_reason = "Menor exigência lateral no catálogo; verificar frenagem e estabilidade."

	var mechanical: String = "EQUILIBRADO"
	if traction >= 1.15:
		mechanical = "FOCO EM TRAÇÃO"
	elif lateral >= 1.16:
		mechanical = "FOCO EM APOIO LATERAL"

	var tyre_priority: String = "MONITORAR"
	if abrasion >= 1.16:
		tyre_priority = "POUPAR PNEUS"
	elif abrasion <= 0.91:
		tyre_priority = "DESGASTE DE BASE MENOR"
	var water_note: String = "Pista seca ou com água baixa no estado atual."
	if wetness >= 0.38:
		water_note = "Pista molhada (%.0f%%); aderência real depende do composto e do motor." % (wetness * 100.0)
	elif wetness >= 0.15:
		water_note = "Pista úmida (%.0f%%); reavaliar aderência antes de alterar o plano." % (wetness * 100.0)
	if wetness >= 0.15 and drainage <= 0.91:
		water_note += " Drenagem do perfil relativamente limitada."

	var car_note: String = "Sem dados de carro individual fornecidos."
	if not car.is_empty():
		var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
		var tyre: String = str(car.get("tire", "indefinido"))
		car_note = "%s, desgaste medido %.0f%%." % [tyre, wear]
		if int(car.get("pit_scheduled_lap", 0)) > 0:
			car_note += " BOX V%d protegido; esta consulta não altera a ordem." % int(car["pit_scheduled_lap"])
		elif bool(car.get("pit_request", false)):
			car_note += " BOX já solicitado; esta consulta não modifica o procedimento."
	var confidence: String = "REFERÊNCIA DE CATÁLOGO"
	var precision: String = "Leitura sintética" if staff_level <= 1 else "Leitura técnica"
	var dimensions: String = "Lateral %.2f; tração %.2f; abrasão %.2f; drenagem %.2f." % [
		lateral, traction, abrasion, drainage]
	if staff_level >= 2:
		dimensions += " Grip-base %.2f; deposição de borracha %.2f." % [grip, rubber]
	var temp_note: String = ("Asfalto observado %.1f°C." % tarmac_c) if tarmac_c >= 0.0 else "Temperatura do asfalto não informada."
	var name: String = str(track.get("name", profile.get("name", code)))
	var briefing: String = "SETUP/PISTA 9.14 | %s (%s). Sugestão aerodinâmica: %s. %s Mecânica: %s. Pneu: %s. %s %s %s Não aplicada ao carro." % [
		name, code, aerodynamic, aero_reason, mechanical, tyre_priority,
		water_note, car_note, temp_note]
	return {
		"available":true, "version":"0.6.6.9.14", "read_only":true,
		"track_code":code, "track_name":name,
		"setup_aero":aerodynamic, "setup_mechanical":mechanical,
		"tyre_priority":tyre_priority, "aero_reason":aero_reason,
		"track_factors":profile.duplicate(true), "staff_level":staff_level,
		"confidence":confidence, "detail_level":precision,
		"dimensions":dimensions, "wet_note":water_note,
		"car_note":car_note, "temperature_note":temp_note,
		"summary":"%s • aero %s • mecânica %s • pneus %s" % [
			code, aerodynamic, mechanical, tyre_priority],
		"briefing":briefing, "can_apply":false,
		"limitations":"Recomendação qualitativa do catálogo APEX 2012, não configuração executável nem telemetria FIA."
	}
