APEX MOTORSPORT MANAGER — FONTE MESTRA DO PROJETO  
Planejamento, ideias, mecânicas, arquitetura de código, conversas, referências e vídeos  
Revisão: 13/11/2026 \| Status: documento vivo \| Ambiente: Godot 4.7.2 / Linux Mint

COMO UTILIZAR ESTA FONTE  
Este documento é a memória de trabalho para novas conversas e tarefas no APEX Simulation. Não é um relatório de funcionalidades 100% implementadas. Para cada pedido futuro, consultar o ZIP mais recente, changelog, testes e este documento, nessa ordem para verificar o estado REAL do código. Planos anteriores podem apresentar versões já ultrapassadas. Nunca deduzir funcionalidade de um título de ZIP ou de uma conversa.  
Etiquetas: \[CONFIRMADO POR FONTE\] decisão/registro documental; \[RECEBIDO\] arquivo submetido, não necessariamente auditado; \[PROPOSTO\] ideia para futuro; \[VALIDAR\] requer exame da árvore Godot/testes; \[REFERÊNCIA\] inspiração, sem cópia.

1\. VISÃO E IDENTIDADE DO JOGO  
APEX Motorsport Manager é um simulador de gerenciamento de equipe automobilística para PC. O jogador é o responsável por uma escuderia: contrata STAFF, negocia com pilotos, acompanha engenharia, produz e mantém componentes, planeja estratégias, delega tarefas e observa as consequências numa corrida simulada. Não é um jogo de pilotagem direta nem uma simples cópia de F1 Manager, Motorsport Manager ou Cockpit Manager.  
Diferencial pretendido: profundidade operacional da fábrica \+ personalidade dos pilotos e funcionários \+ estratégia compreensível \+ corridas 3D animadas e coerentes \+ história de uma escuderia por muitas temporadas.  
Princípios aprovados nas conversas: (a) controle Manual ou Automático, inclusive por piloto/decisão quando aplicável; (b) corrida rápida com decisões nos momentos importantes; (c) câmera aérea estratégica, mapa 2D separado e Diretor TV 3D; (d) HUD unificada, limpa e contextual; (e) simulação determina resultado e apresentação apenas o representa; (f) cada versão aborda UMA funcionalidade principal; (g) não avançar antes de testes/regressões.  
Estética: identidade APEX com laranja principal, grafite e cinza, menus organizados de maneira minimalista; preservar a identidade já aprovada. Não reabrir trabalho de unificação/refatoração de HUD que já foi executado no Work.  
Base histórica: F1 2012, 20 etapas, 12 equipes e 24 pilotos conforme a base do projeto; regras próprias da era (KERS e DRS 2012, motores V8 e compostos correspondentes). Futuras eras somente com regras próprias; não inserir ERS híbrido, teto de gastos ou ATR moderno como se existissem em 2012\.

2\. FONTES HISTÓRICAS DO PLANEJAMENTO E CRONOLOGIA  
\- “Ideia de simulador F1.md”: conversa de origem do produto e desenvolvimento inicial Python/Tkinter; pedidos de física, clima, pits, IA, HUD, câmera e Godot.  
\- “PLANO\_APEX\_RECONSTRUIDO\_2026-11-06.md”: plano formal de 06/11/2026, com pilares, versões e regressões. É referência histórica; sua numeração futura NÃO substitui o roteiro posterior.  
\- “APEX\_PESQUISA\_29\_MODS\_PLANO\_TECNICO.md”: estudo de arquitetura, 29 mods e separação de simulação, inteligência de corrida e apresentação. Algumas observações são diagnósticos de versões 0.5.3.x antigas e não devem ser atribuídas automaticamente à base atual.  
\- “ARQUITETURA\_CORE2.md”: arquitetura Core 2 e fronteiras de módulos.  
\- “CHANGELOG\_APEX\_UI02\_SUITE.md”: a Central da Equipe de 08/11/2026, opções funcionais versus opções bloqueadas sem backend.  
\- Relatórios das versões v0.6.4.9.x, ZIPs v0.6.5.0 e v0.6.5.1 e os ZIPs posteriores fornecidos pelo usuário são evidências de implementação a examinar.  
\- Prompts e conversas recentes (09–13/11/2026) reorganizam as próximas versões em incrementos pequenos.  
História resumida: v0.1–0.4.x protótipo Python e oficina inicial; v0.5.x migração Godot, pistas, Core 2, IA e telemetria; v0.6.0+ temporada e HUD; v0.6.3.x rádio/Soul; v0.6.4.x Pit Wall, Race Engineer, Soul Driver, inteligência estratégica e Strategy Simulator; v0.6.5.x Soul Staff, HUD Unificada, Living Factory, 3D Racing e Sim Racecraft.

3\. ESTADO DO PROJETO E BASE DE TRABALHO  
\[RECEBIDO\] v0.6.5.0 — HUD UNIFICADA, refatorada em Work. O usuário deixou explícito que unificou/refatorou a HUD; não propor essa tarefa novamente.  
\[RECEBIDO\] v0.6.5.1 — LIVING FACTORY 1.0; ZIP recebido, com planejamento de inventário individual, identidades de peças, quilometragem, histórico e persistência. Precisar verificar implementação real antes de reutilizar.  
\[REGISTROS DE TRABALHO\] v0.6.5.2 — 3D Racing: animações laterais vinculadas a preparação/ataque/duelo, retorno à linha, DRS visual, melhorias de iluminação, carroceria, rodas, asfalto, terreno e câmeras. O material exibido contém testes controlados, mas não é prova de avaliação completa em corrida.  
\[RECEBIDO\] v0.6.5.3 — Realistic Racing, ZIP da versão com modelos/ambiente melhorados; conversa anterior registra auditoria inicial, mas classificar entrega apenas após revalidar o conteúdo atual.  
\[RECEBIDO\] v0.6.5.5 — SIM RACECRAFT COMPLETO, último ZIP explicitamente enviado nesta conversa até esta revisão. AUDITORIA INDEPENDENTE DO ZIP NÃO FOI CONCLUÍDA POR FALHA NO AMBIENTE. Nunca afirmar que módulos de racecraft foram validados sem abrir/testar.  
\[PROPOSTO PARA WORK\] v0.6.5.6 — Living Factory 2.0 / Oficina Operacional, usando v0.6.5.5 como base, sujeita a confirmação de ZIP mais recente.  
ATENÇÃO: Não há, neste registro, confirmação suficiente sobre a v0.6.5.4. Não inventar sua existência ou conteúdo. Nenhuma entrega v0.6.5.6 foi comprovada neste documento.  
Regra de precedência: sempre usar o maior número de versão VERIFICADO NO ARQUIVO ENTREGUE (não apenas planejado), nunca sobrescrever uma versão posterior com um ZIP anterior. Fazer inventário de diferenças e rollback.

4\. MECÂNICAS — MOTOR E CORRIDA  
4.1 Core 2 e fluxo de dados  
O motor é independente de apresentação. Estado da corrida → telemetria/eventos → mapas/HUD/rádio/TV. Comandos do jogador passam por validação no controlador, não modificam dicionários de corrida por atalhos da interface. Passo temporal baseado em simulação e semente: mesma seed \+ mesma estratégia \+ mesmo estado inicial \= mesmos resultados mesmo em 1x versus 16x. Câmera, shaders e animações não usam o RNG do motor, não alteram posições, desgaste, tempo ou ordem.  
Módulos históricos mencionados no estudo de código: scripts/race\_engine.gd, scripts/core/race\_combat.gd, race\_performance, race\_strategy, race\_pit\_math, race\_rules, scripts/track\_3d.gd, scripts/car\_model\_3d.gd, scripts/apex\_race\_view\_controller.gd, scripts/garage.gd. São pontos para inspecionar, não contrato de que o arquivo continua idêntico.  
4.2 Pneus, clima e física  
Aderência, temperatura, desgaste, cliff, graining/blistering, borracha e água por circuito/setor; chuva muda decisões de IA e física para todos. Intermediários e chuva extrema apropriados. Cada GP usa os compostos disponíveis naquela etapa. Diferenciar valor calculado, previsão, percepção do piloto e dado histórico. Evitar indicadores que finjam medir por roda o que não é simulado.  
4.3 Disputas e ultrapassagens (Sim Racecraft)  
Sequência causal: aproximação → vácuo/preparação → escolha de lado → ataque → defesa → lado a lado → êxito, recuo, contato ou recuperação. Respeitar largura efetiva, trecho da pista, direção, volta, velocidade relativa, pneus, confiança, agressividade, consciência espacial, KERS/DRS, ar sujo e riscos. Evitar mudança de posição “teleportada”. A ultrapassagem tem que nascer do motor; gráficos representam os mesmos eventos. Não forçar ultrapassagens artificiais para parecer divertido.  
4.4 Pit Wall / Team Strategy  
Planejamento inicial e reavaliação por volta, recomendações contextualizadas, posição prevista de retorno, undercut/overcut, double stack, conflitos entre carros, conservação de pneus e janela de box. Manual/Assistido/Automático por piloto com fronteiras claras; ordem manual de parada na volta 21 NUNCA executada na volta 4 por erro de clima. IA deve explicar recomendação e motivo para alterar a estratégia. Pit stop e equipe mecânica com tempo, erros, filas, reparos e consequências.  
4.5 Race Engineer, rádio e Soul Driver  
Pilotos não são sensores perfeitos: percepção subjetiva de degradação, confiança no carro, estado emocional, moral, pressão, agressividade, preferência por stint e risco. Podem pedir box por perda de ritmo, continuar porque sentem pneus bons, solicitar passagem do companheiro se mais rápidos e contestar ordens dentro das permissões. Engenheiro e piloto conversam a partir de EVENTOS REAIS; staff tem competência e falibilidade; decisões explicitadas. Inspirar-se em rádio real de F1, mas NÃO copiar gravações, roteiros extensos ou vozes protegidas. Permitir rádio com legendas, prioridade, supressão de repetição e filtros.  
4.6 Diretor TV e visualização  
Padrão: câmera aérea alta com carros visíveis e estratégia; mapa 2D de pontos como alternativa, sem recenter brusco; TV em ângulos battle, chase, trackside, corner, aerial e pit. Duelo 3D: offset lateral persistente durante aproximação/ataque/duelo e recuperação, animação de rodas, esterçamento, carroceria, DRS e cenário sem se desconectar do progresso real. Evitar carros visualmente atravessados, virando ao contrário ou cortados pela câmera. Perfis de qualidade para PC modesto (Compatibility, níveis de sombra/AA/LOD).  
4.7 Regulamentos, segurança e consequências  
Bandeiras, SC/VSC (quando adequado ao ano), incidentes, confiabilidade, danos, penalidades e regras de largada/boxes devem ser modelados, testados e contextualizados. Registrar claramente o que já existe e o que é futuro.

5\. MECÂNICAS — FÁBRICA, STAFF E OPERAÇÃO  
5.1 Living Factory 1.0: cada componente tem identificador único, equipe, carro instalado, família, especificação, quilometragem, condição, histórico de montagem/reparo/troca, data/rodada, custo, confiabilidade e efeitos do desempenho. Inventário verdadeiro e persistente, não barras abstratas de upgrade.  
5.2 Living Factory 2.0 / Oficina: fila por carro com inspeção, manutenção preventiva, reparação, substituição, preparação e validação final. Cada ordem tem ID, dependências, componente, prioridade, tempo, recurso humano, custo, estado e histórico. Mecânicos não trabalham em dois serviços ao mesmo tempo. Modo Manual versus Automático do chefe de mecânica. Nada de manutenção instantânea, custo fictício, duplicação de peças, instalação simultânea ou reparo capaz de tornar qualquer peça eternamente nova.  
5.3 Soul Staff: estrategista, engenheiro de corrida, chefe de mecânica, engenheiro aerodinâmico, líder de projeto, mecânicos, recrutadores e chefia. Contratos, salários, competência, personalidade, confiança, relações, fadiga, formação, lealdade e responsabilidade por decisões. STAFF eficiente não é infalível; usar efeitos moderados, legíveis e auditáveis. Contratações devem ter vantagens e tradeoffs — referência Golden Lap.  
5.4 P\&D/Engineering: projetos individualizados de motor V8, caixa, arrefecimento, chassi, suspensão, assoalho/difusor, asa dianteira/traseira e freios. Especificação → desenho → protótipo → testes (pista, bancada, túnel/CFD quando pertinente) → avaliação de ganho/risco → fabricação → instalação. Engenharia não é “gastar pontos para desbloquear \+5”. Custo, duração, capacidade fabril, conhecimento da equipe, correlação dados-reais e incerteza. Mais downforce pode aumentar arrasto; mais potência pode aumentar desgaste/temperatura, etc. Regras e classes por temporada.  
5.5 Econômica e mercado: fluxo de caixa, patrocinadores, fornecedores, contratos, salários, orçamento, instalações, metas da diretoria, riscos de investimento, academias e scouting. Rival também desenvolve carros, recruta staff e responde ao regulamento, sem upgrades gratuitos incoerentes.

6\. CAMPANHA, CARREIRA E UNIVERSO VIVO  
Início na temporada 2012 e, futuramente, seleção de era conforme catálogo confiável; campeonato persistente, duas sessões? treinos/qualificação/corrida com salvamento e histórico, classificação de pilotos e construtores, resultados, contratos, temporada seguinte, recordes. Criar escuderia do zero (nome, país, cores, identidade, fornecedores, orçamento), tornar-se chefe ou proprietário que delega ao chefe contratado, desenvolver academia, novos talentos e aposentadorias. Mercado dinâmico, mudanças de regulamento, rivais, dinastias, reputação e Hall da Fama. Modo alternativo “e se?” e simulação rápida de múltiplas temporadas são FUTUROS, não assumir implementados. Evitar que o jogo perca desempenho ou corrupção de saves após 5, 10 e 20 anos.

7\. UX, HUD E NAVEGAÇÃO  
Unificar e NÃO duplicar. Central da equipe com painéis de corrida, calendário, fábrica, oficina, equipe, pesquisa, contratos, relatórios e finanças; opções sem backend devem ficar desabilitadas/rotuladas, nunca fingir ação. Elementos contextuais em vez de janelas opacas permanentes. Classificação à esquerda, cartões de pilotos e ordens, clima, rádio, mini mapa, telemetria e Pit Wall sob demanda. Testes 1600×900 e 1920×1080 e menores, navegação por mouse e teclado, foco em acessibilidade, evitar scroll quebrado. Interface pode ser minimalista com sistemas complexos (lição Golden Lap).

8\. CATÁLOGO DE JOGOS DE REFERÊNCIA (CONCEITOS; NUNCA ASSETS/CÓDIGO)  
\- F1 Manager: visão de departamentos, estratégia, funcionários, comunicação de corrida, câmeras e modelagem visual de eventos.  
\- Motorsport Manager: legibilidade dos painéis, decisões em ritmo acelerado, gerenciamento amplo e feedback claro.  
\- Backseat Champions: corridas dirigidas autonomamente por pilotos, brigas lado a lado, falhas de frenagem, defesa, movimento natural e câmeras que acompanham acontecimentos. Usar para 3D e futuro Driver Dynamics.  
\- F1 Dynasty — https\://f1dynasty.com/ : criar equipe; temporadas consecutivas; mercado/scouting; academia, mudanças de regulamento, recordes, dinastias e simulação rápida.  
\- Cockpit Simulator: The Motorsport History Engine — https\://shxlashxska.itch.io/cockpit-simulator : sandbox histórico, múltiplas eras, eventos “e se?”, editor de grid, histórico e Hall da Fama.  
\- Cockpit Manager 2026 — https\://shxlashxska.itch.io/cockpitmanager2026 : chefe de equipe, Mission Control, telemetria, rádio, contratos, patrocinadores, fornecedores e P\&D. Funcionalidades anunciadas devem ser diferenciadas de jogabilidade comprovada.  
\- Open Wheel Manager 2 — https\://store.steampowered.com/app/1757580/Open\_Wheel\_Manager\_2/ : gestão técnica de chassi, aero, desenvolvimento e testes, contratos, academia, apresentação 3D.  
\- Racing Series Manager — https\://store.steampowered.com/app/4083830/Racing\_Series\_Manager/ : projetos individualizados e desenvolvimento por trabalho de engenharia, não apenas acumular pontos.  
\- Golden Lap — https\://store.steampowered.com/app/2052040/Golden\_Lap/ : gestão profunda com interface simples, relações e tradeoffs de funcionários/pilotos, custos e eventos.  
\- GT Manager (edição PC) — https\://store.steampowered.com/app/2457030/GT\_Manager/ : integração fábrica-oficina-pit wall, funcionários, peças, clima, desgaste, neutralizações e visão 3D. Adaptar à F1 2012; não copiar endurance GT.  
\- Empire Eleven 2026 — https\://store.steampowered.com/app/4502700/Empire\_Eleven\_2026/ : REFERÊNCIA DE CONTROLE DE QUALIDADE, NÃO DE MECÂNICAS DE AUTOMOBILISMO. Problemas relatados em interface, progressão, save, balanceamento e lentidão motivam QA preventivo.  
\- Automation: engenharia, prototipagem, tradeoffs e testes.  
\- WORKS: Motorsport Factory (referência mencionada nas conversas): cadeia produtiva, componentes rastreáveis, operação e funcionários.  
O objetivo não é reunir todos esses jogos em uma versão: catalogar ideias por sistema, evitar repetição e priorizar uma de cada vez.

9\. REFERÊNCIAS DE VÍDEO E MATERIAL AUDIOVISUAL  
As conversas mencionam vídeos de corridas, imagens de transmissão, animações de ultrapassagem e rádio de F1. Não há neste registro links exatos dos vídeos escolhidos anteriormente. NÃO inventar títulos, canais, minutagens ou transcrições. Criar uma biblioteca de referências com URL oficial, licença e descrição do comportamento observado.  
Lista de captura desejada (PENDENTE DE PESQUISA/SELEÇÃO):  
A. Onboard oficial de ataque: aproximação, DRS, saída do vácuo, frenagem e retorno à linha.  
B. Disputa lado a lado em curva: inside/outside, fechamento de espaço, recuo e contato.  
C. Rádio oficial de corrida: piloto solicita box, discordância sobre pneu, defesa, ordem entre companheiros e mensagens de engenharia.  
D. Pit stops e double stack: sequência de chegada, fila, mecânicos e liberação.  
E. Diretor TV: cortes de câmera que enquadram batalha, trackside, perseguição e pit lane.  
F. Documentários de desenvolvimento de chassi, túnel de vento, testes e fábrica para design de processo, não para copiar imagens.  
Fontes a consultar ao pesquisar posteriormente: canais oficiais de F1, FIA e equipes; press kits oficiais dos jogos; vídeos dos próprios desenvolvedores. Guardar URLs, autores, timestamps e autorização de uso. Não incorporar áudio, vídeo, modelos ou imagens proprietárias ao ZIP sem direitos. Usar material como estudo de eventos e criar áudio/visuais originais.  
Ficha para cada vídeo: ID \| URL \| canal/autor \| data \| minuto inicial/final \| comportamento identificado \| sistema APEX \| implementação sugerida \| licença/verificação.

10\. ROADMAP ATUALIZADO E SEQUÊNCIA DE TRABALHO  
0.6.5.0 HUD Unificada / Soul Staff — registro de base anterior.  
0.6.5.1 Living Factory 1.0 — base recebida.  
0.6.5.2 3D Racing — material Work em registro; incorporado ao desenvolvimento posterior.  
0.6.5.3 Realistic Racing — ZIP recebido.  
0.6.5.4 — NÃO DOCUMENTADO NESTA SÍNTESE; verificar.  
0.6.5.5 Sim Racecraft — ZIP recebido; revisão técnica pendente.  
0.6.5.6 Living Factory 2.0 (Oficina Operacional) — PRÓXIMA PROPOSTA; requer auditoria e sinal verde de implementação no Work. Há prompt específico definido nesta conversa.  
0.6.5.7 Research & Development 2.0 — PROPOSTA, projetos e protótipos; não começar antes de fechar oficina.  
0.6.5.8 Soul Staff 2.0 — PROPOSTA de relações/competências/consequências; número pode ser reavaliado após revisão do código.  
0.6.6.x Driver Dynamics — PROPOSTA de decisões de ataque/defesa, personalidade e risco no próprio motor.  
0.7.x Centro de engenharia profundo e testes de componentes.  
0.8.x Gestão comercial, finanças, contratos, criação de equipe, academia e carreira.  
0.9.x Motorsport Universe: múltiplas temporadas, mudanças regulatórias, aposentadorias, rivais adaptativos, Hall da Fama, modo histórico alternativo.  
1.0.0 Integração e experiência estável, histórico de eras e extensibilidade. META; sem data prometida.  
ATENÇÃO: roteiros antigos davam outras funções aos mesmos números. Roteiro atual prevalece apenas como proposta de priorização, não substitui release notes e ZIP final.

11\. PADRÕES OBRIGATÓRIOS DE CÓDIGO  
\- Uma funcionalidade principal por versão; patches corretivos pequenos.  
\- Antes de editar: extrair ZIP, inventariar módulos existentes, comparar com base anterior, mapear pontos de integração.  
\- Manter regras, telemetria, render e UI desacoplados; dados com fontes únicas.  
\- No Godot, se a interface utiliza snapshots, trabalhar sobre cópias sem mutação do motor.  
\- RNG da corrida, relógio de simulação e semente não podem mudar por efeitos 3D.  
\- Evoluir a estrutura em módulos, não ampliar indefinidamente scripts monolíticos.  
\- Persistência versionada com schema, migração/rollback e teste de saves legados.  
\- Não refatorar novamente o que já foi refatorado, a menos que um bug fundamentado demande correção direcionada.  
\- Perfis gráficos compatíveis com Linux Mint e com o renderizador efetivo do projeto; não habilitar FXAA/efeitos incompatíveis sem testar.  
\- Não implantar botões cenográficos funcionais só na aparência; se a função não existe, mostrar bloqueio honesto.  
\- Código, carros, circuitos, imagens e sons originais ou legalmente licenciados.

12\. REGRESSÕES DE ALTO RISCO  
1\) Ordem manual box V21 não pode disparar V4, mesmo em chuva forte.  
2\) Tempo de volta e velocidade 1x devem ser coerentes; nada de Spa terminar em segundos.  
3\) 2D, 3D, HUD, rádio e resultado lêem a mesma classificação e progresso.  
4\) Motor tem comportamento determinístico para mesma seed/ordens, independentemente da velocidade ou render.  
5\) Chuva/condição da pista influenciam pneus e IA de forma causal e igual para adversários.  
6\) Double stack, filas, danos e paradas não podem duplicar recursos/custos.  
7\) DRS/KERS e pneus correspondem à era 2012\.  
8\) A animação de disputa não atravessa carros nem altera posição esportiva; lidar com curvas, cruzamentos, pits e carros em voltas diferentes.  
9\) HUD persiste preferências e é legível em duas resoluções.  
10\) Funcionários e componentes não desaparecem/duplicam após salvar e reabrir.  
11\) Corrida e oficina continuam funcionais depois de alterações no mercado e na carreira.  
12\) Performance: registrar FPS/tempo de tick, tempo de carregamento, memória e tamanho de save; testar muitos anos futuros.  
13\) Evitar balanceamento “mágico”: gaps absurdos, vitórias garantidas por uma parada cedo, incidentes em excesso ou IA incapaz de reagir.  
14\) Limites de UI: rolagem, botões, localização e ações realmente conectadas.  
15\) Corrida completa até bandeirada em pistas variadas, não apenas fixtures de ataque.

13\. TESTES E EVIDÊNCIAS MÍNIMAS POR RELEASE  
(i) ZIP completo com project.godot e estrutura legível, sem dependência de caminho absoluto do autor; checksum e integridade.  
(ii) Importação nativa em Godot 4.7.2 headless/Editor, sem parser errors.  
(iii) Smoke tests de novos recursos e regressões anteriores, sobretudo pits, piloto, estratégia, save, HUD.  
(iv) Testes de simulação por sementes fixas: Silverstone, Spa, Monza, Singapura; quando possível ampliar aos 20 GPs.  
(v) Capturas REAIS do Godot em 1600×900 e 1920×1080, corrida real versus fixture de demonstração claramente identificadas.  
(vi) Save/load e migração, integridade de orçamento e peças.  
(vii) Benchmarks de CPU, memória, tamanho de saves, estabilidade e render Compatibility.  
(viii) Relatório técnico: alterações, motivo, arquivos, testes executados, falhas/avisos, regressões, métricas, próximo passo. Nada marcado “aprovado” sem execução.  
(ix) Rollback para versão anterior preservado.  
(x) Release só classificada ESTÁVEL quando testes nativos e visuais comprovarem.

14\. DOCUMENTO DE INCIDENTES / LIÇÕES EXTERNAS  
Empire Eleven 2026: usar reclamações públicas de jogadores sobre lentidão, interface, bugs de progressão/salvamento e balanceamento como checklist preventivo — são exemplos de risco, não diagnóstico do APEX. Evitar simular milhares de entidades com cálculos repetidos, carregar saves gigantescos sem compactação, lançar sistemas incompletos sem comunicar ou tornar a UI difícil de navegar. Estabelecer QA contínuo, registro de bugs, avaliação por gravidade e solução com teste de regressão.

15\. MODELO DE SOLICITAÇÃO PARA O WORK  
“Use a versão ZIP mais recente fornecida, verifique integridade e estado do código. Compare com o plano mestre APEX e changelog. Identifique o que já está implementado, o que precisa ajuste e os riscos de regressão. Implemente SOMENTE \[FUNCIONALIDADE\] na v\[VERSÃO\]. Não substitua HUD Unificada, Core 2, Sim Racecraft, Living Factory, Soul Driver/Staff, Pit Wall ou Strategy Simulator. Não altere física/IA quando o escopo for apresentação. Teste no Godot 4.7.2 com documentação de PASS/FAIL real, evidências visuais e comparação entre sementes; entregue ZIP completo, relatório técnico e capturas. Não avance à próxima versão.”

16\. COMO DECIDIR O PRÓXIMO PASSO  
Prioridade 1: comprovar integridade do ZIP mais recente e testes de regressão.  
Prioridade 2: finalizar Living Factory 2.0 — oficina, se ainda não existir na base atual.  
Prioridade 3: P\&D com projetos e protótipos reais, depois Soul Staff aprofundado.  
Prioridade 4: aprofundar comportamento no motor e carreira sem destruir resultados de 2012\.  
Ao receber outro jogo, crítica, vídeo ou mod: adicionar à seção 8/9 com fonte concreta, registrar a ideia e apontar módulo APEX que seria beneficiado. Não criar versão nova só por descobrir uma referência.

17\. REGISTRO DE DECISÕES E QUESTÕES ABERTAS  
Decisões firmes: Godot 4.7.2; PC Linux; 2012; Core 2; jogadores não dirigem diretamente; Manual/IA; HUD Unificada; 2D e 3D; updates incrementais; rollback; testes antes de avançar; inspiração sem copiar.  
Verificar no código atual: nomes de APIs da v0.6.5.5, status do inventário e da fábrica, schema de save, conteúdo da v0.6.5.4, eficiência real das ultrapassagens, compatibilidade gráfica, número de pistas/campeonatos efetivamente jogáveis, cobertura real de QA.  
Futuras decisões a registrar: modos de carreira (chefe/proprietário), nível de automatização do STAFF, sistema financeiro, faixa de era histórica, personalização de equipe, perfil de hardware mínimo e demo pública.

18\. REFERÊNCIAS ORIGINAIS PARA DADOS HISTÓRICOS  
FIA regras técnicas e esportivas por temporada: preferir documentos oficiais correspondentes ao ano.  
Jolpica F1 API: https\://api.jolpi.ca/docs/ (verificar termos e limites antes de usar/distribuir).  
Pirelli press: https\://press.pirelli.com/ (compostos e seleção por GP).  
Links de mods e ideias técnicas: consultar “APEX\_PESQUISA\_29\_MODS\_PLANO\_TECNICO.md”; não copiar seus binários, modelos ou scripts.

FINAL — INSTRUÇÃO PARA NOVAS CONVERSAS  
Tratar este arquivo como REFERÊNCIA CONSOLIDADA DE INTENÇÃO E HISTÓRICO, não como prova de implementação. Não confundir “o usuário quer”, “o Work escreveu”, “o ZIP contém” e “o Godot validou”. Antes de qualquer nova versão, confrontar o plano com o código e com os testes. Se houver conflito, preservar o projeto funcional e explicar a divergência. Construir o APEX de maneira original, progressiva, auditável e coerente com o automobilismo.  