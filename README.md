# APEX Motorsport Manager v0.6.6.0 — Deterministic Simulation & Replay

Abra `project.godot` no **Godot 4.7.2** e pressione F5. No Linux, `linux/run_apex.sh` aceita `GODOT_BIN`. Os saves continuam no diretório estável das versões anteriores.

A corrida usa ticks fixos e grava comandos/estados. **F9 abre o replay:** assistir, pausar, buscar um tick, exportar/importar e retornar à corrida original. **F8** continua abrindo o profiler. Replay é isolado do inventário e do campeonato.

O cenário ganhou áreas de apoio e estacionamento, terreno com variações, consoles e engenheiros nos boxes, detalhes da equipe de pit e zebras. HUD e câmeras existentes foram preservadas.

- [Como usar o replay e seus limites](docs/REPLAY_0660_USO.md)
- [Relatório técnico](RELATORIO_TECNICO_APEX_v0.6.6.0.md)
- [Benchmark](docs/BENCHMARK_0660.md)
- [Contratos](docs/CONTRATOS_0660.md)
- [Pesquisa](docs/PESQUISA_TECNICA_0660.md)
- [Diário](docs/DIARIO_ENGENHARIA_0660.md)
- [Próxima versão: IA de disputas](docs/PLANO_ENGENHARIA_0661.md)

Resultados são específicos ao runtime testado. Seek longo pode demorar, aceleração pode acumular backlog e não se promete identidade entre plataformas. O passo fixo muda a sequência numérica em relação à versão anterior. Consulte as evidências e limitações do relatório antes de comparar resultados esportivos entre versões.
