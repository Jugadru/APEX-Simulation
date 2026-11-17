# APEX Motorsport Manager v0.6.6.4 — Instruções

Projeto completo Godot **4.7.2 stable**, compatível com Linux Mint.

1. Extraia o ZIP inteiro para pasta gravável.
2. Importe pelo Godot ou com `godot --headless --editor --path . --import`.
3. Execute `godot --path .` ou abra `project.godot` e rode a cena principal.
4. Durante uma corrida, abra o painel Replay e pressione **Ver gravação atual**. O jogo usa a reprodução otimizada; não precisa exportar arquivo.
5. O botão **Exportar gravação** continua criando um arquivo no formato histórico `APEX_REPLAY_0660`. **Abrir replay** continua aceitando arquivos anteriores de revisão esportiva compatível.
6. Teste rápido: `godot --headless --path . --script res://tests/replay_watch_0664_test.gd`.
7. Teste de CPU/memória (ambos os modos disponíveis, conforme versão):
   `APEX_WATCH_MODE=direct APEX_WATCH_TICKS=3200 godot --headless --path . --script res://tests/replay_watch_memory_0664_benchmark.gd`.

**Rollback:** feche Godot, faça cópia dos arquivos de `user://` (diretório customizado `APEX_0650_SOUL_STAFF`), extraia o ZIP ORIGINAL v0.6.6.3 em outra pasta e não misture scripts. A v0.6.6.4 não migra dados de carreira nem muda formato de saves. O SHA-256 do ZIP original está no relatório e no manifest.
