# APEX Motorsport Manager — plano mestre consolidado

Revisão: 13/11/2026. Base de planejamento: v0.6.5.8 Race State Optimization.
Este documento combina a Fonte Mestra de 13/11/2026 com o Prompt Mestre de Desenvolvimento Contínuo e as evidências das entregas locais. É o roteiro consolidado para os próximos pedidos; não é declaração de que os sistemas futuros já existem.

## 1. Precedência e estado real

Ordem para decidir o que existe: conteúdo do ZIP entregue e manifesto → testes/evidências e limitações → relatório/changelog → este roteiro → planos históricos. Uma intenção não equivale a implementação; um teste controlado não equivale a validação de temporada inteira.

| Versão | Identidade preservada | Tratamento neste plano |
|---|---|---|
| 0.6.5.0 | HUD Unificada / sistemas anteriores de Staff | Preservar; não reiniciar a unificação |
| 0.6.5.1 | Living Factory 1.0 | Reutilizar inventário e identidades existentes |
| 0.6.5.2 | 3D Racing | Preservar e verificar regressões |
| 0.6.5.3 | Realistic Racing | Preservar e verificar regressões |
| 0.6.5.4 | Racecraft, registrada no workspace e incorporada à base posterior | Não tratar a ausência na síntese histórica como ausência do código; auditoria específica se for modificada |
| 0.6.5.5 | Sim Racecraft | Preservar autoridade espacial do motor |
| 0.6.5.6 | Living Factory 2.0 / Oficina Operacional | Já entregue nesta conversa; não implementar novamente |
| 0.6.5.7 | Performance Profiler | Já entregue; não renomear para P&D |
| 0.6.5.8 | Race State Optimization | Base mais recente entregue; não renomear para Soul Staff |

A verificação do ZIP 0658 registra SHA256 `47397b549c85639792e302e5c896ee4cfa0dc0c1137677b69dc1f9c6fc167840`, CRC/manifesto conferidos, import Godot aprovado e oito testes após extração. O relatório registra 30 verificações selecionadas e paridade em quatro cenários de três voltas. Isso não comprova todos os testes históricos, GPs de duração integral, Compatibility ou temporadas longas.

Pendências conhecidas da base:
- Em 1080p, a montagem visual consumiu menos CPU, mas a taxa global medida caiu 7,3%; causa não isolada. Não declarar ganho geral de FPS ou estabilidade plena.
- Artefato escuro serrilhado na junção da pista, reproduzido também na base anterior; investigar geometria/material.
- Determinismo entre velocidades/FPS diferentes continua sendo objetivo, não garantia validada.

Os rótulos antigos “0657 P&D” e “0658 Soul Staff” viram funcionalidades futuras abaixo, sem apagar releases existentes.

## 2. Identidade e regras permanentes

Godot 4.7.2, PC/Linux Mint, gerenciamento de equipe — não pilotagem direta. Base F1 2012, 20 etapas, 12 equipes e 24 pilotos, sujeita à conferência dos dados do ZIP. KERS, DRS, V8, pneus e regulamento coerentes com a era; não introduzir ERS híbrido, ATR ou teto de gastos moderno como regras de 2012. Safety Car e outros mecanismos exigem compatibilidade histórica; não presumir VSC.

Identidade visual APEX: laranja, grafite e cinza; HUD contextual existente preservada. Mapas 2D, visão aérea e Diretor TV 3D devem coexistir, sem recenter brusco. Não mudar o padrão de câmera durante uma otimização; avaliar o padrão aéreo proposto na entrega de apresentação.

Fluxo: comandos validados → simulação autoritativa → eventos/telemetria → apresentação/HUD/rádio. Nenhum efeito visual modifica RNG esportivo, ordem, tempo, desgaste ou resultados. Uma fonte por dado; diferenciar cálculo, previsão, percepção e histórico. Nada de botões que aparentam executar backend inexistente.

Cada versão tem uma funcionalidade principal. Reutilizar módulos e saves; não reconstruir o jogo, duplicar controladores nem remover qualidade/carros para obter desempenho. Sem threads ou dependências novas sem benefício medido e segurança demonstrada. Não copiar código, marcas visuais, modelos, vozes ou gravações proprietárias.

## 3. Sequência consolidada

A sequência técnica 0659–0663 do prompt contínuo é preservada: geometria e reprodução dão suporte à evolução de IA. A prioridade de engenharia/P&D da Fonte Mestra entra imediatamente após esse bloco, com Staff e fábrica em versões separadas. Os números abaixo são reservas de planejamento, não releases existentes.

| Versão planejada | Funcionalidade principal | Resultado verificável |
|---|---|---|
| 0.6.5.9 | Track Geometry Optimization | Amostragem/cache equivalentes, diagnóstico do desempenho 1080p |
| 0.6.6.0 | Deterministic Simulation & Replay | Comandos/ticks/checkpoints reproduzíveis |
| 0.6.6.1 | Advanced Racing AI / Driver Dynamics | Ataque, defesa e recuo decididos no motor |
| 0.6.6.2 | Driver Personality & Radio 2.0 | Intenções e comunicação ligadas a eventos reais |
| 0.6.6.3 | Pit Wall & Strategy Intelligence | Replanejamento causal e coordenação dos dois carros |
| 0.6.6.4 | 3D Racing Presentation 3.0 | Apresentação coerente, câmeras e perfis gráficos |
| 0.6.6.5 | Research & Development 2.0 | Projetos, protótipos e testes de engenharia |
| 0.6.6.6 | Soul Staff / Staff Intelligence 2.0 | Competências e relações com consequências auditáveis |
| 0.6.6.7 | Living Factory 3.0 | Produção e departamentos conectados ao P&D |
| 0.6.7.x | Carreira, economia e universo persistente | Entregas pequenas descritas na seção 5 |

Se um escopo não couber numa entrega verificável, subdividi-lo antes de codificar, registrar a mudança e deslocar apenas números ainda não entregues. Correções necessárias da base podem receber patch próprio; não misturá-las silenciosamente com novos sistemas.

## 4. Especificação das próximas entregas

### 0.6.5.9 — Track Geometry Optimization (próxima implementação)

Entrada: ZIP 0658 validado, benchmarks e plano técnico 0659 já entregues.
- Auditar `track_map.gd`, `track_3d.gd`, `race_view_snapshot_0658.gd`, `apex_race_view_controller.gd` e consumidores do solver espacial.
- Proposta: `TrackGeometrySampler.build/sample/sample_distance/invalidate`, comprimentos acumulados, tangentes e revisão de rota. Uma busca deve servir posição/direção quando a equivalência estiver demonstrada.
- Reusar âncora/segmentos vizinhos na projeção 3D, com fallback global. Não assumir que os índices da rota 2D correspondem à malha 3D.
- Invalidar em troca de pista, nova sessão e descontinuidade. Tratar progressão absoluta, emenda, entrada/saída de box e curvas fechadas.
- Medir construção/cache/memória e consultas por frame. Investigar a regressão 1080p com séries intercaladas e manter todas as amostras válidas, inclusive resultados desfavoráveis.
- Investigar o artefato da junção; corrigir somente se a causa estiver no escopo geométrico e houver comparação visual. Caso contrário, abrir incidente próprio com evidência.
- LOD/atualizações distantes apenas se as medições justificarem; nunca excluir participantes da simulação ou da ocupação.

Aceitação: amostras densas e aleatórias equivalentes dentro de tolerâncias justificadas antes da alteração; nenhuma mudança esportiva; testes espaciais com varredura contínua; Silverstone, Spa, Monza, Singapura e duas pistas sorteadas com seed; cenas nativas nas duas resoluções reais; regressões de boxes, gestão e saves. Relatório deve distinguir ganho localizado de FPS global. Se a regressão persistir, classificá-la e corrigir ou manter a entrega como experimental, sem chamá-la estável.

### 0.6.6.0 — Deterministic Simulation & Replay

Auditar motor, comandos, sessão, clima, telemetria e RNG. Propor módulos de log de comandos, codec de estado e replay com responsabilidades separadas.
- Tick lógico independente do render; comandos `{tick, sequence, actor, type, payload}`.
- Checkpoints versionados incluem RNG, relógio, clima, pneus, filas de box e decisões pendentes; capture/restore/hash sem duplicar sinais ou transações.
- Reprodução aplica comandos registrados; não decide outra vez nem consome RNG narrativo no motor.
- Comparar 1×/2×/5×/16×/32× e render headless/2D/3D sob a mesma sequência de ticks e inputs. Não prometer identidade entre plataformas sem teste.

Aceitação: diagnóstico do primeiro tick divergente, restore em chuva e serviço de box, replay até bandeirada, resultado e eventos iguais. Compatibilidade de replay explicitada; saves existentes preservados. Pré-requisito para calibrar alterações de comportamento posteriores.

### 0.6.6.1 — Advanced Racing AI / Driver Dynamics

Evoluir `core/race_space_0655.gd` e os pontos de integração reais do motor; não reativar um controlador legado concorrente.
- Estados causais: aproximação, preparação/vácuo, avaliação de lado, ataque, defesa, sobreposição, conclusão/recuo e recuperação.
- Considerar largura/curvatura, velocidade relativa, frenagem, pneus, ar sujo, KERS/DRS, risco e terceiro carro.
- Defender sem liberar a linha artificialmente: movimento antecipado limitado, corredor preservado quando houver sobreposição, retorno apenas com espaço.
- Recuar de oportunidades inseguras; erros proporcionais às competências, registrados e reproduzíveis. Contato/danos novos exigem regra explícita e testes, não animação aleatória.

Aceitação: passagem bloqueada em trecho estreito, ataque por lado livre, defensor ativo, retardatários e emenda de volta; nenhuma troca instantânea de ranking sem causa espacial. Comparar tentativas/sucessos/recuos por seed, não premiar quantidade artificial de ultrapassagens. Esta versão pode mudar resultados; publicar mudanças esportivas e testes de causalidade em vez de exigir hashes iguais à versão antiga.

### 0.6.6.2 — Driver Personality & Radio 2.0

Reutilizar Soul Driver, Race Engineer, rádio e contratos já existentes. Separar atributos persistentes, estado emocional temporário, percepção, intenção, mensagem e comando executável.
- Agressividade, consistência, inteligência, preservação, chuva, confiança, controle emocional, consciência espacial, cooperação e tolerância a risco; mapear atributos atuais antes de criar outros.
- Percepção falível dos pneus e confiança no carro; pedidos de box, extensão de stint, passagem do companheiro e discordância contextual.
- Evento de origem, prioridade, cooldown, deduplicação e filtros/legendas. RNG narrativo separado ou escolha determinística por ID.
- Preparar interface para voz original/licenciada futura; não incorporar áudio protegido.

Aceitação: mensagem sempre rastreável a contexto; sem spam ou mensagem reaplicada no restore; rádio não muda RNG esportivo. Pedidos não viram comandos sem permissão do modo de controle. Testar piloto e engenheiro discordando com registro claro de quem decidiu.

### 0.6.6.3 — Pit Wall & Strategy Intelligence

Reusar AI Director, Race Intelligence, Pit Wall, Strategy Simulator e coordenação de equipe. Avaliar alternativas com previsão disponível ao engenheiro, sem acesso indevido ao clima futuro exato.
- Previsão de degradação/cliff, tráfego de retorno, undercut/overcut, custo de fila, double stack e ambas as estratégias.
- Replanejar em eventos significativos e por volta; não calcular tudo para todos a cada frame.
- Registrar premissas, previsão, decisão, autorização e resultado; medir erro de previsão e custo de CPU.

**Reconciliação obrigatória dos dois documentos: chuva intensa na volta 4, pit previsto na volta 21.**
- Manual: reavaliar imediatamente e alertar/recomendar; manter a ordem V21 até intervenção autorizada. Não transformar um alerta meteorológico em parada silenciosa.
- Assistido: apresentar recomendação e solicitar decisão pelo fluxo do jogo; executar apenas as categorias previamente delegadas.
- Automático: replanejar e executar dentro da delegação, explicando pneus, aderência, previsão e perda estimada. V21 é plano revisável, não ordem manual imutável.
- Exceção de segurança só se uma regra existente a autorizar explicitamente; não inventá-la para contornar o modo manual.

Aceitação: cenário V4/V21 nos três modos, para os dois pilotos e adversários; chuva passageira/persistente, seco/transição, fila e janela manual. Sem antecipação indevida, dupla chamada ou recomendação de composto indisponível.

### 0.6.6.4 — 3D Racing Presentation 3.0

Reutilizar modelos, animações e ocupação existentes. Autoridade continua no motor.
- Rodas/esterçamento/suspensão, DRS visual, asfalto molhado/spray e iluminação, com orçamento por perfil de hardware.
- Diretor TV enquadra acontecimentos; vista aérea estratégica alta, modo seguir, livre e mapa 2D separado, sem cortar carros ou recentrar abruptamente.
- Decidir padrão de câmera nesta entrega e preservar preferências; não refazer HUD.
- Perfis Compatibility/Forward+ com sombras/AA/LOD compatíveis e testados. Não prometer realismo equivalente a jogos comerciais por mera semelhança de HUD.

Aceitação: replay idêntico em todos os modos, comparações visuais reais com batalhas/curvas/pits/chuva, sem atravessamento introduzido pela animação; 1600×900, 1920×1080 e janela menor com resolução registrada. Publicar custos de CPU/GPU quando medidos e limites do hardware.

### 0.6.6.5 — Research & Development 2.0

Incorporar a prioridade técnica da Fonte Mestra sem repetir a oficina já existente. Auditar inventário, upgrades legados e módulos de projetos antes de criar um backend paralelo.
- Projeto individual: família, requisitos de 2012, equipe responsável, orçamento, prazo, conhecimento, metas e incerteza.
- Ciclo: especificação → desenho → protótipo → teste → avaliação de ganho/risco → aprovação para fabricação.
- Iniciar com uma família de componentes e fluxo completo; catálogo de V8, caixa, arrefecimento, chassi, suspensão, assoalho, asas e freios é expansão, não obrigação de lançar todos superficialmente.
- Tradeoffs explícitos de arrasto/downforce, potência/calor/desgaste, massa/confiabilidade; dados previstos separados de medidos.
- Protótipo aprovado produz especificação versionada consumida pelo inventário/fábrica existente. Nenhum bônus simultâneo do sistema novo e do upgrade antigo.

Aceitação: orçamento e recursos reais, tarefas não instantâneas, cancelamento/refundos coerentes, protótipo reprovado/aceito, ausência de bônus duplicados e IDs persistentes. Qualquer efeito novo no motor exige unidades/fórmulas documentadas e testes de equilíbrio/replay. Esta entrega não inclui uma fábrica inteira nova.

### 0.6.6.6 — Soul Staff / Staff Intelligence 2.0

Usar funcionários contratados e departamentos reais: engenheiro, estrategista, chefe de mecânica, aerodinâmica/projetos, mecânicos, scouting e direção conforme backend disponível.
- Competência, personalidade, confiança, relações, fadiga, formação/lealdade e responsabilidade; introduzir apenas atributos com efeito identificável.
- Efeitos moderados e explicáveis: qualidade de estimativa, eficiência de projeto, organização, probabilidade de erro e comunicação. Staff competente não é infalível.
- Contratos/salários e capacidade de trabalho efetivos; Manual/Automático do responsável, sem contratações gratuitas ocultas.

Aceitação: folha e contratos persistentes, pessoa não trabalha em tarefas incompatíveis simultaneamente, diferenças de competência verificáveis, fadiga/recuperação limitadas e relações sem bônus ilimitados. Evitar multiplicar modificadores sobre os mesmos resultados já influenciados por Crew/Soul.

### 0.6.6.7 — Living Factory 3.0

Integrar P&D aprovado e Staff à oficina operacional e inventário existentes.
- Departamentos, capacidade, recursos, filas de fabricação e montagem; especificação aprovada vira componentes únicos rastreáveis.
- Dependências e gargalos, prioridade e prazo de corrida, consumo de materiais e orçamento real; chefe de mecânica pode delegar respeitando restrições.
- Histórico de fabricação/instalação/reparo/teste, confiabilidade e vida útil; reparo não restaura eternamente qualquer peça.
- Efeitos esportivos de condição/confiabilidade só entram com modelagem própria e evidência: a quilometragem existente não implica que todos esses efeitos já estejam ativos.

Aceitação: produção → estoque → serviço → carro → corrida → inspeção, manual e automática; sem duplicação de peças/custos, instalação simultânea ou progresso dependente do FPS. Migração de saves, falha de gravação e rollback, bloqueio de partida coerente com serviços em execução.

## 5. Linha 0.6.7.x — carreira em módulos

Reservas propostas; revisar escopo antes de cada implementação, preservando uma funcionalidade principal:

| Versão | Escopo | Evidência mínima |
|---|---|---|
| 0.6.7.0 | Calendário e múltiplas temporadas | Virada idempotente; contratos, prêmios e folha uma vez; save antes/depois |
| 0.6.7.1 | Mercado de pilotos/funcionários | Ofertas, negociação, expiração, orçamento, IDs e grid válido |
| 0.6.7.2 | Academia e scouting | Talentos, informação incerta, evolução limitada, custos e histórico |
| 0.6.7.3 | Finanças e patrocinadores | Livro de transações, contratos e metas reais; sem receitas duplicadas |
| 0.6.7.4 | Criação e personalização de equipe | Nome/país/cores/fornecedores, orçamento e integração no campeonato |
| 0.6.7.5 | Regulamentos e adaptação técnica | Regras versionadas por temporada, elegibilidade e projetos afetados |
| 0.6.7.6 | Planejamento de equipes rivais | Recursos finitos, recrutamento/desenvolvimento auditáveis e restrições comparáveis |
| 0.6.7.7 | Históricos, recordes e dinastias | Identidades permanentes, consultas eficientes, Hall da Fama e aposentadorias |
| 0.6.7.8 | Simulação rápida de temporadas | Avanço acelerado reproduzível, interrupções por decisões relevantes, saves de 5/10/20 anos |

Treinos/qualificação, perfil chefe versus proprietário, expansão de eras e modo “e se?” permanecem no backlog até auditar suporte atual e dependências. Não presumir implementados nem forçar numeração prematura. As antigas fases 0.7/0.8/0.9 são visão de longo prazo; 1.0 é meta de integração e estabilidade, sem data prometida.

## 6. Método obrigatório por versão

1. Identificar o ZIP mais recente efetivamente entregue; CRC, SHA256 e manifesto. Extrair em pasta nova; manter rollback.
2. Ler relatório, limitações, changelog, este plano e APIs reais. Executar baseline pertinente antes de editar.
3. Pesquisar GitHub e documentação oficial Godot para o sistema concreto; registrar URLs, licenças, conclusões e material incorporado. Não pesquisar/codificar todo o roadmap de uma vez.
4. Definir escopo, arquivos, contratos, dependências, riscos, métricas e testes de aceitação antes de implementar.
5. Criar testes para novos comportamentos; implementar de forma modular; corrigir falhas e registrar tentativas.
6. Regressões funcionais, esportivas, visuais e de persistência. Sem alterar regras para fazer teste de apresentação passar.
7. Comparar desempenho e resultados com a base apropriada. Em mudança esportiva intencional, explicar diferenças e verificar causalidade; não exigir hashes antigos artificialmente.
8. Documentar implementado/parcial/futuro, testes executados/não executados, falhas e limitações. Não chamar estável sem evidência nativa/visual correspondente.
9. Entregar projeto completo, relatório técnico, benchmarks quando pertinentes, capturas, plano detalhado seguinte, diário e checksum. Reextrair o ZIP e repetir import/testes essenciais.
10. Encerrar a versão antes de começar outra. Continuação sequencial somente quando autorizada e sem misturar escopos no mesmo ZIP.

## 7. Matriz comum de QA

- Godot 4.7.2 real; import headless e execução nativa. Registrar versão, renderizador, CPU/GPU e resolução efetiva, não só solicitada.
- Silverstone, Spa, Monza, Singapura e pistas sorteadas com seed registrada; ampliar aos 20 circuitos quando o sistema exigir. Separar corrida curta, GP integral e demonstração controlada.
- Duas Ferrari e adversários; classificação, tempos de volta, pneus legais, KERS/DRS, boxes, filas, chuva e bandeirada. Ordens manuais V21 e evento meteorológico V4 são testes distintos de decisões automáticas.
- Apresentação: curvas, lado a lado, retardatários, cruzamentos, costura, pits, seleção, pausa/reentrada e velocidades. Render não muda RNG/resultado.
- HUD atual: mouse/teclado, foco, scroll, botões reais, preferências e legibilidade em 1600×900, 1920×1080 e tamanho menor especificado no teste.
- Gestão/fábrica: contratos, saldo, componentes únicos, disponibilidade de pessoas, fila e histórico. Save/load legado, migração, falhas e rollback com dados isolados do jogador.
- Desempenho: aquecimento e séries comparáveis/intercaladas; CPU por seção, frame/tick, carregamento, memória e tamanho de save conforme disponíveis. Distinguir CPU/GPU, RSS/monitor Godot e mediana/limites. Compatibility deve ser testado, não inferido.
- Longevidade: benchmarks de 5/10/20 temporadas quando carreira existir; evitar cálculos globais repetidos, históricos ilimitados sem política e gravações frágeis.
- Testes indisponíveis devem ser explicitados; nenhuma aprovação por título do ZIP, screenshot isolado ou ausência de reclamação.

## 8. Referências e biblioteca de pesquisa

Conceitos preservados da Fonte Mestra: F1 Manager (departamentos/TV), Motorsport Manager (legibilidade/decisão), Backseat Champions (disputas autônomas), WORKS (operação fabril), Automation e Racing Series Manager (engenharia), Golden Lap (relações/tradeoffs com interface simples), Open Wheel Manager 2 e GT Manager (gestão técnica), F1 Dynasty e Cockpit Simulator/Manager (carreira/história/controle). Empire Eleven é referência de riscos de QA, não de automobilismo. Nenhuma funcionalidade anunciada de terceiros é considerada comprovada sem pesquisa.

Manter os links originais na Fonte Mestra; conferir páginas oficiais quando utilizados. Não foi feita nova auditoria desses jogos nesta consolidação. Fontes históricas futuras: FIA por temporada, Pirelli por GP e Jolpica conforme termos/licenças verificados antes de incorporar dados.

Biblioteca audiovisual futura: ataque/onboard, disputa em curva, rádio contextual, double stack, cortes de TV e processo de fábrica. Cada registro deve conter ID, URL, autor/canal, data, trecho observado, comportamento, módulo beneficiado e licença/condição de uso. Links/minutagens ausentes continuam pendentes: não inventar. Material serve de estudo, não entra no ZIP sem direitos.

## 9. Prompt operacional para os próximos pedidos

> Use o ZIP mais recente entregue e este plano consolidado. Confirme versão, integridade e funcionalidades reais; leia relatório e limitações. Preserve HUD, Core 2, Sim Racecraft, Living Factory, Soul Driver/Staff, Pit Wall e Strategy Simulator. Trabalhe em UMA versão e funcionalidade principal: [VERSÃO / ESCOPO]. Faça pesquisa técnica específica, estabeleça contratos/testes, implemente e valide no Godot 4.7.2. Não altere física/IA em trabalho de apresentação. Não confunda recomendação de chuva com autorização para antecipar ordem manual. Publique métricas comparáveis, falhas/avisos, capturas reais e limites. Entregue ZIP completo validado, checksum, relatório, diário e plano seguinte. Não avance para outra versão sem concluir a atual.

Próxima tarefa definida: **v0.6.5.9 — Track Geometry Optimization**, começando pela auditoria da regressão 1080p e pelo plano técnico específico já existente. Este arquivo consolida o planejamento; sua criação não implementa nem entrega a 0659.

## 10. Fontes desta consolidação

- Fonte Mestra: `/home/jugdru/Downloads/APEX_SIMULATION_FONTE_MESTRA_2026-11-13.md`.
- Prompt Mestre de Desenvolvimento Contínuo: `/home/jugdru/.codex/attachments/de16444e-4a85-4d48-b168-0593004bfaae/Texto colado.txt`.
- ZIP 0658, `RELATORIO_TECNICO_APEX_v0.6.5.8.md`, `BENCHMARK_APEX_0658.md`, `VERIFICACAO_ZIP_0658.json` e `PLANO_ENGENHARIA_APEX_0659.md` do workspace.

Os caminhos acima documentam procedência; não são dependências de execução do jogo. Os documentos originais e releases foram preservados sem alterações.
