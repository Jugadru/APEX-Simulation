extends RefCounted
## v0.6.4.9.7 — coordenação PREVENTIVA de duas janelas automáticas.
## Uma única decisão tática por stint, somente em seco estável.
## Não muda clima, pneus, tempos, RNG, ordens manuais ou pit urgente.

const SLICKS := ["Supermacio", "Macio", "Médio", "Duro"]
const MIN_LIFE_FOR_HOLD := 2.0
const MAX_WEAR_FOR_HOLD := 65.0
const MAX_WEAR_FOR_EARLY := 64.0
const MIN_WEAR_FOR_EARLY := 25.0

static func _is_auto(car: Dictionary, player_team: String) -> bool:
    # Equipes rivais são sempre controladas pelo motor; a equipe do
    # jogador só é coordenada quando o controle do piloto for IA.
    return str(car.get("team", "")) != player_team or str(car.get("pit_control_mode", "Manual")) == "IA"

static func _priority_before(car: Dictionary, teammate: Dictionary) -> bool:
    # Mais bem posicionado tem prioridade na janela original.
    # ID é desempate determinístico (a ordem de atualização não decide).
    var a: int = int(car.get("position", 99))
    var b: int = int(teammate.get("position", 99))
    return a < b or (a == b and int(car.get("id", 0)) < int(teammate.get("id", 0)))

static func assess(car: Dictionary, teammate: Dictionary,
        plan: Dictionary, teammate_plan: Dictionary,
        weather_now: Dictionary, total_laps: int, next_entry: int,
        player_team: String, available: Array) -> Dictionary:
    var output: Dictionary = {
        "version":"0.6.4.9.7", "decision":"MANTER", "overlap":false,
        "executable":false, "target_lap":next_entry,
        "reason":"Sem conflito elegível na janela automática."
    }
    if teammate.is_empty() or str(car.get("team", "")) != str(teammate.get("team", "")):
        return output
    if int(car.get("id", -1)) == int(teammate.get("id", -1)):
        return output
    if not _is_auto(car, player_team) or not _is_auto(teammate, player_team):
        return output
    if bool(car.get("finished", false)) or bool(teammate.get("finished", false)):
        return output
    if bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.001:
        return output
    if bool(teammate.get("pit_request", false)) or float(teammate.get("pit_left", 0.0)) > 0.001:
        return output
    if int(car.get("pit_scheduled_lap", 0)) != 0 or int(teammate.get("pit_scheduled_lap", 0)) != 0:
        return output
    if int(car.get("team_pit_adjusted_stint_06497", -999)) == int(car.get("stops", 0)):
        return output
    if bool(car.get("pitwall49_held", false)):
        return output
    if int(car.get("lap_strategy_adjusted_stint_06496", -999)) == int(car.get("stops", 0)):
        return output
    var own_stop: int = int(plan.get("planned_pit_lap", 0))
    var mate_stop: int = int(teammate_plan.get("planned_pit_lap", 0))
    if own_stop <= 0 or own_stop != mate_stop or own_stop >= total_laps:
        return output
    if next_entry not in [own_stop - 1, own_stop]:
        return output
    if str(plan.get("compound", "")) not in available or str(teammate_plan.get("compound", "")) not in available:
        return output
    output["overlap"] = true
    output["target_lap"] = own_stop
    if _priority_before(car, teammate):
        output["reason"] = "Janela V%d coincide; piloto prioritário mantém a parada." % own_stop
        return output
    var wear: float = float(car.get("wear", 100.0))
    var life: float = float(plan.get("life_laps", 0.0))
    var water: float = float(weather_now.get("wetness_factor", 1.0))
    var f3: float = float(plan.get("forecast_3", 1.0))
    var f6: float = float(plan.get("forecast_6", 1.0))
    if (str(car.get("tire", "")) not in SLICKS
            or str(teammate.get("tire", "")) not in SLICKS
            or water >= 0.08 or f3 >= 0.10 or f6 >= 0.10
            or float(weather_now.get("rain_intensity", 1.0)) >= 0.035
            or bool(plan.get("critical", false)) or bool(teammate_plan.get("critical", false))
            or int(car.get("stint_laps", 0)) < 4 or next_entry + 1 >= total_laps):
        output["reason"] = "Conflito previsto, mas chuva, limite de pneus ou fim do GP impedem escalonamento seguro."
        return output
    # Antecipar a parada não pode entrar no mesmo giro já reservado
    # pelo companheiro; ocorre somente uma volta ANTES de ambas as janelas.
    if (next_entry == own_stop - 1 and not bool(plan.get("pit_now", false))
            and wear >= MIN_WEAR_FOR_EARLY and wear <= MAX_WEAR_FOR_EARLY
            and life >= MIN_LIFE_FOR_HOLD
            and int(teammate.get("laps_done", 0)) >= int(car.get("laps_done", 0)) - 1):
        output["decision"] = "ANTECIPAR"
        output["executable"] = true
        output["reason"] = "Ambos projetam V%d; adiantar este carro para V%d, evitando compartilhar garagem." % [own_stop, next_entry]
    elif (next_entry == own_stop and bool(plan.get("pit_now", false))
            and wear < MAX_WEAR_FOR_HOLD and life >= MIN_LIFE_FOR_HOLD):
        output["decision"] = "ADIAR"
        output["executable"] = true
        output["reason"] = "Ambos projetam V%d; este carro espera V%d se pista/pneus permanecerem seguros." % [own_stop, own_stop + 1]
    else:
        output["reason"] = "Janela coincidente, mas sem margem demonstrada para mudar uma volta."
    return output
