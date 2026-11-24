extends Control
## Entry menu: live features and the recovered roadmap are labelled separately.
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

func setup(scene_host) -> void:
    host = scene_host
    name = "FrontDoor"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    host.menu_root.add_child(self)
    var bg := ColorRect.new()
    bg.color = INK
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 36)
    add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    margin.add_child(scroll)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 20)
    scroll.add_child(content)
    var header := HBoxContainer.new()
    content.add_child(header)
    var brand := label(header, "APEX  /  MOTORSPORT MANAGER", 42, ORANGE)
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    brand.custom_minimum_size.y = 90
    label(content, "SEU TIME. SUAS DECISÕES. SUA HISTÓRIA.", 14, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var line := HSeparator.new()
    content.add_child(line)
    landing = VBoxContainer.new()
    landing.add_theme_constant_override("separation", 16)
    content.add_child(landing)
    var top := HBoxContainer.new()
    landing.add_child(top)
    var title := label(top, "CENTRAL DE COMANDO", 28, WHITE)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.autowrap_mode = TextServer.AUTOWRAP_OFF
    label(top, "TEMPORADA 2012   /   20 CIRCUITOS", 13, ORANGE).autowrap_mode = TextServer.AUTOWRAP_OFF
    mode_grid = GridContainer.new()
    mode_grid.columns = 2
    mode_grid.add_theme_constant_override("h_separation", 16)
    mode_grid.add_theme_constant_override("v_separation", 16)
    landing.add_child(mode_grid)
    mode_card("01", "STANDARD", "CHEFE DE EQUIPE", "Conduza a temporada, desenvolva o carro e comande seus dois pilotos.", "JOGAR", open_standard)
    mode_card("02", "SIMULATION", "PROPRIETÁRIO • PLANEJADO", "A visão de proprietário e contratação do chefe de equipe faz parte da expansão planejada.", "VER MODO", show_simulation)
    mode_card("03", "SANDBOX", "GP PERSONALIZADO DISPONÍVEL", "Escolha equipe, circuito, clima e semente. Criação e compra de equipes ainda estão planejadas.", "CONFIGURAR GP", open_sandbox)
    mode_card("04", "CENÁRIOS", "TREINOS DISPONÍVEIS", "Experimente condições de corrida preparadas. Desafios históricos com objetivos estão planejados.", "ESCOLHER CENÁRIO", show_scenarios)
    var quick := HBoxContainer.new()
    quick.add_theme_constant_override("separation", 12)
    landing.add_child(quick)
    continue_button = button(quick, "CONTINUAR TEMPORADA", continue_season)
    resume_race_button = button(quick, "VOLTAR À CORRIDA", resume_race)
    button(quick, "CENTRAL / P&D", host._open_garage)
    button(quick, "EQUIPE / SOUL STAFF", host._open_staff)
    detail = VBoxContainer.new()
    detail.add_theme_constant_override("separation", 20)
    content.add_child(detail)
    button(detail, "VOLTAR AO MENU", show_home)
    detail_title = label(detail, "", 30, WHITE)
    detail_text = label(detail, "", 17, MUTED)
    detail_actions = VBoxContainer.new()
    detail_actions.add_theme_constant_override("separation", 14)
    detail.add_child(detail_actions)
    # The menu version must reflect the exported .pck project identity.
    var build_title: String = str(ProjectSettings.get_setting("application/config/name", "APEX Motorsport Manager"))
    label(content, "%s    /    MOTOR DE CORRIDA COMPARTILHADO" % build_title.get_slice(" — ", 0).to_upper(), 11, MUTED)
    resized.connect(_responsive)
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
    node.custom_minimum_size.y = 44
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.add_theme_stylebox_override("normal", MenuSkin.panel(Color("#222831"), 5, EDGE, 12))
    node.add_theme_stylebox_override("hover", MenuSkin.panel(Color("#34302a"), 5, ORANGE, 12))
    node.add_theme_stylebox_override("pressed", MenuSkin.panel(Color("#6c3c1c"), 5, ORANGE, 12))
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
    label(column, number + "   /   " + status, 11, ORANGE)
    label(column, title, 24, WHITE)
    var body := label(column, description, 14, MUTED)
    body.custom_minimum_size.y = 44
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    button(column, cta, action)

func _responsive() -> void:
    mode_grid.columns = 1 if size.x < 850 else 2

func show_home() -> void:
    host.menu_root.get_node("MenuCard").hide()
    show()
    landing.show()
    detail.hide()
    continue_button.disabled = not host.championship.has_season()
    resume_race_button.disabled = not host.navigation.can_resume(host)
    if host.championship.has_season():
        continue_button.text = "VER TEMPORADA CONCLUÍDA" if host.championship.is_complete() else "CONTINUAR TEMPORADA"

func configuration(title: String) -> void:
    if configuration_title != null:
        configuration_title.text = title
    hide()
    host.menu_root.get_node("MenuCard").show()
    host.menu_scroll.scroll_vertical = 0
    host._update_championship_menu()
    host._layout_ui()

func control_mode(index: int) -> void:
    host.pre_race_team_mode_picker.select(index)
    host._select_pre_race_team_mode(index)

func open_standard() -> void:
    control_mode(0)
    configuration("STANDARD / PREPARAÇÃO DA TEMPORADA")

func continue_season() -> void:
    host._resume_championship()
    configuration("STANDARD / TEMPORADA SALVA")
    if host.championship.is_complete():
        host._show_championship_table()

func open_sandbox() -> void:
    host._single_race_mode()
    host.weather_mode_picker.select(0)
    host.pit_test_picker.select(0)
    control_mode(0)
    configuration("SANDBOX / GP PERSONALIZADO")

func resume_race() -> void:
    host._resume_live_race()

func show_detail(title: String, description: String) -> void:
    landing.hide()
    detail.show()
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
    host._single_race_mode()
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
