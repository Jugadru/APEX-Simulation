extends RefCounted
## Contract transactions operate on normalized team state supplied by Garage.
## This module never reads or writes saves. Garage owns persistence.
const StaffMarket = preload("res://scripts/core/staff_market_0648.gd")
const SoulStaff = preload("res://scripts/core/staff_soul_0650.gd")
const RoundRules = preload("res://scripts/core/staff_round_rules.gd")

static func hire(state: Dictionary, role: String, candidate: Dictionary,
        season_serial: int, round_index: int) -> Dictionary:
	var roster: Dictionary = state["staff_roster"]
	if roster.has(role):
		return {"changed": false, "message": "Este departamento já tem um titular. Rescinda o contrato antes de contratar."}
	var price: int = int(candidate["signing"])
	if int(state["budget"]) < price:
		return {"changed": false, "message": "Orçamento insuficiente para o bônus de contratação."}
	state["budget"] = int(state["budget"]) - price
	var contract: Dictionary = candidate.duplicate(true)
	contract["role"] = role
	contract["remaining_gps"] = StaffMarket.CONTRACT_GPS
	contract["hired_serial"] = season_serial
	contract["hired_round"] = round_index
	roster[role] = contract
	SoulStaff.reset_role_relations(state, role)
	add_log(state, "Contratado(a) %s (%s), %d GP(s), bônus %s." % [
		str(contract["name"]), role, StaffMarket.CONTRACT_GPS, StaffMarket.money(price)])
	var message: String = "%s contratado(a) como %s. Salário %s/GP; contrato %d GPs." % [
		str(contract["name"]), role, StaffMarket.money(int(contract["salary"])), StaffMarket.CONTRACT_GPS]
	return {"changed": true, "message": message}

static func release(state: Dictionary, role: String) -> Dictionary:
	var roster: Dictionary = state["staff_roster"]
	if not roster.has(role):
		return {"changed": false, "message": "Departamento sem titular contratado."}
	var previous: Dictionary = roster[role]
	var penalty: int = int(previous.get("salary", 0)) * 2
	if int(state["budget"]) < penalty:
		return {"changed": false, "message": "Saldo insuficiente para a multa rescisória (%s)." % StaffMarket.money(penalty)}
	state["budget"] = int(state["budget"]) - penalty
	roster.erase(role)
	SoulStaff.reset_role_relations(state, role)
	add_log(state, "Rescisão %s: multa %s." % [str(previous.get("name", "Staff")), StaffMarket.money(penalty)])
	var message: String = "Contrato de %s rescindido. Multa: %s." % [str(previous.get("name", "Staff")), StaffMarket.money(penalty)]
	return {"changed": true, "message": message}

static func settle_round(state: Dictionary, season_serial: int, round_number: int) -> Dictionary:
	# 1-based round_number; idempotência por campeonato/etapa/departamento.
	if season_serial <= 0 or round_number <= 0:
		return {"paid": 0, "roles": 0}
	var roster: Dictionary = state["staff_roster"]
	var keys: Dictionary = state["staff_payroll_keys"]
	var paid: int = 0
	var count: int = 0
	for role in StaffMarket.ROLES:
		if not roster.has(role):
			continue
		var person: Dictionary = roster[role]
		# Não cobrar corridas anteriores ao início do contrato.
		if not RoundRules.participated(person, season_serial, round_number):
			continue
		var key: String = "%s_%s" % [RoundRules.round_key(season_serial, round_number), role]
		if keys.has(key):
			continue
		var salary: int = maxi(0, int(person.get("salary", 0)))
		state["budget"] = int(state["budget"]) - salary
		keys[key] = salary
		paid += salary
		count += 1
		person["remaining_gps"] = maxi(0, int(person.get("remaining_gps", 0)) - 1)
		if int(person["remaining_gps"]) == 0:
			add_log(state, "Contrato de %s concluído no GP %d." % [str(person.get("name", "Staff")), round_number])
			roster.erase(role)
			SoulStaff.reset_role_relations(state, role)
	if count > 0:
		add_log(state, "Folha GP %d: %d departamento(s), total %s." % [round_number, count, StaffMarket.money(paid)])
	return {"paid": paid, "roles": count}


static func add_log(state: Dictionary, message: String) -> void:
	var lines: Array = state.get("staff_log", [])
	lines.append(message)
	while lines.size() > 40:
		lines.pop_front()
	state["staff_log"] = lines

