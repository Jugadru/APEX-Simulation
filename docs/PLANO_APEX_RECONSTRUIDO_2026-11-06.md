# APEX MOTORSPORT MANAGER — PLANO RECONSTRUÍDO

**Data:** 06/11/2026  
**Material analisado:** exportação da conversa *Ideia de simulador F1*, arquivos e changelogs da base 0.5.8.0 e projeto 0.5.9.0 experimental.  
**Critério:** separar o que foi desejado, o que está documentado no código e o que foi realmente verificado em execução. Esta proposta não equivale a uma promessa de que todas as funcionalidades já existam.

## 1. Identidade do jogo (direção aprovada pelo usuário)

O Apex não deve ser somente um Cockpit Manager modernizado nem uma imitação do F1 Manager. O jogador **gerencia uma equipe**, contrata e desenvolve STAFF, recebe informações de engenheiros e pilotos, pode delegar decisões e observa consequências coerentes da simulação. A inspiração em Motorsport Manager 2 deve aparecer na legibilidade, nos painéis e na câmera, não na reutilização de código ou assets protegidos.

### Pilares

1. **Corrida contínua**: tempo por distância e setores, pneus e clima da época, KERS/DRS conforme 2012, tráfego, disputa, estratégia e pit lane conectados.
2. **Agência humana**: dois pilotos com percepção imperfeita, opinião, pedidos de box, ordens entre companheiros, confiança e consequências.
3. **Delegação**: escolha pré-corrida e durante a prova entre Manual e Automático. Funcionários devem tomar decisões baseadas em competências, informações, orçamento e objetivos; o jogador intervém quando necessário.
4. **Visual estratégico**: câmera aérea alta como padrão, mapa 2D dinâmico de bolinhas separado, Diretor TV para eventos e câmeras próximas, HUD com cartões contextuais no lugar de janela de Pit Wall permanente.
5. **Campanha**: iniciar na temporada 2012 (20 etapas, 12 equipes e 24 pilotos na base atual); outras épocas no futuro, cada uma com regras, pneus, unidades de potência e pilotos adequados.
6. **Engenharia**: componentes de carro, fabricação e teste com dados simulados e confiabilidade, inspirados no espírito de *Automation*, sem construir uma simulação física excessivamente complexa.

## 2. Situação das versões (código x propostas)

| Versão | Funções entregues/documentadas no material | Estado de verificação |
|---|---|---|
| 0.1–0.4.5 | Motor Python/Tkinter, Spa, visualização 2D, pit wall, Diretor TV, oficina inicial | Histórico de entregas; não revalidado agora |
| 0.5.0–0.5.2.x | Migração Godot, circuitos 2012, dual view 2D/3D, pista e carros, câmeras, boxes | Histórico de correções e testes do usuário |
| 0.5.3.x–0.5.6.x | HUD, comentários, telemetria, pit lane, regras 2012, clima, pneus, disputa e KERS/DRS | Presentes na árvore 0.5.8.0; testes estáticos não substituem Godot |
| 0.5.7.0 | IA estratégica, previsões de água, engenheiro consultivo e planos de stints | Código e changelog presentes |
| 0.5.8.0 | Pit V21 só na V21, Manual/IA **por piloto nos boxes**, ordens registradas, primeira geometria de disputa lateral | ZIP original recebido e testado estaticamente |
| 0.5.9.0 | Manual/Automático **global da equipe**, ritmo/KERS delegados, IA de box herdada, STAFF inicial por níveis | Código implementado; testes Python e Godot do usuário ainda necessários para validar funcionalmente |

**Diferença de escopo importante:** em partes do planejamento original, 0.5.8.0 seria o início da contratação de STAFF; a entrega recebida como 0.5.8.0 priorizou pits e combates. Portanto a primeira implementação de STAFF passou para 0.5.9.0. Não reescrever essa história por conveniência.

## 3. Próximas etapas propostas (reorganização)

### 0.5.9.0 — Estabilização da delegação (agora)

**Código atual:** Manual controla ritmo/KERS; Automático liga a IA de boxes e escolhe ritmo/KERS dos dois pilotos, usando dois níveis técnicos: estrategista e engenheiro.

**Condição para aprovar:** F5 sem erro de parser; alterar global Manual→Automático→Manual; dois pilotos recebem controle automático; ordem explícita de box V21 não executa em V4 mesmo sob chuva; recomendação do engenheiro e ação da IA são distinguíveis; KERS usa nomes e limites de 2012; dinheiro descontado uma vez e STAFF salvo após reabrir; a 0.5.8.0 continua disponível como rollback.

**Pendências:** o STAFF ainda não é um conjunto de pessoas com contrato, salário, qualidades individuais e relacionamentos. A camada atual de ritmo/KERS não altera matematicamente o planejador de pit com base na qualidade do estrategista; essa integração exigirá uma etapa própria. Equipe rival tem IA existente, mas não a mesma camada de STAFF do jogador.

### 0.6.0 — Temporada 2012 com salvamento (próxima major release)

Criar estrutura de calendário, fim de semana, grid, resultado, pontuação individual e de construtores, histórico de corridas e estado entre etapas. Integrar orçamento e upgrades existentes em uma campanha, evitando que iniciar nova corrida reinicie o campeonato. Validar normas e pontuação de 2012 antes da implementação. Não confundir motor de simulação com motor visual.

**Aceite:** executar ao menos duas etapas consecutivas, salvar, fechar e reabrir sem perda de campeonato, resultados, upgrades ou recursos.

### 0.6.1 — HUD estratégica reconstruída (proposta)

Migrar o protótipo Full HD separado, só depois da estabilidade 0.5.9/0.6.0: resolução lógica 1920×1080, câmera aérea estável, mapa 2D e minimapa contextual, classificação dobrável à esquerda, cartões de piloto e rádio próximo, painéis Track/Weather, Strategy e Telemetry/Data acionados conforme necessidade, controles inferiores e Diretor TV secundário. Nada de cobrir permanentemente a pista com grandes janelas opacas.

**Aceite:** troca de câmeras sem recenter indevido; 2D/3D representam o mesmo progresso; HUD não altera estado da corrida; navegação em 1080p e resoluções menores; clique no piloto abre contexto correto.

### 0.6.2 — STAFF de verdade (proposta)

Começar estrutura de cargos: estrategista, engenheiro de corrida, chefe de mecânica, líder de aerodinâmica, chefe de projeto/engenharia. Distinguir recrutamento, treinamento e competência; efeitos auditáveis em estratégia, comunicação, pit, qualidade de peças e confiabilidade. Separar recomendações da execução, sem violar agendamentos manuais. Depois evoluir para candidatos individuais, contratos e salários em vez dos atuais níveis 0–3.

### 0.6.3 — APEX Driver Soul (proposta)

Criar percepção de pneus diferente de desgaste físico, paciência, agressividade, confiança no engenheiro, leitura do clima, iniciativa para solicitar box ou ultrapassagem do companheiro. O piloto pode se equivocar; o rádio nasce dos eventos e do seu estado. Não atribuir temperamentos fictícios como fatos históricos a pessoas reais da temporada 2012.

**Aceite:** pedidos geram recomendações ou decisões permitidas pelo modo da equipe; nunca anulam regras de segurança; é possível distinguir psicologia e física da corrida; repetibilidade por semente.

### 0.6.4 — Rádio e transmissão (proposta)

Conversas piloto↔engenheiro baseadas em eventos reais, frequências configuráveis, narrador/analista/comentarista dos boxes separados, legendas, gravações originais. Não redistribuir rádio real protegido ou clonar vozes de pilotos reais. Checar prioridade e supressão de mensagens repetidas.

### 0.7.x — Centro de engenharia e testes (proposta)

Motor, KERS, arrefecimento, chassi, asa dianteira e traseira, assoalho, difusor, suspensão, câmbio e freios como áreas evolutivas. Construir protótipo, testá-lo com dados gerados pelo motor do jogo, registrar confiabilidade, orçamento e ganho esperado. Evitar ganhos absolutos que garantam vitória e impedir modificações instantâneas no meio do GP.

### 0.8.x — Gestão comercial e carreira (proposta)

Contratos de pilotos e STAFF, fornecedores, patrocinadores, custos de fabricação e salários, objetivos do conselho, instalações, contratação e demissão. Aprofundar gestão sem criar tarefas repetitivas sem consequência.

### 0.9.x — Múltiplas temporadas e adaptação das equipes (proposta)

Calendário persistente, evolução dos regulamentos, novos talentos, aposentadoria, evolução de IA das equipes e dificuldade equilibrada. Proteger bases de dados de 2012 contra alterações destrutivas.

### 1.0.0 — Experiência integrada e eras históricas (meta)

Física consistente, IA robusta, HUD acessível, carreira e banco de dados importáveis, temporadas históricas que respeitem regulamentos próprios (por exemplo 2012 não usa ERS híbrido). Esta é uma meta, não uma data de lançamento.

## 4. Problemas históricos que viram regressões obrigatórias

- Agendamento do pit na volta 21 **não pode** transformar-se em parada na volta 4, inclusive na chuva.
- A IA precisa responder a chuva, desgaste e janela de box, sem uma parada em duros na V5 garantir vitória em Spa.
- Líder não deve abrir diferenças excessivas sem motivo; gaps e intervalos devem ter origem física identificável.
- Não acelerar uma volta de Spa a poucos segundos na velocidade 1×. O relógio de corrida deve refletir o motor e não uma animação arbitrária.
- DRS/KERS históricos de 2012, sem misturar sistemas de outras épocas; energia e rendimento dos três modos de KERS distintos e limitados.
- Mapa 2D e carros 3D compartilham progresso, evitando saltos na troca de modos.
- Diretor TV e Seguir Piloto não voltam ao centro da pista por erro de zoom.
- Pit wall e rádio devem mostrar decisão, recomendação e status real sem informação enganosa.

## 5. Definição de concluído

1. Arquivo ZIP íntegro, com `project.godot`, scripts e dados; nenhum caminho local absoluto necessário para validação.
2. Testes Python da versão passam; testes antigos não podem proibir versões futuras apenas por compararem strings.
3. Validação com parser Godot em `--headless --editor --quit` aprovada.
4. Smoke tests nativos de simulação, pits e comando da equipe aprovados.
5. Teste visual no Linux Mint (F5) sem erro de GDScript e com modos funcionando.
6. Não alterar o motor físico e os visuais aprovados sem justificativa e regressões específicas.
7. Só marcar uma versão estável depois de validar no Godot; testes estáticos sozinhos justificam **experimental**, não lançamento.

---

**Fonte principal deste roteiro:** histórico enviado pelo usuário e árvore do projeto; os números das fases pós-0.6.0 são uma reorganização proposta a partir dos pedidos, não versões já lançadas.
