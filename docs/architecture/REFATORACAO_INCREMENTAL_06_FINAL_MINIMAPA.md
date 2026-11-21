# Refatoração 06 — FINAL — Minimapa da HUD

Esta é a **última refatoração numerada da série 01–06**. Não abrir Refatoração 07 como continuação automática. Próximas alterações só mediante problema identificado ou nova funcionalidade aprovada.

## Escopo
Extraída apenas a montagem visual do painel MINIMAPA da HUD para `scripts/presentation/apex_hud_minimap_panel.gd`, preservando título, espaçamentos, estilo, botão `2D ↗`, callback `_set_view.bind(0)`, tamanho 190×143 e flags de expansão. A HUD permanece dona de `map_box`, `minimap`, `layout_hud()`, atribuição da rota `minimap.set_track(...)`, controle de câmeras, atualização e lógica.

Não alterar motor esportivo, Pit Wall, chuva, IA, física, RNG, replay, save ou estratégia.

## Gate obrigatório
Teste nativo `tests/hud_minimap_panel_refactor_test.gd` registrado na Core 2 CI; 13/13 workflows PASS no SHA da PR, incluindo visual, SaveGuard, Scenario Matrix 20 circuitos, Godot import e longa duração. Até lá, PR permanece draft. Erro de importação (exit 139) não é PASS e deve ser investigado/reexecutado sem esconder evidências.

## Rollback
Reverter somente PR 06 restaura a criação visual do minimapa em `_create_ui()`. Não há alteração de schema de save, algoritmo de rota ou simulação.

## Encerramento
Com esta PR aprovada e integrada, considerar concluído o **ciclo de refatorações 01–06**. Repriorizar desenvolvimento de funcionalidades do APEX, desempenho, QA e problemas comprovados; não refatorar por refatorar.
