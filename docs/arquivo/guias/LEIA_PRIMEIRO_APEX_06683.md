# LEIA PRIMEIRO — APEX v0.6.6.8.3 Core 2

**Este ZIP é um projeto Godot 4.7.2 completo, não apenas arquivos de código.** É construído sobre a v0.6.6.8.1, com a HUD ReBroadcast aprovada e Core 2 como motor principal; não contém Next Engine ativada.

1. Faça backup do diretório de saves e preserve o ZIP v0.6.6.8.1.
2. Extraia esta versão em pasta **nova** (não sobreponha versões).
3. Abra `project.godot` no Godot 4.7.2. Aguarde a importação completa dos assets.
4. Execute normalmente uma corrida em 3D. O ganho de FPS não é garantido; a otimização reduz cópias internas por tick.
5. Para retestar com terminal: `godot --headless --editor --path . --import --quit` e depois `godot --headless --path . --script res://tests/core2_snapshot_06683_regression.gd`. Use a versão Godot 4.7.2.
6. O Core 2 está ativo. Não há flag que ative o APEX 2 neste pacote.

Rollback: feche a versão atual e abra `project.godot` do backup v0.6.6.8.1. Não mova saves entre projetos sem backup; ambos usam o mesmo diretório de usuário.

**Atenção:** a importação headless padrão da cópia limpa abortou em reimportação de CSV no ambiente virtual. A importação com `--single-threaded-scene` passou. Se encontrar erro semelhante no Linux Mint, experimente a flag `--single-threaded-scene` e mantenha a versão 0.6.6.8.1 como rollback.
