# Relatório técnico — APEX Motorsport Manager v0.6.6.8.1

**Status:** EXPERIMENTAL / QA; não é homologação em GPU de destino.  
**Godot:** 4.7.2.stable.official.ed1daf0bf; importação headless PASS.  
**Base de trabalho:** v0.6.6.8, SHA-256 `7d4ff778de6e59dac01edebff9be17419ca6d90d99d5ad5e66c0777776462a5f`.  
**Escopo:** somente HUD e testes; nenhum módulo de simulação, Driver Brain, Racecraft, replay, Pit Wall ou Next Engine foi editado.

## 1. Auditoria

Foi reextraído o ZIP-base e conferido o CRC; projeto-base executou `--headless --editor --quit` com retorno 0, unitários de HUD e as 34 verificações antigas da cena. A interface real é `scripts/apex_race_hud_0622.gd` com auxiliar `scripts/apex_hud_rebroadcast_0668.gd`.

## 2. Erro de apresentação confirmado e corrigido

Comandos de pit destinados ao próximo tick eram gravados na fila (`RaceReplay.commands`, `cursor`, `sequence`) antes de atualizarem o campo oficial `pit_scheduled_lap`. Até então, a HUD não deixava claro ao jogador que a ordem estava pendente. Agora o adaptador visual consulta a fila **sem modificá-la** e apresenta P21, PBOX e CANC, diferenciados do confirmado V21 / BOX. O botão CHAMAR BOX também é desabilitado enquanto a solicitação está em fila para o piloto.

Os status não representam paradas executadas; somente a engine aplica os comandos. O teste nativo `hud_rebroadcast_06681_pending_orders.gd` realizou **30 verificações PASS**, incluindo agendamento, cancelamento, ordem imediata, tooltip, read-only do estado e do hash.

## 3. Regressões e simulação real

- Quatro pistas com a cena e HUD ativas, cada uma atravessando as três primeiras voltas: Silverstone dry 1426 ticks, Spa heavy rain 1867 ticks, Monza dry 1316 ticks, Singapore heavy rain 1842 ticks. Após mudanças de modo e atualizações, hashes instantâneos permaneceram iguais (PASS). **Não equivalem a quatro GPs de distância completa.**
- Monza, corrida integral de **53 voltas**, **24.431 ticks**, **24/24 carros classificados**, hash esportivo histórico `2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b`: **PASS**. Teste de engine headless, não reproduz um GP inteiro graficamente com a HUD.
- Replay integral de Monza: **PASS**. ticks=24431 seconds=437.999009
- Limite V21 × V4 em chuva, double stack no mesmo tick, replay 200 ticks, controle 1×/5×, Diretor TV (18 destaques reais, 26 trocas de câmera no teste curto) e migração de save legado: PASS nos testes específicos, ver matriz.
- Política de visualização Auto testada nas **18 combinações** de três modos HUD × seis velocidades, com prioridade das escolhas manuais de 2D e 3D e hash esportivo inalterado: PASS headless.
- Um replay importado buscou os ticks 150, 320 e 0 enquanto a HUD atualizava: o estado e o hash da corrida original (400 ticks) permaneceram idênticos (PASS).
- Preferência FULL sobreviveu ao encerramento e à inicialização de **um segundo processo** Godot; padrão COMPACT restaurado ao final.

## 4. Imagens do Godot

Foram capturadas cenas nativas nos modos BROADCAST, COMPACT e FULL a 1600×900 e 1920×1080, além de COMPACT 3D a 1600×900, com Xvfb/Mesa llvmpipe. A tentativa de 1366×768 produziu **1365×768**; classificada INCONCLUSIVE para resolução exata. Avisos de inicialização Vulkan e driver de áudio virtual são limitações do ambiente gráfico; renderização em software foi obtida. Essas imagens não são mockups nem prova de GPU/FPS real.

## 5. Benchmark A/B (mesma fixture, amostra de CPU)

Cinco processos por versão, 200 refreshes HUD por processo, seed 1208 e Silverstone seco, modo headless. Medianas observadas:

| Indicador | v0.6.6.8 | v0.6.6.8.1 |
|---|---:|---:|
| Tempo médio por refresh (mediana de 5 runs) | 1034.165 μs | 983.930 μs |
| Memória `Performance.MEMORY_STATIC` (mediana) | 105,134,729 bytes | 105,130,489 bytes |

Diferença observada nas medianas: **+4.86%** de redução de tempo; **INCONCLUSIVE** como alegação de otimização devido a jitter/concorrência com teste integral da corrida e ausência de medição de FPS/GPU. Isso não é speedup comprovado do jogo.

## 6. Matriz de testes

Total por categoria (antes da validação de reextração do ZIP): **{'PASS': 24, 'INCONCLUSIVE': 2, 'NOT_RUN': 4}**. Fonte completa: `APEX_TESTES_v0.6.6.8.1.json`; logs em `qa/hud_rebroadcast_06681/logs`.

## 7. Limitações

- Outros três GPs completos (Silverstone, Spa, Singapura): NOT_RUN (cada um coberto até três voltas na cena).
- Teste real de GPU Linux Mint, consumo de FPS com 10×/16×/32×, monitor exato 1366×768, operação manual humana: NOT_RUN ou INCONCLUSIVE.
- A referência esportiva de Monza é válida para o cenário e seed documentados; não equivale a uma validação de todas as estratégias meteorológicas.
- Não declarar release ESTÁVEL antes de homologar em hardware-alvo.

## 8. Rollback

Preserve os ZIPs v0.6.6.8 e v0.6.6.7.2.4. Se houver problema, feche o editor/jogo e abra a pasta extraída da versão anterior; faça cópia dos saves antes de alternar versões. O caminho `APEX_0650_SOUL_STAFF` continua idêntico e não houve migração de schema. A configuração `hud_rebroadcast_0668.cfg` é exclusiva da HUD.
