# 0.5.4.1 — Pit Lane Core

- **Novo:** `scripts/core/race_pit_lane.gd` (estado, fases e durações dos boxes extraídos literalmente da 0.5.4.0).
- **Novo:** `RaceEngine.get_pit_lane_snapshot()` e `PitLane.snapshot()` para leitura segura do Pit Wall/engenheiro.
- **Novo:** fixture congelada `tests/fixtures/race_engine_0540.gd` para testes de compatibilidade executáveis no Godot.
- **Novo:** `tests/core_0541_pit_parity_test.gd` (corre 2 pistas × 2 sementes × 2 perfis, compara carros, eventos e pit history).
- **Novo:** `tests/test_0541_pit_extraction.py` compara as funções transferidas com o código fonte antigo, ignorando apenas o adaptador de chamadas.
- **Novo:** `linux/validar_core_0541.sh` para verificações offline e comparação no Godot instalado localmente.
- **Mantido:** clima apenas informativo; fórmulas de corrida, pneus, pit stops, carro 3D, pista, telemetria, HUD e rádio.

O módulo não é totalmente autônomo: o motor ainda assume a posse das garagens, os eventos e o resultado do serviço. Isso mantém a compatibilidade e será melhorado em etapas.
