# Relatório de testes — v0.6.0 experimental

- Fonte: v0.5.9.0 Hotfix 2 testada pelo usuário no Godot (botão de iniciar e box automático funcionaram).
- `python3 tests/run_all_static.py`: **29/29 scripts aprovados** no ambiente de desenvolvimento. Algumas verificações históricas informam SKIP de comparação externa com artefatos não incluídos. Não substituem execução nativa.
- Preservados byte a byte: `scripts/race_engine.gd`, `scripts/core/race_team_autonomy.gd`, `scripts/track_map.gd`, `scripts/track_3d.gd`, `scripts/tv_director.gd`, `data/season_2012.json`.
- Arquivo de dados: **20 circuitos, 12 equipes, 24 pilotos** (base 2012 recebida).
- `tests/core_0600_championship_smoke_test.gd`: **preparado, não executado neste ambiente**, pois o binário Godot não está disponível. Ele usa arquivo temporário para não alterar a temporada pessoal.
- Teste F5 visual e jogo completo: **pendente no Linux Mint do usuário**.
- Salva dados **após uma corrida concluída**, não durante o GP.
- Pontuação histórica 2012: 25,18,15,12,10,8,6,4,2,1. Empates na tabela são ordenados provisoriamente pelo nome; desempate esportivo completo por resultados ainda é pendente.
- Receitas por etapa são créditos fictícios do jogo, não prêmios oficiais de 2012. GPs isolados não alteram a pontuação.
