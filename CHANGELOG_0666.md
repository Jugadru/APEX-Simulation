# APEX Motorsport Manager — Changelog v0.6.6.6

**Funcionalidade única:** Replay Fast Seek 1.0 — cache efêmero de âncoras de navegação.

## Alterações no código existente

- `scripts/core/race_replay_0660.gd`: quando o usuário acessa um tick durante a reprodução, mantém até quatro snapshots ZSTD **apenas na memória** (teto agregado de 12 MiB de buffers comprimidos). Um seek subsequente pode começar do estado atual ou do snapshot válido mais próximo, em vez de recalcular obrigatoriamente desde um checkpoint permanente.
- O cache inclui um retrato do observador Racecraft Audit; seu relatório não se perde ao reutilizar uma âncora temporária.
- O cache é invalidado ao carregar outro arquivo/sessão. A troca de fonte força nova restauração do tick inicial, mesmo se o controlador anterior estava pausado no tick zero.
- `project.godot`: identificação da versão v0.6.6.6.

## Adicionados

- `tests/replay_fast_seek_0666_benchmark.gd`: 18 navegações repetidas em Monza 3.200 ticks, com comparação de hashes e relatórios Racecraft.
- `tests/replay_fast_seek_0666_contract.gd`: arquivo legado, invariância da exportação, corrupção de estado, reset da fonte e limites do cache.
- `tests/replay_fast_seek_0666_monza53.gd`: navegação no replay histórico completo de 53 voltas (requer gravação externa da v0.6.6.5).
- `tests/racecraft_0666_gp.gd`: regressão de quatro provas curtas com saída isolada em `qa/replay_fast_seek_0666/`.
- `tests/replay_checkpoints_visual_0666.gd`: capturas reais do Godot, sem montagens.
- `qa/replay_fast_seek_0666/`: fixture legada de 3.200 ticks, logs, tempos e evidências.
- Documentação, checklist de teste e manifesto da versão.

## Fora do escopo / preservado

- Sem alteração em `scripts/race_engine.gd`, IA, física, combate, RNG, desgaste, pneus, clima, KERS/DRS, pit stops, Racecraft Audit, rádio, staff, oficina ou HUD.
- Preservado o arquivo de replay `APEX_REPLAY_0660` e a revisão esportiva `0661_driver_dynamics`; os checkpoints temporários **não são exportados**.
- Os 9 checkpoints históricos da v0.6.6.5 permanecem com a mesma seleção e intervalo.
- A primeira busca fria por uma região distante não recebe um novo checkpoint gratuitamente; o ganho é para navegação repetida e uso do estado atual.
