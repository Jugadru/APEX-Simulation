extends RefCounted
## Apex's own offline, rule-based race commentary. Original Portuguese phrasing;
## consumes real events from the APEX simulation, never third-party telemetry.

const MAX_LINES: int = 72
const Radio3 = preload("res://scripts/presentation/race_radio_06695.gd")
const CAST := {
	"NARRADOR": "#d9eaff",
	"ANALISTA": "#75d8df",
	"BOXES": "#ffca80",
	"ENGENHEIRO": "#75e0b1",
	"PILOTO": "#b9a2ff",
	"CHEFE": "#f6d886"
}

var lines: Array[Dictionary] = []
var _seen: Dictionary = {}
var _last_style: Dictionary = {}
var _last_category_at: Dictionary = {}
var _last_battle_pair_at: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _last_interlude := 0.0
var _last_event_id: int = 0
# Bounded, presentation-only conversations; do not store in the race/save.
var _radio3_memory: Dictionary = {}

func reset(race_seed: int) -> void:
	lines.clear()
	_seen.clear()
	_last_style.clear()
	_last_category_at.clear()
	_last_battle_pair_at.clear()
	_rng.seed = race_seed + 731
	_last_interlude = 0.0
	_last_event_id = 0
	_radio3_memory.clear()

func ingest(race, player_team: String) -> bool:
	var changed := false
	# APEX telemetry is the canonical, unbounded event stream. Fall back to the
	# short legacy ring only when working with older race engines.
	var source_events: Array = race.events
	var from_telemetry: bool = race.telemetry != null
	if from_telemetry:
		source_events = race.telemetry.events_since(_last_event_id)
	for event in source_events:
		if from_telemetry:
			_last_event_id = maxi(_last_event_id, int(event.get("event_id", 0)))
		else:
			var sig := "%.3f|%s|%d|%s" % [float(event.get("time", 0.0)), str(event.get("type", "")), int(event.get("driver_id", -1)), str(event.get("message", ""))]
			if _seen.has(sig):
				continue
			_seen[sig] = true
		if _event_line(event, race, player_team):
			changed = true
	if not from_telemetry and _seen.size() > 1200:
		_seen.clear()
		for event in race.events:
			var sig := "%.3f|%s|%d|%s" % [float(event.get("time", 0.0)), str(event.get("type", "")), int(event.get("driver_id", -1)), str(event.get("message", ""))]
			_seen[sig] = true
	if race.running and not race.finished and float(race.clock) - _last_interlude > 115.0:
		_last_interlude = float(race.clock)
		if _ambient_line(race):
			changed = true
	return changed

func _event_line(event: Dictionary, race, player_team: String) -> bool:
	var kind: String = str(event.get("type", ""))
	var source: String = str(event.get("message", ""))
	var car_id: int = int(event.get("driver_id", -1))
	var car := _driver_by_id(race, car_id)
	var name: String = str(car.get("name", "Piloto"))
	var is_ours: bool = str(car.get("team", "")) == player_team
	var role := "NARRADOR"
	var phrases: Array[String] = []
	var radio_packet: Dictionary = {}
	var soul_request: bool = false
	match kind:
		"grid":
			phrases = ["Está tudo preparado em %s. %d carros para uma prova de %d voltas." % [str(race.track_name), race.cars.size(), int(race.lap_count)],
				"A largada se aproxima em %s. Estratégias prontas, pneus escolhidos." % str(race.track_name)]
		"battle":
			# A simulação emite muitos estados de tentativa; isso não significa
			# uma ultrapassagem nova. Os abortos não são anunciados na TV.
			if source.contains("retirou o ataque"):
				return false
			role = "ANALISTA"
			phrases = ["Disputa se formando: %s" % source]
		"pass":
			phrases = ["%s ganha terreno: agora aparece na posição %d." % [name, int(car.get("position", 0))],
				"Mudança na ordem! %s avança no pelotão." % name]
		"lead":
			phrases = ["Novo líder! %s assume a ponta da corrida." % name,
				"A liderança mudou de mãos: %s agora dita o ritmo." % name]
		"pit":
			role = "BOXES"
			phrases = ["%s chega à entrada dos boxes. A equipe está pronta para o atendimento." % name,
				"Parada em andamento para %s. Vamos acompanhar a troca." % name]
		"service":
			role = "BOXES"
			phrases = ["Pneus instalados em %s. Serviço de %s concluído." % [str(car.get("tire", "novo composto")), name],
				"Os mecânicos concluem a troca de %s. Olho na saída." % name]
		"double_stack":
			role = "BOXES"
			phrases = ["Dupla parada! A garagem precisa coordenar a passagem dos dois carros. %s" % source,
				"A fila do double stack já afeta a corrida. %s" % source]
		"pit_failure":
			role = "BOXES"
			phrases = ["Problema no serviço de pneus! %s" % source,
				"A operação perde segundos preciosos. %s" % source]
		"unsafe_release":
			role = "BOXES"
			phrases = ["A equipe segura o carro para evitar uma liberação insegura. %s" % source]
		"pit_exit":
			role = "ANALISTA"
			phrases = ["%s volta à pista. A diferença de tempo mostrará se a parada compensou." % name,
				"Parada concluída por %s; agora precisamos observar a posição de retorno." % name]
		"wear":
			role = "ANALISTA"
			phrases = ["Os pneus de %s entraram na zona crítica de desgaste. O ritmo pode sofrer." % name]
		"incident":
			phrases = ["Um erro custa tempo nesta volta. %s" % source]
		"flag":
			phrases = ["Bandeirada! %s" % source]
		"driver_radio":
			if not is_ours:
				return false
			role = "PILOTO"
			phrases = [source]
			var intent: String = Radio3.classify_source(source)
			if intent != "":
				var previous: Dictionary = _radio3_memory.get(car_id, {})
				var facts: Dictionary = {"lap": int(car.get("laps_done", 0)),
					"event_id": int(event.get("event_id", -1)),
					"sim_time": float(event.get("time", -1.0)),
					"priority": int(event.get("priority", 60))}
				radio_packet = Radio3.driver(car, intent, facts, previous)
				if not radio_packet.is_empty():
					phrases = ["RÁDIO FICTÍCIO | %s: %s" % [name, str(radio_packet["text"])]]
					_radio3_memory[car_id] = Radio3.remember(previous, radio_packet)
					soul_request = intent in ["revisar_plano", "avaliar_box", "troca_equipe",
						"perda_ritmo", "estender_stint"]
		"engineer_reply":
			if not is_ours:
				return false
			role = "ENGENHEIRO"
			phrases = [source]
			var prior: Dictionary = _radio3_memory.get(car_id, {})
			var prior_kind: String = str(prior.get("last_pilot_kind", ""))
			# Only pair with a confirmed driver report at the SAME sporting
			# timestamp. An older Soul request must not answer a new unrelated event.
			if prior_kind in ["grip_molhado", "chuva_secando", "inter_secando",
				"aderencia", "temperatura", "trafego"] and absf(
				float(event.get("time", -1.0)) - float(prior.get("last_pilot_time", -9999.0))) < 0.01:
				radio_packet = Radio3.engineer(car, prior_kind, {
					"lap": int(car.get("laps_done", 0)),
					"event_id": int(event.get("event_id", -1)),
					"priority": int(event.get("priority", 60)),
					"conversation_id": str(prior.get("last_conversation_id", ""))})
				if not radio_packet.is_empty():
					phrases = ["RÁDIO FICTÍCIO | Engenheiro: %s" % str(radio_packet["text"])]
		"radio":
			role = "ENGENHEIRO" if is_ours else "ANALISTA"
			phrases = [source]
		_:
			if int(event.get("priority", 0)) < 60:
				return false
			role = "ANALISTA"
			phrases = [source]
	if phrases.is_empty():
		return false
	var t := float(event.get("time", 0.0))
	var last_at: float = float(_last_category_at.get(kind, -999.0))
	# Ordinary overtaking updates can arrive in clusters. Critical race events
	# are always shown; repetitive low-priority chatter is rate-limited.
	if kind == "pass" and t - last_at < 5.0:
		return false
	# A foto da v0.6.3.0 mostrou vários ataques em segundos consecutivos.
	# Uma disputa vira informação; ultrapassagens reais e liderança não sofrem
	# este bloqueio e continuam no histórico.
	if kind == "battle" and t - last_at < 30.0:
		return false
	# A mesma dupla em disputa não precisa ser anunciada a cada 30 segundos.
	# Uma dupla diferente pode ser anunciada após o intervalo global.
	if kind == "battle" and t - float(_last_battle_pair_at.get(source, -999.0)) < 210.0:
		return false
	if kind == "battle":
		_last_battle_pair_at[source] = t
	_last_category_at[kind] = t
	var index := 0
	if phrases.size() > 1:
		index = _rng.randi_range(0, phrases.size() - 1)
		if int(_last_style.get(kind, -1)) == index:
			index = (index + 1) % phrases.size()
	_last_style[kind] = index
	_push(t, role, phrases[index], is_ours, kind, car_id)
	if not radio_packet.is_empty():
		lines[-1]["radio3"] = radio_packet
	# Soul3 has no automatic engineer message; this is presentation-only
	# acknowledgement of the already-verified request. The next real driver
	# command remains under the existing manual/AI Pit Wall validation.
	if soul_request:
		var context: Dictionary = {
			"lap": int(car.get("laps_done", 0)),
			"event_id": int(event.get("event_id", -1)),
			"conversation_id": str(radio_packet.get("conversation_id", ""))}
		var answer: Dictionary = Radio3.engineer(car, str(radio_packet["intent"]), context)
		if not answer.is_empty():
			_push(t, "ENGENHEIRO", "RÁDIO FICTÍCIO | Engenheiro: " + str(answer["text"]),
				is_ours, "radio3_ack", car_id)
			lines[-1]["radio3"] = answer
			_radio3_memory[car_id] = Radio3.remember(_radio3_memory.get(car_id, {}), answer)
	return true

func _ambient_line(race) -> bool:
	var ordered: Array = race.get_sorted()
	if ordered.is_empty():
		return false
	var leader: Dictionary = ordered[0]
	var next_gap: float = 0.0
	if ordered.size() > 1:
		next_gap = float(ordered[1].get("interval", 0.0))
	var variants: Array[String] = [
		"%s segue na liderança. A vantagem para o segundo é de %.1f segundo(s)." % [str(leader.get("name", "Líder")), next_gap],
		"A corrida avança para a volta %d. As decisões de ritmo e pneus começam a pesar." % int(race.lap),
		"Situação da ponta: %s lidera. O intervalo imediato está em %.1f segundo(s)." % [str(leader.get("name", "Líder")), next_gap]
	]
	var choice: int = _rng.randi_range(0, variants.size() - 1)
	if int(_last_style.get("ambient", -1)) == choice:
		choice = (choice + 1) % variants.size()
	_last_style["ambient"] = choice
	_push(float(race.clock), "ANALISTA" if choice == 1 else "NARRADOR", variants[choice], false, "ambient")
	return true

func _driver_by_id(race, driver_id: int) -> Dictionary:
	for car in race.cars:
		if int(car.get("id", -1)) == driver_id:
			return car
	return {}

func _push(at: float, role: String, message: String, is_ours: bool, kind: String, car_id: int = -1) -> void:
	lines.append({"time": at, "role": role, "message": message, "team": is_ours, "kind": kind, "car_id": car_id})
	while lines.size() > MAX_LINES:
		lines.pop_front()

func add_driver_consultation(at: float, driver: String, impression: String, engineer_reply: String, car_id: int = -1) -> void:
	# Same instant in the timeline, but three distinct roles. No commands.
	_push(at, "CHEFE", "Para %s: Como sente o carro e os pneus?" % driver, true, "question_driver", car_id)
	_push(at, "PILOTO", "RÁDIO FICTÍCIO | %s: %s" % [driver, impression], true, "driver_consultation", car_id)
	_push(at, "ENGENHEIRO", "Para %s: %s" % [driver, engineer_reply], true, "engineer_comparison", car_id)

func add_stint_discussion(at: float, driver: String, opinion: String, engineer_reply: String, car_id: int = -1) -> void:
	# Fictional strategic conversation, driven by actual telemetry; no engine commands.
	_push(at, "CHEFE", "Para %s: Qual sua preferência para este stint?" % driver, true, "stint_question", car_id)
	_push(at, "PILOTO", "RÁDIO FICTÍCIO | %s: %s" % [driver, opinion], true, "stint_opinion", car_id)
	_push(at, "ENGENHEIRO", "Para %s: %s" % [driver, engineer_reply], true, "stint_analysis", car_id)

func add_soul_alignment(at: float, driver: String, decision: String, opinion: String, engineer_reply: String, car_id: int = -1) -> void:
	# Relação ficcional e restrita ao rádio interno, sem alteração na corrida.
	_push(at, "CHEFE", "%s, para %s. Isso não é uma ordem de box." % [decision, driver], true, "soul_alignment", car_id)
	_push(at, "PILOTO", "RÁDIO FICTÍCIO | %s: %s" % [driver, opinion], true, "soul_response", car_id)
	_push(at, "ENGENHEIRO", "Para %s: %s" % [driver, engineer_reply], true, "soul_engineer", car_id)

func add_soul_spontaneous(at: float, driver: String, message: String, engineer_reply: String, car_id: int = -1) -> void:
	# Reação espontânea ficcional baseada em eventos de corrida reais.
	# A resposta do engenheiro é consultiva; não configura pit/ritmo.
	_push(at, "PILOTO", "RÁDIO FICTÍCIO | %s: %s" % [driver, message], true, "soul_spontaneous", car_id)
	if engineer_reply != "":
		_push(at, "ENGENHEIRO", "Para %s: %s" % [driver, engineer_reply], true, "soul_spontaneous_reply", car_id)

func add_team_question(at: float, question: String, driver: String, reply: String, car_id: int = -1) -> void:
	# Somente o histórico do rádio muda. O motor não recebe comandos.
	_push(at, "CHEFE", "Para %s: %s" % [driver, question], true, "question", car_id)
	_push(at, "ENGENHEIRO", "Para %s: %s" % [driver, reply], true, "interactive_reply", car_id)

func formatted(filter_mode: int = 0, selected_car_id: int = -1) -> String:
	# 0 Todos; 1 Transmissão (TV); 2 Equipe; 3 Pilotos (rádios internos).
	# O rádio de outras equipes nunca é sintetizado nem revelado.
	var output: Array[String] = []
	for line in lines:
		var role: String = str(line["role"])
		var ours: bool = bool(line.get("team", false))
		# The optional individual filter never hides public broadcast messages.
		if filter_mode in [2, 3] and selected_car_id >= 0 and int(line.get("car_id", -1)) != selected_car_id:
			continue
		match filter_mode:
			1:
				if role in ["ENGENHEIRO", "PILOTO", "CHEFE"]:
					continue
			2:
				if not ours or role not in ["ENGENHEIRO", "PILOTO", "CHEFE", "BOXES"]:
					continue
			3:
				if role != "PILOTO" or not ours:
					continue
		var clock_s: int = int(float(line["time"]))
		var stamp := "%02d:%02d" % [clock_s / 60, clock_s % 60]
		var safe: String = str(line["message"]).replace("[", "(").replace("]", ")")
		output.append("[color=%s][b]%s · %s[/b][/color]  %s" % [str(CAST.get(role, "#e7efff")), stamp, role, safe])
	return "\n\n".join(output) if not output.is_empty() else "Aguardando acontecimentos da corrida."
