# APEX Motorsport Manager — Relatório técnico v0.6.6.5

**Funcionalidade única:** Replay Checkpoint Coverage 1.0 (índice histórico equilibrado).  
**Base:** v0.6.6.4 Replay Memory 1.0, ZIP completo fornecido.  
**Motor:** Godot 4.7.2 stable Linux x86_64.

## 1. Problema confirmado e escopo

Na v0.6.6.4, os checkpoints intermediários tinham limite de 9 posições,
mas após atingir o limite o gravador descartava sempre o índice 1. Isso
mantinha tick 0 e apenas os oito checkpoints mais recentes; em gravações
longas a busca para o começo/meio podia precisar simular milhares de ticks
a partir do início.

A v0.6.6.5 modifica **apenas a seleção dos checkpoints retidos**.
Não muda a física, o motor esportivo, o calendário 2012, IA, pits, staff,
pit wall, Racecraft Audit, telemetria, HUD ou persistência.

## 2. Implementação

Em `scripts/core/race_replay_0660.gd`:
- `MAX_CHECKPOINTS := 9` e manutenção da gravação a cada 300 ticks.
- Preservação do checkpoint inicial e do checkpoint mais recente.
- No décimo registro, remoção de um checkpoint intermediário que minimize
  `gap_anterior * gap_posterior`, que equivale a minimizar o aumento do custo
  integrado de reprodução de todos os alvos de seek, considerando os
  checkpoints presentes naquele instante.
- Empates descartam o candidato mais antigo.
- Política determinística de armazenamento, sem efeito nos hashes esportivos.

Os estados dos checkpoints mantêm o mesmo conteúdo e a compressão ZSTD
introduzida na v0.6.6.3. O fork local da v0.6.6.4 também permanece igual.

A exportação `export_data()` e os arquivos `save_file()` continuam usando
**`APEX_REPLAY_0660` / `0661_driver_dynamics`**, e `load_file()` continua
abrindo replays históricos. A seleção dos checkpoints muda a sequência
de snapshots armazenados em novos arquivos, **não o schema público**.

## 3. Benchmark controlado: Monza, 3.200 ticks, seed 660, seco, 24 carros

| Métrica | v0.6.6.4 | v0.6.6.5 |
|---|---:|---:|
| Gravação de 3.200 ticks | 95,955 s | 95,054 s |
| Seek tick 750 | 13,468 s | **4,007 s** |
| Seek tick 1.500 | 0,055 s | **0,047 s** |
| Seek tick 2.800 | 4,449 s | **4,086 s** |
| Exportar arquivo | 0,541 s | 0,507 s |
| Importar arquivo | 0,539 s | 0,621 s |
| Tamanho do arquivo | 8.744.244 B | 8.620.872 B |
| Checkpoints | 0,900,...,3000 | 0,600,1200,1500,...,3000 |
| Hash esportivo | idêntico | idêntico |

Ganho no seek do tick 750: **3,36x**. Diminuição observada do arquivo:
**1,41%**. Os tempos de save/load são operações subsegundo em uma rodada e
não constituem evidência estatística de ganho geral de IO.

Pico RSS amostrado a cada 250 ms: baseline ~205,2 MiB; candidata
~215,2 MiB. **Não há evidência de redução de pico RSS nesta operação; o
teste registrou aumento.** O monitor `Performance.MEMORY_STATIC` final foi
62.610.181 B na base e 62.589.680 B na candidata, sem caracterizar RSS.

O primeiro experimento de dobrar intervalos e descartar pontos não alinhados
foi **rejeitado**: tick750=4,449 s, porém tick1500=12,091 s
e tick2800=14,432 s (contra 0,055 e 4,449 s originais).
A versão entregue contém somente a política equilibrada.

## 4. Monza 53 voltas e arquivo externo

**Corrida completa (Monza 2012, 53 voltas): APROVADA.**
24.431 ticks, 24/24 carros classificados, 24 posições distintas e
24 paradas contabilizadas. Tempo de gravação nesta execução:
**558.941 s**. Hash esportivo final, exatamente igual ao
da v0.6.6.4:

`2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b`

**Checkpoints resultantes (9/9):** 0, 2400, 4200, 6600, 7800, 10200, 15000, 19800, 24300.
Maior intervalo: **4800 ticks**.
A política anterior teria mantido [0,22200,22500,22800,23100,23400,23700,24000,24300],
com uma lacuna inicial de 22.200 ticks. Essa é uma comparação
**estrutural** dos índices, não benchmark A/B de seek completo.

Buscas reais do novo controlador, com hash verificado nos alvos:

| Tick de destino | Tempo | Resultado |
|---|---:|---|
| 10.000 | 45,471 s | MATCH |
| 20.000 | 2,661 s | MATCH |
| 24.431 | 2,254 s | MATCH |

A gravação externa completa usando o **formato original `APEX_REPLAY_0660`**
teve **41,544,880 bytes** (41,54 MB decimais), gravada em
**2.886 s** e carregada em **2.311 s**.
O arquivo foi reaberto e buscou o tick final com hash equivalente. Nada
descartado de comandos, hashes ou estados esportivos.

**Memória:** pico de RSS do processo *integrado* em Monza
**682.5 MiB**, medido ao longo
de corrida + buscas + materialização de arquivo externo + importação.
Não comparar diretamente aos 168,4 MiB da v0.6.6.4, cujo teste
longo não incluía este caminho de exportação/importação.

**Limitação explicitamente mantida:** nesta versão não se repetiu o replay
do tick 0 até o tick 24.431 inteiro. As buscas para três alvos e os hashes
foram verificados em teste nativo, além de provas curtas com replay integral.


## 5. Regressão / testes reais

**26 testes aprovados, 0 falhas
de código confirmadas e 2 testes não executados**, detalhados no JSON:

- A/B Monza 3.200, replay antigo v0.6.6.2 e sessão local.
- Quatro provas curtas completas com replay e contadores Racecraft:
  GBR seco (1.668 ticks), BEL chuva intensa (2.067), ITA seco (1.553)
  e SIN chuva intensa (2.050); hashes históricos rigorosamente idênticos.
- Replay boundaries incluindo pit V21/chuvoso V4, 1x/2x/5x/16x/32x,
  integração UI/2D/3D, telemetria/clima e back-to-live.
- Racecraft Audit, Driver Dynamics, sim engine, pit lane, save migration,
  oficina, inventário, Soul Staff e Strategy Simulator.
- Capturas verdadeiras da cena de corrida GBR seed 661 no Godot Compatibility
  em 1600×900 e 1920×1080, sem montagem gráfica.
- Monza 53 voltas com arquivo externo reaberto.

A primeira tentativa do teste `soul_staff_0650_migration_test.gd` foi
invalidada por `XDG_DATA_HOME` ausente no launcher do teste. Ela foi
interrompida e **reexecutada com ambiente isolado correto**, obtendo
`SOUL_0650_MIGRATION_PASS` e código 0. O código do jogo não foi alterado.

**Não executados:** estresse de 20 temporadas e replay integral de
24.431 ticks passo a passo na 0665. O replay integral já havia sido
exercitado na 0664, mas não o reclassificamos como teste atual.

Importação do ZIP limpo: **APROVADA**, sem erros de parser, seguida por smoke de pit V21/chuvoso V4 e teste de replay antigo (650 ticks).


## 6. Mudanças de arquivos e compatibilidade

Apenas estes arquivos preexistentes foram intencionalmente modificados:
- `project.godot`: nome e descrição v0.6.6.5.
- `scripts/core/race_replay_0660.gd`: escolha de checkpoints.

Arquivos novos: fixtures de benchmark, teste de Monza 53, captura visual,
documentação, manifestos e `qa/replay_checkpoints_0665/`.

**`scripts/race_engine.gd` byte a byte inalterado.** Sem novo formato de
save ou replay. O último ZIP da v0.6.6.4 é a referência para rollback.

## 7. Limitações e próximos passos

- O índice equilibrado é **heurístico incremental** e não afirma encontrar
  a disposição global matematicamente ótima após 400.000 ticks.
- Algumas buscas específicas podem perder velocidade quando um índice
  antigo é removido; não há garantia de melhoria para todo destino e duração.
- Métricas headless Linux do host de teste não predizem FPS na GPU do usuário.
- Stress test de 20 temporadas não faz parte deste release.
- Próximas versões não iniciadas; a v0.6.6.5 limita-se ao replay.

**Rollback:** fechar o jogo, salvar backup de `user://`, extrair a v0.6.6.4
original em diretório novo e nunca combinar scripts de versões.
