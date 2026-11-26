extends Window
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
const UI = preload("res://scripts/apex_management_style.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const QUALITY_LABELS := {
	"grid_size_changed":"Tamanho do grid", "invalid_driver_id":"ID inválido",
	"duplicate_driver_id":"ID duplicado", "invalid_position":"Posição inválida",
	"duplicate_position":"Posição duplicada", "nonfinite_state":"Estado não finito",
	"tyre_wear_out_of_range":"Desgaste fora da faixa", "negative_pit_time":"Tempo de box negativo",
	"negative_gap":"Gap negativo", "reverse_on_track":"Recuo em pista"
}
var host
var report: Tree
var quality_tree: Tree
var recording: CheckButton
var status: Label
var speed_status: Label
var quality_status: Label
var export_notice: Label
var tabs: TabContainer
var timer := 0.0

func _ready() -> void:
	title = "APEX / Race Quality Center 1.0"
	size = Vector2i(1060,700)
	min_size = Vector2i(700,480)
	unresizable = false
	transient = true
	theme = UI.theme()
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var body := UI.column(panel,10)
	UI.label(body,"RACE QUALITY CENTER / F8",24,UI.ORANGE)
	var row := UI.row(body,8)
	recording = CheckButton.new()
	recording.text = "Coletar CPU"
	recording.toggled.connect(func(value): Perf.set_enabled(value); refresh())
	row.add_child(recording)
	UI.button(row,"Limpar CPU",func(): Perf.reset(context()); refresh())
	UI.button(row,"JSON CPU",export_report)
	UI.button(row,"JSON qualidade",func(): export_quality())
	UI.button(row,"Fechar",hide_panel)
	status = UI.label(body,"",14,UI.MUTED)
	speed_status = UI.label(body,"",14,UI.MUTED)
	export_notice = UI.label(body,"Relatórios exportados para a pasta de dados do jogo.",14,UI.MUTED)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	var cpu := VBoxContainer.new()
	cpu.name = "Desempenho"
	tabs.add_child(cpu)
	report = _tree(cpu, ["Seção inclusiva","Chamadas","Média ms","Máximo ms","Total ms"], [220,95,95,95,95])
	UI.label(cpu,"Escopos CPU inclusivos (não somar). FPS e memória estática do Godot; não são tempo de GPU nem RSS. Fechar mantém a coleta; limpar afeta somente o profiler.",13,UI.MUTED)
	var quality := VBoxContainer.new()
	quality.name = "Integridade esportiva"
	tabs.add_child(quality)
	quality_status = UI.label(quality,"",14,UI.MUTED)
	quality_tree = _tree(quality, ["Categoria","Tick / total","Piloto","Evidência"], [210,80,60,180])
	UI.label(quality,"Ocorrências observadas, não nota de qualidade. Amostras recentes limitadas a 64; zero ocorrências não comprova uma corrida perfeita.",13,UI.MUTED)
	tabs.tab_changed.connect(func(_index): refresh())
	close_requested.connect(hide_panel)
	set_process(false)

func _tree(parent: Node, headings: Array, widths: Array) -> Tree:
	var node := Tree.new()
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.columns = headings.size()
	node.hide_root = true
	node.column_titles_visible = true
	for index in range(headings.size()):
		node.set_column_title(index, str(headings[index]))
		node.set_column_expand(index, index == 0 or index == headings.size()-1)
		node.set_column_custom_minimum_width(index, int(widths[index]))
	parent.add_child(node)
	return node

func _active_race() -> bool:
	return host != null and host.race != null and host.game_root != null and host.game_root.visible

func context() -> Dictionary:
	if not _active_race(): return {"mode":"management"}
	var mode: String = "replay" if host.replay_session != null and host.replay_session.playback else "live_race"
	return {"scope":"process aggregate; reset before comparing races","mode":mode,"track":host.race.track_name,"seed":host.race.rng.seed,"weather":host.race.weather_mode,"cars":host.race.cars.size(),"sim_speed":host.sim_speed,"render_mode":host.render_mode}

# Read only the existing session/observer; no new simulation work or capture loop.
func session_snapshot(include_quality: bool = true) -> Dictionary:
	var data: Dictionary = {"state":"inactive","requested_x":null,"effective_x":null,
		"cpu_backlog_limited":null,"pending_sim_seconds":null,"tick":null,
		"quality_state":"unavailable","quality":null,"replay_divergence_tick":null}
	if not _active_race():
		return data
	var session = host.replay_session
	data.requested_x = host.sim_speed
	data.state = "finished" if host.race.finished else ("running" if host.race.running else "paused")
	if session == null or session.race != host.race:
		return data
	data.mode = "replay" if session.playback else "live"
	data.tick = session.tick
	if session.first_divergence >= 0:
		data.replay_divergence_tick = session.first_divergence
		data.state = "diverged"
	if data.state == "running":
		data.cpu_backlog_limited = session.cpu_limited
		data.pending_sim_seconds = session.accumulator
		if host.effective_speed_sample_valid and host.presentation_race == host.race:
			data.effective_x = host.effective_speed_x
	if not include_quality:
		return data
	var q: Dictionary = session.racecraft_audit.quality_report()
	data.quality = q
	if not session.racecraft_audit_enabled:
		data.quality_state = "disabled"
	elif int(q.observed_ticks) == 0:
		data.quality_state = "not_observed"
	elif q.coverage != "from_start" or int(q.end_tick) != session.tick:
		data.quality_state = "partial"
	else:
		data.quality_state = "observed"
	return data

func quality_export_snapshot() -> Dictionary:
	var session_data: Dictionary = session_snapshot()
	# Export on demand only; no extra work on the visible panel refresh.
	if session_data.quality != null:
		session_data["behaviour"] = host.replay_session.racecraft_audit.behaviour_report()
	return {"schema":"APEX_QUALITY_CENTER_0923","game_version":ProjectSettings.get_setting("application/config/version"),
		"simulation_revision":Replay.SIMULATION_REVISION,
		"session":session_data,"profiler":Perf.snapshot(),
		"limitations":["Profiler is process-wide, not necessarily the current race.","Quality counts are observations, not unique incidents or certification.","Effective acceleration is the last completed measurement window; no GPU time or native benchmark."]}

func open_panel(owner_host) -> void:
	host = owner_host
	Perf.metadata["latest_panel_context"] = context()
	recording.set_pressed_no_signal(Perf.enabled)
	popup_centered()
	set_process(true)
	refresh()

func hide_panel() -> void:
	hide()
	set_process(false)

func _process(delta: float) -> void:
	timer -= delta
	if timer<=0:
		timer = 0.5
		refresh()

func refresh() -> void:
	var data := Perf.snapshot()
	var m: Dictionary = data.monitors
	status.text = "%s • %.1fs • FPS %s • CPU quadro %s ms • memória estática %s MiB" % ["COLETANDO CPU" if Perf.enabled else "CPU DESLIGADA",data.active_wall_seconds,str(m.fps) if m.fps!=null else "N/D",str(m.frame_ms) if m.frame_ms!=null else "N/D","N/D" if m.godot_static_bytes==null else "%.1f" % (float(m.godot_static_bytes)/1048576)]
	var s: Dictionary = session_snapshot(tabs.current_tab == 1)
	if s.state == "inactive":
		speed_status.text = "Sem corrida ativa."
	else:
		var state_names: Dictionary = {"running":"em andamento","paused":"pausada","finished":"finalizada","diverged":"replay divergente"}
		var effective: String = "N/D" if s.effective_x == null else "%.2f×" % float(s.effective_x)
		speed_status.text = "%s • %s • solicitada %.0f× • efetiva %s" % [str(s.get("mode","sessão")).to_upper(),state_names.get(s.state,s.state),float(s.requested_x),effective]
		if s.pending_sim_seconds != null:
			speed_status.text += " • demanda %.2fs%s" % [float(s.pending_sim_seconds)," • limite de backlog" if s.cpu_backlog_limited else ""]
		if s.replay_divergence_tick != null:
			speed_status.text += " • divergência no tick %d" % int(s.replay_divergence_tick)
	# Only rebuild the visible tab, even while the F8 window remains open.
	if tabs.current_tab == 0:
		_refresh_cpu(data)
	else:
		_refresh_quality(s)

func _refresh_cpu(data: Dictionary) -> void:
	report.clear()
	var root_item := report.create_item()
	for key in data.sections:
		var sample: Dictionary = data.sections[key]
		var item := report.create_item(root_item)
		var cells := [str(key),str(sample.calls),"%.4f" % sample.mean_ms,"%.4f" % sample.max_ms,"%.2f" % sample.total_ms]
		for index in range(5):
			item.set_text(index,cells[index])
			item.set_tooltip_text(index,cells[index])
	if data.sections.is_empty():
		var item := report.create_item(root_item)
		item.set_text(0,"Ative a coleta e execute uma corrida.")

func _refresh_quality(s: Dictionary) -> void:
	quality_tree.clear()
	var root_item := quality_tree.create_item()
	var q: Variant = s.quality
	if q == null:
		quality_status.text = "Sem diagnóstico de corrida disponível."
		return
	var labels: Dictionary = {"disabled":"Observador desativado — histórico apenas","not_observed":"Aguardando observações","partial":"Cobertura parcial","observed":"Observado desde o início"}
	var total: int = 0
	for value in q.counts.values(): total += int(value)
	var trailing: int = maxi(0, int(s.tick)-int(q.end_tick))
	quality_status.text = "%s • %s • seed %s • ticks %d–%d / sessão %d • %d observados • %d lacunas • %d ocorrências" % [labels.get(s.quality_state,s.quality_state),str(q.track_code),str(q.seed),int(q.start_tick),int(q.end_tick),int(s.tick),int(q.observed_ticks),int(q.missed_ticks)+trailing,total]
	var counts_item := quality_tree.create_item(root_item)
	counts_item.set_text(0,"Contadores por categoria")
	for key in q.counts:
		var item := quality_tree.create_item(counts_item)
		item.set_text(0,str(QUALITY_LABELS.get(key,key)))
		item.set_text(1,str(q.counts[key]))
	var samples_item := quality_tree.create_item(root_item)
	samples_item.set_text(0,"Amostras recentes (%d)" % q.samples.size())
	for i in range(q.samples.size()-1,-1,-1):
		var sample: Dictionary = q.samples[i]
		var item := quality_tree.create_item(samples_item)
		var detail: String = "%s • %s: %s" % [str(sample.condition),str(sample.field),str(sample.value)]
		var cells: Array = [str(QUALITY_LABELS.get(sample.kind,sample.kind)),str(sample.tick),str(sample.driver_id),detail]
		for col in range(cells.size()):
			item.set_text(col,cells[col])
			item.set_tooltip_text(col,cells[col])

func export_report() -> void:
	var path := "user://apex_performance_0657.json"
	var error := Perf.export_json(path)
	export_notice.text = "Relatório salvo: " + ProjectSettings.globalize_path(path) if error==OK else "Falha ao exportar: " + error_string(error)

func export_quality(path: String = "user://apex_quality_0923.json") -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		var open_error := FileAccess.get_open_error()
		export_notice.text = "Falha ao exportar: " + error_string(open_error)
		return open_error
	file.store_string(JSON.stringify(quality_export_snapshot(),"  "))
	file.flush()
	var result := file.get_error()
	export_notice.text = "Relatório salvo: " + ProjectSettings.globalize_path(path) if result==OK else "Falha ao exportar: " + error_string(result)
	return result
