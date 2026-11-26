# Changelog — APEX Motorsport Manager Core 2

## Unreleased — 9.23 Endurance Laboratory 1.0 (bounded FAST)

- Reutiliza FAST e os contratos existentes de replay/telemetria: fixture LAB sintética de 320 ticks, saturação do rádio e cache de busca, checkpoint comprimido, fork, recuperação do arquivo principal com temporário interrompido e rejeição de checksum inválido.
- Relata amostras de memória, contagens, percentis reais por tick e throughput headless informativo; não limita telemetria histórica nem altera runtime, RNG, revisão ou saves.
- FAST pendente; FULL e benchmark nativo não autorizados. Sem comprovação de 32x.

## Unreleased — 9.23 Advanced Architecture (revision capability policy)

- Centraliza as 18 regras de compatibilidade esportiva 023–040 em módulo puro, com máscara derivada de identificadores exatos; revisões desconhecidas não habilitam regras novas.
- Mantém exceção de largada 024/025, flags individuais e aliases públicos do motor; preserva a cadeia de dependências e o caso de sessão não anexada.
- Teste diferencial contra as listas literais pré-refatoração, revisões inválidas, flags e hash; FAST PASS (45889067854, 606 checks); hosted replay PASS 5/5 (45889072674), seis workflows esportivos PASS. PR #163 integrada em 5e71ad8620d23f869cd189355c0c8f9466d42ab0. Sem mudança esportiva, cache persistente, threads ou C++.


## Unreleased — 9.23 Spatial Context Cache (local lane geometry)

- Prepara uma vez por chamada de RaceSpace.plan a largura-base e os setores ordenados em Float64; reutiliza as referências somente de leitura do perfil para as cinco amostras de largura por carro.
- Preserva a função direta lane_limit como referência, intervalos semiabertos, wrap, ordem e precisão; não compartilha progresso resolvido, pares, decisões nem cache entre ticks.
- Regressão diferencial exata nos 20 circuitos, perfil ausente, setores sobrepostos, limites e offsets, mais testes esportivos existentes. FAST PASS no SHA 64c477fbd4fc4edb845f6d9a9986a29e5913ca29 (45887386446), 90.670 comparações exatas nos 20 circuitos e um sintético, Simulation Lab PASS (45887389075), seis workflows esportivos PASS. PR #162 integrada em df376c718472d7323da560fcf4935ecaf62900b3. Sem alegação de ganho de FPS ou retomada da REV2 inconclusiva.


## Unreleased — 9.23 Race Performance Engine 2.0 (same-tick setup reuse)

- Compartilha a avaliação de acerto de asa/freio/suspensão entre o cálculo de ritmo e o modelo de erros do piloto, com a mesma entrada congelada do carro e clima do tick.
- Sem cache entre carros/ticks, sem novos campos esportivos, sem alteração de fórmula, RNG, passo fixo ou revisão 040. APIs independentes conservam avaliação própria.
- Contador opcional no profiler para avaliações redundantes evitadas em curva; regressão compara bytes exatos nos caminhos direto e compartilhado, clima/acertos válidos e inválidos/fases. FAST PASS no SHA 93dd094efd3dd64b8f940e94e7aad5d4d81cdfb4 (45885487059), 15 comparações de ritmo e 60 de fases, seis workflows esportivos PASS, Simulation Lab PASS (45885489574). PR #161 integrada em 6cbf2a250cff207b18a760c893cdd7fd3dd2a1eb. Redução de chamadas não é ganho medido de FPS.


## Unreleased — 9.23 Race Behaviour Polish (diagnostic increment)

- Distingue sinais de ultrapassagem emitidos pelo rádio/eventos do incremento real de combat_passes no motor, sem modificar os contadores antigos.
- Mede segmentos consecutivos de bloqueio observados, por piloto, duração máxima em ticks e lacunas; não estima tempo perdido nem impõe uma regra de ultrapassagem.
- Mantém relatório separado, exportado no JSON de qualidade F8 sob demanda; preserva os diagnósticos em hot seek. Sem alterações esportivas, revisão 040 e saves/replays preservados.
- Testes de injeção, observação, cobertura, identidade de hashes e paridade de replay; cenário hospedado curto Monza seco/Silverstone chuva. FAST PASS no SHA 68cc6cb7a5e52fc7e438eea36fef0c06f17df89f (45883905530), 232/232 Quality, 27/27 F8, Simulation Lab PASS (45883909083), seis workflows esportivos adicionais PASS. PR #160 integrada em 4c315c8ce70c641f55702c6b2edaa6d980c83502. Nenhuma correção de física alegada.

## Unreleased — 9.23 Smart Graphics (runtime profiles)

- Perfis gráficos 3D no Controle da Corrida: Padrão, GTX 1650 e Econômico. Padrão e GTX preservam as configurações anteriores, inclusive APEX_GRAPHICS_PROFILE=gtx1650; Econômico reduz MSAA/TAA e alcance de sombras, sem SSAO.
- Perfil escolhido manualmente, válido durante a execução do jogo; não troca câmera, modo 2D/3D ou geometria, não reconstrói modelos e não modifica física. TAA somente Forward+; SSAO depende do renderizador.
- Regressão direcionada FAST na cena real, configurações e retorno ao padrão, seleção na HUD, alternância 2D/3D, hash esportivo e capturas Xvfb. FAST PASS 66/66 no SHA bed0659d90c03f711b4f6545d43e1667b2e5402a (45882028944), 24 modelos no tick zero; Graphics Lab PASS (45882029558), Race Engineer PASS. PR #159 integrada em b6a09c9ae68690da6ad3f8b22b1e65d687221f98. Sem ganho de FPS comprovado, teste nativo ou revisão visual humana.

## Unreleased — 9.23 Radio Polish (local speech queue)

- Limpa mensagens vencidas por relógio real e tempo esportivo antes de admitir/consumir fala; fila de oito preservada, prioridades maiores podem substituir a pior mensagem e empates mantêm a ordem anterior.
- Em 10x+ elimina mensagens comuns pendentes e interrompe fala não urgente; idioma indisponível não interrompe mensagens válidas. Seleção estável por ID de voz, normalização de locale e tentativa explícita após indisponibilidade.
- Reconstrução do histórico ao entrar, buscar ou sair do replay permanece textual, sem reproduzir mensagens arquivadas; falas futuras e consultas continuam usando a infraestrutura da 9.22.
- Teste direcionado com backend de fala controlado, sem fingir reprodução sonora. A escuta real, efeitos de rádio e sincronização fonética permanecem não verificados. FAST PASS (22/22) no SHA 3c9b09bc6626b2e8d86847cbba5f31c7ba6b8b1f, run 45880337210; Race Engineer 13/13, run 45880337108; PR #158 integrada em 23bec7d48a25aa56a553f7fd4845658e84695f70.

## Unreleased — 9.23 HUD Optimization (demand-driven proximity)

- Calcula a proximidade física O(N²) somente quando DIST. PISTA está selecionado; limpa o resultado ao sair do indicador, recalcula imediatamente na seleção e conserva textos/tooltips originais.
- Reutiliza a classificação já obtida no mesmo ciclo do apresentador, evitando uma ordenação redundante; callbacks independentes mantêm consulta própria. Nenhum cache esportivo ou alteração de frequência da HUD.
- Regressão ampliada no teste existente de Race Gaps: sete métricas sem projeção em 1/16/32x, paridade dos 24 textos e tooltips, seleção pausada, limpeza e hash esportivo. FAST PASS no SHA 55ba69441db20737e239c14f93eda1c450d068ca (run 45879382566), 105/105 Race Gaps, 13/13 jobs Race Engineer (45879382552); PR #157 integrada em bce1fe830e3a3d66a014012a53d705718ee82200. Redução de trabalho demonstrável por contagem, não ganho de FPS medido.

## Unreleased — 9.23 Race Quality Center (F8)

- Evolui o painel F8 original com abas Desempenho e Integridade esportiva; mantém controles e exportação CPU compatíveis.
- Mostra contadores, amostras, cobertura, lacunas e contexto do observador existente; distingue sem sessão, sem observações, desativado e cobertura parcial. Não inventa notas ou interpreta zero como certificação.
- Exibe velocidade solicitada e última medição válida, demanda acumulada e limite do backlog; invalida amostra na mudança de velocidade ou sessão. Não apresenta aceleração ativa quando pausado/finalizado.
- Exportação JSON de qualidade separada da original; atualização limitada à aba visível, sem novo observador por frame.
- Fixture gráfica direcionada no FAST existente: 26/26 PASS em Xvfb no SHA 3c3ee9a8cd1c09f25311c0abc433a332278bc658 (run 45878241985), incluindo duas capturas. PR #156 integrada em 626f8906965d5e78cbcb0e0d4ccf15e6c4a99667. Sem alegação de GPU nativa ou ganho de FPS.

## Unreleased — 9.23 Race Quality Analyzer (integrity observations)

- Evolui o RacecraftAudit existente com observações limitadas: identidade/classificação, tamanho do grid, estado numérico não finito, desgaste fora de faixa, tempos de pit/gaps negativos e recuo em pista entre ticks consecutivos.
- Registro de até 64 ocorrências recentes, contadores completos, seed/circuito, cobertura e ticks não observados. Sem nota artificial, reparo automático, mudanças esportivas ou alteração do formato de replay.
- Preserva dados diagnósticos em hot seek RAM e reinicia a cobertura após checkpoint; exclui pit e carros finalizados da comparação de recuo.
- Novo teste direcionado FAST: 214/214 PASS no candidato 4ee2045bb30f007c839e6470e2c9558fb27dda6d (run 45874861005); /lab simulation PASS (45874864587). PR #155 integrada em 3a767267c24305e1c6f9df5c3a4b48a0c4c84270.

## Unreleased — 9.23 Adaptive Scheduler (speed transitions)

- Ao reduzir explicitamente a velocidade interativa, descarta apenas a demanda de tempo de parede ainda não simulada em ticks inteiros; preserva a fase fracionária, o tick esportivo, comandos, RNG e hashes.
- Não altera orçamento de 12 ms, backlog 6/8/12, limite de 16 ticks por quadro, reprodução de arquivos, nem o contrato de advance() sem orçamento. Aumentar/reselecionar velocidade não altera o backlog; pausa continua sem avanço.
- Regressão no replay existente: transição real pelo controlador, saturação determinística, mudança pausada, paridade do próximo tick, preservação de comandos e fronteira de passo.
- Revisão esportiva 040 e versão registrada 9.22 mantidas enquanto a 9.23 está em desenvolvimento. FAST + APEX Test Lab e /lab replay PASS no candidato f5ecc0cd4e5da98b45f580f8dd5d42cf53d61e9d; PR #154 integrada em 6fe26c6557f47568f8998dc663467bf6ad8b4749. Não constitui ganho de throughput ou nova release.

## Unreleased — Performance Recovery 3.3 (Race Space Leader Resolution)

- Reutiliza limites laterais e longitudinais dos líderes já resolvidos, em cache Float64 local à chamada, mantendo a ordem original de inserção e as desigualdades estritas dos corredores.
- Preserva a propagação de restrições entre seguidores, o limite mínimo de posição inicial, os estados esportivos e a resolução física iterativa posterior.
- Acrescenta testes diferenciais em 96 grids determinísticos, incluindo empates, carros separados por volta, limites laterais, cadeia de três carros, vazio e carro isolado.
- Revisão esportiva 040, saves/replays e otimizações anteriores preservados por escopo. FAST e Lab A/B pendentes; nenhum ganho medido nesta etapa.

## Unreleased — Performance Recovery 3.2 (Race Space Physical Finalization)

- Cache local de posições iniciais, faixas, limites de corredores, elegibilidade passiva e referências de estados durante a resolução longitudinal iterativa.
- Mantém a ordem dos pares, posições resolvidas vivas, limites de iterações, critérios de prioridade, tolerâncias e aritmética de separação; nenhuma alteração na física pretendida.
- Teste diferencial com o solver anterior em 96 grids determinísticos e casos explícitos de propagação entre iterações, vazio e carro isolado.
- Preserva revisão esportiva 040, formatos de save/replay e otimizações 1.0, 2.0 e 3.1. FAST e Lab A/B pendentes; nenhum ganho medido nesta etapa.

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
