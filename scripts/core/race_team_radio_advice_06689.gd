extends RefCounted
## APEX 0.6.6.8.9 — Cooperação de Equipe 2.0.
## Read-only evaluation of a fictional driver's request to pass their team-mate.
## Does NOT issue a team order, alter pace, pit strategy, car, RNG or replay.

const MIN_PACE_EDGE_S := 0.55
const MAX_TEAM_GAP_S := 1.50

static func evaluate(selected: Dictionary, teammate: Dictionary, weather: Dictionary) -> Dictionary:
	var unavailable := {"valid": false, "state": "sem_comparacao",
		"driver": "Não tenho uma comparação confiável com meu companheiro neste momento.",
		"engineer": "Precisamos de duas voltas comparáveis e carros próximos para analisar uma passagem. Nenhuma ordem foi enviada.",
		"read_only": true}
	if selected.is_empty() or teammate.is_empty():
		return unavailable
	if int(selected.get("id", -1)) == int(teammate.get("id", -1)) \
			or str(selected.get("team", "")) == "" \
			or str(selected.get("team", "")) != str(teammate.get("team", "")):
		return unavailable
	if bool(selected.get("finished", false)) or bool(teammate.get("finished", false)):
		return unavailable
	var pos: int = int(selected.get("position", 99))
	var mate_pos: int = int(teammate.get("position", 99))
	if absi(pos - mate_pos) != 1 or pos < 1 or mate_pos < 1:
		return unavailable
	var chasing: Dictionary = selected if pos > mate_pos else teammate
	var leading: Dictionary = teammate if pos > mate_pos else selected
	var gap: float = float(chasing.get("interval", -1.0))
	var chase_lap: float = float(chasing.get("last_lap", 0.0))
	var lead_lap: float = float(leading.get("last_lap", 0.0))
	var chase_done: int = int(chasing.get("laps_done", 0))
	var lead_done: int = int(leading.get("laps_done", 0))
	if gap < 0.0 or gap > MAX_TEAM_GAP_S or chase_done < 2 or lead_done < 2 \
			or absi(chase_done - lead_done) > 1 \
			or chase_lap < 25.0 or lead_lap < 25.0 \
			or chase_lap > 500.0 or lead_lap > 500.0:
		return unavailable
	var delta: float = lead_lap - chase_lap  # Positive: chasing driver faster.
	var streak: int = int((chasing.get("driver_soul", {}) as Dictionary).get("team_streak", 0))
	var wet: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
	var wear: float = clampf(float(chasing.get("wear", 0.0)), 0.0, 100.0)
	var slick: bool = str(chasing.get("tire", "")) in ["Supermacio", "Macio", "Médio", "Duro"]
	var risk: bool = (wet >= 0.60 and (slick or wear >= 60.0))
	var pit_active: bool = bool(chasing.get("pit_request", false)) \
		or float(chasing.get("pit_left", 0.0)) > 0.0 \
		or bool(leading.get("pit_request", false)) \
		or float(leading.get("pit_left", 0.0)) > 0.0
	var booked_selected: int = int(selected.get("pit_scheduled_lap", 0))
	var booked_mate: int = int(teammate.get("pit_scheduled_lap", 0))
	var booking_note: String = ""
	if booked_selected > 0:
		booking_note += " V%d do piloto selecionado permanece agendada." % booked_selected
	if booked_mate > 0:
		booking_note += " V%d do companheiro permanece agendada." % booked_mate
	var state: String = "manter_posicoes"
	var driver: String = "Acompanhando o ritmo do companheiro."
	var engineer: String = "Sem vantagem de ritmo sustentada; manter a situação e medir mais voltas."
	if delta >= MIN_PACE_EDGE_S and streak >= 2 and not risk and not pit_active:
		state = "avaliar_passagem"
		driver = ("Estou %.2fs mais rápido na última volta e a %.2fs do companheiro. Podemos avaliar uma passagem?" % [delta, gap]) if int(chasing.get("id", -1)) == int(selected.get("id", -2)) else ("O companheiro está %.2fs mais rápido atrás, a %.2fs. Vamos conversar sobre a prioridade?" % [delta, gap])
		engineer = "Ritmo favorável por %d voltas comparadas (última: %.2fs de vantagem; distância %.2fs). Podemos discutir a prioridade da equipe, mas nenhuma ordem foi emitida." % [streak, delta, gap]
	elif risk:
		state = "cautela_aderencia"
		driver = "Estamos próximos, mas a aderência torna arriscado tentar uma passagem combinada agora."
		engineer = "Pista %.0f%% molhada, pneus %s, desgaste %.0f%%: priorizar controle e telemetria antes de discutir uma troca." % [wet * 100.0, str(chasing.get("tire", "?")), wear]
	elif pit_active:
		state = "box_em_andamento"
		driver = "Uma operação de box está em andamento. Melhor rever a ordem de equipe depois."
		engineer = "Pit ativo em pelo menos um carro. Não alterar a estratégia por esta consulta."
	elif delta >= MIN_PACE_EDGE_S:
		state = "aguardar_confirmacao"
		driver = "Parece que tenho uma volta mais rápida; quero confirmar antes de pedir passagem."
		engineer = "Diferença de %.2fs na última volta, mas só %d volta(s) comparável(is) consecutiva(s). Aguardar mais dados e considerar tráfego." % [delta, streak]
	return {"valid": true, "state": state, "driver": driver,
		"engineer": engineer + booking_note,
		"selected_id": int(selected.get("id", -1)),
		"chasing_id": int(chasing.get("id", -1)), "leading_id": int(leading.get("id", -1)),
		"pace_edge_s": delta, "gap_s": gap, "team_streak": streak,
		"wetness": wet, "booked_selected": booked_selected,
		"booked_mate": booked_mate, "read_only": true}
