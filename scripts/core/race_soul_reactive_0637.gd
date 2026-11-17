extends RefCounted
## APEX v0.6.3.7 — rádio espontâneo do piloto (apenas comunicação ficcional).
## Somente instantâneos do motor e eventos reais; sem comandos ou RNG de corrida.
## Personalidade é ficção lúdica, não característica factual de pilotos históricos.

static func initial_memory() -> Dictionary:
	return {"last_emission": -10000.0, "last_kind": "", "last_sample_lap": -1,
		"wear_stage": 0, "wet_stage": 0, "traffic_streak": 0,
		"pace_streak": 0, "last_traffic_lap": -100, "last_pace_lap": -100,
		"last_position": -1, "emissions": 0, "last_kind_laps": {}}

static func _find_car(car_id: int, snapshot: Dictionary) -> Dictionary:
	for element in snapshot.get("cars", []):
		var candidate: Dictionary = element
		if int(candidate.get("id", -1)) == car_id:
			return candidate
	return {}

static func _wear_stage(wear: float) -> int:
	if wear >= 90.0:
		return 3
	if wear >= 75.0:
		return 2
	if wear >= 55.0:
		return 1
	return 0

static func _wet_stage(wetness: float) -> int:
	if wetness >= 0.60:
		return 2
	if wetness >= 0.18:
		return 1
	return 0

static func _candidate(kind: String, message: String, priority: int, reply: String) -> Dictionary:
	return {"kind": kind, "message": message, "priority": priority, "engineer": reply}

static func observe(car_id: int, snapshot: Dictionary, profile: Dictionary,
		memory: Dictionary, events: Array = []) -> Dictionary:
	var car: Dictionary = _find_car(car_id, snapshot)
	if car.is_empty() or bool(snapshot.get("finished", false)) or bool(car.get("finished", false)):
		return {"emitted": false, "memory": memory}
	var next: Dictionary = memory.duplicate(true) if not memory.is_empty() else initial_memory()
	var clock: float = float(snapshot.get("time", 0.0))
	var lap: int = int(car.get("laps_done", 0))
	var wear: float = clampf(float(car.get("wear", 0.0)), 0.0, 100.0)
	var pos: int = int(car.get("position", 0))
	var in_pit: bool = bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0
	var wetness: float = clampf(float((snapshot.get("weather", {}) as Dictionary).get("wetness_factor", 0.0)), 0.0, 1.0)
	var tyre: String = str(car.get("tire", ""))
	var risk: float = clampf(float(profile.get("risk", 0.5)), 0.0, 1.0)
	var confidence: float = clampf(float(profile.get("confidence", 0.5)), 0.0, 1.0)
	var candidates: Array[Dictionary] = []
	var general_reply: String = "Recebido. Vamos conferir os dados; nenhuma ordem de ritmo ou box foi alterada."
	# Eventos oficiais do motor têm prioridade, mas não devem ser repetidos.
	for item in events:
		var event: Dictionary = item
		if int(event.get("driver_id", -1)) != car_id:
			continue
		var kind: String = str(event.get("type", ""))
		match kind:
			"incident", "contact":
				candidates.append(_candidate("incidente", "Tive uma situação difícil na pista. Vou avaliar a resposta do carro na próxima sequência.", 100,
					"Entendido. Vamos acompanhar os próximos setores; nenhuma ordem foi emitida."))
			"pit_failure", "unsafe_release":
				candidates.append(_candidate("box", "Perdemos tempo na operação de boxes. Preciso saber como está a disputa na saída.", 96,
					"Confirmamos uma ocorrência no pit stop. Vamos acompanhar os intervalos."))
			"pass", "lead":
				if lap >= 1:
					var words: String = "Assumimos a liderança. Vou cuidar dos pneus e manter a concentração." if kind == "lead" else ("A manobra deu certo, ganhei a posição. Vamos ver o ritmo agora." if risk >= 0.50 else "Passei o carro à frente. Vou administrar a saída e preservar os pneus.")
					candidates.append(_candidate("disputa", words, 71, "Entendido. Intervalos em atualização; nenhuma ordem automática."))
	# Mudanças reais de pneus e água são observadas mesmo sem abrir a janela de rádio.
	var stage: int = _wear_stage(wear)
	var previous_stage: int = int(next.get("wear_stage", 0))
	if wear < 25.0:
		previous_stage = 0  # Novo jogo de pneus: outra oportunidade de comentar desgaste.
	if stage > previous_stage and lap >= 1 and not in_pit:
		var feeling: float = wear + (0.5 - confidence) * 17.0 + (0.5 - risk) * 13.0
		var words: String = "Estou perdendo aderência; vale conferir a janela de parada." if feeling >= 74.0 else "A telemetria deve estar indicando desgaste, mas ainda sinto alguma aderência. Vamos comparar."
		if stage == 3:
			words = "A aderência caiu bastante. Precisamos avaliar este jogo de pneus com cuidado."
		candidates.append(_candidate("desgaste", words, 58 + stage * 6,
			"Desgaste medido: %d%%. O plano de parada permanece como está até receber uma ordem." % int(round(wear))))
	next["wear_stage"] = stage
	var new_wet: int = _wet_stage(wetness)
	var old_wet: int = int(next.get("wet_stage", 0))
	if new_wet > old_wet and tyre not in ["Intermediário", "Chuva"] and lap >= 1:
		candidates.append(_candidate("chuva", "A pista está ficando mais molhada com estes pneus de seco. Podemos revisar as condições?", 85,
			"Água medida na pista: %d%%. Vamos reavaliar, sem trocar pneus automaticamente." % int(round(wetness * 100.0))))
	next["wet_stage"] = new_wet
	# Ritmo/tráfego só são avaliados uma vez por volta concluída, não a cada quadro.
	if lap > int(next.get("last_sample_lap", -1)):
		var interval: float = float(car.get("interval", 999.0))
		var close: bool = pos > 1 and interval >= 0.25 and interval <= 1.35 and not in_pit
		next["traffic_streak"] = int(next.get("traffic_streak", 0)) + 1 if close else 0
		var best: float = float(car.get("best_lap", 9999.0))
		var last: float = float(car.get("last_lap", 0.0))
		var slow: bool = lap >= 3 and best > 20.0 and best < 500.0 and last > best + 2.3 and not in_pit
		next["pace_streak"] = int(next.get("pace_streak", 0)) + 1 if slow else 0
		if int(next["traffic_streak"]) >= 2 and lap - int(next.get("last_traffic_lap", -100)) >= 5:
			var traffic_words: String = "Estou perto do carro à frente, mas o ar sujo dificulta acompanhar nas curvas." if risk < 0.57 else "Estou perto do carro à frente. Tenho ritmo para pressionar, mas preciso de espaço."
			candidates.append(_candidate("tráfego", traffic_words, 65, general_reply))
			next["last_traffic_lap"] = lap
		if int(next["pace_streak"]) >= 2 and lap - int(next.get("last_pace_lap", -100)) >= 4:
			candidates.append(_candidate("ritmo", "Minhas últimas voltas estão mais lentas que a melhor marca. Podemos verificar desgaste e tráfego?", 63,
				"Estamos comparando voltas e pneus. Não alteramos automaticamente o ritmo."))
			next["last_pace_lap"] = lap
		next["last_sample_lap"] = lap
	next["last_position"] = pos
	# Um aviso urgente pode interromper um curto cooldown; observações normais não.
	var eligible: Array[Dictionary] = []
	for candidate in candidates:
		var priority: int = int(candidate["priority"])
		var min_gap: float = 22.0 if priority >= 90 else 85.0
		var same_kind_recent: bool = str(candidate.get("kind", "")) == "disputa" and lap - int((next.get("last_kind_laps", {}) as Dictionary).get("disputa", -100)) < 6
		if clock - float(next.get("last_emission", -10000.0)) >= min_gap and not same_kind_recent:
			eligible.append(candidate)
	if eligible.is_empty():
		return {"emitted": false, "memory": next}
	eligible.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["priority"]) > int(b["priority"]))
	var chosen: Dictionary = eligible[0]
	next["last_emission"] = clock
	next["last_kind"] = str(chosen["kind"])
	var per_kind: Dictionary = next.get("last_kind_laps", {}).duplicate(true)
	per_kind[str(chosen["kind"])] = lap
	next["last_kind_laps"] = per_kind
	next["emissions"] = int(next.get("emissions", 0)) + 1
	return {"emitted": true, "memory": next, "kind": str(chosen["kind"]),
		"message": str(chosen["message"]), "engineer": str(chosen["engineer"]),
		"car_name": str(car.get("name", "Piloto")), "car_id": car_id, "at": clock}
