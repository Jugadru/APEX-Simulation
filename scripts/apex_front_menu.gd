extends Control
## Entry menu: live features and the recovered roadmap are labelled separately.
const Prep = preload("res://scripts/presentation/apex_season_preparation_09179.gd")
const Layout = preload("res://scripts/presentation/apex_main_menu_layout_09178.gd")
const MenuSkin = preload("res://scripts/apex_hud_theme.gd")
const INK := Color("#090b0e")
const PANEL := Color("#15191f")
const EDGE := Color("#303741")
const ORANGE := Color("#ff8126")
const WHITE := Color("#f2f3f5")
const MUTED := Color("#aeb6c1")
const PRESETS := [
    {"title":"SILVERSTONE", "detail":"Clima variável • leitura da pista e pneus", "code":"GBR", "weather":2, "seed":6403},
    {"title":"MONZA", "detail":"Pista seca • ritmo e janela de parada", "code":"ITA", "weather":1, "seed":6503},
    {"title":"SINGAPURA", "detail":"Clima variável • gestão de stint e tráfego", "code":"SIN", "weather":2, "seed":6603}
]
var host
var landing: VBoxContainer
var detail: VBoxContainer
var detail_title: Label
var detail_text: Label
var detail_actions: VBoxContainer
var mode_grid: GridContainer
var continue_button: Button
var resume_race_button: Button
var configuration_title: Label
var body: BoxContainer
var operations_row: BoxContainer
var home_scroll: ScrollContainer
var session_title: Label
var session_info: Label
var race_info: Label

func setup(scene_host) -> void:
    host = scene_host
    name = "FrontDoor"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    host.menu_root.add_child(self)
    Layout.build(self)
    resized.connect(_responsive)
    visibility_changed.connect(refresh_status)
    call_deferred("_responsive")
    show_home()

func label(parent: Node, value: String, font_size: int, color: Color) -> Label:
    var node := Label.new()
    node.text = value
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", color)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(node)
    return node

func button(parent: Node, value: String, action: Callable) -> Button:
    var node := Button.new()
    node.text = value
    node.custom_minimum_size.y = 52
    node.add_theme_font_size_override("font_size", 17)
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.add_theme_stylebox_override("normal", MenuSkin.panel(Color("#222831"), 5, EDGE, 12))
    node.add_theme_stylebox_override("hover", MenuSkin.panel(Color("#34302a"), 5, ORANGE, 12))
    node.add_theme_stylebox_override("pressed", MenuSkin.panel(Color("#6c3c1c"), 5, ORANGE, 12))
    node.add_theme_stylebox_override("disabled", MenuSkin.panel(Color("#14171c"), 5, EDGE, 12))
    node.add_theme_color_override("font_disabled_color", Color("#8b929e"))
    node.add_theme_stylebox_override("focus", MenuSkin.panel(Color(0,0,0,0), 5, ORANGE, 2))
    node.pressed.connect(action)
    parent.add_child(node)
    return node

func mode_card(number: String, title: String, status: String, description: String, cta: String, action: Callable) -> void:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", MenuSkin.panel(PANEL, 6, EDGE, 20))
    mode_grid.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    panel.add_child(column)
    label(column, number + "   /   " + status, 14, ORANGE)
    label(column, title, 30, WHITE)
    var body := label(column, description, 18, MUTED)
    body.custom_minimum_size.y = 50
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var cta_button := button(column, cta, action)
    if title == "STANDARD": Layout.primary(cta_button)

func _responsive() -> void:
    body.vertical = size.x < 1050
    operations_row.vertical = size.x < 620
    mode_grid.columns = 1 if size.x < 620 else 2

func show_home() -> void:
    host.menu_root.get_node("MenuCard").hide()
    show()
    landing.show()
    detail.hide()
    home_scroll.scroll_vertical = 0
    refresh_status()

func refresh_status() -> void:
    if not is_instance_valid(continue_button) or not is_visible_in_tree(): return
    var saved: bool = host.championship.has_season()
    continue_button.disabled = not saved
    continue_button.text = "VER TEMPORADA CONCLUÍDA" if saved and host.championship.is_complete() else "CONTINUAR TEMPORADA"
    if saved:
        var state: Dictionary = host.championship.state
        session_title.text = str(state.get("team", "TEMPORADA 2012"))
        var calendar: Array = state.get("calendar", [])
        var done: int = int(state.get("round_index", 0))
        var next: Dictionary = host.championship.next_round()
        session_info.text = "%d/%d etapas concluídas%s" % [done, calendar.size(), " • Próxima: " + str(next.get("name", "")) if not next.is_empty() else " • Temporada concluída"]
    else:
        session_title.text = "TEMPORADA 2012"
        session_info.text = "Nenhuma temporada salva. Prepare sua equipe para iniciar o campeonato."
    var resumable: bool = host.navigation.can_resume(host)
    resume_race_button.disabled = not resumable
    race_info.text = str(host.race.track.get("name", "GP atual")) + (" • concluído" if host.race.finished else " • sessão em memória") if resumable else "Nenhuma corrida disponível para retomar."

func configuration(title: String) -> void:
    if configuration_title != null:
        configuration_title.text = title
    hide()
    host.menu_root.get_node("MenuCard").show()
    host.menu_scroll.scroll_vertical = 0
    host._update_championship_menu()
    host._layout_ui()

# Returning from P&D is not a request to create a new season or reset a GP.
func return_to_preparation() -> void:
    var was_preparing: bool = host.menu_root.get_node("MenuCard").visible
    var scroll: int = host.menu_scroll.scroll_vertical
    var title: String = "GP AVULSO / PREPARAÇÃO"
    if was_preparing and is_instance_valid(configuration_title):
        title = configuration_title.text
    elif host.championship_mode:
        title = "STANDARD / TEMPORADA SALVA"
    elif Prep.find(host).drafting:
        title = "STANDARD / PREPARAÇÃO DA TEMPORADA"
    host._show_menu()
    configuration(title)
    if was_preparing:
        host.menu_scroll.set_deferred("scroll_vertical", scroll)

func control_mode(index: int) -> void:
    host.pre_race_team_mode_picker.select(index)
    host._select_pre_race_team_mode(index)

func open_standard() -> void:
    Prep.find(host).prepare_new()
    control_mode(0)
    configuration("STANDARD / PREPARAÇÃO DA TEMPORADA")

func continue_season() -> void:
    host._resume_championship()
    configuration("STANDARD / TEMPORADA SALVA")
    if host.championship.is_complete():
        host._show_championship_table()

func open_sandbox() -> void:
    Prep.find(host).prepare_gp()
    host.weather_mode_picker.select(0)
    host.pit_test_picker.select(0)
    control_mode(0)
    configuration("SANDBOX / GP PERSONALIZADO")

func resume_race() -> void:
    host._resume_live_race()

func show_detail(title: String, description: String) -> void:
    landing.hide()
    detail.show()
    home_scroll.scroll_vertical = 0
    detail_title.text = title
    detail_text.text = description
    for child in detail_actions.get_children():
        detail_actions.remove_child(child)
        child.queue_free()

func show_simulation() -> void:
    show_detail("SIMULATION / VISÃO DE PROPRIETÁRIO", "Planejado: ser proprietário, contratar um chefe de equipe e delegar as operações. Standard e Simulation usarão o mesmo motor de corrida.\n\nDisponível hoje: delegação de ritmo, KERS e boxes ao STAFF. Você pode experimentar essa função em um GP avulso; ela ainda não representa o modo proprietário completo.")
    button(detail_actions, "EXPERIMENTAR GP COM STAFF AUTOMÁTICO", open_delegated_gp)

func open_delegated_gp() -> void:
    open_sandbox()
    control_mode(1)
    configuration("GP AVULSO / DELEGAÇÃO AO STAFF")

func show_scenarios() -> void:
    show_detail("CENÁRIOS / LABORATÓRIO DE CORRIDA", "Treinos com clima e semente definidos, usando o motor atual. Você pode ajustar a equipe antes de largar.\nOs desafios históricos com metas, criação e compra de equipes pertencem ao planejamento futuro.")
    for index in range(PRESETS.size()):
        var preset: Dictionary = PRESETS[index]
        button(detail_actions, str(preset["title"]) + "  /  " + str(preset["detail"]), apply_preset.bind(index))

func apply_preset(index: int) -> void:
    if index < 0 or index >= PRESETS.size():
        return
    var preset: Dictionary = PRESETS[index]
    Prep.find(host).prepare_gp()
    for track_index in range(host.season_tracks.size()):
        if str(host.season_tracks[track_index].get("code", "")) == str(preset["code"]):
            host.track_picker.select(track_index)
            host._on_track_selected(track_index)
            break
    host.weather_mode_picker.select(int(preset["weather"]))
    host.seed_picker.value = int(preset["seed"])
    host.pit_test_picker.select(0)
    control_mode(0)
    host._update_weather_briefing()
    configuration("TREINO / " + str(preset["title"]))
