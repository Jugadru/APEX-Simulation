extends RefCounted
## APEX 0.6.3.4: short-term fictional radio feedback, read-only for RaceEngine.
## The memory belongs to the UI, never to the simulated driver's physical state.
const Perception = preload("res://scripts/core/race_driver_perception_0633.gd")

static func observe(car_id: int, snapshot: Dictionary, previous: Dictionary = {}) -> Dictionary:
    var base: Dictionary = Perception.assess(car_id, snapshot)
    if base.is_empty():
        return {}
    var car: Dictionary = {}
    for item in snapshot.get("cars", []):
        if int(item.get("id", -1)) == car_id:
            car = item
            break
    var now: float = float(snapshot.get("time", 0.0))
    var wear: float = float(car.get("wear", 0.0))
    var heat: float = float(car.get("tyre_heat", 0.0))
    var tire: String = str(car.get("tire", ""))
    var message: String = str(base.get("message", ""))
    var repeated: bool = false
    if not previous.is_empty():
        var last_tire: String = str(previous.get("tire", ""))
        var delta_wear: float = wear - float(previous.get("wear", wear))
        var delta_heat: float = heat - float(previous.get("heat", heat))
        if last_tire != tire:
            message = "Com os pneus novos, a sensação mudou. " + message
        elif delta_wear >= 12.0:
            message = "Desde nossa última conversa a aderência caiu mais. " + message
        elif delta_heat >= 0.18:
            message = "A temperatura piorou desde o último contato. " + message
        elif now - float(previous.get("time", -999.0)) < 30.0:
            repeated = true
            message = "Sem novidade desde o último contato. Continuo acompanhando o carro."
    return {
        "car_id": car_id, "car_name": str(base.get("car_name", "Piloto")),
        "message": message, "subjective_only": true, "repeat": repeated,
        "memory": {"time": now, "wear": wear, "heat": heat, "tire": tire}
    }
