# Plano de engenharia posterior à v0.6.5.7
Uma funcionalidade principal por entrega. Cada versão começa com benchmark da anterior, auditoria de consumidores e saves isolados. Nenhuma proposta abaixo foi implementada nesta versão. Ganhos são hipóteses até medição comparável.

## v0.6.5.8 — Apresentação eficiente do estado
**Problema:** `main._process` copia profundamente os dicionários esportivos, incluindo históricos, e atualiza várias vistas. Profiler separa montagem de estados, mapas, 3D e HUD; usar resultados reais para priorizar.

**Arquivos:** `main.gd`, `apex_race_view_controller.gd`, `track_map.gd`, `track_3d.gd`, `apex_race_hud_0622.gd`, consumidores de minimapa. Novo `race_view_snapshot_0658.gd` somente se centralizar um contrato útil.

**Contrato/algoritmo:** inventariar chaves lidas por cada consumidor; `RaceViewSnapshot.build(cars, focus, presentation_clock)` com campos escalares necessários e estruturas somente leitura. Diferenciar eventos/lap history de estado visual. `needs_refresh(view, revision)` pode evitar atualizar vista invisível, mantendo reentrada correta. Retenção e interpolação visual não alteram `race.cars`. Primeiro preservar frequência; reduzir refresh somente em etapa separadamente medida dentro da mesma funcionalidade.

**Dependências:** profiler validado; mapa de campos e owners. **Riscos:** omitir pit_stage, radio, KERS, seleção, pausa ou flags de animação; alias mutável entrar no motor.

**Ganho esperado:** menos alocação/cópias de histórico; nenhuma promessa de FPS específico. **Aprovação:** hashes esportivos iguais; snapshots não modificam origem; callbacks de HUD/câmera, pausa, seguir piloto e pits funcionam; benchmark nativo repetido em 1600/1920, mesma seed/câmera/renderer; medir objetos e memória após reentrada.

## v0.6.5.9 — Cache e amostragem de geometria
**Problema:** ponto e direção 2D fazem buscas repetidas; ocupação 3D busca âncora sobre segmentos. Evitar cache novo se amostras atuais forem suficientes.

**Arquivos:** `track_map.gd`, `track_3d.gd`, `apex_racecraft_0654.gd`, `main.gd`; novo `track_geometry_sampler_0659.gd` se puder servir consumidores sem misturar coordenadas.

**Contrato/algoritmo:** `build(route, world_scale, revision)`, `sample(progress) -> {point,tangent,segment,arc}`, `invalidate(revision)`. Pré-computar comprimentos/tangentes; busca binária conjunta para ponto/direção; cache por tick/progress/revisão. Projetar origem 3D por segmento conhecido ou vizinhos e fallback global validado. Testar posição de pit lane separada da linha de corrida. Limites de pista usados por racecraft continuam calculados no espaço correto; não alterar largura para disfarçar clipping.

**Dependências:** snapshot visual estável e métricas das consultas. **Riscos:** emenda da volta, curvas de raio pequeno, tangente degenerada, rota alterada, ultrapassagens usando âncora errada.

**Ganho esperado:** menos consultas por carro/frame; custo de build separado. **Aprovação:** comparar amostras densas e aleatórias com implementação anterior, erro de posição/tangente com tolerância documentada; GBR/Monza/Singapura e pista procedural; fronteiras 0/1 e pit lane; mesmas classificações e eventos; ganho de CPU medido em consultas reais.

## v0.6.6.0 — Replay e simulação determinística
**Problema:** seed não basta para reproduzir inputs e decisões dependentes de sequência de ticks. Não assumir identidade entre plataformas de ponto flutuante.

**Arquivos:** `race_engine.gd`, `apex_race_commands.gd`, `apex_race_session_controller.gd`, telemetria, clima, campeonato. Novos `race_command_log_0660.gd`, `race_state_codec_0660.gd`, `race_replay_0660.gd`.

**Contrato/algoritmo:** comandos imutáveis `{tick, sequence, actor, type, payload}`; checkpoints versionados com RNG state/seed, clima, pneus, pits e decisões pendentes. `capture_state`, `restore_state`, `hash_sporting_state`, `advance_to_tick`. Hash de representação canônica (ordem de chaves/IDs definida). Reprodução aplica comandos gravados sem gerar decisões duas vezes; motor não depende de relógio real. Aceleração muda entrega de ticks, não delta lógico.

**Dependências:** contrato explícito de estado e comandos; compatibilidade de schemas e dados de pista. **Riscos:** callbacks/sinais duplicados, eventos omitidos, RNG extra, persistir objetos Godot, double stack/restauração parcial.

**Ganho esperado:** diagnóstico reproduzível e replay seek, não aceleração presumida. **Aprovação:** OFF/ON profiler idênticos; replays de seco/chuva/pits/defesa, checkpoint no meio de serviço e chuva; 1×/5×/20× versus headless com mesma sequência de ticks; detectar divergência no primeiro tick; política explícita de compatibilidade de replays entre versões.

## v0.6.6.1 — Disputas e ultrapassagens
**Problema:** enriquecer decisões de ataque/defesa sobre o modelo espacial existente, com oportunidades e desistências coerentes.

**Arquivos:** `core/race_space_0655.gd`, `race_engine.gd`, `apex_racecraft_0654.gd`, testes `sim_space`/`sim_engine`. Evitar reativar `race_combat.gd` como segundo controlador autoritativo.

**Contrato/algoritmo:** `evaluate_opportunity`, `select_attack_line`, `commit_defense`, `abort_attempt`; estados de intenção distintos do deslocamento. Avaliação determinística de velocidade relativa, largura/curvatura, distância de frenagem e terceiro carro. Uma defesa antecipada, manutenção de corredor com sobreposição e retorno só com distância segura. Otimização de vizinhos só se profiler justificar e preservar ordenação.

**Dependências:** replay/diagnóstico de tick; geometria validada. **Riscos:** deadlock, trens artificiais, ultrapassagem sem espaço, viés de ordem, múltiplas mudanças defensivas, diferença visual/simulação.

**Ganho esperado:** melhores decisões, possivelmente mais CPU; não prometer mais ultrapassagens como sinônimo de realismo. **Aprovação:** nenhum atravessamento no espaço de simulação, bloqueio estreito, ataque por linha livre, defensor ativo, retardatários e emenda da volta; GBR e dois circuitos sorteados com seed; relatórios de taxa de tentativa/sucesso/abandono e revisão de replay.

## v0.6.6.2 — Personalidade e rádio contextual
**Problema:** falas e intenções devem refletir eventos reais e personalidade sem decisões duplicadas ou spam.

**Arquivos:** `race_driver_soul_0647.gd`, `race_soul_driver_0636.gd`, `race_soul_reactive_0637.gd`, módulos de engenheiro e `apex_radio_feed.gd`, comandos e HUD de rádio.

**Contrato/algoritmo:** `RadioContext.from_event`, `DriverIntent.evaluate`, `RadioPolicy.select_message`; identificadores de evento, cooldowns por assunto, prioridade e deduplicação. Separar intenção do piloto, sugestão do engenheiro e ordem executável. Avaliações em eventos/lap, não a cada frame. RNG narrativo separado do esportivo ou escolha determinística pelo ID.

**Dependências:** log de eventos/replay, schema de Soul Driver. **Riscos:** rádio alterar RNG esportivo, sugerir pit impossível, contrariar ordem manual, repetir fala após restore.

**Ganho esperado:** coerência contextual, medível por taxa de mensagens sem causa e duplicações. **Aprovação:** nenhum pit executado só por fala em modo Manual, evento rastreável, cenários de degradação/chamada de box/companheiro, deduplicação e replay determinístico, localização/legibilidade.

## v0.6.6.3 — Estratégia e Pit Wall
**Problema:** medir erro de previsão e qualidade de decisões em chuva, fila, undercut/overcut sem misturar ajustes arbitrários de física.

**Arquivos:** `race_ai_director.gd`, `race_intelligence_0645.gd`, `race_pitwall_strategy_0649.gd`, módulos dynamic/lap strategy, Strategy Simulator e relatórios de pit; confirmar nomes por referências no motor.

**Contrato/algoritmo:** `PredictionLedger.record(prediction, tick)`, `settle(outcome)`, `evaluate_candidates` e `coordinate_team_pits`. Previsões versionadas contendo premissas/clima/tráfego; comparar custo previsto e realizado. Coordenação dos dois carros respeita autorização, janela e custo de espera. Não usar clima futuro perfeito fora do modelo disponível ao engenheiro.

**Dependências:** logs/replay, métricas de custo de planejamento e cenários representativos. **Riscos:** otimizar um GP e degradar outros, antecipação indevida de ordem agendada, pitting duplicado, overfit de seed.

**Ganho esperado:** menor erro de previsão e menos filas evitáveis; comparar distribuição em seeds de treino e validação. **Aprovação:** matriz seco/transição/chuva intensa, pneus e combustível, fila intencional versus evitável, agendamento manual inviolado, GPs completos de várias pistas e budgets de CPU.

## v0.6.7.x — Carreira persistente, em entregas separadas
**0.6.7.0 Calendário/múltiplas temporadas:** evoluir `championship_2012.gd`, Garage e calendário de gestão; `SeasonTransition.apply` idempotente, datas/horas reais de gestão, prazos de oficina vinculados a eventos. Migração explícita da meta operacional LF2; teste de virada e saves antes/depois, folha/prêmios uma vez.

**0.6.7.1 Mercado/academia:** reutilizar contratos, scouting e Soul; `DriverMarket.generate_candidates`, `ContractOffer.evaluate`, sem contratar recursos inexistentes. Riscos de inflação, IDs duplicados e rosters incompletos. Testar negociações, expiração, orçamento e distribuição de talento por seeds.

**0.6.7.2 Fábrica/P&D/regulamentos:** reutilizar `workshop_0656.gd`, inventário, níveis e projetos; `RegulationSet.validate_component` e `ResearchPlan.schedule`. Qualquer efeito esportivo novo de condição requer versão/testes próprios e modelo calibrado. Riscos de saves e peças ilegais; validar inventário/filas/custos, GP e migração.

**0.6.7.3 Adversários autônomos:** `RivalTeamPlanner.plan_week`, restrições iguais ao jogador, decisões registradas e orçamento finito; reusar Rival Development sem duplicar bônus. Testar várias temporadas e seeds, solvência, recursos e fairness.

**0.6.7.4 Históricos/dinastias:** registros append-only de campeões/equipes/pilotos, consultas indexadas fora do tick; migração e retenção explícitas. Testes de continuidade, IDs permanentes, consultas após dezenas de temporadas e tamanho do save.

**Ganho esperado geral:** continuidade e consequências de gestão; métricas de equilíbrio e integridade, não apenas volume de telas. Cada subversão só inicia após a anterior passar seus testes de aceitação e comparação esportiva apropriada.
