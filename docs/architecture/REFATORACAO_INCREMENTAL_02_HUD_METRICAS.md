# Refatoração 02 — métricas da classificação da HUD

## Escopo

Separar exclusivamente a apresentação textual das sete métricas da classificação de `scripts/apex_race_hud_0622.gd` em `scripts/presentation/apex_hud_standings_metric.gd`. A seleção da métrica, os nós visuais, o fluxo de atualização, a ordenação esportiva, os callbacks, os sinais, a lógica de pit e a telemetria permanecem na HUD original.

A fachada `_standing_value(sorted_cars, idx)` continua disponível e passa a delegar somente os textos. O componente usa callables injetados para os formatadores existentes de compostos e tempos de volta; ele não acessa nem altera `RaceEngine`, `host`, `rng`, a árvore de nós ou o arquivo de replay.

## Contrato e regressão

O teste `tests/hud_metric_refactor_test.gd` compara a saída *exatamente*, caractere a caractere, contra a expressão anterior, para os 7 modos, estado de corrida/final, líder/meio/último e um modo desconhecido. Também verifica que a renderização não alterou os dados de entrada. Executado por `APEX Core 2 - Godot 4.7.2 CI` com o marcador `HUD_METRIC_REFACTOR_PASS`.

Não há mudanças intencionais no visual, física, balanceamento, determinismo, calendário, estratégia, save ou replay.

## Verificação de integração

Manter esta PR em Draft até **13 de 13 workflows** aprovados (incluindo Core 2, SaveGuard, Scenario Matrix de 20 circuitos e longa duração). Se a importação Godot falhar antes dos testes (por exemplo, exit 139), repetir apenas jobs interrompidos e analisar o motivo; nunca forçar PASS. Se qualquer regressão esportiva for detectada, não integrar.

## Próxima etapa, separada

Inspecionar outro bloco autônomo da HUD, especialmente construção do painel ou atualização visual, mas não extrair rádio/estratégia/sinais/câmeras nesta versão. Cada extração exige teste real de paridade.

## Reversão

Reverter somente esta PR; a função `_standing_value` mantém exatamente sua assinatura, e as sete expressões originais podem retornar ao método sem migração de saves, cenas ou recursos.
