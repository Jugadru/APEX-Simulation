# APEX — Roadmap Unificado 3.0 / numeração simplificada

Decisão do responsável: encerrar a sequência longa v0.6.6.9.* e usar v0.6.7, v0.6.8, v0.6.9, v0.7.0 e seguintes. Somente os números do planejamento futuro mudam; não há remoção, reordenação de funcionalidades ou reescrita de versões históricas. A nova numeração é uma convenção de desenvolvimento, não certificação de maturidade ou promessa de release. O Plano Mestre Unificado 2.0 continua como arquitetura e escopo. Este documento consolida a sequência de 44 atualizações (40 anteriores + 4 etapas de pesquisa nativa) aprovada na conversa, incluindo as quatro atualizações 9.36–9.39. A ordem histórica de 9.17.5/9.17.6 é reproduzida conforme o roadmap informado, não como auditoria dos títulos reais de releases; consultar changelog para histórico efetivo.

## Fase 1 — Estabilização e refinamento
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.17.3 | v0.6.6.9.17.3 | Race Motion Refinement | Histórico do roadmap |
| 9.17.4 | v0.6.6.9.17.4 | Largada competitiva — múltiplas sementes | Histórico do roadmap |
| 9.17.5 | v0.6.6.9.17.5 | Navigation Hotfix | Histórico do roadmap |
| 9.17.6 | v0.6.6.9.17.6 | Driver HUD Restoration | Histórico do roadmap |
| 9.17.7 | v0.6.6.9.17.7 | Race Traffic Hotfix | Histórico do roadmap |
| 9.17.8 | v0.6.6.9.17.8 | Main Menu Rework | Histórico do roadmap |
| 9.17.9 | v0.6.6.9.17.9 | Season Preparation Rework | Histórico do roadmap |
| 9.17.10 | v0.6.6.9.17.10 | Racing Line Intelligence 1.0 | Histórico do roadmap |
| 9.17.11 | v0.6.6.9.17.11 | Slipstream & Dirty Air 1.0 | Histórico do roadmap |
| 9.17.12 | v0.6.6.9.17.12 | Coordenação entre trajetória, ataque e defesa | Histórico do roadmap |

## Fase 2 — Inteligência esportiva
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.18 | v0.6.6.9.18 | Wet Weather Setups | Histórico do roadmap |
| 9.19 | v0.6.6.9.19 | Corner Battle Intelligence | Histórico do roadmap |
| 9.20 | v0.6.6.9.20 | Driver Traffic Intelligence | Histórico do roadmap |
| 9.21 | v0.6.6.9.21 | Driver Error & Recovery | Histórico do roadmap |
| 9.22 | v0.6.6.9.22 | Race Engineer | Histórico do roadmap |
| 9.23 | v0.6.6.9.23 | Race Quality & Performance | Histórico do roadmap |
| 9.23.1 (PR #166 provisoriamente 9.24) | v0.6.7 | Living Factory — Integridade operacional | Código integrado, FAST PASS |
| 9.24 | v0.6.8 | Race Randomness & Simulation Integrity 1.0 | Planejada |

## Fase 3 — Física e dinâmica veicular
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.25 | v0.6.9 | Braking & Acceleration Physics 1.0 | Planejada |
| 9.26 | v0.7.0 | Gearbox, Torque & Power Delivery | Planejada |
| 9.27 | v0.7.1 | Tyre Grip & Load Transfer | Planejada |
| 9.28 | v0.7.2 | Vehicle Dynamics Integration | Planejada |

### Fase 3A — Pesquisa do núcleo nativo
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| Nova etapa | v0.7.2.1 | Native Core Research — estudo de C++ | Planejada: pesquisa |
| Nova etapa | v0.7.2.2 | GDExtension Experimental — protótipo isolado | Planejada: experimental |
| Nova etapa | v0.7.2.3 | Native Core Benchmark — comparação GDScript × C++ | Planejada: avaliação |
| Nova etapa | v0.7.2.4 | Native Core Integration — somente se aprovado | Condicional |

## Fase 4 — Inteligência competitiva avançada
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.29 | v0.7.3 | Overtaking Preparation | Planejada |
| 9.30 | v0.7.4 | Braking Intelligence | Planejada |
| 9.31 | v0.7.5 | Side-by-Side Dynamics | Planejada |
| 9.32 | v0.7.6 | Defensive Intelligence | Planejada |
| 9.33 | v0.7.7 | Driver Mistakes & Recovery 2.0 | Planejada |
| 9.34 | v0.7.8 | Tyre Thermal Dynamics | Planejada |
| 9.35 | v0.7.9 | Racecraft Quality | Planejada |

## Fase 5 — Realismo mecânico, esportivo e estrutural
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.36 | v0.8.0 | Mechanical Reliability & Damage | Planejada |
| 9.37 | v0.8.1 | Race Control Intelligence | Planejada |
| 9.38 | v0.8.2 | Sporting Regulations | Planejada |
| 9.39 | v0.8.3 | Engineering & Factory Evolution | Planejada |

## Fase 6 — Engenharia profunda e fábrica inteligente
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.40 | v0.8.4 | Individual Component Engineering | Planejada |
| 9.41 | v0.8.5 | Manufacturing & Production Planning | Planejada |
| 9.42 | v0.8.6 | Engineering Prototypes | Planejada |
| 9.43 | v0.8.7 | Component Testing & Validation | Planejada |
| 9.44 | v0.8.8 | Factory-to-Track Correlation | Planejada |
| 9.45 | v0.8.9 | Quality Control & Reliability Management | Planejada |
| 9.46 | v0.9.0 | Technical Staff Intelligence | Planejada |

## Escopo preservado

- Integridade probabilística: RNG controlado, causalidade, incerteza e hashes/replay.
- Realismo mecânico: V8/câmbio, temperatura de motor/freios, hidráulica/elétrica, KERS/DRS, danos de asas/suspensão/assoalho/pneus, perda de ritmo, abandono, reparos e histórico.
- Race Control: bandeiras amarela/azul/vermelha, Safety Car, neutralização, relargada, investigação e segurança; estratégia condicionada aos eventos reais.
- Regulamentos: limites de pista, vantagem indevida, colisões/defesa, bandeiras, pit lane, drive-through, stop-and-go, grid, pneus, parque fechado, classificação e desclassificação; regras de 2012, sem VSC moderno.
- Engenharia: componentes individuais, produção com capacidade/filas/custos/recursos, protótipos com riscos, testes, instalação e correlação com pista, controle de qualidade, desgaste e inteligência do staff técnico. Evoluir Living Factory e Soul Staff, sem substituí-los.
- Escopo futuro sem numeração ainda: Soul Driver, Soul Staff, mercado de pilotos, academia, contratos/expectativas, patrocínios, finanças e economia, gestão dos rivais, Career Desk, Simulation Mode (Manual/Assistido/Automático quando aplicável), carreira multitemporada, Hall da Fama. Preservar também as demais metas e dependências do Plano Mestre Unificado 2.0.

## Regras de continuidade

- Versão integrada mais recente de gameplay: v0.6.7, PR #166, merge 2abe40cfdd86f161ef2dbe64fb2f12f8fd6f7822, FAST 45896250747 PASS. Nome de fixtures e revisão esportiva 040 não mudam.
- Próxima atualização: v0.6.8 — Race Randomness & Simulation Integrity 1.0. Não iniciada nesta consolidação.
- Uma funcionalidade por versão, PR própria, FAST exato e regressões direcionadas, preservar saves/replays/determinismo/2012. FULL e runner pessoal não são automáticos; seguir AGENTS.md.
- Nenhum novo binário, tag ou release publicado pela mudança de identificação. Histórico e arquivos de referência do Plano Mestre permanecem intactos.

---

# Detalhamento de escopo, dependências e critérios de aceitação

Complemento documental de 26/11/2026. As tabelas de numeração, estados,
escopo preservado e regras de continuidade acima permanecem como referência.
Os detalhes abaixo são especificações de planejamento, não afirmações de que
todas as funcionalidades históricas foram entregues. Para o histórico efetivo,
consultar CHANGELOG e PRs correspondentes. Para versões futuras, critérios
quantitativos devem ser fixados com baseline real antes da implementação, sem
ajustá-los para obter aprovação. Nenhuma versão é renumerada ou removida.

## Fase 1 — Estabilização e refinamento (referências históricas)

| Versão histórica | Objetivo e escopo de referência | Evidência esperada |
|---|---|---|
| v0.6.6.9.17.3 — Race Motion Refinement | Refinar deslocamento, interpolação, transições de ritmo e representação da corrida. Separar correção visual de mudança esportiva; não disfarçar travamentos com aumento artificial de velocidade. | Trajetórias contínuas em 2D/3D, sem saltos ou regressão de posições; hashes preservados se a mudança for apenas visual. |
| v0.6.6.9.17.4 — Largada competitiva | Reação, aderência, atributos e risco individual; validar largadas com múltiplas sementes em seco e chuva. | 24 carros, ordem de classificação coerente, diversidade entre sementes e repetibilidade dentro da mesma seed. |
| v0.6.6.9.17.5 — Navigation Hotfix | Retornos entre telas, rotas de menu, estado da sessão, seleção de equipe e continuidade do jogador. | Ida e volta em todas as rotas afetadas sem duplicação de telas ou perda indevida de dados. |
| v0.6.6.9.17.6 — Driver HUD Restoration | Retratos, nomes, equipes, cores e identidade dos pilotos; restaurar assets existentes com licença e fallback. | Identidade correta dos 24 pilotos, HUD e perfil consistentes, assets ausentes tratados sem crash. |
| v0.6.6.9.17.7 — Race Traffic Hotfix | Investigar congestionamentos, carros parando em curvas e bloqueios físicos; diagnosticar causa real e resolver impasses de forma coerente. | Casos de pista afetados, inclusive curvas apertadas; ausência de deadlock, sobreposição e teletransporte. |
| v0.6.6.9.17.8 — Main Menu Rework | Menu organizado, identidade visual, acesso a carreira, corrida rápida, configurações e carregamento. | Navegação completa, acessibilidade básica e preservação dos saves. |
| v0.6.6.9.17.9 — Season Preparation Rework | Preparação de temporada, equipe, pilotos, configurações e validação das condições iniciais. | Início de carreira coerente com as escolhas e sem duplicar registros. |
| v0.6.6.9.17.10 — Racing Line Intelligence 1.0 | Linha de referência, aproximação, ápice e saída; separar trajetória desejada e realizada; compromisso de linha e prevenção de zigue-zague. | Espaço físico respeitado, mudanças de linha estáveis e comportamento verificável nas curvas. |
| v0.6.6.9.17.11 — Slipstream & Dirty Air 1.0 | Redução de arrasto no vácuo e perda aerodinâmica em ar turbulento, segundo distância, alinhamento e contexto. Separar efeito aerodinâmico de decisão lateral. | Efeitos limitados, transições suaves e ausência de oscilação provocada pelo vácuo. |
| v0.6.6.9.17.12 — Coordenação entre trajetória, ataque e defesa | Coordenar intenções competitivas com ocupação do espaço e linha de corrida; evitar múltiplos sistemas comandando a direção. | Ataques e defesas sem trocas artificiais de posição, bloqueios permanentes ou zigue-zague. |

## Fase 2 — Finalização da inteligência esportiva

| Versão | Objetivo e escopo | Evidência esperada |
|---|---|---|
| v0.6.6.9.18 — Wet Weather Setups | Acertos de chuva com compromissos de equilíbrio, aderência e comportamento em condições variáveis. | Diferenças explicáveis entre setups, sem benefício universal; preservar a lógica de pneus e clima. |
| v0.6.6.9.19 — Corner Battle Intelligence | Escolha de linha interna/externa, disputa de ápice, entradas e saídas de curva, avaliação do risco. | Disputas plausíveis e respeito ao espaço; regressão de trajetória. |
| v0.6.6.9.20 — Driver Traffic Intelligence | Leitura de ritmo relativo, grupos, retardatários e oportunidade de ultrapassar; gestão de perda de tempo. | Tráfego realista, sem bloqueios artificiais; comportamentos de aproximação e espera verificáveis. |
| v0.6.6.9.21 — Driver Error & Recovery | Erros individuais condicionados às circunstâncias, habilidade e pressão; recuperação de ritmo com consequência esportiva. | Erros reproduzíveis, diferenças estatísticas coerentes e ausência de punição arbitrária ao jogador. |
| v0.6.6.9.22 — Race Engineer | Comunicação baseada em telemetria, pneus, ritmo, tráfego e estratégia; recomendações, pedidos de pilotos e ordens autorizadas. | Rádio contextual sem informação futura, spam ou alteração indevida de ordens manuais. |
| v0.6.6.9.23 — Race Quality & Performance | Consolidar qualidade esportiva, estabilidade, movimentação e desempenho com medições. | Regressões direcionadas; comparar CPU, memória e hashes com baseline apropriado; não confundir headless com FPS real. |
| v0.6.7 — Living Factory: Integridade operacional | Oficina, ordens de serviço, inventário, componentes persistentes e continuidade dos dados. Código integrado na PR #166; numeração sincronizada pela PR #167. | Registro histórico informado: FAST PASS, 28 testes selecionados e 23/23 verificações da funcionalidade; oficina, inventário, migração e replay. Não implica homologação FULL ou publicação. |
| v0.6.8 — Race Randomness & Simulation Integrity 1.0 | Seeds automáticas internas para carreira e corrida rápida; reprodução de cenário pelo Test Lab; avaliar subfluxos RNG independentes por domínio e entidade; probabilidades condicionadas ao estado real e não roteiro de eventos; serializar estado RNG e versão do algoritmo. | Mesma revisão, seed, estado inicial e comandos produzem resultado igual; seeds diferentes geram diversidade calibrada; alterar rádio/visual ou desativar replay não afeta resultado esportivo; save/load e replay legado funcionam com revisão apropriada. |

### v0.6.8 — limites de implementação

Auditar consumidores de RNG existentes, formatos de seed, estados persistidos
e revisão esportiva antes de alterar o código. Derivar substreams de forma
estável, com IDs de domínio explícitos, sem depender de ordem de iteração,
clock ou hash instável. Geração automática de seed ocorre na criação da
sessão, não durante a simulação. Separar RNG cosmético do esportivo.
Não introduzir falhas mecânicas, novo modelo de pneus ou física longitudinal
nesta versão. Não prometer hashes iguais entre revisões esportivas diferentes:
preservar leitores/migração e testar continuidade dentro de cada revisão.
Usar probabilidades por evento ou intervalo coerente, evitando a multiplicação
inadvertida de chances por tick ou velocidade de apresentação.

## Fase 3 — Física e dinâmica veicular

| Versão | Objetivo, entregáveis e dependência | Evidência esperada |
|---|---|---|
| v0.6.9 — Braking & Acceleration Physics 1.0 | Auditar discrepância entre velocidade esportiva e representação visual; perfil de velocidade por distância, curvatura e aderência, frenagem antecipada, ápice e aceleração progressiva; integração longitudinal com passo fixo e unidades consistentes. O tempo de volta deve emergir do movimento, não impor uma velocidade artificial para alcançar um tempo. Base: trajetória e v0.6.8. | Telemetria velocidade/distância, aceleração e frenagem; curvas lentas/rápidas, seco/chuva, massa e pneus; ausência de saltos e tempo de volta coerente com distância percorrida. |
| v0.7.0 — Gearbox, Torque & Power Delivery | Evoluir a aceleração com motor V8, curvas de torque/potência, relações de marcha, rotações, troca de marcha, arrasto e KERS conforme 2012; DRS respeita elegibilidade. Base: v0.6.9. | Aceleração e velocidade máxima plausíveis; efeitos distintos de marchas, potência, arrasto e KERS; sem energia ou velocidade instantânea fictícia. |
| v0.7.1 — Tyre Grip & Load Transfer | Aderência longitudinal/lateral combinada, sensibilidade à carga, transferência longitudinal e lateral, desgaste e molhado; modelo reduzido calibrável para manager. Base: v0.6.9–0.7.0. | Limites coerentes ao frear e virar simultaneamente; variação de carga e aderência sem instabilidade numérica; testes de seco/chuva e pneus gastos. |
| v0.7.2 — Vehicle Dynamics Integration | Integrar propulsão, frenagem, pneus, carga, aerodinâmica, trajetória e estratégia em uma única fonte de estado esportivo; remover dupla contagem de bônus. | Voltas completas, 24 carros, 2D/3D representando o mesmo estado, replay e save/load; orçamento de CPU medido. |

Os modelos físicos devem ser proporcionais a um simulador gerencial de 24
carros; não exigir CFD ou simulação integral de pneus. A camada visual pode
interpolar snapshots, mas não inventar resultados. A versão 0.6.9 trata
capacidade física de frear/acelerar; a 0.7.4 trata escolha do piloto, evitando
a duplicação das responsabilidades. Perfis de velocidade e referências de
tempo podem auxiliar calibração e previsão, não substituir o cálculo esportivo.

## Fase 3A — Pesquisa e avaliação do núcleo nativo (0.7.2.1–0.7.2.4)

Inserção aprovada no planejamento de 26/11/2026: quatro etapas entre
Vehicle Dynamics Integration (0.7.2) e Overtaking Preparation (0.7.3).
Nenhuma versão existente é removida, renumerada ou reordenada. O objetivo
é investigar se uma extensão C++ beneficia gargalos reais da simulação,
mantendo GDScript como implementação de referência e alternativa funcional.
A existência de um protótipo não autoriza a integração.

| Versão | Objetivo, entregáveis e dependência | Evidência esperada |
|---|---|---|
| v0.7.2.1 — Native Core Research | Após estabilizar 0.7.2, perfilar ticks e memória; localizar gargalos computacionais; estudar GDExtension, godot-cpp, compatibilidade com Godot 4.7.2, compilação Linux/Windows, licença, custo de manutenção e fronteira de API. Selecionar um candidato pequeno, de preferência cálculo puro em lote, sem UI, RNG próprio ou acesso à árvore de cenas. | Relatório com baseline exato, hotspot medido, alternativas GDScript e C++, riscos, plano de equivalência e critérios de benchmark definidos antes da medição. Sem alteração no motor de produção. |
| v0.7.2.2 — GDExtension Experimental | Construir protótipo C++ isolado em ambiente/branch de pesquisa; interface de dados mínima, passagem em lote, unidades e ordem de operações documentadas. Não substituir o motor; manter o jogo executável sem biblioteca experimental. | Testes de entradas/saídas contra implementação GDScript, limites, erros, estabilidade, repetição determinística e prova de compilação/carregamento nas plataformas testadas; reportar plataformas não verificadas. |
| v0.7.2.3 — Native Core Benchmark | Comparar GDScript e C++ equivalentes, com SHAs, hardware, build, sementes e workloads fixados; medir função isolada e simulação integrada de 24 carros, incluindo custo de conversão de dados e chamada à extensão. Aquecimento, repetições e dispersão; CPU por tick, tempo total, memória e estabilidade, em velocidades de simulação relevantes. | Relatório reproduzível com todos os resultados, equivalência esportiva e ganho global além do ruído e do custo de integração. Critérios de aprovação definidos antes dos testes; resultado negativo ou inconclusivo é legítimo. Não inferir FPS/GPU de headless. |
| v0.7.2.4 — Native Core Integration | Somente após aprovação explícita do responsável e evidências suficientes de 0.7.2.3: integrar apenas módulos aprovados mediante adaptador, seleção de backend e fallback GDScript; empacotamento Linux/Windows, versionamento da ABI e testes de compatibilidade. Não reescrever o motor inteiro nem migrar UI/gestão por conveniência. | FAST no SHA exato, Test Lab, regressões direcionadas, equivalência entre backends conforme contrato, determinismo por revisão, saves/replays, execução sem extensão e rollback testado. Verificar binários antes de distribuição. Sem ganho comprovado ou com regressão essencial, não integrar; manter GDScript e seguir para 0.7.3. |

### Contrato de integridade e decisão

- Fixar o escopo e a referência GDScript da 0.7.2; não introduzir nova física
  junto à tradução de código. Não usar C++ para mascarar um algoritmo ruim.
- Preservar passo fixo, unidades, ordem estável, RNG esportivo e semântica de
  comandos. Auditar precisão numérica, arredondamento, compilador e flags;
  evitar otimizações que invalidem os contratos de determinismo.
- Exigir equivalência dos resultados esportivos conforme o contrato da revisão;
  qualquer tolerância numérica intermediária deve ser definida previamente e
  não pode ocultar divergências em decisões, eventos ou classificação.
  Não prometer igualdade binária de ponto flutuante entre plataformas sem prova.
- Manter uma fonte de estado esportivo. O backend nativo calcula; não deve criar
  estado paralelo incoerente, consumir RNG cosmético ou alterar save/replay
  silenciosamente. Se a revisão exigir migração, documentar e testar antes.
- Comparar primeiro otimizações algorítmicas em GDScript. O custo de manutenção,
  compilação, depuração e distribuição da extensão entra na decisão.
- FAST + APEX Test Lab e regressões direcionadas permanecem obrigatórios.
  Benchmark pesado, FULL e runner pessoal seguem AGENTS.md e exigem
  autorização quando aplicável; não executá-los automaticamente.
- A etapa 0.7.2.4 pode terminar como não integrada, com justificativa registrada.
  A continuidade de 0.7.3–0.9.0 não depende da adoção de C++.

## Fase 4 — Inteligência competitiva avançada

| Versão | Objetivo, entregáveis e dependência | Evidência esperada |
|---|---|---|
| v0.7.3 — Overtaking Preparation | Preparar ataque ao longo de várias curvas: saída anterior, diferença de ritmo, vácuo, posicionamento, disponibilidade legal de KERS/DRS e janela de oportunidade. Base: v0.7.2. | Intenção persistente e desistência quando a oportunidade desaparece; ultrapassagem por progresso real, não por sorteio de posição. |
| v0.7.4 — Braking Intelligence | Escolha de ponto e intensidade de frenagem conforme habilidade, agressividade, confiança, pneus, visibilidade e tráfego; atacar, defender ou poupar. Base: física v0.6.9 e preparação v0.7.3. | Pilotos com perfis distinguíveis, frenagem limitada pela aderência, riscos proporcionais; sem ganho obrigatório por frear tarde. |
| v0.7.5 — Side-by-Side Dynamics | Disputas persistentes lado a lado, envelopes físicos, linhas alternativas, espaço negociado, compromisso de trajetória e saída de curva. | Sem atravessar carros ou trocar posições artificialmente; resoluções de disputa em curvas estreitas e rápidas. |
| v0.7.6 — Defensive Intelligence | Defender linha interna, antecipar ataque, escolher custo/benefício, ceder quando necessário; respeito às regras aplicáveis. | Defesas coerentes sem zigue-zague, bloqueios indefinidos ou perda de tempo artificial; interação com v0.7.3–0.7.5. |
| v0.7.7 — Driver Mistakes & Recovery 2.0 | Evoluir v9.21 com erros de frenagem, perda de ápice, travamento, escapada e recuperação gradual; consequências dependentes da física e do risco. | Frequências calibradas em múltiplas seeds, diferenças entre atributos, recuperação não instantânea e determinismo. |
| v0.7.8 — Tyre Thermal Dynamics | Estado térmico de pneus, aquecimento, resfriamento, janela de funcionamento, efeitos de pilotagem, clima e pit; avaliar graining e blistering em modelo calibrado. | Temperaturas limitadas, evolução temporal coerente, aderência/desgaste acoplados sem dupla penalização; persistência e desempenho. |
| v0.7.9 — Racecraft Quality | Consolidar as seis versões anteriores, ajustar interações e balancear risco e ritmo; proteger estratégia, ordens manuais e desempenho. | Corridas representativas com múltiplas seeds, testes de batalha e tráfego, dados de CPU/memória e inspeção visual quando disponível. |

## Fase 5 — Realismo mecânico, esportivo e estrutural

| Versão | Objetivo, entregáveis e dependência | Evidência esperada |
|---|---|---|
| v0.8.0 — Mechanical Reliability & Damage | Componentes com identidade, desgaste, temperatura, quilometragem e confiabilidade; motor V8, câmbio, elétrica/hidráulica, freios, KERS/DRS, asas, assoalho, suspensão e pneus; falha gradual, dano, reparo, abandono e histórico. Base: RNG v0.6.8, dinâmica v0.7.2 e fábrica v0.6.7. | Falhas condicionadas a causas reais, sem roteiro arbitrário; deterioração e reparos consistentes; inventário e histórico persistentes; casos de abandono e corrida sem falhas. |
| v0.8.1 — Race Control Intelligence | Máquina de estados da direção de prova: amarelas, azuis, vermelhas, Safety Car, neutralização e relargada; detecção de perigo e incidentes; comunicação e coordenação estratégica. Base: incidentes e falhas v0.8.0. | Transições legais, restrição de ultrapassagens, retomada consistente, fila de SC sem deadlock e estratégias reagindo aos eventos reais; sem VSC na temporada de 2012. |
| v0.8.2 — Sporting Regulations | Evoluir regras de 2012 verificadas em documentação histórica: limites de pista e vantagem, colisões/defesa, bandeiras, pit lane, penalidades, grid, pneus, parque fechado, classificação e desclassificação. Base: v0.8.1. | Casos positivos/negativos por regra, eventos auditáveis, penalidades sem duplicação, resultado final consistente; não transportar regulamento moderno para 2012. |
| v0.8.3 — Engineering & Factory Evolution | Integrar departamentos de engenharia, projetos, custos, prazos, fabricação, instalação e feedback de pista; usar componentes persistentes da Living Factory, telemetria e confiabilidade reais. Base: v0.6.7, v0.7.2 e v0.8.0. | Ciclo projeto–produção–instalação–pista–feedback funcional, orçamento/estoque coerentes, sem upgrades instantâneos abstratos ou duplicação de sistemas. |

## Fase 6 — Engenharia profunda e fábrica inteligente

| Versão | Objetivo, entregáveis e dependência | Evidência esperada |
|---|---|---|
| v0.8.4 — Individual Component Engineering | Componentes e revisões individuais: geometria/parâmetros técnicos simplificados, metas, compromissos de desempenho/confiabilidade/custo, compatibilidade e rastreabilidade. Evoluir modelos existentes, não substituir catálogo sem necessidade. | Duas revisões da mesma peça têm identidades e efeitos distintos; instalação compatível, efeitos físicos rastreáveis, saves antigos preservados. |
| v0.8.5 — Manufacturing & Production Planning | Ordens de produção, capacidade por oficina, materiais, mão de obra, prioridades, filas, prazos, custo e estoque; reservas e impedimentos reais. | Conservação de recursos, capacidade respeitada, conclusão/cancelamento sem duplicar itens ou despesas; simulação diária reproduzível. |
| v0.8.6 — Engineering Prototypes | Protótipos versionados, hipóteses de projeto, incerteza técnica, iteração, falha e custo de oportunidade; decisões de aprovar, revisar ou abandonar. | Protótipo não instalado não altera desempenho; resultado rastreável e reproduzível; prazo/custo e consumo de recursos corretos. |
| v0.8.7 — Component Testing & Validation | Ensaios virtuais e testes de pista permitidos pelo período: protocolos, dados, comparação, limites, aprovação e rejeição de peças. | Métricas, condições e revisões registradas; testes capazes de detectar regressões conhecidas; ausência de aprovação automática sem evidência. |
| v0.8.8 — Factory-to-Track Correlation | Correlacionar previsões de engenharia, medições e feedback dos pilotos com desempenho observado; incerteza do modelo e aprendizado técnico. | Comparação em condições equivalentes, erro de previsão registrado, melhoria de conhecimento sem ganho físico gratuito; evitar feedback circular e informação futura. |
| v0.8.9 — Quality Control & Reliability Management | Inspeção de fabricação, lotes, tolerâncias, defeitos, retrabalho, desgaste, manutenção e rastreabilidade de componentes; integrar v0.8.0 e v0.8.5. | Peça rejeitada não é instalada como aprovada; custos e recursos contabilizados; confiabilidade condicionada à qualidade e uso; histórico persistente. |
| v0.9.0 — Technical Staff Intelligence | Competências e personalidade dos responsáveis por engenharia, aero, mecânica, produção e qualidade; autonomia configurável, alocação de trabalho, decisões justificadas e colaboração com Soul Staff. | Staff afeta decisões, prazos e qualidade de forma causal e limitada; autoridade manual preservada; equipes rivais usam regras equivalentes; resultados registrados. |

As sete versões da Fase 6 são uma decomposição progressiva da engenharia:
projeto individual → capacidade produtiva → protótipo → ensaio → correlação
com pista → qualidade/confiabilidade → inteligência técnica. Preservar a
possibilidade de revisar ou abandonar um projeto, nunca transformar a fábrica
em simples compra de pontos de melhoria.

## Escopo posterior, sem numeração aprovada

Manter no planejamento Soul Driver (personalidade, relações, confiança e
feedback), Soul Staff (competências, autonomia, contratos e relações),
mercado de pilotos e funcionários, academia, patrocínios, finanças, economia,
gestão autônoma de rivais, Career Desk, carreira multitemporada, Simulation
Mode manual/assistido/automático e Hall da Fama. Preservar também HUD, mapa
2D, corrida 3D, Diretor TV, telemetria, acessibilidade, performance e
distribuição PC conforme Plano Mestre Unificado 2.0. Não atribuir versões a
esses itens nesta revisão.

## Protocolo de entrega e validação aplicável a cada versão

1. Conferir a main, AGENTS.md, o código real e a implementação anterior; o
   roadmap não substitui auditoria do repositório.
2. Definir o problema, a fronteira da versão, dependências, invariantes e
   critérios mensuráveis antes de escrever código. Uma funcionalidade principal
   por versão; não duplicar sistemas existentes.
3. Trabalhar em PR própria. Preservar saves, revisões de replay, determinismo,
   ordens manuais (incluindo BOX V21), arquitetura modular e regras de 2012.
4. Exigir FAST + APEX Test Lab + regressões direcionadas no SHA exato,
   conforme AGENTS.md (política vigente de 23/11/2026 e complementos).
   Usar casos reais e múltiplas sementes quando necessários; selecionar
   cenários e comparações de desempenho proporcionais ao risco.
5. FULL, matriz 20/180, endurance, benchmarks pesados e runner pessoal
   NÃO são condições universais de merge e não serão acionados automaticamente.
   Homologação ampliada somente por solicitação explícita do responsável;
   sem evidência essencial, não integrar.
6. Registrar resultados PASS/FAIL/NOT_RUN/INCONCLUSIVE/BLOCKED, limites e
   riscos. Não confundir logs, presença de ferramentas, skip ou benchmark
   headless com prova de jogabilidade, FPS/GPU ou release.
7. Atualizar changelog/documentação, preservar rollback e separar merge de
   código de publicação de binários. Não publicar sem autorização e validação.

Este complemento não inicia a v0.6.8, não modifica AGENTS.md, versão do jogo,
código esportivo, RNG, fixtures, assets, saves ou replays e não cria releases.
