# v0.6.4.9 — Pit Wall & Estratégia 3.0

Base v0.6.4.8 integral. Adicionado painel opcional de estratégia de corrida em tempo real com cenários por piloto; projeção simples de retorno à pista, undercut/overcut consultivos, chuva e detecção de double stack. Comandos rápidos de agendamento manual são confirmados por clique e revalidados no motor. O sistema nunca sobrescreve uma parada existente sem ação explícita no controle clássico.

Novo `race_pitwall_strategy_0649.gd` com cálculos determinísticos puros; coordenação automática de no máximo uma volta **apenas quando comprovadamente segura**, sem atrasar condições críticas, agendamento manual ou urgência. Resumo legado de estratégia também atualizado. Soul 2.0, Race Engineer 3.0 e Staff 0.6.4.8 mantidos.

Validação e limitações em `RELATORIO_TESTES_0649.md` e `LEIA_PRIMEIRO_0649.md`. Mudança de diretório de saves para isolamento, sem migração automática de dados entre versões.
