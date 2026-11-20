# APEX Motorsport Manager — Relatório técnico v0.6.6.6

**Módulo único:** Replay Fast Seek 1.0 — cache de navegação efêmero.
**Base real:** ZIP completo v0.6.6.5 Replay Checkpoint Coverage 1.0.
**Runtime:** Godot 4.7.2 stable Linux x86_64.

## 1. Diagnóstico e propósito

A v0.6.6.5 mantém 9 checkpoints históricos distribuídos, suficiente para limitar parte das buscas longas. Porém, cada novo clique em **Ir ao tick** restaurava novamente a última âncora histórica anterior e recalculava todos os ticks intermediários, mesmo quando o usuário acabara de visitar a mesma região. Essa repetição prejudicava navegação de análise de pit stop, ultrapassagem, incidente ou comparação de stints.

Esta versão otimiza **somente a experiência de navegação do replay**. Não muda decisões ou resultados da corrida, o número de checkpoints exportados ou o formato dos arquivos.

## 2. Implementação isolada

`scripts/core/race_replay_0660.gd`:

- Preserva `CHECKPOINT_TICKS=300` e `MAX_CHECKPOINTS=9`, bem como a política de cobertura introduzida na v0.6.6.5.
- Ao finalizar um seek válido, pode preservar seu estado em um novo checkpoint temporário comprimido ZSTD. Até quatro entradas, **12 MiB no conjunto de buffers comprimidos** (não é teto absoluto de RAM do processo).
- Escolhe o checkpoint permanente ou temporário mais recente que não ultrapasse o alvo. O estado atual da reprodução também pode ser reutilizado para seeks crescentes, se não estiver divergente.
- Mantém o **hash esportivo de verificação a cada tick efetivamente calculado**. O cache não contorna o verificador de estado de origem nem aceita estado atual adulterado como referência confiável.
- O snapshot auxiliar do observador `RacecraftAudit` preserva início da cobertura, último evento processado, contadores, pilotos, condições, amostras e estados prévios. Isso evita perder ou duplicar sinais somente por reutilizar o cache.
- Limpa o cache ao carregar outro replay/sessão. Antes do `seek(0)` da nova fonte, zera a referência ao motor anterior, resolvendo o caso do controlador reutilizado enquanto estava no tick zero.
- O cache não aparece em `checkpoint()`, `export_data()`, `save_file()` ou no contrato serializado de `load_file()`.

**Não modificados:** `scripts/race_engine.gd`, RNG, IA, física, KERS/DRS, pit wall, regras, pneus, clima, pit stops, pilotos/staff, oficina, HUD, código do Racecraft Audit e esquemas de persistência.

## 3. Comparação controlada: Monza com 3.200 ticks

**A/B verdadeiro, com o mesmo arquivo `.apexreplay` gerado na v0.6.6.5**, seed 660, 24 carros, pista ITA, condições secas, 18 alvos na mesma ordem, Godot 4.7.2 headless, processos sequenciais isolados.

| Indicador | v0.6.6.5 | v0.6.6.6 |
|---|---:|---:|
| Tempo agregado dos 18 seeks | **114,788497 s** | **35,369259 s** |
| Ganho na sequência | — | **3,2454x** |
| Redução do tempo agregado | — | **69,19%** |
| Primeiro seek no tick 750 | 4,338 s | 4,638 s |
| Seek 780 logo após o 750 | 5,189 s | 0,980 s |
| Revisita do tick 750 | 4,562 s | 0,030 s |
| Revisita do tick 1050 | 17,446 s | 0,027 s |
| Revisita do tick 2800 | 4,586 s | 0,077 s |
| Seek final até tick 3200 | 7,838 s | 7,990 s |
| `Performance.MEMORY_STATIC` ao final | 44.510.751 B | 45.412.744 B |

**Exatidão:** hashes esportivos **18/18 idênticos**, contadores e relatórios Racecraft **18/18 idênticos**; leitura de arquivo original da v0.6.6.2 confirmada nos dois processos. Mesmo hash de referência do tick 3200: `f771fab5025055653075f853b4a06370097d5af74843d2deea4cc8dc17be9b90`.

**Memória:** o monitor estático do Godot aumentou 901.993 bytes (~0,90 MB decimal) nessa comparação. Ao final, quatro âncoras de cache somavam 374.049 bytes em buffers comprimidos, com teto de 12 MiB. Não foi medido um A/B controlado do pico RSS total: **não afirmar redução de RAM**. O espaço do observador e os objetos temporários têm overhead adicional ao tamanho dos buffers comprimidos.

**Limitação:** não há promessa de busca fria mais rápida; certos seeks frios ficaram ligeiramente piores. Os tempos por busca têm variabilidade de máquina e não são média de múltiplas rodadas. O ganho de 3,2454x representa **a sequência exata de 18 navegações**, não FPS ou corrida acelerada.

Fixture reproduzível: `qa/replay_fast_seek_0666/fixture_monza3200_0665.apexreplay` (8.620.872 bytes), script `tests/replay_fast_seek_0666_benchmark.gd` e JSONs da comparação na pasta QA.

## 4. Replay histórico Monza 53 voltas

A v0.6.6.6 **importou o arquivo histórico completo da v0.6.6.5** (41.544.880 bytes) e realizou buscas de navegação. Não regravou uma nova corrida de 53 voltas.

- Gravação: **24.431 ticks, 24 carros**; hash esportivo final histórico `2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b` preservado.
- Alvos efetivamente verificados: **10.000 → 10.035 → 10.000 → 20.000 → 20.030 → 20.000 → 24.431 → 24.400 → 24.431**.
- Tempos respectivos da rodada (s): **55,810; 0,763; 0,164; 3,817; 0,772; 0,452; 2,429; 2,225; 0,650**.
- O mesmo relatório Racecraft reapareceu após o retorno ao tick 10.000, incluindo contadores, pilotos e início de cobertura no tick 7800.
- Todas as posições visitadas passaram pelo verificador de hash do estado; zero divergências reportadas.

**Não realizado nesta versão:** corrida nova de 53 voltas nem replay de todos os 24.431 ticks em ordem. O teste usa somente o arquivo histórico e os trechos necessários para as buscas. Não comparar os 55,810 s da busca fria de tick 10.000 com um teste anterior que usou ambiente e sequências diferentes.

## 5. Regressões de base

Os seguintes **15 testes foram aprovados com código de saída 0** após a otimização: contrato de cache, replay boundaries (inclui pit agendado na volta 21 que não vira parada na volta 4 com chuva), replay unitário 1x/2x/5x/16x/32x, integração UI e retorno à sessão ao vivo, compatibilidade de replays locais/externos, mudança de clima, Racecraft Audit, Driver Dynamics, Sim Engine, pit lane, migração de saves, oficina, inventário, Strategy Simulator e migração Soul Staff.

O teste de contrato inclui arquivos de replay legados, igualdade exata de `export_data()` antes/depois de navegar, tolerância a seek inválido, detecção de estado modificado e invalidação do cache na troca de fonte.

Logs individuais em `qa/replay_fast_seek_0666/logs/` e `qa_results_0666.json`. Cenários adicionais e validação do ZIP constam na matriz final anexada ao release.

## 6. Compatibilidade, limites e rollback

- `APEX_REPLAY_0660`, `SIMULATION_REVISION="0661_driver_dynamics"`, arquivos de campeonato e pasta `user://` não mudam.
- 9 checkpoints históricos exportáveis e até 4 temporários, que nunca entram no arquivo.
- Cache frio ainda depende de avanço determinístico e pode bloquear momentaneamente a interface em buscas de vários milhares de ticks. Otimização de agendamento assíncrono e UI é **outra funcionalidade futura**, fora desta versão.
- Não foi feito teste de estresse por 20 temporadas.
- Para reverter, usar o ZIP íntegro v0.6.6.5 numa pasta nova, depois de backup de `user://`.


## 7. Testes de circuito / visualização / extração limpa

As quatro provas curtas foram gravadas e reproduzidas tick a tick com hash histórico idêntico, 24 carros classificados e observador Racecraft consistente:

| Pista | Condição | Ticks | Hash esportivo |
|---|---|---:|---|
| GBR/Silverstone | Seco | 1.668 | `7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837` |
| BEL/Spa | Chuva intensa | 2.067 | `33c7c2d71e34779fb7e74f359f2663e0bea34074aaf4c655dc678f3b97fd8c0e` |
| ITA/Monza | Seco | 1.553 | `5d4c508a64dce8d1c481a3661f56c6bdf97a2a7a7bab37a5e290be5e54188592` |
| SIN/Singapura | Chuva intensa | 2.050 | `48085a06fed3d7761a58206673c03685043645d813ea809e0b76c968e94439c9` |

Renderizações de corrida reais do Godot Compatibility com Mesa llvmpipe e Xvfb: **1600×900** e **1920×1080**, ambas exportadas pelo viewport do Godot, sem montagem de imagens.

**Integridade da fonte:** 2.410 arquivos preexistentes no ZIP v0.6.6.5 confrontados byte a byte. Todos preservados; diferenças somente em `project.godot` e `scripts/core/race_replay_0660.gd`. O script esportivo `scripts/race_engine.gd` continua com SHA-256 `522327cc1bf06d0bcbe7e54d0eebf7c7026fdb0b0d8247e7d32f2d754e0aac7a`.

**ZIP preliminar testado:** 2.464 entradas e CRC válido; extração para pasta isolada, importação do editor Godot 4.7.2 sem parser errors; regressões de contrato do cache e agendamento de pit V21/chuva V4 aprovadas também na cópia extraída. O ZIP definitivo foi recompilado incorporando estes logs e checklist; seu checksum/CRC são auditados depois da montagem.

**Matriz final:** 30 casos aprovados, **0 reprovados, 2 não executados** (20 temporadas e reprodução integral sequencial da Monza longa). As linhas incluem testes de unidade, A/B, quatro GPs, arquivo longo, screenshots e verificações de empacotamento; não equivalem a 30 corridas independentes.
