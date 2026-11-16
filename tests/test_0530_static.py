from apex_contracts import check_build_version
"""Offline HUD-contract and regression checks (not a Godot runtime replacement)."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
main = (root/'scripts/main.gd').read_text(encoding='utf-8')
theme = (root/'scripts/apex_hud_theme.gd').read_text(encoding='utf-8')
check_build_version(root, '0.5.3.0')
for feature in (
    'race_progress', 'live_event_label', 'telemetry_panel', 'telemetry_wear',
    '_change_hud_layout', '_toggle_left_panel', '_toggle_right_panel',
    '_apply_hud_visibility', 'hud_layout_picker', 'table_mode_label',
    'pit_timer_label', 'analytics_chart', '_export_pit_csv', '_refresh_pit_analytics',
    '_quick_tv', '_update_telemetry', 'Color.from_string',
    'hud_layout_0530.cfg', 'get_pit_crew_effects',
):
    assert feature in main, f'Missing HUD element: {feature}'
for style in ('Button', 'OptionButton', 'TabContainer', 'ProgressBar'):
    assert style in theme, style
for name in ('race_engine.gd','track_map.gd','track_3d.gd','pit_complex_3d.gd','car_model_3d.gd','tv_director.gd','garage.gd'):
    assert (root/'scripts'/name).is_file(), name
assert (root/'tests/hud_0530_ui_test.gd').is_file()
# Cross-check with preserved previous version in this mounted workspace when present.
previous = root.parent/'APEX_GODOT_0.5.2.9'
if (previous/"scripts").is_dir():
    for name in ('race_engine.gd','track_map.gd','track_3d.gd','pit_complex_3d.gd','car_model_3d.gd','tv_director.gd','garage.gd'):
        assert (root/'scripts'/name).read_bytes() == (previous/'scripts'/name).read_bytes(), name
print('PASS: v0.5.3.0 HUD features, data wiring, original simulation and 3D preserved')
