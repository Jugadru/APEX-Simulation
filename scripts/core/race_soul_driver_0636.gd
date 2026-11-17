extends RefCounted
## APEX 0.6.3.6 — alma ficcional e dinâmica do piloto, somente na comunicação.
## Estes parâmetros são inventados para jogabilidade: NÃO descrevem pessoas reais.
## Este módulo não possui referência ao RaceEngine e nunca envia comandos de pista.

static func initial_profile(car_id: int) -> Dictionary:
    # Perfil reprodutível por ID durante um GP, sem consumo do RNG da corrida.
    return {
        "trust": 0.48 + float(posmod(car_id * 11 + 3, 9)) * 0.026,
        "confidence": 0.43 + float(posmod(car_id * 7 + 5, 11)) * 0.026,
        "risk": 0.32 + float(posmod(car_id * 13 + 1, 13)) * 0.030,
        "sensitivity": float(posmod(car_id * 17 + 2, 11) - 5) * 0.8,
        "last_choice": "",
        "conversation_id": 0,
        "answered_id": 0,
        "revision": 0,
        "history": []
    }

static func _find_car(car_id: int, snapshot: Dictionary) -> Dictionary:
    for item in snapshot.get("cars", []):
        if int(item.get("id", -1)) == car_id:
            return item
    return {}

static func perceive(car_id: int, snapshot: Dictionary, profile: Dictionary) -> Dictionary:
    var car: Dictionary = _find_car(car_id, snapshot)
    if car.is_empty():
        return {}
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var heat: float = clampf(float(car.get("tyre_heat", 0.0)), 0.0, 1.0)
    var trust: float = clampf(float(profile.get("trust", 0.5)), 0.0, 1.0)
    var confidence: float = clampf(float(profile.get("confidence", 0.5)), 0.0, 1.0)
    var risk: float = clampf(float(profile.get("risk", 0.5)), 0.0, 1.0)
    # Sensação subjetiva, não desgaste real. Calor extremo continua perceptível.
    var bias: float = float(profile.get("sensitivity", 0.0)) * 2.1 - (confidence - 0.5) * 23.0 - (risk - 0.5) * 18.0
    var perceived: float = clampf(wear + bias + maxf(0.0, heat - 0.60) * 13.0, 0.0, 100.0)
    return {"actual_wear": wear, "perceived_wear": perceived, "difference": perceived - wear,
        "trust": trust, "confidence": confidence, "risk": risk, "revision": int(profile.get("revision", 0))}

static func status(car_id: int, snapshot: Dictionary, profile: Dictionary) -> String:
    var feeling: Dictionary = perceive(car_id, snapshot, profile)
    if feeling.is_empty():
        return "Apex Soul: aguardando telemetria."
    var mode: String = "cauteloso" if float(profile.get("risk", 0.5)) < 0.46 else ("arrojado" if float(profile.get("risk", 0.5)) > 0.60 else "equilibrado")
    return "ALMA FICCIONAL · confiança no engenheiro %d%% · autoconfiança %d%% · estilo %s\nSensação de desgaste ~%d%% | telemetria %d%%" % [
        int(round(float(profile.get("trust", 0.5)) * 100.0)),
        int(round(float(profile.get("confidence", 0.5)) * 100.0)), mode,
        int(round(float(feeling.get("perceived_wear", 0.0)))),
        int(round(float(feeling.get("actual_wear", 0.0))))]

static func begin_discussion(profile: Dictionary) -> Dictionary:
    var updated: Dictionary = profile.duplicate(true)
    updated["conversation_id"] = int(updated.get("conversation_id", 0)) + 1
    return updated

static func choose(profile: Dictionary, choice: String) -> Dictionary:
    # Escolha comunicativa: apoiar a percepção do piloto ou priorizar dados.
    # Jamais presume que o box, o ritmo ou a ordem foram modificados.
    if choice not in ["piloto", "engenheiro"]:
        return {"applied": false, "profile": profile, "reason": "Opção inválida."}
    var current: int = int(profile.get("conversation_id", 0))
    if current <= 0:
        return {"applied": false, "profile": profile, "reason": "Discuta o stint primeiro."}
    if int(profile.get("answered_id", 0)) >= current:
        return {"applied": false, "profile": profile, "reason": "A equipe já respondeu a esta conversa. Para uma nova resposta, discuta o stint novamente quando houver mudança de dados."}
    var updated: Dictionary = profile.duplicate(true)
    updated["answered_id"] = current
    updated["revision"] = int(updated.get("revision", 0)) + 1
    updated["last_choice"] = choice
    var trust: float = float(updated.get("trust", 0.5))
    var confidence: float = float(updated.get("confidence", 0.5))
    var pilot_reply: String = ""
    var engineer_reply: String = ""
    var decision: String = ""
    if choice == "piloto":
        confidence = clampf(confidence + 0.045, 0.20, 0.82)
        trust = clampf(trust - 0.012, 0.20, 0.85)
        pilot_reply = "Obrigado por considerar o que sinto no cockpit. Vou avisar se a aderência mudar; não é garantia de que o pneu dure."
        engineer_reply = "Entendido. A opinião do piloto entra na análise, mas nenhuma ordem de box ou ritmo foi alterada."
        decision = "Chefia valorizou a percepção do piloto"
    else:
        confidence = clampf(confidence - 0.015, 0.20, 0.82)
        trust = clampf(trust + 0.045, 0.20, 0.85)
        pilot_reply = "Entendi. Confio na avaliação da equipe e continuarei relatando a sensação dos pneus."
        engineer_reply = "Seguiremos avaliando a telemetria. A conversa não muda a estratégia nem executa box."
        decision = "Chefia deu prioridade à leitura do engenheiro"
    updated["trust"] = trust
    updated["confidence"] = confidence
    var history: Array = updated.get("history", []).duplicate()
    history.append(decision)
    while history.size() > 6:
        history.pop_front()
    updated["history"] = history
    return {"applied": true, "profile": updated, "driver": pilot_reply,
        "engineer": engineer_reply, "decision": decision}
