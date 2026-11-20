# RELATÓRIO TÉCNICO — Apex v0.6.4.6 Race Engineer 3.0
Data: 09/11/2026
Engine: Godot 4.7.2.stable.official.ed1daf0bf

## Código alterado
- `scripts/apex_race_hud_0622.gd` — interface Race Engineer 3.0 e quatro perguntas de rádio; preservada HUD híbrida 0635.
- `project.godot` — nome da versão; pasta de dados híbrida mantida para continuidade do save.
- Novo `scripts/core/race_engineer_0646.gd` — análise determinística e textos contextuais.

## Código de produção original preservado
Comparação por CRC32 com o ZIP original `APEX_MOTORSPORT_MANAGER_v0.6.4.5_HUD_HIBRIDA_0635.zip`:
**somente dois arquivos preexistentes alterados**: `project.godot` e `scripts/apex_race_hud_0622.gd`.
Todos os outros arquivos preexistentes, incluindo `scripts/race_engine.gd`, os motores Core 2, a IA Estratégica 2.0, Soul Driver e física de pista/pneus, têm bytes idênticos.
A antiga bateria de oito GPs da v0.6.4.5 não foi repetida.

## Testes nativos realizados
- **PASS** `tests/race_0646_engineer_3_test.gd` — RE3_0646_PASS: pure planning, staff horizon, rain 83, V21, double stack, 4 radios, UI, manual pit, 0.20 native
- **PASS** `tests/race_0645_intelligence_test.gd` — APEX_0645_PASS strategy, guards, soul, RNG, native ticks, manual V21, HUD UI03
- **PASS** `tests/core_0640_pitwall_intelligence_test.gd` — APEX 0640 PIT WALL PASS: true BRA/71; individual MANUAL/ASSISTIDO/AUTO; V21; evidence; wet; double-stack; HUD; radio
- **PASS** `tests/core_0639_race_engineer_test.gd` — APEX 0639 ENGINEER PASS: 71-lap setup; immutable advice; V21; STAFF AI parity; HUD/manual/auto/radio
- **PASS** `tests/track_0644_hud_integration_test.gd` — APEX_0644_HUD_PASS: scene, PNEUS panel, thermal data, HUD, weather, 2 player cars
- **PASS** `tests/core_0622_corner_hud_smoke_test.gd` — PASS APEX 0622: native parse, corner cards, compact speed controls, upward panes and strategy
- **PASS** `tests/race_0646_visual_render_test.gd` — Xvfb/Mesa 1600×900 e 1920×1080, screenshots nativos.
- **PASS** Importação Godot headless inicial, sem erros de parse.
- **PASS** Validação de ZIP posterior (testzip e hashes).

## Casos de cobertura da v0.6.4.6
- Função de diagnóstico puramente de leitura, sem mutação de estado.
- Janela de pit válida, composto disponível, cenário com box já chamado, em andamento ou carro finalizado.
- Agendamento manual V21 **preservado** com umidade de 83% em caso unitário e também em corrida nativa configurada com **Chuva intensa**, com `step(0.20)`.
- Aviso de double stack quando piloto e companheiro concorrem pela garagem.
- Mudança de clima e antecipação consultiva de janela conforme nível do Estrategista.
- Respostas de rádio independentes para plano, pneus, chuva e tráfego/box.
- Throttle de repetição no rádio e estado da corrida/RNG intacto após perguntas.
- UI de ambos os pilotos com critérios de bloqueio e ações reais de pit manual.

## Observações
O status de decisão é derivado do motor v0.6.4.5. O novo consultor só libera o botão ACEITAR BOX se o estado real e a recomendação atual permitem; não inventa ordens.
Áudio de rádio em voz não foi implementado.
A renderização Xvfb usa Mesa software, portanto **não valida FPS em GPU real**.
A ausência de dispositivo de áudio no ambiente de teste pode produzir avisos de driver/dummy sem ser erro de script.
