# Apex v0.6.1.2 — Hotfix de Parse Error

- Corrigida a indentação conflitante em `scripts/track_map.gd`, linhas da função `_draw_strategic_circuit()`.
- Corrigida a identificação da versão em `scripts/main.gd`, `project.godot` e janela.
- Adicionado teste Python para detectar mistura tabs/espaços e smoke nativo Godot para validar o carregamento de `main.gd` / `track_map.gd` / clima.
- Incluída a especificação entregue pelo usuário em `docs/HUD-RACE-060_ESPECIFICACAO.md`.
- Motor de corrida, IA, campeonato, equipe, pneus, clima, dados e câmeras **não foram alterados**.
- O mapa 2D continua com o novo desenho de pista vista de cima, com marcadores coloridos.

## Validação

O compilador/runner Godot 4 não está disponível no ambiente de criação. Foram realizados testes de estrutura e integridade; falta o teste de importação/F5 no Godot 4.7.2 do usuário.
