from apex_contracts import check_build_version
"""Offline checks for v0.5.3.1 HUD overhaul."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
main = (root/'scripts/main.gd').read_text(encoding='utf-8')
theme = (root/'scripts/apex_hud_theme.gd').read_text(encoding='utf-8')
project = (root/'project.godot').read_text(encoding='utf-8')
check_build_version(root, '0.5.3.1')
assert 'F1M / Motorsport Manager inspired controls' in main
for feature in (
    'player_card_strip', 'player_cards', '_rebuild_player_cards',
    '_create_player_card', '_refresh_player_cards', '_driver_initials',
    '_focus_driver', 'RACE CONTROL', 'PIT WALL / ESTRATÉGIA',
    'LIVE TIMING', 'telemetry_panel', 'analytics_chart',
):
    assert feature in main, f'Missing 0.5.3.1 HUD feature: {feature}'
for style in ('LineEdit', 'SpinBox', 'OptionButton', 'TabContainer', 'ProgressBar'):
    assert style in theme, style
print('PASS: v0.5.3.1 menu + race HUD structure present')
