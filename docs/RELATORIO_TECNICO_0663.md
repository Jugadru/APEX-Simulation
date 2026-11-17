# APEX Motorsport Manager v0.6.6.3 — Relatório técnico

**Funcionalidade única:** Long Race Performance 1.0  
**Runtime:** Godot 4.7.2.stable.official.ed1daf0bf, Linux, execução headless; capturas via Xvfb/Mesa llvmpipe (OpenGL Compatibility).  
**Base obrigatória:** `APEX_MOTORSPORT_MANAGER_v0.6.6.2_RACECRAFT_TELEMETRY_COMPLETO.zip`  
**SHA-256 da base:** `d6aa37f5337cb41a0f45b6a48e9ef9aa7082ff8b6c33543b9fb5ad33d87afcd5`  
**Estado:** release com validação documentada; conferir o resultado da corrida longa abaixo.

## 1. Auditoria da origem

ZIP original íntegro (CRC), 2.234 entradas e ~112,8 MB descompactados; extração e cópia original preservadas. Projeto com `project.godot` da v0.6.6.2, 322 scripts `.gd`, cenas, dados históricos F1 2012, módulos de IA, HUD, fábrica e QA. A fonte mestra foi tratada como planejamento, não como prova de funcionalidades implementadas.

O relatório da v0.6.6.2 registra que Monza 53 voltas não terminou após 13min16s e que o RSS naquele processo ultrapassou 1,1 GB. Esse episódio histórico não foi falsamente tratado como resultado de um benchmark reproduzido em idênticas condições de host.

## 2. Problema analisado e mudanças

O Replay original mantém o checkpoint inicial mais até oito estados intermediários. Estados intermediários eram duplicações profundas de todo o estado, incluindo a telemetria de posições, voltas, setores e eventos acumulados. À medida que a corrida se estende, os históricos permanecem obrigatoriamente completos e a retenção de até oito cópias aumenta a pressão de memória.

**Correção 0663:** compactação ZSTD do estado interno dos checkpoints periódicos após `Codec.capture`, descompactação controlada antes de `Codec.restore` e antes da exportação no formato original. O estado inicial, método público `checkpoint()`, `APEX_REPLAY_0660`, `simulation_revision=0661_driver_dynamics`, tick 0,20s, RNG, comandos e hashes não foram alterados.

**Observador Racecraft:** varredura reversa para encontrar a fronteira dos `event_id` novos, com consumo posterior em ordem cronológica. A fonte de eventos e as contagens por piloto, clima e risco permanecem as mesmas. Nenhum evento foi descartado da telemetria.

**Experimento reprovado:** troca da cópia profunda dos carros no tick por cópia rasa. Apesar de manter o hash nos 4.500 ticks e nos GPs curtos, executou em **137,69s**, pior que a candidata; foi removido. **`scripts/race_engine.gd` é byte a byte idêntico à base.**

## 3. Comparação reprodutível — Monza (4.500 ticks)

Mesma seed 660, Ferrari, comandos de pit fixos no tick 3, clima seco, configuração de 53 voltas, Godot 4.7.2 headless, 24 carros. Comparação da execução antes de atingir a bandeirada; portanto **não é** um teste de GP completo.

| Métrica | v0.6.6.2 | v0.6.6.3 | Alteração |
|---|---:|---:|---:|
| Duração de 4.500 ticks | 136,09 s | 131,63 s | −3,28% |
| Memória estática monitorada pelo Godot | 80.612.430 B | 39.157.289 B | −51,43% |
| Checkpoints residentes no fim | 9 | 9 (8 compactados) | mesmos pontos lógicos |
| Hash esportivo no tick 4.500 | `fdd9d237...b91` | `fdd9d237...b91` | **idêntico** |
| CPU % por processo (comparativo) | não medido com o mesmo amostrador | não medido com o mesmo amostrador | **inconclusivo** |

Os valores de memória são do monitor `Performance.MEMORY_STATIC` e **não** são RSS do processo. As durações são tempo de relógio, não CPU% nem tempo GPU. O benchmark é predominantemente CPU-bound; não se inventa percentual de utilização comparativo. Resultados brutos: `qa/long_race_0663/comparison_4500.json` e os dois arquivos individuais.

## 4. Compatibilidade e determinismo

Gravação de **650 ticks** produzida pela v0.6.6.2 e reproduzida pela v0.6.6.3 com checkpoints intermediários, inclusive busca por checkpoint e replay desde o início. Uma gravação nova de 650 ticks, gerada pela v0.6.6.3 nas mesmas condições, foi **idêntica byte a byte** à original. SHA-256 de ambos os arquivos: `4488d6e8ea33d0455a66cbe05971d4a52fc0b005dace74409f772f69f5b02ae7`.

As quatro regressões curtas preservaram hash e contadores da v0.6.6.2:

| Pista | Condição | Ticks | Hash final | Status |
|---|---|---:|---|---|
| GBR | Seco | 1668 | `7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837` | APROVADO |
| BEL | Chuva intensa | 2067 | `33c7c2d71e34779fb7e74f359f2663e0bea34074aaf4c655dc678f3b97fd8c0e` | APROVADO |
| ITA | Seco | 1553 | `5d4c508a64dce8d1c481a3661f56c6bdf97a2a7a7bab37a5e290be5e54188592` | APROVADO |
| SIN | Chuva intensa | 2050 | `48085a06fed3d7761a58206673c03685043645d813ea809e0b76c968e94439c9` | APROVADO |

O teste de replay `replay_0660_test.gd` confirmou equivalência esportiva nas velocidades **1x, 2x, 5x, 16x e 32x**. A ordem manual de box na volta 21 não foi antecipada para a volta 4 mesmo com chuva intensa.

## 5. Monza — distância oficial

**Corrida completa:** APROVADA; **replay integral:** APROVADO. Ticks: 24431, tempo do motor 544.70s, replay 531.83s. Pico RSS observado no teste completo: 788.2 MiB (amostragem a cada 2s), dividido em aproximadamente 175.2 MiB durante a corrida e 788.2 MiB durante a exportação/validação do replay; este último retém cópias descompactadas para cotejo integral.

A condição para aprovação inclui 24 carros classificados, 53 voltas oficiais do circuito, classificação sem duplicações, eventos, Pit Wall e replay **integral desde o tick zero**, checando cada hash e as contagens do Racecraft. Abrir o replay sem percorrê-lo não satisfaz a condição.

## 6. Matriz de testes

A matriz consolidada registra **26 testes aprovados**, nenhum reprovado e **1 não executado** (estresse de 20 temporadas, fora do escopo da versão). Consulte `qa/long_race_0663/test_results_0663.json` para as evidências individuais.

| Teste | Estado | Evidência |
|---|---|---|
| Importação Godot 4.7.2 | **APROVADO** | `qa/long_race_0663/logs/import_candidate.log` |
| Racecraft — 1.027 verificações | **APROVADO** | `qa/long_race_0663/logs/racecraft_1027_checks.log` |
| Silverstone, Spa, Monza, Singapura (3 voltas) | **APROVADO** | logs e JSON individuais |
| Replay legado, speeds, clima e integridade | **APROVADO** | logs + replay binário 650 ticks |
| Ordem de pit V21 em chuva | **APROVADO** | `qa/long_race_0663/logs/pit_v21_rain.log` |
| Driver Dynamics, RaceSpace e pit lane | **APROVADO** | logs dedicados |
| Save migration, Soul Staff, inventário e oficina | **APROVADO** | logs com XDG_DATA_HOME isolado |
| Strategy Simulator e Replay Integration | **APROVADO** | logs dedicados |
| HUD/corrida em 1600×900 e 1920×1080 | **APROVADO para captura** | PNGs nativos do Godot, não GPU hardware |
| Monza 53 voltas | **APROVADO** | `qa/long_race_0663/monza_53.json` |
| Replay integral de Monza | **APROVADO** | `qa/long_race_0663/monza_53.json` |
| Simulação de carreira por 20 temporadas | **NÃO EXECUTADO** | não é escopo da 0663 |

Os testes de persistência acima validam suas fixtures, não equivalem a validar todos os saves de usuários nem todos os hardwares. Foram preservadas as falhas históricas no relatório anterior sem reclassificá-las automaticamente; nesta execução isolada, a fixture Soul Staff 0650 passou.

## 7. Arquivos de produção modificados

- `scripts/core/race_replay_0660.gd` — retenção de checkpoints comprimidos; exportação compatível.
- `scripts/core/racecraft_audit_0662.gd` — leitura de eventos recentes eficiente.
- `project.godot` — identificador da v0.6.6.3.

**Arquivos acrescentados:** fixtures `tests/long_race_benchmark_0663.gd`, `tests/long_race_full_0663.gd`, `tests/replay_0663_legacy_fixture.gd`, `tests/long_race_visual_0663.gd`, documentação, release notes e QA. Nenhum script de física, IA, estratégia, renderizador, equipe, oficina ou carreira foi modificado. Todos os arquivos originais do pacote permanecem presentes na árvore da candidata.

## 8. Limitações, execução e rollback

O ganho de memória é comprovado no benchmark de 4.500 ticks; isso não implica que o problema inteiro de performance tenha uma causa única. Não foram inventadas medições GPU nem resultados para hardware real do usuário. O desempenho em 20 temporadas e a carga visual com GPU dedicada permanecem sem validação.

Para executar ou repetir o teste, consulte `LEIA_PRIMEIRO_0663.md`. Antes do rollback, feche o jogo, faça backup de `user://` (o diretório customizado preservado é `APEX_0650_SOUL_STAFF`), extraia o ZIP original v0.6.6.2 em outra pasta e não misture arquivos entre versões. O projeto não executou migração irreversível de saves.

**CPU da execução longa:** monitor do processo registrou 1062.24 s em modo usuário e 7.48 s no kernel, amostrados durante o teste combinado de corrida e replay. O gráfico completo encontra-se em `qa/long_race_0663/monza_53_memory_cpu.json`. Não existe monitor equivalente da execução longa original no mesmo host, portanto CPU antes/depois permanece inconclusivo.

**Decisão de versão:** somente v0.6.6.3. Não foi iniciada a v0.6.6.4.
