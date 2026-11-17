# Relatório de testes — v0.6.4.8 Team & Staff

Engine: Godot 4.7.2 stable, Linux. Ambiente isolado de saves por teste.

| Teste | Resultado | Escopo |
|---|---|---|
| Importador/editor `--headless --editor --quit` | PASS | Parser e compilação |
| `staff_0648_contracts_test.gd` | PASS | Candidatos, orçamento, contrato, pagamentos, rescisão, expiração, migração e efeitos |
| `staff_0648_career_integration_test.gd` | PASS | Recompensas e folha pela reconciliação real, sem duplicação, impacto em ritmo/KERS |
| `staff_0648_ui_test.gd` | PASS | Cena real, botões, cargos, contratação, UI 1600/1920, corrida, HUD |
| `race_0647_soul2_test.gd` | PASS | Soul Driver 2.0 e proteção de V21 |
| `race_0647_soul2_ui_test.gd` | PASS | HUD, rádio, Engineer 3, Soul 2.0 |
| `race_0646_engineer_3_test.gd` | PASS | Engenheiro, chuva 83, pit programado, rádio |
| `race_0645_intelligence_test.gd` | PASS | Race Intelligence e decisões |
| `track_0644_hud_integration_test.gd` | PASS | Pneus e dados da pista |
| `core_0640_pitwall_intelligence_test.gd` | PASS | Pit Wall, múltiplos modos, double stack |
| `core_0622_corner_hud_smoke_test.gd` | PASS | Geometria compacta de interface |
| `core_0642_save_migration_test.gd` | PASS | Migração de save legado |

Captura gráfica renderizada em 1600x900: `docs/APEX_0648_TEAM_STAFF_REAL.png`.
O screenshot foi obtido com Xvfb/Mesa. Mensagens de falha do dispositivo ALSA sem áudio físico não invalidam a renderização.

## Limitações dos resultados
Não foram reexecutadas as oito provas completas em passos de 0,20 segundo após o patch de Staff. O código-base de física não foi reescrito; ainda assim a compatibilidade de uma temporada inteira e o desempenho em GPU real necessitam validação adicional.
