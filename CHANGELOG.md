# Changelog — APEX Motorsport Manager Core 2

## Unreleased — Performance Recovery 3.1 (Race Space Tactical Optimization)

- Compartilha a observação congelada de separações circulares entre following e racecraft independente, evitando repetir a mesma busca de adversários quando ambos estão ativos.
- Preserva critérios distintos de prioridade, tolerância, desempate, ordem dos candidatos de vácuo, limites e percurso legado sem racecraft independente.
- Acrescenta testes diferenciais das duas buscas originais, incluindo fronteira da volta, posições iguais, distância limite e grids determinísticos.
- Revisão esportiva 040, saves/replays, Traffic Pack e Pass Completion preservados. FAST e A/B pendentes; nenhum ganho medido ou release publicada.

## Unreleased — Performance Recovery 2.0 (Pass Completion)

- Cache dos estados escalares de cada carro por chamada; elimina o mapa live não utilizado e evita avaliar a distância atual de pares que não podem iniciar confirmação nem possuem confirmação pendente.
- Preserva ordem original, regras de cruzamento, largura, folga, tempo de confirmação, cancelamento, exclusão por boxes/abandono e revisão esportiva 040.
- Teste diferencial contra a implementação anterior: 120 grids determinísticos, estados completos, contagens, continuação e imutabilidade da entrada histórica.
- FAST e comparação A/B no Development Lab pendentes; nenhuma melhoria medida ou release publicada até a homologação.

## Unreleased — Performance Recovery 1.0 (Traffic Pack)

- Preserva revisão esportiva 040, formatos de save/replay e regras do Traffic Pack.
- Adia dados exclusivos do líder para depois da ordenação por distância/ID; conserva DRS e duelos de todos os candidatos, fallback de ritmo, retardatários, boxes e ordem determinística.
- Reaproveita valores invariantes do observador dentro da mesma chamada. Não altera a busca quadrática nem a geometria.
- Acrescenta regressões direcionadas ao teste Traffic Mega já integrado ao FAST.
- Ganhos de desempenho e equivalência entre commits: pendentes de execução do Development Lab e FAST no SHA exato. Não constitui release homologada.

## v0.6.6.9.22 — Race Engineer 4.0

Integrada na PR #133, merge `b295e467fc73fdb54d724dc1ee042a771a267f7a`.

- Rádio contextual, diagnóstico e acompanhamento de erros e condições da corrida.
- Identidade e familiaridade piloto/engenheiro persistentes no campeonato, sem bônus esportivo.
- Fila de comunicação compartilhada, legendas PT, TTS local opcional e volume independente.
- Revisão esportiva 040 preservada; comunicação consultiva sem alterar BOX V21.
- FAST no merge aprovado; [validação específica final](https://github.com/Jugadru/APEX-Simulation/actions/runs/45643712708): 13/13 jobs. FULL, exportação 9.22 e GPU/áudio real não comprovados.
- Sincronização de metadados: README, project.godot, identificação da janela/prévia, documentação Linux e exportação reutilizável. Sem nova versão esportiva ou migração de saves. Testes desta sincronização dependem do CI do novo SHA.

[Relatório 9.22](docs/APEX_RELEASE_v0.6.6.9.22_RACE_ENGINEER.md).

## Versões anteriores

- [9.21 — Driver Error & Recovery](docs/APEX_RELEASE_v0.6.6.9.21_DRIVER_ERROR.md)
- [9.20.1 — Traffic Mega](docs/APEX_RELEASE_v0.6.6.9.20.1_TRAFFIC_MEGA.md)
- [9.20 — Driver Traffic](docs/APEX_RELEASE_v0.6.6.9.20_DRIVER_TRAFFIC.md)
- [9.19 — Corner Battle](docs/APEX_RELEASE_v0.6.6.9.19_CORNER_BATTLE.md)
- [9.18 — Wet Setups](docs/APEX_RELEASE_v0.6.6.9.18_WET_SETUPS.md)
- [9.17.12 — Coordination](docs/APEX_RELEASE_v0.6.6.9.17.12_COORDINATION.md)
- [Demais notas de versão](docs/) · [changelogs e relatórios históricos](docs/arquivo/README.md) · [README histórico](https://github.com/Jugadru/APEX-Simulation/blob/b295e467fc73fdb54d724dc1ee042a771a267f7a/README.md).
