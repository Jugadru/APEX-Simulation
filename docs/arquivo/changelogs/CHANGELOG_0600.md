# Changelog — v0.6.0 experimental

- **Nova camada:** `scripts/championship_2012.gd` — calendário, resultados, pontos, serial de temporada, salvar/carregar, classificação.
- **Menu:** `scripts/main.gd` — Nova Temporada, Continuar, GP Avulso, classificação, próximo GP, recompensa por etapa.
- **Oficina:** `scripts/garage.gd` — ledger idempotente de pagamentos por etapa e migração compatível de saves da v0.5.9.0; receitas fictícias, não dados históricos.
- **Configuração:** `project.godot` — rótulo correto 0.6.0, mantendo janela original 1600 × 900 e diretório persistente `ApexMotorsportManager`.
- **Teste nativo:** `tests/core_0600_championship_smoke_test.gd` — 20 etapas, pontuação, save, duplicidade, semente, reabrir.
- **Testes Python:** `tests/test_0600_campaign_static.py` e `tests/test_0600_no_regressions.py`.
- **Arquivados** três testes da 0.5.9.0 que exigiam especificamente o nome/hash da versão antiga, em `tests/historical_0590`. Seus requisitos de integridade de física e menu são cobertos por testes da 0.6.0.

A HUD 1920 × 1080 experimental feita anteriormente **não integra** esta entrega. O motor físico e o Diretor TV não foram modificados.
