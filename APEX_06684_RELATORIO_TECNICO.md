# APEX Motorsport Manager v0.6.6.8.4 — Relatório técnico

**Base original:** `v0.6.6.8.3 — Core 2 Snapshot CPU` (SHA-256: `e4f4d39602c82c07a2ff5c354c111930fd1f9e65d18765b50f3c08bb07a0a4ad`)  
**Escopo:** otimização exclusiva de atualizações da HUD legada oculta. **Não reativamos APEX 2 Next Engine.**

## Problema comprovado

A HUD ReBroadcast é a interface exibida durante a corrida, mas `scripts/apex_race_ui_presenter.gd` ainda atualizava a antiga classificação de 24 linhas, os antigos cards, painéis de estratégia, diagnósticos e telemetria. Mesmo quando invisíveis, esses controles faziam formatação, cálculos de apresentação e alterações de propriedades visuais em toda atualização de UI.

## Correção

O presenter agora verifica `is_visible_in_tree()` dos painéis legados antes de renderizar essas áreas. A atualização esportiva, os eventos e comentários, o Pit Wall verdadeiro, o replay, a HUD ReBroadcast e a renderização 3D permanecem ativos. Se algum painel legado for explicitamente mostrado, ele volta a receber atualização. Nenhum módulo de física, IA, Pit Wall, replay ou save foi alterado.

**Arquivos existentes modificados:** `scripts/apex_race_ui_presenter.gd`, `scripts/main.gd` (título), `project.godot` (identificação). **Arquivos idênticos à base:** 2821 de 2824. Nenhum arquivo anterior foi removido.

## Benchmark A/B

Godot 4.7.2 headless, HUD COMPACT, grid de 24 carros, seed 660, **160 atualizações da interface por processo**, 3 pares de processos independentes, após 20 atualizações de aquecimento. Mediana dos totais: **1612.945 ms** (0.6.6.8.3) versus **1032.880 ms** (0.6.6.8.4), redução observada de **35.96%** nesse microbenchmark. A segunda repetição da versão nova foi mais lenta que a original, evidenciando variabilidade do ambiente. **Não equivale a aumento de FPS** nem prova redução global do tempo de execução de corrida.

## Integridade esportiva e testes

- PASS: 4 circuitos, **750 ticks por circuito**, hashes intermediários e estados esportivos idênticos aos arquivos de referência.
- PASS: 19 verificações de controle de atualização visual, incluindo atualização do painel antigo ao ser explicitamente exibido.
- PASS: ordem de pit manual V21, fila pendente, cancelamento, replay, Racecraft, Driver Dynamics e double stack.
- PASS: 18 combinações automáticas/manuais das câmeras 2D e 3D.
- INCONCLUSIVE: teste gráfico produziu captura real do Godot em 1600×900, mas o processo do renderizador virtual extrapolou o limite de execução depois de imprimir PASS; não o classificar como teste gráfico final aprovado.
- NOT_RUN: 53 voltas completas de Monza nesta versão, FPS em GPU real e 1366×768 no equipamento de destino.

Resumo da matriz: **14 PASS, 0 FAIL, 1 INCONCLUSIVE, 3 NOT_RUN**. A bateria automática conjunta foi interrompida pelo ambiente, e os testes individuais foram repetidos de forma separada. Logs brutos disponíveis em `qa/core2_06684/logs/`.

## Limitações

Não alterar funções de atualização da HUD antiga sem verificar sua visibilidade e possível reutilização futura. O custo real de 3D depende de GPU e renderização no PC do usuário. A HUD nova permanece visualmente igual. O Core 2 continua principal; Next Engine está fora do release.

## Rollback

Preservar a v0.6.6.8.3 em pasta separada. Fechar o jogo e abrir `project.godot` dessa versão anterior. O diretório de saves e o schema não mudaram; fazer backup dos saves do jogo antes de trocar versões.
