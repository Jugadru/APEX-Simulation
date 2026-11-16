# APEX Motorsport Manager — v0.6.4.9.7

## Atualização única: coordenação automática preventiva de pit stops (dois pilotos)

Base integral: v0.6.4.9.6. Engine: Godot 4.7.2. Projeto-fonte completo.

### Mudança funcional

- Novo módulo puro `scripts/core/race_team_pit_coordination_06497.gd`: compara as próximas janelas recomendadas **dos dois carros da mesma equipe**, antes de o companheiro entrar no pit lane.
- Prioriza o piloto que ocupa a melhor posição na pista; o outro pode **antecipar em uma volta** se ambos projetam exatamente a mesma parada e a antecipação for segura.
- Se a antecipação não foi possível, pode **adiar em uma volta** dentro de uma janela seca, com desgaste e vida estimada seguros. Essa alternativa é apenas possível, não garantida.
- O estado de decisão é registrado em `team_pit_coord_06497`; ações efetivas são guardadas no histórico por stint, com evento identificável e limite de 12 entradas.
- É permitida **no máximo uma mudança por stint** devido a essa camada. Uma ação por volta anterior da v0.6.4.9.6 também impede uma segunda mudança consecutiva nesse stint.
- O Race Engineer e o Pit Wall apresentam a última decisão e sua justificativa.
- A coordenação não inclui telemetria futura perfeita, nem promete evitar todas as filas.

### Proteções

- Somente **controle IA**, para os dois pilotos da equipe. Qualquer controle Manual ou Assistido com pit Manual continua sem alterações automáticas.
- Agendamentos explícitos (incluindo V21), pit solicitado, pit urgente, carro em pit e carro finalizado são intocados.
- Nunca altera decisões sob chuva, crossover molhado, pneus críticos, vida estimada insuficiente, próximo da bandeirada ou candidato sem composto disponível.
- As proteções já existentes do Pit Wall, Race Engineer, Soul Driver, Staff e regras de pneus seguem ativas.

### Como abrir

1. Extraia todo este ZIP em uma nova pasta.
2. Importe `project.godot` no **Godot 4.7.2**.
3. Execute **F5**, inicie uma corrida.
4. Na HUD, abra **ENG.** ou **ESTRAT. → PIT WALL 3.0** para ver as justificativas.
5. No modo **Automático** dos pilotos, as decisões autorizadas podem ser executadas pela IA; no Manual elas são apenas consultivas.

### Saves

A pasta de dados do projeto é `APEX_06497_AUTO_TEAM_PIT`, separada das versões anteriores. Os saves originais não são transferidos automaticamente. Faça backup antes de importar saves antigos.

### Testes

Veja `RELATORIO_TESTES_06497.md` e `qa/06497/`. Uma captura real da interface encontra-se em `docs/APEX_06497_COORDENACAO_PITWALL_1600.png`; o texto de coordenação nesse screenshot foi injetado no **teste de interface** para avaliar a renderização e não representa uma ordem espontânea naquele instante do GP.

### Próxima versão (NÃO incluída)

`v0.6.4.9.8`: gráficos dinâmicos de desgaste e estratégia. Não foram implementados aqui.
