extends RefCounted
## Apex Soul Driver 0.6.3.3 — first read-only perception layer.
## Parameters are fictional gameplay variables, not claims about real 2012 drivers.
## Does not mutate race, consume RNG, run pits or modify physical tyre wear.

static func assess(car_id: int, snapshot: Dictionary) -> Dictionary:
    var cars: Array = snapshot.get("cars", [])
    var car: Dictionary = {}
    for item in cars:
        var candidate: Dictionary = item
        if int(candidate.get("id", -1)) == car_id:
            car = candidate
            break
    if car.is_empty():
        return {}
    var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
    var heat: float = clampf(float(car.get("tyre_heat", 0.0)), 0.0, 1.0)
    var wetness: float = clampf(float((snapshot.get("weather", {}) as Dictionary).get("wetness_factor", 0.0)), 0.0, 1.0)
    var compound: String = str(car.get("tire", ""))
    var stint: int = int(car.get("stint_laps", 0))
    var gap: float = float(car.get("interval", 999.0))
    # Stable, small variability in subjective threshold, keyed only by car ID.
    # It is NOT a factual assessment of the named person's psychology.
    var tolerance: float = float(posmod(car_id * 17 + 7, 11) - 5) * 1.2
    var phrase: String = ""
    if wetness >= 0.35 and compound not in ["Intermediário", "Chuva"]:
        phrase = "Estou sentindo a pista muito escorregadia com pneus de seco; precisamos acompanhar a chuva."
    elif wetness <= 0.09 and compound == "Chuva" and stint >= 2:
        phrase = "A pista parece secar. Estes pneus de chuva já não passam confiança."
    elif heat >= 0.72:
        phrase = "O carro escorrega na saída das curvas. Sinto que a temperatura está prejudicando os pneus."
    elif wear >= 76.0 + tolerance:
        phrase = "Estou perdendo bastante aderência; para mim os pneus já estão no limite."
    elif wear >= 50.0 + tolerance:
        phrase = "Ainda consigo manter o carro, mas sinto a aderência cair. Posso tentar alongar um pouco, se os dados permitirem."
    elif wear >= 30.0 + tolerance:
        phrase = "Ainda sinto boa aderência. Não estou percebendo uma degradação tão forte por enquanto."
    elif int(car.get("position", 0)) > 1 and gap > 0.0 and gap < 1.0:
        phrase = "Os pneus parecem bons, mas estou no ar sujo do carro à frente."
    else:
        phrase = "O carro está equilibrado, e os pneus ainda estão respondendo bem."
    return {"car_name": str(car.get("name", "Piloto")), "car_id": car_id, "message": phrase, "subjective_only": true}
