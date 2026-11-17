# Apex v0.6.1.1 — Hotfix mapa/HUD/previsão

Base: v0.6.1 experimental enviada e testada no Linux Mint. Esta é uma **cópia independente**, para não substituir a versão com que os pontos da temporada funcionaram.

- `scripts/track_map.gd`: 2D estratégico redesenhado para vista de cima com asfalto, grama, zebras discretas, apenas bolinhas de pilotos e pista sem faixas de setores em neon.
- `scripts/main.gd`: novo enquadramento completo do circuito no modo estratégico, sem cortes automáticos de TV ao seguir líder (exceto se o usuário pedir "Seguir piloto"); laterais menores e cartões recolhidos no perfil inicial; novas preferências de HUD `user://hud_layout_0611.cfg` (não apaga preferências antigas). 
- `scripts/core/race_weather.gd`: risco nos próximos 15 min recalculado conforme o relógio, a semente e a aproximação dos episódios climáticos, separado do risco-base do circuito e da chuva real.
- `scripts/apex_mini_map.gd`: cor de fundo alinhada à vista aérea.
- Testes adicionados: `tests/test_0611_static.py`, `tests/core_0611_map_weather_smoke_test.gd`, `tests/diagnostico_melbourne_pits.gd`.

## Preservado
`race_engine.gd`, `race_performance.gd`, `race_strategy.gd`, `race_ai_director.gd`, `race_team_autonomy.gd`, `championship_2012.gd`, `track_3d.gd`, `garage.gd` e dados da temporada idênticos ao pacote 0.6.1. Ou seja: **a IA de paradas e desgaste excessivo ainda não foi recalibrada**. Isso será feito com o diagnóstico de Melbourne, sem limitar artificialmente a dois pits.

## Execução
Abra `project.godot` no Godot 4, F5. Escolha visual **Mapa estratégico** e confirme circuito inteiro com 24 bolinhas. Em **CHUVA**, observe o risco de 15 min em diferentes pontos do GP.
No terminal: `bash linux/validar_0611.sh`; diagnóstico específico de boxes: `godot --headless --path . --script res://tests/diagnostico_melbourne_pits.gd`.

## Limitação
Sem Godot no ambiente de geração: scripts conferidos estaticamente; renderização e teste nativo pendentes no Linux Mint.
