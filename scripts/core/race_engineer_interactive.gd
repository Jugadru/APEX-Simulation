extends RefCounted
## APEX 0.6.3.2 — Perguntas sob demanda, sem modificar o estado da corrida.
## Consome instantaneo e plano fornecidos pelo simulador; nenhuma telemetria inventada.

const QUESTIONS := {
    "pneus": "Como estão os pneus?",
    "ritmo": "Como está nosso ritmo?",
    "trafego": "Como está o tráfego?",
    "box": "Vale a pena parar agora?"
}

static func answer(topic: String, car_id: int, snapshot: Dictionary, advice: Dictionary) -> Dictionary:
    if not QUESTIONS.has(topic):
        return {}
    var ordered: Array = snapshot.get("cars", [])
    var car: Dictionary = {}
    var idx: int = -1
    for i in range(ordered.size()):
        var candidate: Dictionary = ordered[i]
        if int(candidate.get("id", -1)) == car_id:
            car = candidate
            idx = i
            break
    if car.is_empty():
        return {}
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var tire: String = str(car.get("tire", "desconhecido"))
    var stint: int = int(car.get("stint_laps", 0))
    var remaining: int = maxi(0, int(snapshot.get("lap_count", 0)) - int(car.get("laps_done", 0)))
    var weather: Dictionary = snapshot.get("weather", {})
    var wetness: float = clampf(float(weather.get("wetness_factor", 0.0)), 0.0, 1.0)
    var booked: int = int(car.get("pit_scheduled_lap", 0))
    var manual: bool = str(car.get("pit_control_mode", "Manual")) != "IA"
    var reply: String = ""
    match topic:
        "pneus":
            reply = "Estamos de %s há %d voltas, com desgaste de %.0f%%." % [tire, stint, wear]
            if wetness >= 0.18 and tire not in ["Intermediário", "Chuva"]:
                reply += " A pista está úmida; o composto atual pode perder aderência."
            elif wear >= 78.0:
                reply += " Já estamos na faixa de desgaste elevado; avaliaremos uma troca."
            elif wear >= 50.0:
                reply += " Ainda há margem, mas precisamos acompanhar a queda de rendimento."
            else:
                reply += " Sem sinal de desgaste crítico neste instante."
        "ritmo":
            reply = "O carro está em P%d, no modo %s." % [int(car.get("position", idx + 1)), str(car.get("pace", "Normal"))]
            var last: float = float(car.get("last_lap", 9999.0))
            var best: float = float(car.get("best_lap", 9999.0))
            if last > 0.0 and last < 500.0 and best > 0.0 and best < 500.0:
                reply += " Última volta %.2fs, melhor volta %.2fs: diferença de %.2fs." % [last, best, maxf(0.0, last - best)]
            else:
                reply += " Ainda não temos voltas suficientes para comparar tempos."
            if wear >= 75.0:
                reply += " O desgaste alto pode estar afetando o ritmo."
        "trafego":
            if idx == 0:
                reply = "Estamos na liderança e temos pista livre à frente."
            else:
                var ahead: Dictionary = ordered[idx - 1]
                var interval: float = maxf(0.0, float(car.get("interval", 0.0)))
                reply = "Temos %s à frente, a %.2fs." % [str(ahead.get("name", "um adversário")), interval]
                if interval < 1.0:
                    reply += " Estamos muito próximos; o tráfego pode comprometer o ar limpo."
                elif interval < 3.0:
                    reply += " Estamos em distância de aproximação."
                else:
                    reply += " Ainda há espaço livre até alcançar o adversário."
            if idx + 1 < ordered.size():
                var behind: Dictionary = ordered[idx + 1]
                reply += " Atrás vem %s, a %.2fs." % [str(behind.get("name", "outro carro")), maxf(0.0, float(behind.get("interval", 0.0)))]
        "box":
            var current_lap: int = int(car.get("laps_done", 0))
            var compound: String = str(advice.get("compound", ""))
            var window: int = int(advice.get("planned_pit_lap", 0))
            var future_window: bool = window > current_lap and window < int(snapshot.get("lap_count", 0))
            if remaining <= 0 or bool(car.get("finished", false)):
                reply = "Corrida concluída para este carro. Não há parada pendente."
            elif float(car.get("pit_left", 0.0)) > 0.0:
                reply = "Já estamos no procedimento de boxes. Vamos acompanhar a saída."
            elif bool(car.get("pit_request", false)):
                reply = "A chamada de box já foi feita. Aguarde a entrada."
            elif bool(advice.get("pit_now", false)):
                reply = "Os dados indicam que vale avaliar o box agora%s." % (" para %s" % compound if compound != "" else "")
            elif future_window:
                reply = "Por enquanto, podemos continuar. A janela estimada é na volta %d%s." % [window, " para %s" % compound if compound != "" else ""]
            else:
                # Never repeat an outdated projected stop as if it were in the future.
                reply = "Não vejo vantagem confirmada em chamar o box neste instante. Vamos reavaliar na próxima volta."
            if remaining > 0:
                reply += " Desgaste %.0f%%; restam %d voltas." % [wear, remaining]
            if booked > current_lap and booked < int(snapshot.get("lap_count", 0)):
                reply += " Sua ordem para V%d continua registrada." % booked
            elif manual and remaining > 0 and not bool(car.get("pit_request", false)):
                reply += " Se decidir parar, preciso de sua confirmação."
    return {"question": str(QUESTIONS[topic]), "reply": reply, "car_name": str(car.get("name", "Piloto")), "car_id": car_id}
