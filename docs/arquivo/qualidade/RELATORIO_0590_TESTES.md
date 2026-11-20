# Relatório de validação — Apex v0.5.9.0

**Origem:** `/mnt/data/Apex_0580_Completo(2).zip`; CRC validado sem erros, `project.godot` presente.

**Ambiente:** terminal e Python 3.13.5 funcionando. Executável `godot`/`godot4` indisponível aqui.

- `python3 tests/test_0590_static.py`: **PASS** — integração Manual/Automático e STAFF, nomes/versão, saves, dados 2012, comparação SHA-256 de motor/mapa/3D/TV com 0.5.8.0.
- `python3 tests/test_0580_static.py`: **PASS** — preserva contrato de pit por volta e IA de box da 0.5.8.0.
- 27 testes Python legados e novos: **21 PASS, 6 FAIL**.
  - **4 falhas anteriores:** `test_0530_static.py`, `test_0531_static.py`, `test_0532_static.py` (afirmações fixas de versão antiga) e `test_0570_ai_strategy_static.py` (dependência externa antiga não presente).
  - **2 falhas por mudança intencional:** `test_05324_static.py` e `test_0543_static.py` esperam SHA-256 da antiga `garage.gd`; a garagem foi atualizada para persistir STAFF. São *contratos históricos de congelamento*, não testes de execução da nova funcionalidade.
- O smoke test `tests/core_0590_team_control_smoke_test.gd` foi **escrito mas não executado** aqui. Ele precisa ser executado pelo Godot no Linux Mint.

**Não validado:** parser Godot, renderização, sinais de UI, smoke de simulação e equilíbrio da IA durante a corrida. Portanto **versão experimental**.
