extends Window
const Perf = preload("res://scripts/debug/apex_perf_trace_0657.gd")
const UI = preload("res://scripts/apex_management_style.gd")
var host
var report: Tree
var recording: CheckButton
var status: Label
var export_notice: Label
var timer := 0.0
func _ready() -> void:
	title = "APEX / Performance Profiler 1.0"
	size = Vector2i(1060,700)
	min_size = Vector2i(700,480)
	unresizable = false
	transient = true
	theme = UI.theme()
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var body := UI.column(panel,10)
	UI.label(body,"PERFORMANCE PROFILER 1.0 / F8",24,UI.ORANGE)
	var row := UI.row(body,8)
	recording = CheckButton.new()
	recording.text = "Coletar medições"
	recording.toggled.connect(func(value): Perf.set_enabled(value); refresh())
	row.add_child(recording)
	UI.button(row,"Limpar amostras",func(): Perf.reset(context()); refresh())
	UI.button(row,"Exportar JSON",export_report)
	UI.button(row,"Fechar painel",hide_panel)
	status = UI.label(body,"",14,UI.MUTED)
	export_notice = UI.label(body,"JSON exportado para a pasta de dados do jogo.",14,UI.MUTED)
	report = Tree.new()
	report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report.columns = 5
	report.hide_root = true
	report.column_titles_visible = true
	for index in range(5):
		report.set_column_title(index,["Seção inclusiva","Chamadas","Média ms","Máximo ms","Total ms"][index])
		report.set_column_expand(index,index==0)
		report.set_column_custom_minimum_width(index,340 if index==0 else 125)
	body.add_child(report)
	UI.label(body,"Tempos CPU inclusivos: pai e filhos se sobrepõem. FPS/memória são monitores Godot; sem tempo GPU ou RSS. Fechar o painel mantém a coleta escolhida. Nenhuma configuração é salva.",14,UI.MUTED)
	close_requested.connect(hide_panel)
	set_process(false)
func context() -> Dictionary:
	if host == null or host.race == null: return {"mode":"management"}
	return {"scope":"process aggregate; reset before comparing races","mode":"live_race","track":host.race.track_name,"seed":host.race.rng.seed,"weather":host.race.weather_mode,"cars":host.race.cars.size(),"sim_speed":host.sim_speed,"render_mode":host.render_mode}
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
	status.text = "%s • janela ativa %.1fs • FPS %s • frame %s ms • memória Godot %s MiB" % ["COLETANDO" if Perf.enabled else "DESLIGADO",data.active_wall_seconds,str(m.fps),str(m.frame_ms),"N/D" if m.godot_static_bytes==null else "%.1f" % (float(m.godot_static_bytes)/1048576)]
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

func export_report() -> void:
	var path := "user://apex_performance_0657.json"
	var error := Perf.export_json(path)
	export_notice.text = "Relatório salvo: " + ProjectSettings.globalize_path(path) if error==OK else "Falha ao exportar: " + error_string(error)
