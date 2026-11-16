extends RefCounted
## APEX 0.6.3.1 — Resposta informativa do engenheiro ao relato do piloto.
## Calcula somente texto; não cria ordens, não altera IA, não usa sorteio.

static func compose(report: Dictionary, car: Dictionary, conditions: Dictionary, advice: Dictionary, nominated: Array) -> String:
    if report.is_empty():
        return ""
    var kind: String = str(report.get("kind", ""))
    var driver: String = str(car.get("name", "Piloto"))
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var wet: float = clampf(float(conditions.get("wetness_factor", 0.0)), 0.0, 1.0)
    var next_lap: int = int(car.get("pit_scheduled_lap", 0))
    var manual: bool = str(car.get("pit_control_mode", "Manual")) != "IA"
    var content: String = ""
    match kind:
        "grip_molhado":
            var compound: String = "Chuva" if wet >= 0.66 else "Intermediário"
            content = "Recebido. A umidade estimada da pista está em %d%%. Vamos comparar %s com o pneu atual." % [int(round(wet * 100.0)), compound]
        "chuva_secando", "inter_secando":
            content = "Entendido. A pista está com umidade estimada de %d%%. Vamos avaliar o momento de passar aos pneus de seco." % int(round(wet * 100.0))
        "aderencia":
            if bool(advice.get("pit_now", false)) and str(advice.get("compound", "")) in nominated:
                content = "Confirmado, desgaste em %d%%. A análise sugere box para %s; vamos verificar a janela." % [int(round(wear)), str(advice.get("compound", ""))]
            else:
                content = "Entendido, desgaste em %d%%. Ainda precisamos comparar perda de ritmo e custo de parada." % int(round(wear))
        "temperatura":
            content = "Copiado. O indicador de aquecimento está elevado; acompanhe a aderência enquanto monitoramos os próximos setores."
        "trafego":
            content = "Recebido. Você está a %.1fs do carro à frente. Vamos monitorar uma oportunidade de ataque sem comprometer os pneus." % maxf(0.0, float(car.get("interval", 0.0)))
        _:
            return ""
    # A booked stop is never changed by speech, including urgent tyre feedback.
    if next_lap > 0:
        content += " A ordem de BOX V%d continua válida; não será antecipada sem nova decisão." % next_lap
    elif manual:
        content += " A decisão de chamar box continua com você."
    else:
        content += " O controle automático de box permanece ativo."
    return "RÁDIO FICTÍCIO | Engenheiro para %s: %s" % [driver, content]
