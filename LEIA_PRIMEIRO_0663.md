# APEX Motorsport Manager v0.6.6.3 — Como executar

Pacote completo do projeto Godot. Necessário **Godot 4.7.2 stable** no Linux (ou versão comprovadamente compatível).

1. Extraia o ZIP para uma pasta gravável, mantendo `project.godot`, `scripts/`, `scenes/`, `assets/`, `data/`, `tests/` e `qa/`.
2. No terminal, dentro da pasta do projeto, importe os recursos: `godot --headless --editor --path . --import`.
3. Para jogar: `godot --path .` ou abra `project.godot` no editor Godot e execute a cena principal.
4. Benchmark opcional (escreve resultados na pasta indicada):
   `APEX_TRACK=ITA APEX_FULL=1 APEX_SEED=660 APEX_TEST_TICKS=4500 APEX_BENCH_OUTPUT=/tmp/apex_bench.json godot --headless --path . --script res://tests/long_race_benchmark_0663.gd`
5. Testes existentes: `godot --headless --path . --script res://tests/replay_0660_boundaries.gd` e `.../tests/racecraft_0662_test.gd`.
6. Corrida oficial: `APEX_FULL_REPORT=/tmp/apex_monza53.json godot --headless --path . --script res://tests/long_race_full_0663.gd`. Trata-se de teste potencialmente longo; não é corrida acelerada nem simulação encurtada.

## Rollback e persistência

A versão anterior permanece no ZIP original `APEX_MOTORSPORT_MANAGER_v0.6.6.2_RACECRAFT_TELEMETRY_COMPLETO.zip`, preservado separadamente. Para voltar, feche o Godot, copie previamente seus saves e preferências (o projeto utiliza o diretório customizado `APEX_0650_SOUL_STAFF` de `user://`), e extraia a versão v0.6.6.2 em outra pasta. **Não** sobrescreva o projeto antigo com a versão nova, nem delete saves. A v0.6.6.3 não executa migrações da campanha por conta própria.

## Replay

O replay exportado conserva `APEX_REPLAY_0660`, `simulation_revision=0661_driver_dynamics`, seeds, comandos e hashes. Apenas os checkpoints intermediários residentes no controlador são compactados; ao exportar, são reconstruídos no formato anterior. Arquivos da v0.6.6.0 continuam intencionalmente incompatíveis, pois trazem regras esportivas diferentes.

Veja `CHANGELOG_0663.md` e `docs/RELATORIO_TECNICO_0663.md`.
