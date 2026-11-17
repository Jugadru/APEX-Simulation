extends RefCounted
## APEX 0.6.2.3 — extracted responsibility; main.gd remains the scene host.
## The wrapper preserves legacy signals and callbacks.

const GREEN := Color("#46dcc0")
const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")
static func _set_radio_filter(host, index: int) -> void:
	host.radio_filter = clampi(index, 0, 3)
	for i in range(host.radio_filter_buttons.size()):
		var button: Button = host.radio_filter_buttons[i]
		var active: bool = i == host.radio_filter
		button.add_theme_stylebox_override("normal", HudThemeScript.panel(Color("#18516a") if active else Color("#10283c"), 7, GREEN if active else Color("#31546b"), 4))
	host._render_commentary()


static func _render_commentary(host) -> void:
	if host.radio_log == null or host.commentary == null:
		return
	host.radio_log.text = host.commentary.formatted(host.radio_filter)

