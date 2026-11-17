extends RefCounted
## APEX 0.6.4.3 — original water-on-line crossover decision logic.
## Backward-compatible 0..1 humidity is translated to millimeters when no mm passed.
## No external game source code or balance data is copied.
static func validate(current: String, next: String, wear: float,
		critical: bool, water: float, rain: float, forecast_3: float,
		line_water_mm: float = -1.0, forecast_line_mm: float = -1.0,
		surface_moisture: float = 0.0) -> Dictionary:
	if critical or wear >= 88.0 or current == next:
		return {"allowed": true, "reason": "desgaste ou composto igual"}
	var actual_mm: float = water * 5.0 if line_water_mm < 0.0 else line_water_mm
	var future_mm: float = forecast_3 * 5.0 if forecast_line_mm < 0.0 else forecast_line_mm
	var trend: float = future_mm - actual_mm
	var film: float = clampf(surface_moisture, 0.0, 1.0)
	var slick: bool = current not in ["Intermediário", "Chuva"]
	var target_wet: bool = next in ["Intermediário", "Chuva"]
	var allow: bool = true
	var reason: String = ""
	if slick and target_wet:
		if next == "Chuva":
			# A rain shower alone cannot warrant full wets.
			if not (actual_mm >= 3.80 or (actual_mm >= 3.20 and rain >= 0.73 and future_mm >= 3.90)):
				allow = false
				reason = "precisa de água acumulada na linha para pneus de chuva extrema"
		elif next == "Intermediário":
			# Current precipitation, standing water, and trend must agree.
			if not (actual_mm >= 1.35 or (actual_mm >= 0.95 and
					(rain >= 0.22 or trend >= 0.25) and future_mm >= 1.12) or
					(actual_mm >= 0.80 and rain >= 0.68 and trend >= 0.75)):
				allow = false
				reason = "chuva no céu, mas sem água suficiente no asfalto"
	elif current == "Chuva" and next == "Intermediário":
		# Remain on wets while water is high even with a dry forecast.
		if actual_mm > 3.50 or (actual_mm > 3.15 and future_mm >= 3.30):
			allow = false
			reason = "linha ainda muito molhada para abandonar pneus de chuva"
	elif not slick and not target_wet:
		# Residual moisture contributes to the dry crossover.
		if actual_mm >= 0.62 or future_mm >= 0.78 or (film >= 0.78 and actual_mm >= 0.42):
			allow = false
			reason = "linha de corrida ainda não secou para slicks"
	elif current == "Intermediário" and next == "Chuva":
		if not (actual_mm >= 3.90 or (actual_mm >= 3.45 and rain >= 0.68 and future_mm >= 4.10)):
			allow = false
			reason = "aguardar acúmulo real de água para chuva extrema"
	return {"allowed": allow, "reason": reason}
