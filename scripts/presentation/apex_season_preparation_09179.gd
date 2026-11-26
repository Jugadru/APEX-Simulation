extends VBoxContainer
## Presentation and explicit preparation intent. The championship controller
## alone creates seasons; team roster remains the existing 2012 data.
const Randomness = preload("res://scripts/core/race_randomness_068.gd")
const Portrait = preload("res://scripts/apex_portrait_local_2012.gd")
const ORANGE := Color("#ff8126")
const WHITE := Color("#f2f3f5")
const MUTED := Color("#adb4bf")
var host
var drafting := false
var team_name: Label
var team_rating: Label
var stripe: ColorRect
var names: Array[Label] = []
var ratings: Array[Label] = []
var portraits: Array[TextureRect] = []
var circuit: Label
var conditions: Label
var mode_status: Label
var create_button: Button
var roster_key := ""

static func find(scene_host):
	return scene_host.menu_root.find_child("SeasonPreparationPreview", true, false) if is_instance_valid(scene_host.menu_root) else null

func setup(scene_host) -> void:
	host = scene_host
	name = "SeasonPreparationPreview"
	add_theme_constant_override("separation", 9)
	host._label(self, "01 / EQUIPE E PILOTOS", 14, ORANGE)
	stripe = ColorRect.new()
	stripe.custom_minimum_size.y = 5
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stripe)
	team_name = host._label(self, "", 26, WHITE)
	team_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team_rating = host._label(self, "", 14, MUTED)
	for i in range(2):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		add_child(row)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(68,72)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)
		portraits.append(portrait)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var title: Label = host._label(info, "", 20, WHITE)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		names.append(title)
		ratings.append(host._label(info, "", 14, MUTED))
	var note: Label = host._label(self, "Dupla oficial de 2012 • vinculada à equipe.", 13, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(HSeparator.new())
	host._label(self, "02 / PRÓXIMA CORRIDA", 14, ORANGE)
	circuit = host._label(self, "", 19, WHITE)
	circuit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conditions = host._label(self, "", 14, MUTED)
	conditions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_status = host._label(self, "", 14, ORANGE)
	mode_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func prepare_new() -> void:
	host._single_race_mode()
	drafting = true
	host.track_picker.select(0)
	host._on_track_selected(0)
	host.seed_picker.value = Randomness.automatic_seed(int(host.seed_picker.value))
	host.weather_mode_picker.select(0)
	host.pit_test_picker.select(0)
	host._update_championship_menu()

func prepare_gp(generate_seed: bool = true) -> void:
	drafting = false
	host._single_race_mode()
	if generate_seed:
		host.seed_picker.value = Randomness.automatic_seed(int(host.seed_picker.value))

func confirm_new() -> void:
	if not drafting: return
	var warning := "\nA temporada salva será substituída. As melhorias da oficina serão mantidas." if host.championship.has_season() else "\nA temporada começa na primeira etapa do calendário."
	host.championship_new_dialog.dialog_text = "Criar temporada 2012 com %s?\nSemente: %d.%s" % [host.selected_team, int(host.seed_picker.value), warning]
	host._ask_new_championship()

func refresh() -> void:
	if not is_instance_valid(create_button): return
	if host.championship_mode: drafting = false
	host.track_picker.disabled = drafting or host.championship_mode
	host.start_button.visible = not drafting
	create_button.visible = drafting
	if drafting:
		host.championship_status.text = "NOVA TEMPORADA • semente gerada automaticamente; você pode editá-la. O calendário começa em Melbourne. Nenhum save é alterado até confirmar."
	if roster_key != host.selected_team:
		roster_key = host.selected_team
		for team in host.teams:
			if str(team.name) != roster_key: continue
			team_name.text = roster_key
			stripe.color = Color(str(team.color))
			team_rating.text = "Carro base: %s/100 (atributo do jogo)" % str(team.car)
			for i in range(2):
				var driver: Dictionary = team.drivers[i]
				names[i].text = str(driver.name)
				ratings[i].text = "Habilidade: %s/100" % str(driver.skill)
				portraits[i].texture = Portrait.get_texture(str(driver.name), "hud")
				portraits[i].visible = portraits[i].texture != null
			break
	if host.championship_mode and host.championship.is_complete():
		circuit.text = "Temporada concluída"
		conditions.text = "Todas as etapas disputadas. Consulte a classificação final."
		mode_status.text = "CAMPEONATO ENCERRADO"
		return
	var track: Dictionary = host.season_tracks[host.selected_track_index]
	circuit.text = str(track.name)
	conditions.text = "%s voltas • %.3f km/volta\n%s • %s\nSemente: %d" % [str(track.laps), float(track.lap_km), host.weather_mode_picker.get_item_text(host.weather_mode_picker.selected), host.team_control_mode, int(host.seed_picker.value)]
	mode_status.text = "RASCUNHO • confirme para criar" if drafting else ("CAMPEONATO • calendário vinculado" if host.championship_mode else "GP AVULSO • não pontua no campeonato")
