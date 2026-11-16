# APEX — Arquivos alterados / novos v0.6.6.7.2.2

## Alterados (código e testes)

- `project.godot` — identidade do hotfix.
- `scripts/track_map.gd` — separar renderização estática/dinâmica e invalidar cache em mudanças de pista/mode.
- `scripts/apex_race_view_controller.gd` — modo Auto por faixa de velocidade e respeito a câmeras manuais.
- `scripts/apex_race_session_controller.gd` — novos GPs entram em Auto a 1x.
- `scripts/apex_race_hud_0622.gd` — acesso à escolha AUTO no menu CORRIDA.
- `tests/speed_visual_066721.gd` — atualizar teste de isolamento de velocidade para o modo manual, mantendo cobertura.

## Adicionados

- `scripts/track_map_static_066722.gd` e UID Godot.
- `tests/strategic_2d_066722.gd`, `tests/strategic_2d_benchmark_066722.gd`, `tests/strategic_2d_066722_capture.gd`.
- `qa/strategic_2d_066722/` — resultados, logs e capturas reais.
- Documentação e relatórios da nova versão.

## Proteções

`race_engine.gd`, `race_replay_0660.gd`, `tv_director.gd` e componentes esportivos continuam byte a byte iguais aos originais da v0.6.6.7.2.1. Dados históricos de `qa/racecraft_0662/` e `qa/replay_0660/unit.json` foram restaurados à base depois dos retestes para preservar o arquivo original.
