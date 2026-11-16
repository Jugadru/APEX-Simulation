extends RefCounted
## Module extracted from main.gd v0.6.2.0. Works through the live scene host.
## Keeps existing callbacks while separating responsibilities.
const RaceScript = preload("res://scripts/race_engine.gd")

static func _update_garage(host) -> void:
	var data: Dictionary = host.garage.get_team(host.selected_team)
	host.garage_title.text = "OFICINA  /  %s" % host.selected_team.to_upper()
	host.money_label.text = "ORÇAMENTO: R$ %.2f MILHÕES" % (float(data["budget"]) / 1000000.0)
	for part in ["Motor", "Asa", "Chassi"]:
		var level := int(data["levels"].get(part, 0))
		var cost: int = host.garage.next_cost(host.selected_team, part)
		var b: Button = host.upgrade_buttons[part]
		var on_order: bool = str(data.get("development_project", {}).get("part", "")) == part
		b.text = "%s  •  N%d/3  •  %s" % [part, level, "EM P&D" if on_order else ("MÁXIMO" if cost < 0 else "R$ %.2f mi" % (float(cost) / 1000000.0))]
		b.disabled = cost < 0 or int(data["budget"]) < cost
	for part in ["Agilidade", "Precisão", "Coordenação"]:
		var level := int(data["crew_levels"].get(part, 0))
		var cost: int = host.garage.crew_next_cost(host.selected_team, part)
		var b: Button = host.crew_buttons[part]
		var on_order: bool = str(data.get("development_project", {}).get("part", "")) == part
		b.text = "%s  •  N%d/3  •  %s" % [part, level, "EM P&D" if on_order else ("MÁXIMO" if cost < 0 else "R$ %.2f mi" % (float(cost) / 1000000.0))]
		b.disabled = cost < 0 or int(data["budget"]) < cost
	var speed: int = int(data["crew_levels"].get("Agilidade", 0))
	var accuracy: int = int(data["crew_levels"].get("Precisão", 0))
	var coordination: int = int(data["crew_levels"].get("Coordenação", 0))
	var training_service: float = RaceScript.CREW_SERVICE_SAVE_PER_LEVEL * float(speed)
	var training_dock: float = RaceScript.CREW_DOCK_SAVE_PER_LEVEL * float(coordination)
	var incident_chance: float = 100.0 * RaceScript.PIT_GUN_FAILURE_CHANCE * (1.0 - RaceScript.CREW_FAULT_REDUCTION_PER_LEVEL * float(accuracy))
	var release_chance: float = 100.0 * RaceScript.PIT_UNSAFE_RELEASE_CHANCE * (1.0 - RaceScript.CREW_UNSAFE_REDUCTION_PER_LEVEL * float(accuracy))
	host.crew_summary.text = "GANHOS DA EQUIPE: -%.2fs na troca • -%.2fs no encaixe • Falha %.2f%% • Retenção %.2f%%" % [training_service, training_dock, incident_chance, release_chance]
	for role in ["Estrategista", "Engenheiro"]:
		var cost: int = host.garage.staff_next_cost(host.selected_team, role)
		var level: int = int(data["staff_levels"].get(role, 0))
		var button: Button = host.staff_buttons[role]
		button.text = "%s • N%d/3 • %s" % [role, level, "MÁXIMO" if cost < 0 else "R$ %.2f mi" % (float(cost) / 1000000.0)]
		button.disabled = cost < 0 or int(data["budget"]) < cost
	var performance_gain: float = host.garage.estimated_lap_gain(data["levels"])
	var best: String = host.garage.recommend_upgrade(host.selected_team)
	host.garage_development_summary.text = "GANHO ESTIMADO DA SUA EQUIPE: %.2fs/volta sobre a base do Apex (sem clima/tráfego). Próximo investimento de melhor ganho/custo: %s.\nEsses coeficientes são gameplay, não dados históricos da Fórmula 1." % [performance_gain, "nenhum disponível" if best.is_empty() else best]
	var campaign: bool = host.championship_mode and host.championship.has_season() and not host.championship.is_complete()
	var serial: int = int(host.championship.state.get("serial", 0)) if host.championship.has_season() else 0
	var round_index: int = int(host.championship.state.get("round_index", 0)) if host.championship.has_season() else 0
	var rounds: int = (host.championship.state.get("calendar", []) as Array).size() if host.championship.has_season() else 0
	var project: Dictionary = data.get("development_project", {})
	if not project.is_empty():
		host.garage_project_status.text = "EM PROJETO: %s • entrega após GP %d • restante %d GP(s) • pagamento já reservado" % [str(project.get("part", "")), int(project.get("ready_round", 0)), maxi(0, int(project.get("ready_round", 0)) - round_index)]
	else:
		host.garage_project_status.text = "Sem P&D em andamento. Projetos ficam prontos após duas etapas de campeonato."
	host.garage_cancel_project.disabled = project.is_empty()
	for part in ["Motor", "Asa", "Chassi"]:
		var b: Button = host.garage_project_buttons[part]
		var cost: int = host.garage.research_next_cost(host.selected_team, part)
		b.text = "%s • P&D N%d→N%d • %s" % [part, int(data["levels"].get(part,0)), mini(3,int(data["levels"].get(part,0))+1), "INDISPONÍVEL" if cost < 0 else "R$ %.2f mi" % (float(cost)/1000000.0)]
		b.disabled = not campaign or round_index + 2 > rounds or not project.is_empty() or cost < 0 or int(data["budget"]) < cost
	var rival_lines: Array[String] = []
	if host.championship.has_season():
		var all_rivals: Dictionary = host.championship.get_rival_development()
		var names: Array = all_rivals.keys()
		names.sort()
		for name in names:
			var rival: Dictionary = all_rivals[name]
			var up: Dictionary = rival.get("levels", {})
			rival_lines.append("%s  |  Motor %d • Asa %d • Chassi %d  |  ganho estimado %.2fs/volta  |  caixa R$ %.2f mi" % [str(name), int(up.get("Motor",0)),int(up.get("Asa",0)),int(up.get("Chassi",0)), float(up.get("Motor",0))*0.12+float(up.get("Asa",0))*0.10+float(up.get("Chassi",0))*0.07, float(rival.get("budget",0))/1000000.0])
	host.garage_rivals_summary.text = "\n".join(rival_lines) if not rival_lines.is_empty() else "Sem campeonato: rivais não investem em GPs avulsos."
	host.staff_summary.text = "No Automático, staff de nível superior melhora decisões de ritmo e consumo de KERS. A IA de pit usa o planejamento de stints já existente, sem promessa de estratégia perfeita."


	var hub = host.garage_root.get_node_or_null("ManagementHub")
	if hub != null:
		hub.refresh()
