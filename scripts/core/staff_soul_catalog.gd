extends RefCounted
## Static Soul Staff content. No team state or persistence dependencies.
const ACTIONS := {
    "briefing": {"label":"BRIEFING TÉCNICO", "cost":85000, "morale":3, "energy":-3, "trust":7, "bond":3,
        "reason":"O alinhamento aumenta a confiança, mas exige energia."},
    "recovery": {"label":"DESCANSO & SUPORTE", "cost":55000, "morale":6, "energy":15, "trust":2, "bond":0,
        "reason":"A equipe recupera energia e moral antes do próximo GP."},
    "integration": {"label":"INTEGRAÇÃO DE ÁREAS", "cost":120000, "morale":4, "energy":-2, "trust":3, "bond":9,
        "reason":"As relações entre departamentos ficam mais fortes."}
}
# Pessoas ficcionais do universo Apex. A personalidade é um atributo de gameplay,
# não uma afirmação sobre profissionais reais ou sobre o campeonato histórico.
const PROFILES := {
    "est_a":{"personality":"Metódica", "style":"Planejamento", "trait":"prudente"},
    "est_b":{"personality":"Analítico", "style":"Dados", "trait":"equilibrado"},
    "est_c":{"personality":"Visionária", "style":"Exploração", "trait":"intenso"},
    "eng_a":{"personality":"Conciliador", "style":"Diálogo", "trait":"equilibrado"},
    "eng_b":{"personality":"Investigativa", "style":"Dados", "trait":"prudente"},
    "eng_c":{"personality":"Competitivo", "style":"Execução", "trait":"competitivo"},
    "mec_a":{"personality":"Disciplinado", "style":"Planejamento", "trait":"prudente"},
    "mec_b":{"personality":"Colaborativa", "style":"Diálogo", "trait":"equilibrado"},
    "mec_c":{"personality":"Exigente", "style":"Execução", "trait":"intenso"},
    "aero_a":{"personality":"Paciente", "style":"Planejamento", "trait":"prudente"},
    "aero_b":{"personality":"Curiosa", "style":"Exploração", "trait":"equilibrado"},
    "aero_c":{"personality":"Ambicioso", "style":"Dados", "trait":"competitivo"}
}

static func profile(person: Dictionary) -> Dictionary:
    var entry: Dictionary = PROFILES.get(str(person.get("id", "")), {})
    if entry.is_empty():
        return {"personality":"Profissional", "style":"Equilibrado", "trait":"equilibrado"}
    return entry.duplicate(true)

# Texto contextual de gestão, não rádio da corrida nem uma ordem à IA.
static func staff_voice(person: Dictionary, cohesion: int = 50) -> String:
    if int(person.get("energy", 78)) < 40:
        return "Estou cansado(a). Precisamos reorganizar o trabalho antes do próximo GP."
    if int(person.get("morale", 70)) < 42:
        return "Os resultados pesaram no ambiente. Quero recuperar a confiança da equipe."
    if int(person.get("trust", 65)) < 42:
        return "As prioridades mudam sem explicação. Gostaria de decisões mais claras."
    if cohesion < 43:
        return "Há ruído entre departamentos. Uma conversa conjunta ajudaria."
    match str(person.get("id", "")):
        "est_a": return "Quero um plano simples e margens de segurança para a equipe."
        "est_b": return "Prefiro comparar dados e compartilhar as hipóteses com todos."
        "est_c": return "Podemos experimentar soluções, mas quero apoio para avaliar riscos."
        "eng_a": return "Quando o diálogo funciona, consigo organizar melhor o trabalho."
        "eng_b": return "Me dê tempo para validar as leituras com os outros departamentos."
        "eng_c": return "Estou motivado para melhorar nossos processos a cada etapa."
        "mec_a": return "Uma rotina clara e bem ensaiada mantém a oficina organizada."
        "mec_b": return "Quero a mecânica e a estratégia conversando mais de perto."
        "mec_c": return "Precisão começa com preparo e responsabilidades bem definidas."
        "aero_a": return "Prefiro desenvolver com calma e documentar o que aprendemos."
        "aero_b": return "Trocar ideias com os engenheiros pode revelar bons caminhos."
        "aero_c": return "Quero metas exigentes, desde que tenhamos recursos para alcançá-las."
    return "Quero entender melhor o plano e contribuir para a equipe."

