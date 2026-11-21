# Refatoração 03 — painel visual de classificação da HUD

## Objetivo e escopo

O bloco de construção do painel de classificação (cabeçalho com navegação, scroll e 24 linhas) deixa de residir em `scripts/apex_race_hud_0622.gd` e passa a ser montado por `scripts/presentation/apex_hud_ranking_panel.gd`.

A HUD original mantém as referências `ranking`, `standings_title`, `standing_rows`; os handlers `_move_metric` e `_select_grid_car` continuam sendo os mesmos. Os estilos `HudSkin`, dimensões, textos, ordem de nós, nomes dos campos das linhas e ligações de sinais devem continuar idênticos.

## Arquitetura

O builder de apresentação recebe somente a cena pai, os estilos de seleção e *Callables* dos construtores existentes de UI e dos dois handlers. Retorna as referências visuais como `Dictionary`; não possui estado de corrida, não lê `RaceEngine`, não altera `host`, regras esportivas, RNG, replay, estratégia ou save.

A HUD permanece dona do desenho/layout responsivo, atualização das linhas, seleção, telemetria, rádio e comandos.

## Critérios de validação

- `tests/hud_ranking_panel_refactor_test.gd` no Godot real: existência do painel e título, 24 linhas, ordem dos seis nós de cada linha, valores iniciais, métricas de tamanho/separação, scroll horizontal e bindings reais de `pressed` do anterior/próximo e de cada piloto, incluindo os estilos normais/selecionados.
- A regressão visual existente compara captura de HUD 2D/3D, incluindo Silverstone.
- Todos os 13 workflows obrigatórios devem concluir com sucesso antes de integrar: Core 2, GdUnit4, SaveGuard, Pit Wall, Race Intelligence, Scenario Matrix (20 circuitos), longa duração, Benchmark, Quality Gate, auditoria, exportação, capturas e regressão visual.
- Se algum job abortar durante importação do Godot, investigar o log e reexecutar o job, sem mascarar falhas.

## Escopo explicitamente excluído

Nenhuma alteração de física, posicionamento em corrida, regras FIA 2012, pneus, clima, componentes 3D, câmera, taxa de quadros, persistência, estratégia de pit ou indicadores do replay. A estrutura de nós visual anterior é preservada.

## Rollback

Reverter apenas esta PR; repor o corpo antigo de construção do painel em `_create_ui`. As referências e handlers da HUD não foram renomeados.
