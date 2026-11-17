extends RefCounted
## APEX 0.6.5.0 — Soul Staff 1.0.
## Persisted human-management layer. Never writes to the race engine, tyre physics,
## pit requests, driver AI or existing skill-based performance multipliers.
const StaffMarket = preload("res://scripts/core/staff_market_0648.gd")
const Catalog = preload("res://scripts/core/staff_soul_catalog.gd")
const RoundRules = preload("res://scripts/core/staff_round_rules.gd")
# Compatibility aliases for the existing UI and external callers.
const ACTIONS = Catalog.ACTIONS
const PROFILES = Catalog.PROFILES

static func action_cost_label(cost: int) -> String:
    return "R$ %d mil" % int(round(float(cost) / 1000.0))

static func profile(person: Dictionary) -> Dictionary:
    return Catalog.profile(person)

static func staff_voice(person: Dictionary, cohesion: int = 50) -> String:
    return Catalog.staff_voice(person, cohesion)

static func ensure(state: Dictionary) -> void:
    var soul: Dictionary = state.get("staff_soul", {}) if typeof(state.get("staff_soul", {})) == TYPE_DICTIONARY else {}
    for key in ["relations", "round_keys", "action_keys"]:
        if typeof(soul.get(key, null)) != TYPE_DICTIONARY:
            soul[key] = {}
    state["staff_soul"] = soul
    var roster: Dictionary = state.get("staff_roster", {})
    for role in StaffMarket.ROLES:
        if not roster.has(role):
            continue
        var person: Dictionary = roster[role]
        var traits: Dictionary = profile(person)
        for key in traits:
            if not person.has(key) or str(person[key]).is_empty():
                person[key] = traits[key]
        # Legacy contracts upgraded without replacement or additional fee.
        person["morale"] = clampi(int(person.get("morale", 70)), 0, 100)
        person["energy"] = clampi(int(person.get("energy", 78)), 0, 100)
        person["trust"] = clampi(int(person.get("trust", 65)), 0, 100)
    var desired: Dictionary = {}
    for i in range(StaffMarket.ROLES.size()):
        for j in range(i + 1, StaffMarket.ROLES.size()):
            var left: String = StaffMarket.ROLES[i]
            var right: String = StaffMarket.ROLES[j]
            if not roster.has(left) or not roster.has(right):
                continue
            var key: String = pair_key(left, right)
            var a: Dictionary = roster[left]
            var b: Dictionary = roster[right]
            var initial: int = 54 if str(a.get("style", "")) == str(b.get("style", "")) else 48
            desired[key] = clampi(int(soul["relations"].get(key, initial)), 0, 100)
    soul["relations"] = desired

static func pair_key(a: String, b: String) -> String:
    return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]

static func reset_role_relations(state: Dictionary, role: String) -> void:
    ensure(state)
    var relations: Dictionary = state["staff_soul"]["relations"]
    for key in relations.keys():
        if str(key).split("|").has(role):
            relations.erase(key)
    ensure(state)

static func summary(state: Dictionary) -> Dictionary:
    ensure(state)
    var roster: Dictionary = state.get("staff_roster", {})
    var count: int = 0
    var morale: int = 0
    var energy: int = 0
    var trust: int = 0
    for person in roster.values():
        count += 1
        morale += int(person.get("morale", 70))
        energy += int(person.get("energy", 78))
        trust += int(person.get("trust", 65))
    if count == 0:
        return {"count":0, "morale":0, "energy":0, "trust":0, "cohesion":0, "relations":0}
    var bonds: Dictionary = state["staff_soul"]["relations"]
    var total: int = 0
    for value in bonds.values():
        total += int(value)
    var cohesion: int = int(round(float(total) / float(bonds.size()))) if not bonds.is_empty() else 0
    return {"count":count, "morale":int(round(float(morale) / count)),
        "energy":int(round(float(energy) / count)), "trust":int(round(float(trust) / count)),
        "cohesion":cohesion, "relations":bonds.size()}

static func relations_report(state: Dictionary) -> Array[String]:
    ensure(state)
    var relations: Dictionary = state["staff_soul"]["relations"]
    var roster: Dictionary = state.get("staff_roster", {})
    var rows: Array[String] = []
    for a in StaffMarket.ROLES:
        for b in StaffMarket.ROLES:
            if str(a) >= str(b):
                continue
            if not roster.has(a) or not roster.has(b):
                continue
            var value: int = int(relations.get(pair_key(a, b), 50))
            var status: String = "ALINHADOS" if value >= 70 else ("ATENÇÃO" if value < 40 else "EM DESENVOLVIMENTO")
            rows.append("%s × %s  •  %d/100  •  %s" % [str(a), str(b), value, status])
    return rows

static func action_allowed(state: Dictionary, action_id: String,
        season_serial: int, next_round: int, total_rounds: int) -> String:
    if not ACTIONS.has(action_id):
        return "Ação desconhecida."
    if season_serial <= 0 or next_round <= 0 or next_round > total_rounds:
        return "Ações de equipe exigem uma etapa futura em temporada ativa."
    ensure(state)
    if (state.get("staff_roster", {}) as Dictionary).is_empty():
        return "Contrate pelo menos um titular para gerir a equipe."
    var key: String = RoundRules.round_key(season_serial, next_round)
    if state["staff_soul"]["action_keys"].has(key):
        return "A reunião desta etapa já foi realizada (1 ação por GP)."
    var cost: int = int(ACTIONS[action_id]["cost"])
    if int(state.get("budget", 0)) < cost:
        return "Saldo insuficiente para a ação (%s)." % action_cost_label(cost)
    return ""

static func apply_action(state: Dictionary, action_id: String,
        season_serial: int, next_round: int, total_rounds: int) -> String:
    var forbidden: String = action_allowed(state, action_id, season_serial, next_round, total_rounds)
    if not forbidden.is_empty():
        return forbidden
    var action: Dictionary = ACTIONS[action_id]
    state["budget"] = int(state["budget"]) - int(action["cost"])
    for person in (state["staff_roster"] as Dictionary).values():
        for field in ["morale", "energy", "trust"]:
            person[field] = clampi(int(person.get(field, 60)) + int(action[field]), 0, 100)
    for pair in state["staff_soul"]["relations"]:
        state["staff_soul"]["relations"][pair] = clampi(
            int(state["staff_soul"]["relations"][pair]) + int(action["bond"]), 0, 100)
    var key: String = RoundRules.round_key(season_serial, next_round)
    state["staff_soul"]["action_keys"][key] = action_id
    return "%s realizada antes do GP %d • custo %s. %s" % [str(action["label"]),
        next_round, action_cost_label(int(action["cost"])), str(action["reason"])]

static func settle_round(state: Dictionary, season_serial: int,
        round_number: int, best_position: int) -> Dictionary:
    if season_serial <= 0 or round_number <= 0:
        return {"updated":false, "members":0, "reason":"etapa inválida"}
    ensure(state)
    var key: String = RoundRules.round_key(season_serial, round_number)
    if state["staff_soul"]["round_keys"].has(key):
        return {"updated":false, "members":0, "reason":"etapa já processada"}
    # Never replay history after upgrading a v0.6.4.9.9 season.
    for role in StaffMarket.ROLES:
        if state.get("staff_payroll_keys", {}).has("%s_%s" % [key, role]):
            state["staff_soul"]["round_keys"][key] = "migrated"
            return {"updated":false, "members":0, "reason":"etapa anterior à versão"}
    var members: int = 0
    var result_delta: int = 4 if best_position <= 3 else (1 if best_position <= 10 else -3)
    var active_roles: Array[String] = []
    for role in StaffMarket.ROLES:
        if not state.get("staff_roster", {}).has(role):
            continue
        var person: Dictionary = state["staff_roster"][role]
        if not RoundRules.participated(person, season_serial, round_number):
            continue
        var temperament_key: String = str(person.get("trait", "equilibrado"))
        var bonus: int = (2 if temperament_key == "competitivo" and best_position <= 3 else 0)
        var penalty: int = (-2 if temperament_key == "intenso" and best_position > 10 else 0)
        person["morale"] = clampi(int(person["morale"]) + result_delta + bonus + penalty, 0, 100)
        person["energy"] = clampi(int(person["energy"]) - (8 if temperament_key == "intenso" else 5), 0, 100)
        person["trust"] = clampi(int(person["trust"]) + (2 if best_position <= 10 else -1), 0, 100)
        members += 1
        active_roles.append(role)
    for i in range(active_roles.size()):
        for j in range(i + 1, active_roles.size()):
            var a: String = active_roles[i]
            var b: String = active_roles[j]
            var pair: String = pair_key(a, b)
            var advance: int = 2 if best_position <= 10 else -1
            var people: Dictionary = state["staff_roster"]
            if str(people[a].get("style", "")) != str(people[b].get("style", "")):
                advance -= 1
            state["staff_soul"]["relations"][pair] = clampi(
                int(state["staff_soul"]["relations"].get(pair, 50)) + advance, 0, 100)
    state["staff_soul"]["round_keys"][key] = "computed"
    return {"updated":true, "members":members, "reason":"pós-GP aplicado"}
