# LEIA PRIMEIRO — APEX v0.6.6.8.4

1. Descompacte o ZIP em uma nova pasta, sem substituir a v0.6.6.8.3.
2. Abra `project.godot` no Godot 4.7.2 e deixe o editor importar recursos.
3. Execute o jogo e teste uma corrida em 3D; os modos BROADCAST, COMPACT e FULL permanecem os mesmos.
4. O Core 2 é a única física de corrida ativa; APEX 2 Next Engine não está ativado.
5. Para regressões em Linux: `Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/core2_06684_hidden_legacy_hud_test.gd`
6. Em caso de falha intermitente do editor headless na importação, experimente `--single-threaded-scene` (contorno de infraestrutura, não alteração esportiva).
7. Para rollback, feche o jogo e abra a cópia preservada da versão v0.6.6.8.3. Mantenha backup dos saves.

**Benchmarks:** números headless não equivalem a FPS no seu PC. Veja APEX_06684_RELATORIO_TECNICO.md.
