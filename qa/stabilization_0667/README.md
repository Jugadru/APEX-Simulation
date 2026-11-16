# APEX v0.6.6.7.1 — manutenção do Pit Wall e QA

Base oficial: `APEX_MOTORSPORT_MANAGER_v0.6.6.7_TV_DIRECTOR_HIGHLIGHTS_COMPLETO.zip` (mantida intacta).

**Correção de jogo:** `scripts/core/race_replay_0660.gd` agora rejeita uma segunda ordem manual pendente para a mesma volta e equipe, ou uma substituição no mesmo tick do mesmo carro. Ordens do segundo piloto para volta diferente continuam válidas. A física, IA, Racecraft, Diretor TV, formato do replay e telemetria não foram modificados. Arquivos de replay anteriores continuam aceitos.

**Testes mantidos:** `tests/pitwall_0649_ui_test.gd` e `tests/core_0640_pitwall_intelligence_test.gd` agora observam os comandos *após* `step_tick()`; o teste 0640 verifica `replay_session.policy.fingerprints` em vez do cache anterior. Os testes originais estão guardados em `qa/stabilization_0667/legacy_*.txt`.

**Testes novos:** `tests/pitwall_0667_same_tick_regression.gd` (reprodução/proteção do bug) e `tests/career_0667_20_season_data_stress.gd` (400 resultados administrativos; não representa 400 GPs simulados).

**Estado validado:** 12 testes de regressão aprovados (quatro GPs curtos completos e seus replays, migração, integração e unidade), Pit Wall visual 1600×900 e 1920×1080 aprovado, 5 testes de estratégia (4 históricos imediatos aprovados + teste 0640 atualizado aprovado), Monza histórico 53 voltas com 9 buscas aprovado, nova corrida Monza 53 voltas com replay integral aprovado, estresse administrativo 20 campeonatos aprovado.

**Limitação:** o motor ainda trabalha com o campeonato histórico de 2012. O ensaio administrativo de 20 campeonatos não prova uma carreira de 20 anos realmente jogável. Testes de desempenho gráfico em GPU dedicada não foram realizados.

**Execução rápida:**

```bash
Godot_v4.7.2-stable_linux.x86_64 --headless --editor --import --path CAMINHO_DO_PROJETO
Godot_v4.7.2-stable_linux.x86_64 --headless --path CAMINHO_DO_PROJETO -s res://tests/pitwall_0667_same_tick_regression.gd
Godot_v4.7.2-stable_linux.x86_64 --headless --path CAMINHO_DO_PROJETO -s res://tests/replay_0660_boundaries.gd
```

Para o teste visual, use um display X11/Xvfb. Para o teste de migração, use um diretório `HOME` e `XDG_DATA_HOME` **isolado** para não misturar saves do usuário. Para Monza histórico, veja as variáveis de ambiente no teste `tests/replay_fast_seek_0666_monza53.gd` e não inclua replays pessoais no projeto distribuído.

**Rollback:** extraia o ZIP original v0.6.6.7 em pasta diferente; faça cópia dos saves antes de alterar instalações. Esta manutenção não converte nem apaga saves.
