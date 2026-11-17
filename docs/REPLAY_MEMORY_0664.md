# Replay Session Fork 1.0 — arquitetura

## Linha de dados original (v0.6.6.3)

`Ver gravação atual` -> `export_data()` -> `_export_checkpoints()` -> `decompress(...)` de todos os checkpoints -> `.duplicate(true)` de cada estado -> `load_data()` -> validação/`Codec.restore` repetidos -> compactação novamente dos checkpoints residentes -> `seek(0)`.

Esse caminho é correto para arquivos externos ou transferência entre versões, mas custa CPU e retém cópias temporárias do histórico acumulado quando a origem **já é** um controlador de replay vivo e local. Ele não é necessariamente a causa inteira do antigo RSS de 788 MiB; outras estruturas históricas são esperadas durante uma corrida longa.

## Novo caminho interno (v0.6.6.4)

`Ver gravação atual` -> `load_live_session(host.replay_session)`:

1. Verifica se o controlador local tem corrida e hashes coerentes.
2. Verifica o checkpoint inicial no tick 0.
3. Duplica estruturas compactadas de checkpoint, comandos ordenados e hash por tick diretamente, sem descompactar checkpoints intermediários para reexportação.
4. Inicia a reprodução chamando `seek(0)` e a mesma rotina de restauração/validação do estado inicial.
5. O motor executa os mesmos `step_tick()` e compara cada hash esportivo normalmente.
6. Falha de restauração limpa os dados parciais.

Não há ligação mutável com o registro original, que é preservado e restaurado ao sair da reprodução. O diálogo aceita também sessões locais de replay já em reprodução, como no comportamento anterior.

### Distinção entre fonte confiável local e arquivo externo

Arquivos externos e arquivos antigos continuam obrigatoriamente passando por `load_file()` e `load_data()`, com verificações completas de revisão, versão do Godot, schema, comandos, política, checkpoints, hash e integridade. **Não** se oferece o caminho direto de sessão local para dados deserializados não confiáveis.

Nenhuma atualização de `format` nem de `simulation_revision` foi necessária, já que nem os eventos esportivos nem o formato de arquivo foram alterados.

### Conformidade

Mesma seed + mesmo estado + mesmos comandos mantêm os mesmos resultados. Não foi alterado RNG, frequência de ticks, valores de física, IA, Racecraft, motor, configuração dos 24 carros nem apresentação visual.

Para evidências, consulte os logs e JSON em `qa/replay_memory_0664/` e o relatório técnico.
