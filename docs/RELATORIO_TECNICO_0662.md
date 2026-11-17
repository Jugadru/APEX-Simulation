# APEX Motorsport Manager — Relatório técnico v0.6.6.2

**Release:** Racecraft Telemetry 1.0 — observabilidade e validação de disputas  
**Base:** `APEX_MOTORSPORT_MANAGER_v0.6.6.1_DRIVER_DYNAMICS_COMPLETO.zip`  
**SHA-256 da base original:** `5bbcaa22742323be5b0a00d4cfccb1202764ebcc7a86beecd2903c2b296f6137`  
**Runtime de teste:** Godot 4.7.2 stable, Linux, sem GPU dedicada (capturas via OpenGL llvmpipe/Compatibility)

## Escopo

Foi acrescentado **somente um observador passivo de racecraft**, para medir os resultados que o simulador realmente gera, sem reprogramar o comportamento esportivo. O foco desta release foi diagnosticar ataques e defesas antes de recalibrar coeficientes. Uma IA mais agressiva artificialmente não foi adicionada.

### Arquivos de código

- `scripts/core/racecraft_audit_0662.gd` (novo): coleta de contadores de aproximação, sinais de ataque e defesa, recuo, início de duelo, ticks bloqueados, ultrapassagem confirmada, ganho de posição por outros motivos, contatos e erros; agregação por piloto, clima e perfil de risco; últimas 256 amostras.
- `scripts/core/race_replay_0660.gd` (alterado): integração após verificação de hash; `racecraft_report()`; reinicialização da análise no seek para não apresentar estatísticas obsoletas.
- `project.godot`: identificação da versão. Nenhum script de pneus, espaço, performance, estratégia, câmera, HUD, workshop ou IA foi alterado.
- `tests/racecraft_0662_*.gd` e `docs/RACECRAFT_TELEMETRY_0662.md`: fixtures e documentação de QA.

### Replay

Não houve revisão de física. `simulation_revision` permanece **`0661_driver_dynamics`** e `format` permanece **`APEX_REPLAY_0660`**; a observação é excluída do hash, do checkpoint e dos dados exportados do replay. Uma gravação de 250 ticks criada **com a instalação original v0.6.6.1** foi aberta e reproduzida pela v0.6.6.2 com hash idêntico (`a2a3a575f888c775be55ecf3c96c105c79367700b85a504074e0b4d1f8558e82`). O replay da v0.6.6.0 continua incompatível com as regras 0661/0662, como já era na versão anterior.

## Testes realizados — evidência real

| Teste | Resultado |
|---|---|
| Importação Godot 4.7.2 / análise de scripts | **PASS no segundo ciclo isolado** — sem erros de parser; primeira tentativa de importação limpa encerrou em falha 139 durante reimportação de recursos |
| `racecraft_0662_test.gd` | **PASS** — 1.027 verificações, 500 ticks comparativos, hashes idênticos com auditoria ativada/desativada, seek e recontagem |
| `driver_dynamics_0661_test.gd` | **PASS** — 17 verificações |
| `sim_space_0655_test.gd` | **PASS** |
| `replay_0660_test.gd` | **PASS** — 1×, 2×, 5×, 16× e 32× |
| `replay_0660_weather.gd` | **PASS** |
| `replay_0660_boundaries.gd` | **PASS** — inclui comando de pit V21 não executado na V4 sob chuva |
| Compatibilidade real: replay 0661 → 0662 | **PASS** — exportado na versão original e importado/reproduzido na nova |
| Captura gráfica 1600×900 | **PASS de captura**, pela execução Godot real; execução conjunta atingiu o timeout após salvar a primeira imagem |
| Captura gráfica 1920×1080 | **PASS**, execução própria com saída 0 |

### Corridas completas curtas (três voltas cada)

A classificação, os boxes e os hashes finais do motor são iguais aos da **v0.6.6.1** — prova direta de que a telemetria não altera o esporte. Cada replay foi percorrido novamente desde o checkpoint inicial, com os mesmos totais por piloto.

| GP | Condição | Ticks | Ataques registrados | Ultrapassagens confirmadas | Resultado |
|---|---|---:|---:|---:|---|
| Silverstone | Seco | 1668 | 91 | 4 | **PASS** |
| Spa | Chuva intensa | 2067 | 3 | 0 | **PASS** |
| Monza | Seco | 1553 | 84 | 5 | **PASS** |
| Singapura | Chuva intensa | 2050 | 6 | 0 | **PASS** |

Os eventos de ultrapassagem incluem somente `pass` classificado pelo motor; `position_gain` (boxes/ritmo) é contado separadamente. Na chuva, essas duas amostras observaram muito menos ataques; **isto não demonstra estatisticamente balanceamento correto para todas as sementes**.

## Teste de distância oficial

Foi iniciada uma corrida **Monza/ITA, 53 voltas (distância oficial), seco**, com 24 carros, pit stops e replay completo na mesma fixture dos testes curtos. A execução **NÃO CONCLUIU** no período de observação: depois de **13 minutos e 16 segundos** sem resultado terminal, o processo foi interrompido deliberadamente (saída 143). **Não há PASS, nem hash final verificado** para a corrida de distância oficial. O processo consumia CPU continuamente e atingiu cerca de **1.125.332 KiB de RAM residente** durante a tentativa. Essa observação recomenda investigar desempenho/uso de memória da simulação e do replay longos antes de declarar estabilidade de distância oficial; não há prova de que a telemetria tenha causado esse consumo.

Evidências: `qa/racecraft_0662/logs/ITA_full.log` e `qa/racecraft_0662/logs/memory_full.log`. Testes curtos de quatro GPs e replays completos desses GPs continuam **PASS**.

## Limitações e pendências

- O novo sistema é diagnóstico, **não é um painel novo na HUD**. A telemetria é consultável pela API `session.racecraft_report()` e pelos resultados dos testes armazenados em `qa/racecraft_0662/`.
- O identificador `battle` depende das mensagens táticas atuais para diferenciar ataque, defesa e recuo. Se os textos mudarem, o parser deve ser atualizado.
- `blocked_ticks` soma observações de 0,20 segundo por carro bloqueado; não representa número de incidentes independentes.
- Há um limite de 256 amostras recentes (contadores ilimitados durante a sessão). Se começar o replay de um checkpoint intermediário, o relatório indica `coverage=since_checkpoint`; nunca sugere análise de corrida integral.
- Os coeficientes não foram calibrados com telemetria histórica de 2012; nenhuma taxa de ultrapassagem foi forçada artificialmente.
- Uma importação limpa do pacote apresentou falha nativa 139 na primeira tentativa; após repetir na mesma pasta limpa, a importação concluiu com saída 0 e sem erros de parser, e o teste Driver Dynamics executou em cópia extraída. Vale observar reprodutibilidade desse erro de importação em outras máquinas.
- O teste oficial de Monza não concluiu em 13m16s e não recebeu PASS.
- O problema preexistente do teste histórico de migração Soul Staff 0650 foi identificado na v0.6.6.1 e **não foi corrigido nem reclassificado como PASS**. Testes completos de temporada e save de carreira continuam pendentes.
- Capturas com renderizador de software não medem desempenho GPU de usuário.

## Rollback e integridade

A versão `v0.6.6.1_DRIVER_DYNAMICS_COMPLETO.zip` original está intacta. O ZIP novo preserva `project.godot`, cenas, scripts, dados, recursos e testes; contém relatório e evidências. Após compactação, verificar CRC, checksum e importação de cópia limpa.
