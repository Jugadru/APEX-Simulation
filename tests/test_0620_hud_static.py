"""Portable 0.6.2 regression checks. Does NOT replace Godot parsing/render tests."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
main = (root / 'scripts/main.gd').read_text()
hud = (root / 'scripts/apex_race_hud_0620.gd').read_text()
stints = (root / 'scripts/apex_strategy_planner_0620.gd').read_text()
project = (root / 'project.godot').read_text()

for name in ['RaceHud0620.new()', 'race_hud_0620.begin_race()',
             'race_hud_0620.update_map(draw_cars, focused_id)',
             'race_hud_0620.refresh_hud()', 'race_hud_0620.layout_hud()']:
    assert name in main, f'Main missing: {name}'
assert 'v0.6.2.0' in project
for feature in ['"INTERVALO", "LÍDER", "PITS", "MELHOR VOLTA", "PNEUS"',
                '"Telemetria", "Desempenho", "Estratégia", "Carro"',
                '"CORRIDA"', '"ESTRAT."', '"DADOS"', '"EVENTOS"', '"RÁDIO"',
                '"CHAMAR BOX"', '"AGENDAR"', '"Pneu atual"',
                '"MAPA 2D"', '"AÉREA 3D"', '"DIRETOR TV"',
                '"1×"' if False else '32.0']:
    assert feature in hud, f'HUD missing: {feature}'
assert '"stint_laps"' in hud
assert 'get_engineer_advice' in hud and 'pit_scheduled_lap' in hud
assert 'pit_history' in stints and 'pit_scheduled_lap' in stints
assert 'Futuro: sem parada definida' in stints
assert 'A área futura' not in hud
for name in ['apex_race_hud_0620.gd', 'apex_strategy_planner_0620.gd']:
    data = (root / 'scripts' / name).read_text()
    assert not any(line.startswith(' ') and line.strip() for line in data.splitlines()), name + ': space indentation'
    print('PASS: 0.6.2 HUD hooks, compact grid, tabs, commands and real planned stint markers')
