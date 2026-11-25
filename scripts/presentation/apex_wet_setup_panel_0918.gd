extends RefCounted
## Compact setup section in the existing scrollable pre-race screen.
const WetSetup = preload("res://scripts/core/race_wet_setup_0918.gd")
static func build(host, parent: Node, white: Color, muted: Color) -> void:
	host.wet_setup_pickers.clear()
	host.wet_setup_labels.clear()
	host._label(parent,"ACERTO CLIMÁTICO / WET WEATHER SETUPS",16,white)
	for slot in range(2):
		var title: Label=host._label(parent,"Piloto %d" % (slot+1),14,white)
		host.wet_setup_labels.append(title)
		var picker: OptionButton=host._option(parent,WetSetup.LABELS,func(_index):pass)
		picker.name="WetSetupDriver%d" % (slot+1)
		picker.fit_to_longest_item=false
		picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		picker.select(0)
		picker.tooltip_text="Acerto fixo para o GP: asa, freio e suspensão. Não troca pneus nem altera a previsão."
		host.wet_setup_pickers.append(picker)
	var note: Label=host._label(parent,"Seco: precisão e suspensão firme. Misto: compromisso. Chuva: mais asa, freio conservador e suspensão macia; perde desempenho se secar. A escolha permanece até você alterá-la e é travada na largada.",12,muted)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	refresh(host)

static func refresh(host) -> void:
	if host.wet_setup_labels.size()!=2: return
	for team in host.teams:
		if str(team.get("name",""))!=host.selected_team: continue
		var drivers: Array=team.get("drivers",[])
		for i in range(2):
			host.wet_setup_labels[i].text=str(drivers[i].get("name","Piloto %d" % (i+1))) if i<drivers.size() else "Piloto %d" % (i+1)
		return
