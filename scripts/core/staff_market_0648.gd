extends RefCounted
## Mercado fictício e determinístico. Os nomes/atributos são do universo Apex,
## nunca pontuações históricas de profissionais reais.
const ROLES := ["Estrategista", "Engenheiro", "Chefe de Mecânica", "Chefe de Aerodinâmica"]
const CONTRACT_GPS := 8
const MARKET := {
    "Estrategista": [
        {"id":"est_a","name":"Lívia Monteiro","skill":61,"salary":55000,"signing":200000,"specialty":"Gestão de risco"},
        {"id":"est_b","name":"Miguel Torres","skill":76,"salary":95000,"signing":420000,"specialty":"Janelas e tráfego"},
        {"id":"est_c","name":"Elisa Nogueira","skill":90,"salary":165000,"signing":760000,"specialty":"Estratégia em clima variável"}
    ],
    "Engenheiro": [
        {"id":"eng_a","name":"Rafael Couto","skill":62,"salary":52000,"signing":180000,"specialty":"Rádio e telemetria"},
        {"id":"eng_b","name":"Clara Ferreira","skill":78,"salary":105000,"signing":440000,"specialty":"Pneus e KERS"},
        {"id":"eng_c","name":"Davi Amaral","skill":91,"salary":170000,"signing":790000,"specialty":"Ritmo e feedback"}
    ],
    "Chefe de Mecânica": [
        {"id":"mec_a","name":"César Vieira","skill":58,"salary":48000,"signing":170000,"specialty":"Rotina de garagem"},
        {"id":"mec_b","name":"Júlia Barbosa","skill":75,"salary":88000,"signing":390000,"specialty":"Coordenação de parada"},
        {"id":"mec_c","name":"Nina Carvalho","skill":88,"salary":152000,"signing":710000,"specialty":"Precisão e segurança"}
    ],
    "Chefe de Aerodinâmica": [
        {"id":"aero_a","name":"Caio Ribeiro","skill":60,"salary":51000,"signing":190000,"specialty":"Eficiência de projeto"},
        {"id":"aero_b","name":"Bianca Leal","skill":77,"salary":99000,"signing":435000,"specialty":"Redução de retrabalho"},
        {"id":"aero_c","name":"André Valença","skill":90,"salary":162000,"signing":780000,"specialty":"Otimização de asa"}
    ]
}

static func level(skill: int) -> int:
    if skill >= 85:
        return 3
    if skill >= 70:
        return 2
    if skill >= 55:
        return 1
    return 0

static func candidate(role: String, candidate_id: String) -> Dictionary:
    for entry in MARKET.get(role, []):
        if str(entry.get("id", "")) == candidate_id:
            return (entry as Dictionary).duplicate(true)
    return {}

static func money(value: int) -> String:
    return "R$ %.2f mi" % (float(value) / 1000000.0)

static func effective_levels(team: Dictionary) -> Dictionary:
    var levels: Dictionary = team.get("staff_levels", {}).duplicate(true)
    var roster: Dictionary = team.get("staff_roster", {})
    for role in ["Estrategista", "Engenheiro"]:
        var contract: Dictionary = roster.get(role, {})
        if not contract.is_empty():
            levels[role] = maxi(int(levels.get(role, 0)), level(int(contract.get("skill", 0))))
    return levels

static func effective_crew(team: Dictionary) -> Dictionary:
    var levels: Dictionary = team.get("crew_levels", {}).duplicate(true)
    var leader: Dictionary = team.get("staff_roster", {}).get("Chefe de Mecânica", {})
    var bonus: int = maxi(0, level(int(leader.get("skill", 0))) - 1)
    for skill_name in ["Agilidade", "Precisão", "Coordenação"]:
        levels[skill_name] = clampi(int(levels.get(skill_name, 0)) + bonus, 0, 3)
    return levels

static func aero_research_factor(team: Dictionary, part: String) -> float:
    if part != "Asa":
        return 1.0
    var chief: Dictionary = team.get("staff_roster", {}).get("Chefe de Aerodinâmica", {})
    var lvl: int = level(int(chief.get("skill", 0)))
    return 1.0 - 0.04 * float(maxi(0, lvl - 1))
