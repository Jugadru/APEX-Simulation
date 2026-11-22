# Refatoração 05 — Painel de condições climáticas da HUD

## Mudança

A construção do pequeno painel **CONDIÇÕES DA PISTA** foi extraída de `scripts/apex_race_hud_0622.gd` para `scripts/presentation/apex_hud_weather_panel.gd`.

O novo módulo apenas instancia um `PanelContainer`, uma coluna e dois `Label` com os textos, estilos e modo de quebra de linha que já existiam. A HUD principal preserva suas propriedades `weather_box` e `weather_line`, o posicionamento, o callback `minimum_size_changed.connect(layout_hud, CONNECT_DEFERRED)`, e a atualização dos dados meteorológicos em `refresh_hud()`.

Nenhuma alteração de previsão, intensidade de chuva, umidade, água na pista, probabilidade, Pit Wall, seleção de pneus, estratégia, física, IA, seed ou replays.

## Contrato de regressão

`tests/hud_weather_panel_refactor_test.gd` roda com Godot 4.7.2 no Core 2 e valida hierarquia, texto do título, texto inicial, dimensões tipográficas, cores, espaçamento, estilo de fundo, `AUTOWRAP_WORD_SMART` e possibilidade de conectar o relayout. A CI também executa as regressões visuais, SaveGuard, matriz de cenários dos 20 circuitos e testes de longa duração.

**A integração requer 13 de 13 workflows aprovados no commit final da PR.** Falha de importação Godot por encerramento do editor deve ser investigada e o job repetido, nunca transformada artificialmente em PASS.

## Reversão

Reverter exclusivamente esta PR devolve a criação do painel para `_create_ui()` e remove o novo construtor. As propriedades públicas da HUD e os dados esportivos não mudam; não há migração de saves, recursos ou cenas.
