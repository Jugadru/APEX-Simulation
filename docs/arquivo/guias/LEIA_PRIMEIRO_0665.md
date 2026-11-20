# APEX Motorsport Manager v0.6.6.5 — Replay Checkpoint Coverage 1.0

## Base
Projeto Godot 4.7.2 (Linux x86_64), derivado integralmente de
`APEX_MOTORSPORT_MANAGER_v0.6.6.4_REPLAY_MEMORY_COMPLETO.zip`.

## Funcionalidade nova
O replay grava os mesmos checkpoints determinísticos (de 300 em 300 ticks), mas
o índice conserva **no máximo 9**, incluindo o primeiro e o último. Quando há
10 posições, remove o checkpoint intermediário com menor produto dos intervalos
entre seus vizinhos. Isso distribui referências ao longo da corrida sem
descartar todos os checkpoints antigos.

A regra esportiva `0661_driver_dynamics`, a simulação, o pit wall, a IA, a
física e os formatos de replay/save permanecem inalterados. Arquivos antigos
`APEX_REPLAY_0660` continuam legíveis.

## Como iniciar
1. Extraia o ZIP completo em uma pasta nova, sem misturar scripts antigos.
2. Abra `project.godot` no Godot 4.7.2 stable.
3. Execute uma corrida e abra **Ver gravação atual** no painel de replay.
4. Use o controle de busca para voltar às voltas antigas, pausar, reproduzir
   e retornar à corrida. Também é possível importar arquivos de replay antigos.

## Segurança dos saves
- Faça backup do diretório `user://` antes de alternar versões.
- O projeto usa `config/custom_user_dir_name="APEX_0650_SOUL_STAFF"`.
- Para rollback, execute a v0.6.6.4 original em uma pasta separada.
- Não sobrescreva um arquivo de replay antigo sem guardar cópia.

## Benchmark 3.200 ticks, seed 660, Monza seco
- Busca tick 750: 13,468 s (0664) → **4,007 s** (0665), ~3,36×.
- Busca tick 1.500: 0,055 s → 0,047 s.
- Busca tick 2.800: 4,449 s → 4,086 s.
- Arquivo de replay: 8.744.244 bytes → 8.620.872 bytes.
- Mesmo hash esportivo `f771fab5025055653075f853b4a06370097d5af74843d2deea4cc8dc17be9b90`.
- Pico RSS da candidata ligeiramente maior na rodada controlada: **nenhuma promessa de redução de RAM**.

A opção de duplicar espaçamento (power-of-two) foi **rejeitada** pois
piorava drasticamente buscas intermediárias.

Veja o relatório técnico e a matriz de testes para resultados completos,
limitações e evidências reais.

## Monza completo — v0.6.6.5
- 53 voltas, 24.431 ticks, 24 classificados e hash esportivo histórico igual.
- Checkpoints preservados nos ticks 0, 2400, 4200, 6600, 7800, 10200, 15000, 19800, 24300.
- Buscas, save e importação da gravação de 41544880 bytes aprovados.
- 26 testes aprovados; 2 não executados (20 temporadas e replay integral tick a tick).
- Versão do jogo testada em Godot 4.7.2 Linux; ZIP extraído e validado.
