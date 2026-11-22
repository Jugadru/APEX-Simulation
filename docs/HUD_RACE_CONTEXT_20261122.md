# HUD — contexto de corrida, 22/11/2026

Base: main 736ba64 (v0.6.6.9.8). Branch: feat/hud-race-context-20261122.

## Mudanças

- BOX amarelo separado das abas, com estado sem parada, programada Vn, pendente, confirmado e nos boxes. Comando original preservado; pendente continua bloqueando duplicação antes do tick.
- Identificação 1/2 + sigla do piloto, composto em badge e vida restante. Vizinhos da classificação e intervalos oficiais do motor nos cartões; não representam proximidade física de retardatários.
- Linha temporal AGORA / +5 / +10 / +15 minutos para água na linha, com barras e valores em mm. Previsões usam o nowcast observacional já existente, sem consultar calendário oculto de chuva. Atualização limitada a cada cinco segundos simulados. Incerteza nos tooltips e acesso à Central de Dados.
- Painéis grafite, cabeçalhos claros e geometria do estilo Manager preservados. Sem mudanças de física, schema ou revisão esportiva.

## Arquivos

HUD: scripts/apex_race_hud_0622.gd. Apresentadores: scripts/presentation/apex_hud_weather_panel.gd e apex_hud_race_context.gd. Testes: hud_race_context_test.gd, hud_context_20261122_visual.gd e ajuste do contrato de composição do painel climático.

## Evidências locais

Pasta qa/hud_context_20261122 (logs e capturas reais Godot 4.7.2/OpenGL/NVIDIA).

- PASS: importação final sem erros de scripts/recursos.
- PASS: 10 scripts em tests.json — painel climático, métricas, isolamento de replay, replay/determinismo, migração de saves, prevenção de fila, estratégia de chuva, ordenação Core2, Driver Soul e coordenação de pit.
- PASS: hud_race_context_test — vizinhos/líder/último/retardatário no resultado final, previsão molhada, imutabilidade e reset de previsão.
- PASS: regressão física grip/defense, 24 verificações; comandos pendentes, 30 verificações.
- PASS: GdUnit4, 2/2 casos.
- PASS: 13 capturas e verificações espaciais, 1600×900, 1920×1080 e janela1366×768 (canvas real1365×768). Abertura das quatro abas, isolamento esportivo, V21, BOX pendente/confirmado, detalhes meteorológicos e sessão com chuva real.
- PASS: quatro cenários de três voltas — Silverstone/Monza secos e Spa/Singapura com chuva intensa; hash esportivo intacto durante todas as atualizações da HUD. Ver scenarios.log.
- NOT_RUN: benchmark de FPS e GP completo; GitHub Actions desta alteração. Capturas nativas não equivalem a homologação de performance.

A primeira execução visual detectou um composto indisponível no cenário de teste. O teste agora usa o catálogo real e configura sessão isolada/Silverstone explicitamente. A revisão visual também detectou percentual do pneu comprimido; largura mínima corrigida e todas as capturas regeneradas.

Rollback: reverter o commit desta branch; nenhuma migração de save necessária.
