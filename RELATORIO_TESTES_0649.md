# RELATÓRIO DE TESTES — APEX v0.6.4.9 Pit Wall & Estratégia 3.0

**Data:** 09/11/2026. **Godot:** 4.7.2.stable.official, Linux x86_64. Importação editor em modo headless e renderização OpenGL/Mesa com Xvfb. Saves de ensaio isolados via `XDG_DATA_HOME`.

## Resultados confirmados

| Teste nativo | Resultado | Cobertura |
|---|---|---|
| Editor/importação Godot | PASS | parse e importação de scripts / recursos |
| `pitwall_0649_strategy_test.gd` | PASS | três cenários, análise somente leitura, chuva, V21, controle manual/assistido/automático, prevenção de double stack, adiamento seguro |
| `pitwall_0649_ui_test.gd` | PASS | menu Pit Wall no jogo 3D, dois pilotos, agendamento real, recusa mesma volta, preservação de agendamentos, modo AUTO e capturas reais 1600×900 e 1920×1080 |
| `race_0645_intelligence_test.gd` | PASS | IA Estratégica 2.0, Soul antigo, RNG e proteção V21 |
| `race_0646_engineer_3_test.gd` | PASS | Race Engineer 3.0, Staff, chuva 83%, V21 e rádio |
| `race_0647_soul2_test.gd` | PASS | memória, pedidos dos pilotos, ausência de ordens indevidas |
| `race_0647_soul2_ui_test.gd` (Xvfb) | PASS | HUD do rádio e estado Soul 2.0 |
| `staff_0648_contracts_test.gd` | PASS | contratos, remuneração, oficina, persistência |
| `staff_0648_career_integration_test.gd` | PASS | pagamentos, campanha e estratégia com Staff |
| `staff_0648_ui_test.gd` (Xvfb) | PASS | tela de Staff, navegação, UI responsiva, Race Engineer |
| `core_0640_pitwall_intelligence_test.gd` | PASS | autoridade de pit, modo misto, V21 e alertas |
| `core_0622_corner_hud_smoke_test.gd` | PASS | cartões, janelas sobrepostas e estratégia |
| `core_0635_soul_stint_smoke_test.gd` | PASS | rádio consultivo e divergência de stint |
| `core_0642_save_migration_test.gd` | PASS | compatibilidade de saves legados |
| `track_0644_hud_integration_test.gd` | PASS | pneus térmicos e dados reais do motor |

O teste `race_0647_soul2_ui_test` inicialmente não terminou em modo headless (que não fornece renderização de tela). Reexecutado com Xvfb, saiu com **status 0 e PASS**. Não tratar a primeira tentativa como evidência de falha de jogo.

## Verificações-chave

- O Pit Wall é uma função consultiva pura. Apenas callbacks de **agendamento/aceitação** executam ordens na simulação, com checagens de compostos, próxima entrada, modo Manual/Assistido e ocupação da garagem.
- O agendamento V21 não é substituído por uma recomendação V4, mesmo sob chuva intensa.
- O motor de física, pneus, chuva, pista, IA de comportamento, Staff, classificação e economia existentes não foram reescritos.
- A coordenação adicional da IA só adia **uma** volta quando os critérios de segurança estão satisfeitos; nunca em urgência ou condição crítica. O caminho antigo de prevenção de double stack continua em vigor.
- As imagens em `docs/APEX_0649_PITWALL_1600.png` e `docs/APEX_0649_PITWALL_1920.png` foram geradas pelo Godot real via Xvfb/Mesa.

## Não validado nesta entrega

Não houve corrida integral de todos os 20 GPs nem repetição da bateria nativa de 8 GPs da 0.6.4.5. A verificação da integração automática e de saves durante uma temporada completa requer bateria prolongada; o PASS dos testes curtos não equivale a tal resultado. O teste visual foi em software Mesa, não um benchmark de GPU real. Xvfb sem ALSA pode emitir aviso do áudio e usar dummy driver.

## Integridade

O manifesto `BUILD_MANIFEST_0649.json` e o arquivo SHA-256 junto ao ZIP identificam os arquivos desta entrega. Os manifestos das versões anteriores no projeto são históricos e não representam hashes atuais dos arquivos modificados na v0.6.4.9.
