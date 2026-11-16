# v0.5.4.0 — Core Rebuild fase 1

- `core/race_rules.gd`: tabelas de pneus e ritmo, perfis, severidade aproximada de pista.
- `core/race_performance.gd`: cálculo puro de alvo de volta e desgaste, com termodinâmica simplificada opcional.
- `core/race_combat.gd`: distância do oponente e porta de ultrapassagem, com ataque preparado no perfil experimental.
- `core/race_strategy.gd`: decisão de pneus da IA, inalterada no modo clássico, sensível ao desgaste no Core 2.
- `core/race_pit_math.gd`: funções puras de bônus e serviço; máquina de estados dos boxes permanece no motor.
- `race_engine.gd`: perfil e estado de simulação; `get_state_snapshot`; observação central de telemetria preservada.
- `main.gd`: opção de motor antes da largada; painel direito do menu com scroll.
- `tools/choose_renderer.py`: seleção reversível Compatibility/Forward+.
- `tests/fixtures/race_engine_0533.gd`: referência congelada do motor de corrida original.
- `tests/core_0540_parity_test.gd`: comparação de 6 corridas modo clássico x referência.
- `tests/core_0540_experimental_test.gd`: determinismo e snapshots do motor experimental.
- `tests/test_0540_static.py`, `tests/test_0540_math.py`: regressões offline.

**Observação:** refatoração não é tradução de código Python. O motor já era GDScript; Python só existe no ambiente de testes.
