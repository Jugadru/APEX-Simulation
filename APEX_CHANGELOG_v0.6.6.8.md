# Changelog — APEX Motorsport Manager 0.6.6.8
## HUD ReBroadcast 2.0

### Adicionado
- Alternância direta e persistente de três modos **BROADCAST**, **COMPACT** (padrão) e **FULL** na HUD realmente utilizada pelo jogo.
- Persistência isolada no arquivo `user://hud_rebroadcast_0668.cfg` (sem migração de saves de carreira).
- Serviço visual `scripts/apex_hud_rebroadcast_0668.gd` para atualização incremental de labels, siglas, pneus, status de boxes e destaque do piloto.
- Painel **PIT WALL / CENTRO DE DECISÕES** visível no modo FULL. Atalhos acionam janelas existentes: Resumo → Pit Wall 3.0; Plano → Estratégia; Decisão → Engenheiro; Análise → Gráficos.
- Colunas de composto e ordem de boxes no leaderboard; métrica extra **Última volta**.
- Status contextual de corrida (AO VIVO, PAUSA, FINAL) e clima com valores atuais separados da previsão.

### Refinado
- Paleta, contraste, tipografia, layout responsivo e espaçamento da classificação e painel do clima.
- Manutenção das 24 linhas do leaderboard, sem reconstruir a lista a cada refresh.
- Visibilidade de cards conforme o modo; a pista permanece protagonista.

### Preservado
- Core 2, modelos esportivos, Racecraft, IA, KERS 2012, Pit Wall, comando manual V21, replay oficial, telemetria, minimapa 2D, apresentação 3D, Diretor TV, carreira e saves.
- O arquivo original v0.6.6.7.2.4 não foi alterado.

### Evidências
- Testes unitários, de integração e regressões registradas em `APEX_TESTES_v0.6.6.8.json`.
- Benchmark A/B limitado a 200 refreshes headless, em `APEX_BENCHMARK_REBROADCAST_v0.6.6.8.json`.
- Capturas reais Godot com Xvfb em `qa/hud_rebroadcast_0668/`.
- Status: **EXPERIMENTAL**; GPs completos e verificação em GPU do usuário ainda não executados.
