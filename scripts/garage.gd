extends RefCounted
## Garage shared by both cars of the selected team. Saves to user://.
const SAVE_PATH := "user://apex_garage_050.json"
const StaffMarket = preload("res://scripts/core/staff_market_0648.gd")
const StaffContracts = preload("res://scripts/core/staff_contracts.gd")
const SoulStaff = preload("res://scripts/core/staff_soul_0650.gd")
const SaveMigration = preload("res://scripts/core/apex_save_migration_0650.gd")
const PARTS := ["Motor", "Asa", "Chassi"]
const BASE_COST := {"Motor": 2000000, "Asa": 1600000, "Chassi": 1400000}
const INITIAL_BUDGET := 12000000
const MAX_LEVEL := 3
const RESEARCH_DISCOUNT: float = 0.85
const RESEARCH_LEAD_ROUNDS: int = 2
const PERFORMANCE_GAIN := {"Motor": 0.13, "Asa": 0.11, "Chassi": 0.06}
# Training and equipment development share the existing team budget.
# Levels default to zero for all existing saves, preserving older careers.
const CREW_PARTS := ["Agilidade", "Precisão", "Coordenação"]
const CREW_BASE_COST := {"Agilidade": 240000, "Precisão": 180000, "Coordenação": 200000}
const STAFF_ROLES := ["Estrategista", "Engenheiro"]
const STAFF_BASE_COST := {"Estrategista": 350000, "Engenheiro": 300000}
const Workshop = preload("res://scripts/core/workshop_0656.gd")
const Inventory = preload("res://scripts/core/component_inventory_0651.gd")
var team_data: Dictionary = {}
var inventory_locked := false
var inventory_session := ""
var inventory_team := ""
var inventory_context: Dictionary = {}
var inventory_last_lap := -1
var save_path := SAVE_PATH

func _init(path: String = SAVE_PATH) -> void:
	save_path = path
	_load_data()

func get_team(team_name: String) -> Dictionary:
	if not team_data.has(team_name):
		team_data[team_name] = {
			"budget": INITIAL_BUDGET,
			"levels": {"Motor": 0, "Asa": 0, "Chassi": 0},
			"crew_levels": {"Agilidade": 0, "Precisão": 0, "Coordenação": 0},
			"staff_levels": {"Estrategista": 0, "Engenheiro": 0},
			"championship_awards": {},
			"development_project": {}, "development_history": [],
			"staff_roster": {}, "staff_payroll_keys": {}, "staff_log": [], "staff_soul": {}
		}
	var state: Dictionary = team_data[team_name]
	# Compatible with v0.5.2.7 save files that do not have this section.
	if not state.has("crew_levels") or typeof(state["crew_levels"]) != TYPE_DICTIONARY:
		state["crew_levels"] = {"Agilidade": 0, "Precisão": 0, "Coordenação": 0}
	for part in CREW_PARTS:
		state["crew_levels"][part] = clampi(int(state["crew_levels"].get(part, 0)), 0, MAX_LEVEL)
	if not state.has("staff_levels") or typeof(state["staff_levels"]) != TYPE_DICTIONARY:
		state["staff_levels"] = {}
	for role in STAFF_ROLES:
		state["staff_levels"][role] = clampi(int(state["staff_levels"].get(role, 0)), 0, MAX_LEVEL)
	if not state.has("championship_awards") or typeof(state["championship_awards"]) != TYPE_DICTIONARY:
		state["championship_awards"] = {}
	if typeof(state.get("development_project", null)) != TYPE_DICTIONARY:
		state["development_project"] = {}
	if typeof(state.get("development_history", null)) != TYPE_ARRAY:
		state["development_history"] = []
	# v0.6.4.8: contratos opt-in. Nenhuma contratação presumida em saves antigos.
	if typeof(state.get("staff_roster", null)) != TYPE_DICTIONARY:
		state["staff_roster"] = {}
	if typeof(state.get("staff_payroll_keys", null)) != TYPE_DICTIONARY:
		state["staff_payroll_keys"] = {}
	if typeof(state.get("staff_log", null)) != TYPE_ARRAY:
		state["staff_log"] = []
	SoulStaff.ensure(state)
	if Inventory.ensure(state, PARTS):
		var target := ProjectSettings.globalize_path(save_path)
		if FileAccess.file_exists(target) and not FileAccess.file_exists(target + ".pre0651"):
			if DirAccess.copy_absolute(target, target + ".pre0651") != OK:
				push_error("Living Factory: não foi possível criar backup pré-migração.")
				return state
		save()
	Workshop.ensure(state)
	return state

func next_cost(team_name: String, part: String) -> int:
	if not BASE_COST.has(part):
		return -1
	var lvl := int(get_team(team_name)["levels"].get(part, 0))
	if lvl >= MAX_LEVEL or str(get_team(team_name).get("development_project", {}).get("part", "")) == part:
		return -1
	return int(BASE_COST[part]) * (lvl + 1)

func buy(team_name: String, part: String) -> String:
	var cost := next_cost(team_name, part)
	if cost == -1:
		return "Nível máximo ou projeto de P&D já reservado para a peça."
	var state := get_team(team_name)
	if int(state["budget"]) < cost:
		return "Saldo insuficiente para essa melhoria."
	state["budget"] = int(state["budget"]) - cost
	state["levels"][part] = int(state["levels"][part]) + 1
	inventory_sync_spec(team_name, part)
	save()
	return "%s atualizado para nível %d." % [part, int(state["levels"][part])]

func estimated_lap_gain(levels: Dictionary) -> float:
	# Gameplay estimate, NOT FIA telemetry and not a promise of race position.
	var total: float = 0.0
	for part in PARTS:
		total += float(clampi(int(levels.get(part, 0)), 0, MAX_LEVEL)) * float(PERFORMANCE_GAIN[part])
	return total

func research_next_cost(team_name: String, part: String) -> int:
	var normal: int = next_cost(team_name, part)
	if normal < 0:
		return -1
	var state: Dictionary = get_team(team_name)
	return int(round(float(normal) * RESEARCH_DISCOUNT * StaffMarket.aero_research_factor(state, part)))

func sync_project_season(team_name: String, serial: int) -> void:
	var state: Dictionary = get_team(team_name)
	var active: Dictionary = state.get("development_project", {})
	if active.is_empty() or int(active.get("season_serial", serial)) == serial:
		return
	# A new championship never strands money in an old, unreachable contract.
	state["budget"] = int(state["budget"]) + int(active.get("cost", 0))
	state["development_project"] = {}
	save()

func start_research(team_name: String, part: String, serial: int,
		current_round: int, calendar_length: int) -> String:
	if serial <= 0 or calendar_length <= 0 or current_round < 0 or current_round + RESEARCH_LEAD_ROUNDS > calendar_length:
		return "Projeto exige uma temporada ativa com pelo menos dois GPs restantes."
	if not PARTS.has(part):
		return "Peça desconhecida."
	sync_project_season(team_name, serial)
	var state: Dictionary = get_team(team_name)
	if not (state.get("development_project", {}) as Dictionary).is_empty():
		return "Já existe um projeto de desenvolvimento em execução."
	var price: int = research_next_cost(team_name, part)
	if price < 0:
		return "Peça no máximo ou indisponível para pesquisa."
	if int(state["budget"]) < price:
		return "Saldo insuficiente para pesquisa."
	state["budget"] = int(state["budget"]) - price
	state["development_project"] = {"part": part, "cost": price,
		"season_serial": serial, "started_round": current_round,
		"ready_round": current_round + RESEARCH_LEAD_ROUNDS}
	save()
	return "P&D de %s iniciado: R$ %.2f mi, disponível após a etapa %d." % [part, float(price)/1000000.0, current_round + RESEARCH_LEAD_ROUNDS]

func cancel_research(team_name: String) -> String:
	var state: Dictionary = get_team(team_name)
	var project: Dictionary = state.get("development_project", {})
	if project.is_empty():
		return "Nenhum projeto de pesquisa ativo."
	var refund: int = int(round(float(project.get("cost", 0)) * 0.75))
	state["budget"] = int(state["budget"]) + refund
	state["development_project"] = {}
	var history: Array = state.get("development_history", [])
	history.append({"part": project.get("part", ""), "status": "cancelado", "refund": refund})
	state["development_history"] = history
	save()
	return "Projeto cancelado. Reembolso de R$ %.2f mi (75%%)." % (float(refund)/1000000.0)

func deliver_research(team_name: String, serial: int, completed_round: int) -> bool:
	var state: Dictionary = get_team(team_name)
	var project: Dictionary = state.get("development_project", {})
	if project.is_empty() or int(project.get("season_serial", -1)) != serial or int(project.get("ready_round", 999)) > completed_round:
		return false
	var part: String = str(project.get("part", ""))
	if PARTS.has(part) and int(state["levels"].get(part, 0)) < MAX_LEVEL:
		state["levels"][part] = int(state["levels"][part]) + 1
		inventory_sync_spec(team_name, part)
		var history: Array = state.get("development_history", [])
		history.append({"part": part, "status": "entregue", "round": completed_round, "new_level": int(state["levels"][part])})
		state["development_history"] = history
	else:
		state["budget"] = int(state["budget"]) + int(project.get("cost", 0))
	state["development_project"] = {}
	save()
	return true

func recommend_upgrade(team_name: String) -> String:
	var best: String = ""
	var ratio: float = -1.0
	for part in PARTS:
		var price: int = next_cost(team_name, part)
		if price <= 0:
			continue
		var value: float = float(PERFORMANCE_GAIN[part]) / float(price)
		if value > ratio:
			best = part
			ratio = value
	return best

func crew_next_cost(team_name: String, part: String) -> int:
	if not CREW_BASE_COST.has(part):
		return -1
	var level: int = int(get_team(team_name)["crew_levels"].get(part, 0))
	if level >= MAX_LEVEL:
		return -1
	return int(CREW_BASE_COST[part]) * (level + 1)

func buy_crew(team_name: String, part: String) -> String:
	if not CREW_BASE_COST.has(part):
		return "Treinamento desconhecido."
	var cost: int = crew_next_cost(team_name, part)
	if cost < 0:
		return "Equipe de boxes já está no nível máximo."
	var state: Dictionary = get_team(team_name)
	if int(state["budget"]) < cost:
		return "Orçamento insuficiente para treinar os mecânicos."
	state["budget"] = int(state["budget"]) - cost
	state["crew_levels"][part] = int(state["crew_levels"][part]) + 1
	save()
	return "%s: equipe de boxes no nível %d." % [part, state["crew_levels"][part]]

func staff_next_cost(team_name: String, role: String) -> int:
	if not STAFF_BASE_COST.has(role):
		return -1
	var level: int = int(get_team(team_name)["staff_levels"].get(role, 0))
	if level >= MAX_LEVEL:
		return -1
	return int(STAFF_BASE_COST[role]) * (level + 1)

func hire_staff(team_name: String, role: String) -> String:
	var cost: int = staff_next_cost(team_name, role)
	if cost < 0:
		return "Cargo desconhecido ou equipe técnica no nível máximo."
	var state: Dictionary = get_team(team_name)
	if int(state["budget"]) < cost:
		return "Orçamento insuficiente para contratar esse especialista."
	state["budget"] = int(state["budget"]) - cost
	state["staff_levels"][role] = int(state["staff_levels"].get(role, 0)) + 1
	save()
	return "%s contratado/desenvolvido: nível %d/3." % [role, int(state["staff_levels"][role])]

## ---------- Team & Staff Manager 0.6.4.8 ----------
## Um titular por departamento. Candidatos não são pessoas reais.
func staff_candidates(role: String) -> Array:
	return StaffMarket.MARKET.get(role, []).duplicate(true)

func staff_hire_candidate(team_name: String, role: String, candidate_id: String,
		season_serial: int = 0, round_index: int = -1) -> String:
	var candidate: Dictionary = StaffMarket.candidate(role, candidate_id)
	if candidate.is_empty():
		return "Candidato ou departamento desconhecido."
	return _persist_staff_transaction(StaffContracts.hire(
		get_team(team_name), role, candidate, season_serial, round_index))

func staff_release(team_name: String, role: String) -> String:
	return _persist_staff_transaction(StaffContracts.release(get_team(team_name), role))

func _persist_staff_transaction(result: Dictionary) -> String:
	if bool(result["changed"]):
		save()
	return str(result["message"])

func effective_staff_levels(team_name: String) -> Dictionary:
	return StaffMarket.effective_levels(get_team(team_name))

func effective_crew_levels(team_name: String) -> Dictionary:
	return StaffMarket.effective_crew(get_team(team_name))

func staff_payroll_total(team_name: String) -> int:
	var total: int = 0
	for person in get_team(team_name)["staff_roster"].values():
		total += int((person as Dictionary).get("salary", 0))
	return total

func staff_settle_round(team_name: String, season_serial: int, round_number: int) -> Dictionary:
	if season_serial <= 0 or round_number <= 0:
		return {"paid": 0, "roles": 0}
	var result: Dictionary = StaffContracts.settle_round(get_team(team_name), season_serial, round_number)
	if int(result["roles"]) > 0:
		save()
	return result


## ---------- v0.6.5.0: gestão humana da equipe (sem alterações de corrida) ----------
func staff_soul_summary(team_name: String) -> Dictionary:
	return SoulStaff.summary(get_team(team_name))

func staff_soul_relations(team_name: String) -> Array[String]:
	return SoulStaff.relations_report(get_team(team_name))

func staff_soul_action(team_name: String, action_id: String, season_serial: int,
		next_round: int, total_rounds: int) -> String:
	var state: Dictionary = get_team(team_name)
	var problem: String = SoulStaff.action_allowed(state, action_id, season_serial, next_round, total_rounds)
	if not problem.is_empty():
		return problem
	var message: String = SoulStaff.apply_action(state, action_id, season_serial, next_round, total_rounds)
	_add_staff_log(state, message)
	save()
	return message

func staff_soul_settle_round(team_name: String, season_serial: int,
		round_number: int, best_position: int) -> Dictionary:
	var state: Dictionary = get_team(team_name)
	var result: Dictionary = SoulStaff.settle_round(state, season_serial, round_number, best_position)
	if bool(result.get("updated", false)):
		if int(result.get("members", 0)) > 0:
			_add_staff_log(state, "Soul Staff GP %d: P%d melhor resultado; %d titular(es) atualizados." % [
				round_number, best_position, int(result["members"])])
		save()
	elif str(result.get("reason", "")) == "etapa anterior à versão":
		save()
	return result

func _add_staff_log(state: Dictionary, message: String) -> void:
	StaffContracts.add_log(state, message)

func credit_championship_prize(team_name: String, award_id: String, amount: int) -> bool:
	if amount <= 0 or award_id.is_empty():
		return false
	var team: Dictionary = get_team(team_name)
	if team["championship_awards"].has(award_id):
		return false
	team["championship_awards"][award_id] = amount
	team["budget"] = int(team["budget"]) + amount
	save()
	return true

func save() -> bool:
	var target := ProjectSettings.globalize_path(save_path)
	var file := FileAccess.open(target + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(team_data, "  "))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return false
	if FileAccess.file_exists(target):
		if DirAccess.copy_absolute(target, target + ".bak") != OK: return false
	return DirAccess.rename_absolute(target + ".tmp", target) == OK

func component_action(team: String, id: String, action: String, car: int, context: Dictionary = {}) -> String:
	if inventory_locked: return "Oficina bloqueada durante a sessão, inclusive em pausa."
	var state := get_team(team)
	if Workshop.locked(state,id): return "Peça reservada na oficina. Cancele ou conclua o serviço."
	if action == "install":
		var category := str(state.component_inventory.parts.get(id,{}).get("category",""))
		if Workshop.slot_locked(state,car,category) or Workshop.locked(state,Inventory.installed(state.component_inventory,car,category)):
			return "Slot reservado na oficina."
	var original: Dictionary = state.component_inventory
	var candidate := original.duplicate(true)
	var error := Inventory.operate(candidate, PARTS, id, action, car, context)
	if not error.is_empty(): return error
	state.component_inventory = candidate
	if not save():
		state.component_inventory = original
		return "Falha ao salvar. Operação revertida."
	return "Inventário atualizado e salvo."

func inventory_begin(team: String, context: Dictionary) -> void:
	inventory_team = team
	inventory_context = context.duplicate(true)
	inventory_session = Crypto.new().generate_random_bytes(16).hex_encode()
	inventory_last_lap = -1
	inventory_locked = true

func inventory_observe(race, flush: bool = false) -> void:
	# Defense in depth for menu, exit-tree and management callbacks during replay.
	if race != null and race.get("command_session") != null:
		var session = race.command_session.get_ref()
		if session != null and session.playback: return
	if inventory_session.is_empty() or race == null: return
	var state := get_team(inventory_team)
	if not Inventory.validate(state.component_inventory, PARTS).is_empty(): return
	Inventory.observe(state.component_inventory, inventory_session, race, inventory_context)
	if flush or int(race.lap) != inventory_last_lap or race.finished:
		if save(): inventory_last_lap = int(race.lap)
	if race.finished: inventory_locked = false

func inventory_sync_spec(team: String, category: String) -> void:
	var state := get_team(team)
	for part in state.component_inventory.parts.values():
		if part.category != category: continue
		part.specification = int(state.levels[category])
		Inventory._event(part, "specification", "Especificação compartilhada atualizada pelo P&D existente", {})

func _find_previous_godot_save() -> String:
	return SaveMigration.previous_file("apex_garage_050.json")

func _load_data() -> void:
	var content := ""
	if FileAccess.file_exists(save_path):
		content = FileAccess.get_file_as_string(save_path)
	else:
		# Godot originally used a new user:// directory for each version because
		# project.godot changed its visible name. Import the newest old save once.
		var previous_godot: String = _find_previous_godot_save() if save_path == SAVE_PATH else ""
		if not previous_godot.is_empty():
			content = FileAccess.get_file_as_string(previous_godot)
		else:
			# Read-only import of the earlier Tkinter v0.4.5 garage data.
			var home := OS.get_environment("HOME")
			var data_home := OS.get_environment("XDG_DATA_HOME")
			if data_home.is_empty():
				data_home = home.path_join(".local/share")
			var legacy := data_home.path_join("apex-motorsport-manager/garage.json")
			if save_path == SAVE_PATH and FileAccess.file_exists(legacy):
				content = FileAccess.get_file_as_string(legacy)
	if content.is_empty():
		return
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for team_name in parsed.keys():
		var state = parsed[team_name]
		if typeof(state) != TYPE_DICTIONARY:
			continue
		var levels = state.get("levels", {})
		if typeof(levels) != TYPE_DICTIONARY:
			continue
		var cleaned := {"Motor": 0, "Asa": 0, "Chassi": 0}
		for part in PARTS:
			cleaned[part] = clampi(int(levels.get(part, 0)), 0, MAX_LEVEL)
		var raw_crew: Dictionary = state.get("crew_levels", {}) if typeof(state.get("crew_levels", {})) == TYPE_DICTIONARY else {}
		var cleaned_crew := {"Agilidade": 0, "Precisão": 0, "Coordenação": 0}
		for part in CREW_PARTS:
			cleaned_crew[part] = clampi(int(raw_crew.get(part, 0)), 0, MAX_LEVEL)
		var raw_staff: Dictionary = state.get("staff_levels", {}) if typeof(state.get("staff_levels", {})) == TYPE_DICTIONARY else {}
		var cleaned_staff := {"Estrategista": 0, "Engenheiro": 0}
		for role in STAFF_ROLES:
			cleaned_staff[role] = clampi(int(raw_staff.get(role, 0)), 0, MAX_LEVEL)
		var raw_awards: Dictionary = state.get("championship_awards", {}) if typeof(state.get("championship_awards", {})) == TYPE_DICTIONARY else {}
		team_data[str(team_name)] = {
			"budget": int(state.get("budget", INITIAL_BUDGET)),
			"levels": cleaned,
			"crew_levels": cleaned_crew,
			"staff_levels": cleaned_staff,
			"championship_awards": raw_awards.duplicate(true),
			"development_project": state.get("development_project", {}).duplicate(true) if typeof(state.get("development_project", {})) == TYPE_DICTIONARY else {},
			"development_history": state.get("development_history", []).duplicate(true) if typeof(state.get("development_history", [])) == TYPE_ARRAY else [],
			"staff_roster": state.get("staff_roster", {}).duplicate(true) if typeof(state.get("staff_roster", {})) == TYPE_DICTIONARY else {},
			"staff_payroll_keys": state.get("staff_payroll_keys", {}).duplicate(true) if typeof(state.get("staff_payroll_keys", {})) == TYPE_DICTIONARY else {},
			"staff_log": state.get("staff_log", []).duplicate(true) if typeof(state.get("staff_log", [])) == TYPE_ARRAY else [],
			"staff_soul": state.get("staff_soul", {}).duplicate(true) if typeof(state.get("staff_soul", {})) == TYPE_DICTIONARY else {}
		}
		var cleaned_state: Dictionary = team_data[str(team_name)]
		team_data[str(team_name)] = state.duplicate(true)
		team_data[str(team_name)].merge(cleaned_state, true)
		if state.has("component_inventory"):
			team_data[str(team_name)]["component_inventory"] = state["component_inventory"].duplicate(true)
	if not FileAccess.file_exists(save_path):
		save()

func workshop_action(team: String, action: String, args: Dictionary = {}) -> String:
	if inventory_locked: return "Oficina bloqueada durante a sessão."
	var state := get_team(team)
	var before := state.duplicate(true)
	var error := ""
	match action:
		"create": error = Workshop.create(state,args)
		"start": Workshop.schedule(state)
		"advance": error = Workshop.advance(state,float(args.get("hours",1)))
		"cancel": error = Workshop.cancel(state,str(args.get("id","")))
		"auto": error = Workshop.automatic(state)
		"manual": state.workshop.mode = "Manual"
		"deadline": state.workshop.deadline = float(state.workshop.hour)+clampf(float(args.get("hours",72)),1,720)
		"priority":
			for t in state.workshop.tasks:
				if t.id == args.get("id","") and Workshop.active(t): t.priority = clampi(int(args.get("priority",2)),1,3)
		"assign":
			for t in state.workshop.tasks:
				if t.id == args.get("id","") and t.status == "pendente" and Workshop.staff(state).has(args.get("staff","")):
					var fraction := float(t.remaining)/float(t.estimated)
					var person: Dictionary = Workshop.staff(state)[args.staff]
					t.estimated = float(Workshop.SERVICES[t.service][0])*(1.15-float(person.speed)*0.003)
					t.remaining = float(t.estimated)*fraction
					t.quality = person.precision
					t.staff = args.staff
					t.staff_name = Workshop.staff(state)[args.staff].name
		_: error = "Operação desconhecida."
	if not error.is_empty() or not save():
		team_data[team] = before
		return error if not error.is_empty() else "Falha ao salvar: operação revertida."
	return "Oficina atualizada e salva."
