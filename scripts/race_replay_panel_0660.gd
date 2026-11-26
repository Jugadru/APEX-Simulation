extends CanvasLayer
const Replay = preload("res://scripts/core/race_replay_0660.gd")
var host
var window: Window
var status: Label
var target: SpinBox
var path: LineEdit
var live_session
var live_running: bool = false
var live_modes: Dictionary = {}
var live_team: String
var live_selected: String
var live_championship: bool

func setup(scene) -> void:
	host=scene
	window=Window.new();window.title="APEX • Replay / F9";window.size=Vector2i(680,310)
	window.close_requested.connect(window.hide);add_child(window)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,18)
	window.add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(status)
	var row:=HBoxContainer.new();column.add_child(row)
	button(row,"Ver gravação atual",watch)
	button(row,"▶ / Ⅱ",toggle)
	button(row,"Voltar à corrida",leave)
	var seekrow:=HBoxContainer.new();column.add_child(seekrow)
	var label:=Label.new();label.text="Tick (5 por segundo):";seekrow.add_child(label)
	target=SpinBox.new();target.max_value=Replay.MAX_TICKS;target.step=1;target.custom_minimum_size.x=160;seekrow.add_child(target)
	button(seekrow,"Ir ao tick",seek_target)
	path=LineEdit.new();path.text="user://apex_replay_0660.apexreplay";column.add_child(path)
	var files:=HBoxContainer.new();column.add_child(files)
	button(files,"Exportar gravação",save)
	button(files,"Abrir replay",load_replay)
	var tip:=Label.new();tip.text="Replay não altera saves, inventário ou campeonato. Comandos esportivos ficam bloqueados.\nFeche esta janela para assistir com a HUD e as câmeras atuais.";tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(tip)
	window.hide()

func button(parent: Node, text: String, action: Callable) -> void:
	var b:=Button.new();b.text=text;b.pressed.connect(action);parent.add_child(b)

func open() -> void:
	status.text="F9 • Inicie uma corrida para gravar." if host.replay_session==null else "Gravação: %d ticks • %.1f s • %d comandos. %s" % [host.replay_session.end_tick,host.replay_session.end_tick*Replay.STEP,host.replay_session.commands.size(),host.replay_session.error]
	window.popup_centered()

func watch() -> void:
	if host.replay_session==null: return
	var replay=Replay.new()
	if not replay.load_live_session(host.replay_session):
		status.text=replay.error;return
	enter(replay)

func enter(replay) -> void:
	if live_session==null:
		live_session=host.replay_session
		live_running=host.race.running if host.race!=null else false
		live_modes=host.engineer_driver_modes.duplicate(true)
		live_team=host.team_control_mode
		live_selected=host.selected_team
		live_championship=host.championship_race_active
		if host.race!=null: host.race.running=false
	host.replay_session=replay;host.race=replay.race
	host.selected_team=host.race.team_name
	host.championship_race_active=false
	host.game_root.show();host.menu_root.hide()
	refresh_scene()
	status.text="Replay carregado. ▶ para assistir; Ir ao tick para avançar/retroceder."
	host.run_button.disabled=false

func refresh_scene() -> void:
	host.presentation.reset();host.presentation_race=null
	host.map_view.set_track_data(host.race.track)
	host.mini_map.set_track(host.map_view.route)
	if host.tactical_mini_map!=null:host.tactical_mini_map.set_track(host.map_view.route)
	host.world_view.set_track_data(host.map_view.route,host.race.track_name,host.race.teams,
		host.map_view.point_on_track(host.race.PIT_ENTRY_FRACTION),host.map_view.direction_on_track(host.race.PIT_ENTRY_FRACTION),
		host.map_view.point_on_track(host.race.PIT_EXIT_FRACTION),host.map_view.direction_on_track(host.race.PIT_EXIT_FRACTION))
	host._rebuild_player_cards()
	host.commentary.reset(int(host.race.rng.seed));host.last_radio_count=0
	# Reconstruct visible historical radio without playing archived speech.
	host.commentary.suppress_radio_audio = true
	host._update_game_ui()
	host.commentary.suppress_radio_audio = false
	host.next_ui=0.0

func toggle() -> void:
	if host.replay_session!=null and host.replay_session.playback:
		host.race.running=not host.race.running
		status.text="Replay em reprodução." if host.race.running else "Replay pausado."

func seek_target() -> void:
	if host.replay_session==null or not host.replay_session.playback:return
	if host.replay_session.seek(int(target.value)):
		host.race=host.replay_session.race
		refresh_scene()
		status.text="Replay no tick %d; estado verificado." % host.replay_session.tick
	else: status.text=host.replay_session.error if not host.replay_session.error.is_empty() else "Tick fora da gravação."

func leave() -> void:
	if host==null or host.replay_session==null or not host.replay_session.playback: return
	if live_session==null:
		host.race=null;host.replay_session=null;host._show_menu();return
	host.replay_session=live_session;host.race=live_session.race
	host.race.running=live_running
	host.engineer_driver_modes=live_modes;host.team_control_mode=live_team
	host.selected_team=live_selected;host.championship_race_active=live_championship
	live_session=null
	refresh_scene()
	status.text="Corrida original restaurada. Nenhum efeito do replay foi aplicado ao save."

func save() -> void:
	if host.replay_session==null:return
	status.text="Replay exportado: "+ProjectSettings.globalize_path(path.text) if host.replay_session.save_file(path.text) else host.replay_session.error

func load_replay() -> void:
	var replay=Replay.new()
	if not replay.load_file(path.text):status.text=replay.error;return
	enter(replay)
