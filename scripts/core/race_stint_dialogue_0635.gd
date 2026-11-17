extends RefCounted
## Apex 0.6.3.5: fictional subjective stint preference versus current measured race state.
## Read-only. Not historical characterisation; no pit, pace, RNG or engine state mutation.

static func evaluate(car_id: int, snapshot: Dictionary, advice: Dictionary, previous: Dictionary = {}, soul: Dictionary = {}) -> Dictionary:
    var car: Dictionary = {}
    for entry in snapshot.get("cars", []):
        if int(entry.get("id", -1)) == car_id:
            car = entry
            break
    if car.is_empty():
        return {}
    var now: float = float(snapshot.get("time", 0.0))
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var heat: float = clampf(float(car.get("tyre_heat", 0.0)), 0.0, 1.0)
    var tire: String = str(car.get("tire", ""))
    var stint: int = int(car.get("stint_laps", 0))
    var wetness: float = clampf(float((snapshot.get("weather", {}) as Dictionary).get("wetness_factor", 0.0)), 0.0, 1.0)
    var lap: int = int(car.get("laps_done", 0))
    var remaining: int = maxi(0, int(snapshot.get("lap_count", 0)) - lap)
    var booked: int = int(car.get("pit_scheduled_lap", 0))
    var estimated: int = int(advice.get("planned_pit_lap", 0))
    var pit_now: bool = bool(advice.get("pit_now", false))
    var pit_active: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
    var tire_mismatch: bool = (wetness >= 0.35 and tire not in ["Intermediário", "Chuva"]) or (wetness <= 0.08 and tire == "Chuva" and stint >= 2)
    var felt_wear: float = wear if soul.is_empty() else clampf(float(soul.get("perceived_wear", wear)), 0.0, 100.0)
    # Arbitrary, small FICTIONAL tolerance: not sourced from the named human driver.
    var tolerance: float = float(posmod(car_id * 13 + 3, 9) - 4) * 1.5
    var driver: String = ""
    var engineer: String = ""
    var wants_extend: bool = false
    var conflict: bool = false
    if remaining <= 0 or bool(car.get("finished", false)):
        driver = "A corrida acabou para mim."
        engineer = "Sessão concluída; não há decisão de pneus pendente."
    elif pit_active:
        driver = "Já recebemos a chamada de box. Vou cumprir a ordem."
        engineer = "A operação de boxes já está em andamento ou foi solicitada. Nenhuma nova ordem será enviada por esta conversa."
    elif tire_mismatch:
        driver = "A aderência não combina com estas condições. Prefiro rever o pneu."
        engineer = "Concordo em reavaliar o composto: a pista mudou e o pneu atual pode estar inadequado. Vamos analisar a estratégia."
    elif felt_wear >= 78.0 + tolerance or heat >= 0.82:
        driver = "Está difícil manter o carro neste ritmo. Acho melhor avaliarmos uma parada."
        engineer = "O desgaste está em %.0f%% e o aquecimento em %.0f%%; os dados justificam revisar a janela de box." % [wear, heat * 100.0]
    elif felt_wear >= 54.0 + tolerance:
        wants_extend = true
        driver = "Ainda consigo administrar estes pneus. Podemos tentar mais uma volta antes de decidir?"
        if wear >= 62.0 or heat >= 0.67 or pit_now:
            conflict = true
            engineer = "Entendo, mas os sensores indicam %.0f%% de desgaste e %.0f%% de aquecimento. Eu não confirmaria a extensão sem reavaliar o ritmo na próxima volta." % [wear, heat * 100.0]
        else:
            engineer = "Podemos considerar uma volta a mais, com vigilância do desgaste (%.0f%%). É uma possibilidade, não garantia de rendimento." % wear
    else:
        wants_extend = true
        driver = "Os pneus ainda respondem bem. Minha preferência é seguir e observar a próxima volta."
        if wear >= 76.0 or heat >= 0.72:
            conflict = true
            engineer = "Sua sensação importa, mas os sensores medem %.0f%% de desgaste e %.0f%% de aquecimento. Não confirmaria extensão sem reavaliar a estratégia." % [wear, heat * 100.0]
        elif pit_now:
            conflict = true
            engineer = "Seu retorno é útil, mas o plano atual indica avaliar o box agora. Vamos comparar a perda esperada antes de qualquer decisão."
        else:
            engineer = "O desgaste medido é %.0f%% após %d voltas deste stint. Não há sinal suficiente para exigir uma parada imediata." % [wear, stint]
    if not soul.is_empty() and remaining > 0 and not pit_active:
        if str(soul.get("last_choice", "")) == "piloto":
            driver += " Lembro que minha avaliação foi ouvida na conversa anterior."
        elif str(soul.get("last_choice", "")) == "engenheiro":
            driver += " Lembro que priorizamos os dados; seguirei informando minha sensação."
        if absf(felt_wear - wear) >= 7.0:
            driver += " Pela minha sensação, o desgaste parece %s do que sugerem os sensores." % ("maior" if felt_wear > wear else "menor")
        # O engenheiro mantém a telemetria como fonte de verdade.
    if remaining > 0 and not pit_active:
        if booked > lap and booked < int(snapshot.get("lap_count", 0)):
            engineer += " A ordem explícita para a volta %d permanece registrada." % booked
        elif booked > 0 and booked <= lap:
            engineer += " A antiga volta agendada já passou; não vou tratá-la como uma janela futura."
        elif estimated > lap and estimated < int(snapshot.get("lap_count", 0)):
            engineer += " A projeção atual aponta a volta %d, sujeita a revisão." % estimated
        elif pit_now:
            engineer += " O plano também sinaliza oportunidade de box neste momento."
        engineer += " Esta conversa não modifica a ordem de box nem o modo de controle da equipe."
    var memory: Dictionary = {"time": now, "wear": wear, "heat": heat, "wetness": wetness,
        "tire": tire, "booked": booked, "estimated": estimated, "pit_now": pit_now,
        "remaining": remaining, "pit_active": pit_active,
        "soul_revision": int(soul.get("revision", 0))}
    var repeat: bool = false
    if not previous.is_empty():
        repeat = now - float(previous.get("time", -9999.0)) < 60.0 \
            and absf(wear - float(previous.get("wear", wear))) < 6.0 \
            and absf(heat - float(previous.get("heat", heat))) < 0.12 \
            and absf(wetness - float(previous.get("wetness", wetness))) < 0.08 \
            and tire == str(previous.get("tire", "")) \
            and booked == int(previous.get("booked", -99)) \
            and estimated == int(previous.get("estimated", -99)) \
            and pit_now == bool(previous.get("pit_now", not pit_now)) \
            and pit_active == bool(previous.get("pit_active", not pit_active))
    return {"car_id": car_id, "car_name": str(car.get("name", "Piloto")),
        "driver": driver, "engineer": engineer, "disagreement": conflict,
        "wants_extend": wants_extend, "repeat": repeat, "memory": memory,
        "fictional": true, "read_only": true, "perceived_wear": felt_wear}
