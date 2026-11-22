extends RefCounted
## APEX v0.6.6.9.10 — Strategy Staff Intelligence 1.0.
## Pure, deterministic and bounded advice. Observes only live known conditions;
## never consults hidden weather events, race RNG or future rival commands.
## The RaceEngine alone authorizes an optional +1 lap automatic hold.
const PitWall = preload("res://scripts/core/race_pitwall_strategy_0649.gd")
const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]

static func profile(team_state: Dictionary) -> Dictionary:
	var roster: Dictionary = team_state.get("staff_roster", {})
	var person: Dictionary = roster.get("Estrategista", {})
	var trained: int = clampi(int(team_state.get("staff_levels", {}).get("Estrategista", 0)), 0, 3)
	var hired: bool = not person.is_empty()
	var skill: int = clampi(int(person.get("skill", 50 + trained * 10)), 0, 100)
	var relations: Dictionary = team_state.get("staff_soul", {}).get("relations", {})
	# SoulStaff.pair_key("Estrategista", "Engenheiro") == "Engenheiro|Estrategista".
	var bond: int = clampi(int(relations.get("Engenheiro|Estrategista", 50)), 0, 100)
	return {
		"active": hired or trained > 0,
		"name": str(person.get("name", "Equipe de estratégia" if trained > 0 else "Sem estrategista")),
		"specialty": str(person.get("specialty", "Análise de corrida")),
		"skill": skill, "trained_level": trained,
		"morale": clampi(int(person.get("morale", 70)), 0, 100),
		"energy": clampi(int(person.get("energy", 78)), 0, 100),
		"trust": clampi(int(person.get("trust", 65)), 0, 100),
		"engineer_bond": bond,
		"source": "contrato" if hired else ("treinamento" if trained > 0 else "sem titular")
	}

static func assess(car: Dictionary, teammate: Dictionary, grid: Array,
		proposal: Dictionary, observed_weather: Dictionary, staff: Dictionary,
		available_compounds: Array, pit_loss: float, base_lap: float, race_laps: int, next_entry: int) -> Dictionary:
	var plan: Dictionary = PitWall.assess(car, teammate, grid, proposal, observed_weather,
		available_compounds,
		race_laps, pit_loss, base_lap, next_entry)
	var active: bool = bool(staff.get("active", false))
	var skill: int = clampi(int(staff.get("skill", 0)), 0, 100)
	var energy: int = clampi(int(staff.get("energy", 70)), 0, 100)
	var trust: int = clampi(int(staff.get("trust", 65)), 0, 100)
	var bond: int = clampi(int(staff.get("engineer_bond", 50)), 0, 100)
	# Heuristic review quality, not a calibrated probability or a performance bonus.
	var review_quality: float = clampf(0.62 * float(skill) + 0.18 * float(energy)
		+ 0.12 * float(trust) + 0.08 * float(bond), 0.0, 100.0)
	var water: float = clampf(float(observed_weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var future3: float = clampf(float(proposal.get("forecast_3", water)), 0.0, 1.0)
	var future6: float = clampf(float(proposal.get("forecast_6", future3)), 0.0, 1.0)
	var dry_stable: bool = water < 0.10 and future3 < 0.10 and future6 < 0.12
	var next_tire: String = str(proposal.get("compound", ""))
	var own_wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var partner_safe: bool = teammate.is_empty() or (
		not bool(teammate.get("pit_request", false))
		and float(teammate.get("pit_left", 0.0)) <= 0.0
		and int(teammate.get("pit_scheduled_lap", 0)) != next_entry
		and int(teammate.get("pit_scheduled_lap", 0)) != next_entry + 1)
	var now: Dictionary = plan.get("now", {})
	var later: Dictionary = plan.get("later", {})
	var own_stop: int = int(car.get("stops", 0))
	# Single optional +1V hold per stint, only when next-lap rejoin has
	# objectively better projected free air. No override for critical tyres,
	# wet crossovers, explicit schedules, pit conflicts or the last legal window.
	var hold: bool = (
		active and skill >= 70 and energy >= 45 and review_quality >= 66.0
		and bool(proposal.get("pit_now", false)) and not bool(proposal.get("critical", false))
		and not bool(proposal.get("deferred", false))
		and bool(plan.get("can_extend", false)) and not bool(plan.get("critical", false))
		and not bool(plan.get("team_overlap", false)) and partner_safe
		and dry_stable and str(car.get("tire", "")) in SLICKS and next_tire in SLICKS
		and own_wear < 58.0 and float(proposal.get("life_laps", 0.0)) >= 3.0
		and int(car.get("stint_laps", 0)) >= 4 and next_entry + 2 < race_laps
		and not bool(car.get("pitwall49_held", false))
		and int(car.get("staff_strategy_hold_stint_066910", -999)) != own_stop
		and int(car.get("lap_strategy_adjusted_stint_06496", -999)) != own_stop
		and int(car.get("team_pit_adjusted_stint_06497", -999)) != own_stop
		and bool(now.get("traffic", false)) and bool(later.get("clear_air", false))
	)
	var recommendation: String = "MANTER PLANO"
	var reason: String = str(plan.get("reason", "Reavaliar pneus e tráfego."))
	if not active:
		reason = "Sem estrategista disponível; o Pit Wall convencional permanece responsável."
	elif int(car.get("pit_scheduled_lap", 0)) > 0:
		recommendation = "ORDEM MANUAL PROTEGIDA"
		reason = "Agendamento V%d permanece intacto." % int(car.get("pit_scheduled_lap", 0))
	elif bool(plan.get("critical", false)):
		recommendation = "PRIORIDADE SEGURANÇA"
		reason = "Pneus ou condições críticas não permitem adiamento discricionário."
	elif hold:
		recommendation = "CONSIDERAR +1 VOLTA"
		reason = "Retorno imediato projetado em tráfego; próxima volta oferece ar mais livre, com pneus e pista estáveis."
	elif bool(proposal.get("pit_now", false)):
		recommendation = "BOX NA JANELA"
		reason = "Conservar chamada do motor: não há evidência suficiente para uma extensão segura."
	var confidence: String = "BAIXA"
	if active and str(plan.get("confidence", "")) == "ALTA" and review_quality >= 82.0:
		confidence = "ALTA"
	elif active and str(plan.get("confidence", "")) != "BAIXA" and review_quality >= 60.0:
		confidence = "MODERADA"
	var name: String = str(staff.get("name", "Sem estrategista"))
	var summary: String = "%s: %s. %s (confiança %s, qualitativa)." % [
		name, recommendation, reason, confidence]
	return {
		"version": "0.6.6.9.10", "source":"observacoes_e_previsoes_imperfeitas",
		"staff_name":name, "skill":skill, "review_quality":review_quality,
		"specialty":str(staff.get("specialty", "")),
		"recommendation":recommendation, "reason":reason, "summary":summary,
		"confidence":confidence, "proposed_hold_one_lap":hold,
		"executable_only_if_automatic":true,
		"pitwall_gate":str(plan.get("gate", "CONSULTIVO")),
		"now_traffic":bool(now.get("traffic", false)),
		"later_clear_air":bool(later.get("clear_air", false)),
		"current_wetness":water, "forecast_3":future3, "forecast_6":future6,
		"alternatives":plan.get("cases", []).duplicate(true),
		"limitations":"Projeção local, sem futuro conhecido e sem probabilidade calibrada."
	}
