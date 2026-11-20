# Arquivos alterados — v0.6.6.7.2.3

**Arquivos existentes modificados:**
- `project.godot` — identidade da atualização.
- `scripts/core/race_stint_optimizer.gd` — cache exato limitado e chave inteira de DP.
- `scripts/core/race_replay_0660.gd` — orçamento de quadro opcional e diagnóstico de saturação.
- `scripts/main.gd` — usa orçamento do scheduler nas velocidades 10x ou maiores.
- `scripts/apex_race_hud_0622.gd` — indicador `CPU` e tooltip.
- `tests/strategic_2d_066722.gd` — expectativa ajustada ao orçamento, sem exigir o 32x nominal se a CPU limitar a execução.

**Novos:**
- `tests/high_speed_growth_066723_benchmark.gd`
- `tests/high_speed_ui_066723.gd`
- `tests/stint_optimizer_perf_066723.gd`
- `qa/high_speed_cpu_066723/` e documentos da versão.

**Intocados:** `scripts/race_engine.gd`, `scripts/core/race_ai_director.gd`, física, condições de corrida, cálculo de ultrapassagens, IA esportiva, formato externo de replay e todos os recursos 3D/2D existentes.
