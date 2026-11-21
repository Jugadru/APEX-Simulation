# Refatoração 04 — painel de atalhos do Pit Wall na HUD

## Escopo

O painel **PIT WALL / CENTRO DE DECISÕES**, exclusivo do modo FULL da HUD, agora é montado por `scripts/presentation/apex_hud_pitwall_quick_panel.gd`. O construtor recebe as mesmas funções auxiliares `_panel`, `_column`, `_line`, `_text`, `_btn` e o callback `_open_window`, por meio de `Callable`.

`scripts/apex_race_hud_0622.gd` mantém a propriedade `pit_quick_panel`, a visibilidade e layout responsivo, as janelas, os atalhos e todas as decisões esportivas. A ordem de criação dos nós e a posição do painel na árvore da HUD não mudam.

Os quatro comandos permanecem idênticos: **RESUMO** → `pitwall3`, **PLANO** → `estrategia`, **DECISÃO** → `engineer`, **ANÁLISE** → `graficos`. Foram preservados rótulos, tooltips, estilos do `HudSkin`, tamanhos de botões, separações e `pressed` signals.

## Validação

`tests/hud_pitwall_quick_panel_refactor_test.gd` verifica no Godot real a hierarquia do painel, a ordem das quatro ações, as dimensões dos botões e a ligação das funções com os mesmos argumentos. O teste integra o workflow Core 2.

A PR só pode sair de Draft e ser integrada quando todos os **13 workflows** (incluindo importação Godot, Core 2, SaveGuard, Scenario Matrix 20 circuitos, GdUnit4, Pit Wall Intelligence, regressão visual e longa duração) forem aprovados. Importações interrompidas (exit 134/139) devem ser analisadas e repetidas, nunca falsamente marcadas como sucesso.

## Fora do escopo

Não são alterados: `_open_window`, dados de corrida, Pit Wall strategy, IA, controle manual/automático, pit stops, rádio, desenho 3D, RNG, física 2012, save, replay ou hashes determinísticos.

## Rollback

Reverter apenas esta PR e restabelecer o bloco original de construção de `pit_quick_panel` em `_create_ui`. Não há migração de cenas ou saves.
