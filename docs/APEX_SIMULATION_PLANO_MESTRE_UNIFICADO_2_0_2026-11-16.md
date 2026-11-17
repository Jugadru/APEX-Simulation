# APEX MOTORSPORT MANAGER
# PLANO MESTRE UNIFICADO 2.0
## Engenharia Profunda, Simulação Causal e Refinamento Contínuo

**Revisão:** 16/11/2026  
**Motor:** Godot 4.7.2 — GDScript  
**Plataforma principal:** PC / Linux Mint  
**Temporada histórica inicial:** Fórmula 1 de 2012  
**Natureza:** documento vivo de arquitetura, planejamento e qualidade  
**Substitui, como referência de planejamento:** Fonte Mestra de 13/11/2026  
**Não substitui:** código-fonte, testes, changelogs e ZIPs efetivamente validados.

---

## 1. NOVA FILOSOFIA DO APEX

O APEX Motorsport Manager não será desenvolvido com a mentalidade de simplesmente adicionar funcionalidades.

O objetivo é construir um simulador de gerenciamento automobilístico no qual cada departamento, personagem, componente e decisão tenha comportamento próprio, limitações, consequências e conexões com os demais sistemas.

**Princípio central:**

> A complexidade do APEX deve nascer de modelos causais, código bem estruturado, decisões inteligentes e consequências persistentes. Não de multiplicadores arbitrários, menus decorativos ou grandes quantidades de código sem propósito.

### 1.1 Dez princípios obrigatórios

1. **Profundidade antes de quantidade.** Refinar sistemas existentes antes de criar substitutos ou duplicações.
2. **Causalidade antes de aleatoriedade.** Cada resultado deve possuir causas identificáveis; a aleatoriedade reproduzível representa incerteza, não substitui o modelo.
3. **Complexidade interna, clareza externa.** Os sistemas podem ser sofisticados, mas a interface deve permitir decisões compreensíveis.
4. **Código modular.** Separar responsabilidades, dependências e contratos de integração.
5. **Consequências persistentes.** Decisões importantes devem repercutir em corridas, equipe, finanças, desenvolvimento ou carreira.
6. **IA sujeita a limitações.** Pilotos e funcionários não devem possuir conhecimento perfeito, nem cometer erros artificiais apenas para criar drama.
7. **Determinismo esportivo.** O mesmo estado inicial, semente, comandos e sequência de ticks deve produzir os mesmos resultados.
8. **Otimização demonstrável.** Cada melhoria de desempenho exige benchmark e comparação.
9. **Evolução incremental.** Uma funcionalidade principal por versão, com regressões obrigatórias.
10. **Nenhuma implementação fingida.** Um sistema planejado, descrito ou apresentado visualmente não pode ser declarado funcional sem código e testes.

### 1.2 O que evitar

- Acrescentar atributos que não alteram nenhuma decisão.
- Usar pontos abstratos como substitutos de engenharia e fabricação.
- Criar bônus enormes para simular diferença de habilidade.
- Fazer ultrapassagens sem disputa plausível.
- Permitir recursos ilimitados ou manutenção instantânea.
- Fazer todos os pilotos seguirem a mesma estratégia.
- Simular funcionários perfeitos ou completamente imprevisíveis.
- Criar telas sem backend e apresentá-las como funcionais.
- Reescrever grandes módulos sem evidência de necessidade.
- Sacrificar resultados determinísticos para aumentar FPS.
- Confundir quantidade de linhas com qualidade ou profundidade do software.

---

## 2. IDENTIDADE DO PRODUTO

O jogador é o responsável por uma escuderia.

Ele contrata pilotos e funcionários, define políticas, acompanha engenharia, desenvolve componentes, organiza produção, administra orçamento, estabelece estratégias e observa os resultados em corridas simuladas.

O APEX **não é um jogo de pilotagem direta**.

A experiência desejada combina:

- Gestão técnica profunda.
- Personalidade de pilotos e funcionários.
- Corridas estratégicas e visualmente convincentes.
- Fábrica, oficina e operações integradas.
- Decisões manuais ou delegadas à IA.
- Campeonato e carreira persistentes.
- Histórias emergentes baseadas em acontecimentos reais da simulação.

### 2.1 Identidade visual

Preservar a identidade aprovada:

- Laranja APEX como cor principal.
- Grafite e cinza na estrutura.
- Menus minimalistas e contextuais.
- HUD unificada já existente.
- Visualização 3D estratégica, mapa 2D e Diretor TV.

Não iniciar outra refatoração completa de HUD sem diagnóstico técnico comprovado.

### 2.2 Regulamento histórico

A temporada inicial permanece 2012, com 20 etapas, 12 equipes e 24 pilotos conforme a base histórica do projeto.

Usar regulamentos correspondentes ao ano, incluindo motores V8, KERS, DRS e pneus apropriados.

Não incorporar automaticamente tecnologias ou regras posteriores, como ERS híbrido e limites orçamentários modernos.

---

## 3. ESTADO DOCUMENTADO DO DESENVOLVIMENTO

**Regra de autoridade:** o código do ZIP realmente entregue é superior ao planejamento. O relatório de testes confirma somente aquilo que foi executado. Uma versão identificada em documentos não comprova, isoladamente, que o ZIP correspondente está disponível ou íntegro.

### 3.1 Evolução recente identificada

| Versão | Evidência técnica recuperada |
|---|---|
| 0.6.6.0 | Replay determinístico introduzido no histórico do projeto |
| 0.6.6.1 | Driver Dynamics: refinamento de ataque e defesa |
| 0.6.6.2 | Racecraft Telemetry: observação passiva de disputas |
| 0.6.6.3 | Otimização de corridas longas e compressão ZSTD dos checkpoints, conforme registros posteriores |
| 0.6.6.4 | Replay Memory: retenção limitada e navegação de histórico |
| 0.6.6.5 | Seleção equilibrada de até nove checkpoints, preservando o primeiro e o mais recente |
| 0.6.6.7 | Diretor TV e highlights, com auditoria adicional de regressões |
| 0.6.6.7.2 | Refinamento de apresentação visual e comportamento de carros |
| 0.6.6.7.2.1 | Interpolação visual e ajustes de velocidade, conforme testes recuperados |
| 0.6.6.7.2.2 | Strategic 2D Performance: cache de geometria e alternância automática de visualização |

**Importante:** essa tabela registra evidências documentais, não uma auditoria integral de todos os ZIPs.

### 3.2 Resultados técnicos relevantes

Os relatórios recuperados registram uma corrida completa de Monza com 53 voltas, 24 carros e 24.431 ticks, preservando o hash esportivo:

`2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b`

Na v0.6.6.5, a busca pelo tick 750 caiu de 13,468 s para 4,007 s no benchmark documentado.

A política de checkpoints mantém até nove posições distribuídas no histórico e evita descartar indiscriminadamente os pontos antigos.

Um experimento de espaçamento por potências de dois foi rejeitado porque prejudicava significativamente determinadas buscas.

Na v0.6.6.7.2.2, o mapa estratégico passou a separar geometria estática e objetos dinâmicos. Em um ensaio com 180 atualizações, a geometria estática foi desenhada uma vez, em vez de ser reconstruída em cada atualização.

**Limitação:** essa redução de redesenho não demonstrou ganho mensurável de FPS no benchmark apresentado.

### 3.3 Pendências abertas

- Desempenho efetivo de 10x, 16x e 32x em hardware real.
- Regulação do custo esportivo por tick, sem pular simulação.
- Validação prolongada de 20 temporadas.
- Testes integrais de corrida e replay a cada atualização relevante.
- Desempenho de gravações históricas com grandes distâncias entre checkpoints.
- Problemas visuais de duelos prolongados e de curvas.
- Erros específicos de janela X11/Editor que não foram definitivamente reproduzidos ou solucionados.
- Testes de compatibilidade histórica após mudanças futuras em save, carreira e regulamento.

Não reabrir problemas já resolvidos sem evidência de regressão.

---

## 4. ARQUITETURA-ALVO DE ENGENHARIA

A arquitetura deverá separar rigorosamente seis responsabilidades.

### Camada A — Domínio

Representa as entidades e regras fundamentais:

- Piloto.
- Funcionário.
- Equipe.
- Carro.
- Componente.
- Projeto de engenharia.
- Circuito.
- Sessão de corrida.
- Estratégia.
- Contrato.
- Campeonato.

Cada entidade deve possuir identidade estável, estado válido e ciclo de vida definido.

### Camada B — Simulação determinística

Responsável pela evolução esportiva:

- Tempo e ticks.
- Física simplificada de corrida.
- Pneus e condições da pista.
- Ritmo e consumo.
- Combate e posições.
- Pit stops.
- Incidentes e confiabilidade.
- Regras esportivas.

Somente esta camada, ou módulos autorizados por ela, pode alterar o estado esportivo oficial.

### Camada C — Serviços de decisão

Responsável pelo raciocínio dos agentes:

- Driver Dynamics.
- Race Engineer.
- Pit Wall.
- Staff AI.
- IA de desenvolvimento.
- IA de contratação.
- IA de operação da fábrica.

Os agentes recebem observações compatíveis com suas competências e devolvem intenções ou comandos validados.

### Camada D — Eventos, telemetria e persistência

Responsável por:

- Registrar acontecimentos.
- Produzir telemetria.
- Gerar checkpoints.
- Gravar replays.
- Serializar saves.
- Registrar decisões.
- Preservar histórico de carreira.

A observação não altera os eventos observados.

### Camada E — Apresentação

Responsável por:

- HUD.
- Mapa estratégico 2D.
- Visualização 3D.
- Diretor TV.
- Gráficos.
- Rádio.
- Relatórios e menus.

A apresentação consome snapshots e eventos, sem escrever diretamente no estado do motor.

### Camada F — Infraestrutura e qualidade

Responsável por:

- Scheduler.
- Profiler.
- Testes.
- Validação de conteúdo.
- Migração de schema.
- Integridade dos arquivos.
- Benchmarks.
- Logs e diagnóstico.

### 4.1 Contratos técnicos

**SimulationKernel**

Entrada: estado inicial, seed, comandos ordenados e quantidade de ticks.

Saída: novo estado e eventos esportivos.

**DecisionService**

Entrada: observações autorizadas e perfil do agente.

Saída: intenção, avaliação de risco, confiança e comando proposto.

**CommandValidator**

Verifica autoridade do emissor, momento, recursos, regras e conflito com comandos existentes.

**TelemetryObserver**

Recebe eventos confirmados e produz indicadores sem modificar o motor.

**ReplayStore**

Registra comandos, estados de referência, hashes e checkpoints versionados.

**PresentationAdapter**

Transforma snapshots em informação gráfica sem criar resultados esportivos.

Esses são contratos arquiteturais **propostos**, não nomes garantidos de classes existentes. Antes de criar novos scripts, mapear implementações equivalentes no código atual e reutilizá-las.

---

## 5. REFINAMENTO PROFUNDO DO MOTOR DE CORRIDA

### 5.1 Física de corrida

O modelo deve evoluir para uma cadeia causal:

**Carro + piloto + configuração + pneus + pista + clima + tráfego + estratégia → desempenho e risco.**

Não representar todos esses fatores apenas com um multiplicador genérico.

Criar ou aprimorar os modelos de:

- Aderência disponível.
- Tração e frenagem.
- Resistência aerodinâmica.
- Carga aerodinâmica.
- Temperatura e desgaste de pneus.
- Massa de combustível.
- Estado mecânico.
- Sensibilidade às características dos setores.
- Ar sujo e vácuo.
- Gestão de energia KERS.
- Condições de DRS compatíveis com 2012.

As aproximações devem permanecer compatíveis com o nível de abstração escolhido. Não apresentar grandezas de engenharia como medidas físicas exatas se forem indicadores aproximados.

### 5.2 Driver Dynamics avançado

Cada piloto deve utilizar um modelo de decisão com:

- Percepção de ritmo.
- Confiança.
- Agressividade.
- Paciência.
- Consciência espacial.
- Habilidade de frenagem.
- Tolerância ao risco.
- Preferência por trajetória.
- Experiência.
- Estado emocional.
- Condição física e fadiga.
- Relação com a equipe.
- Obediência ou contestação de ordens.

Evitar que atributos se somem como bônus independentes exagerados.

Adotar um processo de decisão em estágios:

1. Observar o carro da frente.
2. Estimar ritmo relativo e oportunidade.
3. Avaliar pneus, pista, combustível e riscos.
4. Selecionar estratégia de aproximação.
5. Escolher corredor.
6. Iniciar ou abortar o ataque.
7. Resolver disputa lateral.
8. Recuperar a trajetória.
9. Aprender ou atualizar estado subjetivo após o evento.

### 5.3 IA de defesa

O defensor deve:

- Reconhecer ameaças reais.
- Avaliar o risco de perder a posição.
- Considerar linha interna e externa.
- Antecipar a defesa quando permitido.
- Evitar mudanças repetidas durante a mesma disputa.
- Preservar espaço para carros que já estejam lado a lado.
- Saber quando defender é mais prejudicial que ceder.
- Adaptar-se à chuva, pneus e danos.

A IA não deve garantir a manutenção de posição por meio de bloqueios mágicos.

### 5.4 Resolução de disputas

Preservar uma máquina de estados de combate:

**Aproximação → Preparação → Ataque → Defesa → Lado a lado → Resolução → Recuperação.**

A resolução poderá incluir:

- Ultrapassagem.
- Defesa bem-sucedida.
- Recuo.
- Perda de tempo.
- Contato plausível.
- Erro de frenagem.
- Incidente.
- Penalização, quando aplicável.

A posição esportiva deve ser definida exclusivamente pelo motor. O modelo 3D recebe o evento para representá-lo.

### 5.5 Largadas realistas

Nova linha futura de refinamento:

- Tempo de reação do piloto.
- Preparação da embreagem, em abstração apropriada.
- Tração inicial.
- Temperatura dos pneus.
- Aderência da posição de largada.
- Diferença de ritmo entre carros.
- Decisão de corredor.
- Congestionamento da primeira curva.
- Capacidade de evitar contatos.
- Recuperação após uma largada ruim.

Os resultados devem surgir das condições iniciais e decisões dos pilotos, não de uma distribuição fixa de posições ganhas.

---

## 6. CLIMA, PREVISÃO E ACERTO DO CARRO

A referência Wet Weather Setups sugere aprofundar a preparação do carro para diferentes condições meteorológicas.

**Status:** proposta de design inspirada em referência externa; não considerar implementada sem validação.

### 6.1 Acertos por condição

Estabelecer alvos de preparação:

- Seco.
- Úmido.
- Molhado.

Esses alvos não devem ser três bônus fixos.

Eles deverão influenciar um conjunto coerente de parâmetros:

- Carga aerodinâmica.
- Arrasto.
- Distribuição de frenagem.
- Rigidez e comportamento de suspensão.
- Estabilidade.
- Temperatura de pneus.
- Tração.
- Desgaste.

O efeito deve variar continuamente com as condições efetivas do asfalto e o perfil do circuito.

### 6.2 Previsão imperfeita

A previsão meteorológica deve ser uma observação da equipe, não acesso antecipado ao clima real.

Sua qualidade dependerá de:

- Departamento e ferramentas meteorológicas.
- Competência dos profissionais.
- Dados disponíveis.
- Antecedência.
- Incerteza do fenômeno previsto.

A IA adversária deve receber o mesmo tipo de informação imperfeita, respeitando diferenças justificadas entre equipes.

### 6.3 Treinos e conhecimento acumulado

Cada saída de pista poderá contribuir para o conhecimento do carro:

- O piloto percebe um comportamento.
- O engenheiro interpreta o relato.
- A telemetria oferece evidências.
- A equipe atualiza a estimativa do acerto.
- O conhecimento persiste para sessões futuras.

Dados históricos e estimativas subjetivas devem ser armazenados separadamente.

### 6.4 Consequências estratégicas

Um acerto conservador para chuva poderá prejudicar classificação em pista seca, mas ajudar na corrida molhada.

A escolha deverá ser uma aposta estratégica real, sem garantir recompensa.

---

## 7. PIT WALL ESTRATÉGICO DE ALTA PROFUNDIDADE

O Pit Wall deve operar como um departamento com capacidade de análise, prioridades e limitações.

### 7.1 Modelo decisório

O estrategista deverá considerar:

- Probabilidade de chuva.
- Vida útil estimada dos pneus.
- Condição real e observada.
- Tráfego de retorno.
- Janelas de pit.
- Undercut e overcut.
- Risco de neutralização.
- Desgaste de componentes.
- Conflitos de garagem.
- Necessidade de reparos.
- Objetivos diferentes para cada piloto.

### 7.2 Controle e delegação

Manter modos Manual, Assistido e Automático, quando suportados.

**Invariante obrigatório:** uma ordem manual para parar na volta 21 não pode ser executada na volta 4 devido a uma reavaliação automática de chuva.

Comandos agendados devem possuir:

- Emissor.
- Tick de criação.
- Condições.
- Prioridade.
- Prazo.
- Política de cancelamento.
- Status.
- Motivo de rejeição ou alteração.

Comandos enviados pela interface não devem alterar diretamente os dicionários internos da corrida.

### 7.3 Staff estratégico

Competência não deve produzir apenas estratégias melhores.

Pode afetar:

- Precisão de estimativas.
- Rapidez de reação.
- Capacidade de lidar com informações conflitantes.
- Coordenação entre estrategista e engenheiro.
- Qualidade de comunicação.
- Frequência de erros justificáveis.

---

## 8. LIVING FACTORY E ENGENHARIA DE VERDADE

A fábrica deve ser um sistema operacional persistente, não uma loja de upgrades.

### 8.1 Componentes individuais

Cada peça precisa de uma identidade única e histórico próprio:

- ID.
- Família.
- Especificação.
- Equipe proprietária.
- Carro instalado.
- Origem de fabricação.
- Revisão do projeto.
- Quilometragem.
- Desgaste.
- Integridade.
- Confiabilidade.
- Histórico de manutenção.
- Custo de produção.
- Estado de inventário.

### 8.2 Projetos de engenharia

O ciclo de desenvolvimento deve ser:

**Requisito → Projeto → Simulação → Protótipo → Testes → Avaliação → Fabricação → Inspeção → Instalação → Validação de pista.**

Cada etapa deve consumir tempo e recursos reais da simulação.

A engenharia deve permitir decisões com tradeoffs:

- Mais downforce pode aumentar arrasto.
- Mais potência pode elevar exigências térmicas.
- Mais leveza pode afetar durabilidade.
- Mais rigidez pode prejudicar determinadas pistas.
- Maior desempenho pode elevar custo de fabricação.
- Melhor confiabilidade pode exigir peças mais conservadoras.

### 8.3 Oficina operacional

Ordens de serviço deverão ter:

- Identidade única.
- Prioridade.
- Componente.
- Dependências.
- Mecânico responsável.
- Duração.
- Recursos e peças necessários.
- Custo.
- Risco de retrabalho.
- Estado.
- Histórico.

Não permitir que o mesmo funcionário execute simultaneamente duas tarefas incompatíveis.

Não permitir instalação duplicada da mesma peça ou reparos infinitos sem perda de vida útil.

### 8.4 Engenharia e corrida

O desempenho do carro deve derivar dos componentes realmente instalados e disponíveis.

Uma melhoria aprovada pelo departamento de projetos não pode aparecer automaticamente na pista antes de ser fabricada, instalada e validada.

---

## 9. SOUL STAFF E ORGANIZAÇÃO HUMANA

Funcionários devem ser agentes com competências, preferências e relações.

### 9.1 Modelo de funcionário

Cada profissional poderá possuir:

- Formação.
- Competência por especialidade.
- Experiência.
- Personalidade.
- Capacidade de decisão.
- Comunicação.
- Fadiga.
- Motivação.
- Lealdade.
- Preferências de trabalho.
- Relações profissionais.
- Contrato.
- Evolução de carreira.

### 9.2 Relações entre departamentos

As relações deverão produzir consequências moderadas e verificáveis.

Exemplos:

- Um engenheiro experiente identifica uma interpretação equivocada de dados.
- Um estrategista competente convence a equipe a reconsiderar uma parada.
- Um chefe de mecânica reduz erros de coordenação.
- Um líder de projeto organiza melhor os testes de protótipos.
- Um piloto com pouca confiança pode interpretar um problema de forma exagerada.

Evitar relações em que uma simples pontuação de amizade determine automaticamente todos os resultados.

### 9.3 Explicabilidade

Sempre que uma decisão relevante acontecer, o sistema deverá conseguir registrar:

- Informação disponível ao agente.
- Objetivo.
- Alternativas avaliadas.
- Riscos considerados.
- Decisão escolhida.
- Consequência observada.

Esses registros não precisam ser exibidos integralmente na HUD; poderão alimentar relatórios e ferramentas de depuração.

---

## 10. MERCADO DE PILOTOS E TRANSFERÊNCIAS

A referência Realistic Transfers motiva uma simulação de mercado mais profunda.

### 10.1 Decisões dos pilotos

Um piloto poderá considerar:

- Salário.
- Duração contratual.
- Desempenho esperado.
- Reputação da equipe.
- Perspectiva técnica.
- Chance de conquistar vitórias.
- Preferência por permanecer.
- Relação com engenheiros.
- Status de primeiro ou segundo piloto.
- Oportunidade de desenvolvimento.

### 10.2 Decisões das equipes rivais

As equipes também deverão:

- Identificar fraquezas.
- Analisar pilotos disponíveis.
- Considerar restrições financeiras.
- Negociar contratos.
- Promover jovens.
- Substituir profissionais.
- Planejar sucessões.

Não permitir contratações gratuitas ou equipes rivais com conhecimento perfeito do futuro.

Uma janela específica de transferências, como agosto, é referência observada em mod, **não regra universal a impor ao APEX de 2012**.

### 10.3 Troca de carros entre pilotos

Inspirado em Driver Swap, o APEX poderá permitir troca de assentos com consistência transacional.

O sistema deverá tratar separadamente:

- Piloto.
- Assento.
- Carro físico.
- Componentes instalados.
- Engenheiro associado.
- Contrato.
- Promessas contratuais.
- Inscrição esportiva.

A operação só pode ser confirmada quando todas as pré-condições forem válidas. Em caso de falha, nenhuma alteração parcial deverá permanecer.

---

## 11. CARREIRA E UNIVERSO AUTOMOBILÍSTICO

O objetivo de longo prazo é uma carreira com múltiplas temporadas e história consistente.

### 11.1 Universo persistente

Incluir progressivamente:

- Campeonatos.
- Evolução de equipes.
- Resultados históricos.
- Transferências.
- Contratos.
- Desenvolvimento de talentos.
- Mudanças regulatórias.
- Aposentadorias.
- Recordes.
- Reputação.
- Patrocinadores.
- Finanças.
- Instalações.
- Academia de pilotos.

### 11.2 Career Desk integrado

A ideia de Career Desk deve inspirar uma central integrada ao jogo, não depender de lançamento manual de estatísticas.

Eventos de carreira podem produzir:

- Histórico por temporada.
- Evolução de pilotos.
- Histórico de equipes.
- Estatísticas de pistas.
- Resultados de rivalidades.
- Recordes.
- Notícias internas geradas com base em fatos simulados.
- Hall da Fama.

Nenhum relatório deve inventar resultados que não constem do histórico persistido.

### 11.3 Carreira tecnicamente sustentável

Testar períodos de 5, 10 e 20 temporadas considerando:

- Tamanho do save.
- Crescimento de históricos.
- Custo de processamento entre eventos.
- Consistência de contratos.
- Identidades e referências.
- Desempenho do mercado.
- Migração de versões.

---

## 12. AUTO SAVE E INTEGRIDADE DE DADOS

O salvamento deve se tornar uma infraestrutura robusta.

### 12.1 Objetivos

- Evitar perda de progresso.
- Impedir corrupção silenciosa.
- Suportar recuperação.
- Preservar compatibilidade histórica quando possível.
- Permitir rollback.

### 12.2 Estratégia proposta

1. Criar snapshot consistente.
2. Validar entidades e referências.
3. Serializar em arquivo temporário.
4. Confirmar integridade.
5. Substituir o arquivo principal com mecanismo seguro suportado pela plataforma.
6. Manter cópia anterior recuperável.
7. Registrar versão e checksum.
8. Validar o carregamento.

Prever comportamento para disco cheio, falta de permissão, encerramento inesperado e migração incompleta.

### 12.3 Identidade dos dados

Não usar a posição de uma entidade em um array como sua identidade permanente.

Pilotos, funcionários, peças, contratos e projetos devem possuir IDs estáveis.

Referências inválidas devem ser detectadas, não silenciosamente substituídas por outra entidade.

---

## 13. REPLAY, TELEMETRIA E OBSERVABILIDADE

Preservar as implementações comprovadas de replay e telemetria.

### 13.1 Invariantes

- A mesma entrada reproduz o mesmo estado esportivo.
- A apresentação não usa o RNG da simulação.
- Telemetria não interfere na decisão.
- Eventos possuem ordenação estável.
- Comandos são aplicados no tick correto.
- Checkpoints são verificáveis.
- Gravações históricas têm revisão identificável.

### 13.2 Refinamentos futuros

Investigar, somente com benchmark:

- Custo de reconstrução de estados.
- Índices de busca por tick, volta e evento.
- Compressão de dados redundantes.
- Retenção limitada de caches.
- Separação entre dados esportivos e visuais.
- Gravação e leitura incremental de grandes arquivos.
- Custos de exportação e importação.

Não alterar arbitrariamente a política de nove checkpoints já implementada.

### 13.3 Telemetria avançada

A Racecraft Telemetry deve evoluir como ferramenta de diagnóstico.

Métricas desejadas:

- Tentativas de ataque por setor.
- Ultrapassagens confirmadas.
- Defesas.
- Recuos.
- Duração de duelos.
- Distância entre carros.
- Perda ou ganho de tempo por disputa.
- Desempenho em chuva.
- Efeito de pneus.
- Incidentes.
- Diferenças por perfil de piloto.

Não usar frequência de ultrapassagens como única métrica de qualidade da IA.

---

## 14. APRESENTAÇÃO 2D, 3D E DIRETOR TV

A simulação deve permanecer independente da visualização.

### 14.1 Mapa 2D

Preservar o cache de geometria introduzido nos registros da v0.6.6.7.2.2.

Continuar refinando:

- Atualização dos carros.
- Miniaturas ou marcadores.
- Seleção de pilotos.
- Proximidade entre carros.
- Exibição de eventos.
- Invalidação correta de cache.
- Legibilidade em velocidades altas.

### 14.2 Câmeras 3D

Priorizar:

- Movimento coerente com progresso esportivo.
- Interpolação visual.
- Redução de saltos.
- Separação de carros em disputas.
- Recuperação de trajetória.
- Enquadramentos estáveis em curvas.
- Câmeras de batalha e trackside.
- Adaptação a hardware modesto.

A interpolação não pode alterar tempos, gaps, posições ou hashes esportivos.

### 14.3 Política de visualização documentada

Na v0.6.6.7.2.2, o modo automático foi registrado com:

- 1x, 2x e 5x: 3D.
- 10x, 16x e 32x: mapa estratégico 2D.
- Seleção manual: prioridade sobre o automático.

Não confundir essa política com garantia de FPS.

### 14.4 Diretor TV

O diretor deve selecionar acontecimentos por critérios verificáveis:

- Intensidade do duelo.
- Proximidade.
- Importância esportiva.
- Mudança de posição.
- Incidentes.
- Pit stops.
- Recuperações.
- Momentos decisivos.

Evitar cortes incessantes, repetição excessiva e foco em acontecimentos irrelevantes.

---

## 15. NOVO CATÁLOGO DE REFERÊNCIAS — OVERTAKE.GG

Essas referências são propostas para estudo de conceitos. Nenhum mod deve ser copiado ou incorporado diretamente ao código do APEX sem análise de licença e compatibilidade.

| Referência | Sistema APEX | Aplicação planejada |
|---|---|---|
| Portrait Editor | Identidade visual | Retratos de pilotos e STAFF |
| Auto Save | Persistência | Backups, integridade e recuperação |
| Driver Swap by lurz | Gestão esportiva | Troca consistente de assentos |
| F1 Career Desk | Carreira | Histórico, estatísticas e acontecimentos persistentes |
| Realistic Race Start | Motor de corrida | Largadas e disputas iniciais |
| Realistic Transfers Lite | Mercado | Contratações e decisões dos rivais |
| Wet Weather Setups Lite | Engenharia/clima | Acertos por condição, previsão e aprendizado |

**Evidência:** os comportamentos de Driver Swap e Wet Weather Setups foram consultados nas páginas originais. Para os outros mods, parte das aplicações acima permanece como inferência de design, não como funcionalidade integralmente confirmada.

Links:

- https://www.overtake.gg/downloads/portrait-editor.88832/
- https://www.overtake.gg/downloads/auto-save.88850/
- https://www.overtake.gg/downloads/driver-swap-by-lurz.88791/
- https://www.overtake.gg/downloads/f1-career-desk-%E2%80%93-career-companion-for-f1-manager-2024.88792/
- https://www.overtake.gg/downloads/realistic-race-start-mod.88786/
- https://www.overtake.gg/downloads/realistic-transfers-lite-by-lurz.88767/
- https://www.overtake.gg/downloads/wet-weather-setups-lite-by-lurz.88728/
- https://www.overtake.gg/members/lurcesaptor.3565895/#latest-activity

Preservar também as referências conceituais anteriores: F1 Manager, Motorsport Manager, Backseat Champions, Golden Lap, Open Wheel Manager 2, Racing Series Manager, GT Manager, F1 Dynasty, Cockpit Manager, Cockpit Simulator, Automation e WORKS: Motorsport Factory.

---

## 16. NOVA DISCIPLINA DE CÓDIGO

Cada sistema deverá possuir uma ficha técnica com:

1. Responsabilidade.
2. Entradas e saídas.
3. Entidades afetadas.
4. Estados possíveis.
5. Invariantes.
6. Dependências.
7. Regras de transição.
8. Condições de erro.
9. Persistência.
10. Telemetria.
11. Custo computacional.
12. Testes unitários.
13. Testes de integração.
14. Compatibilidade com replays e saves.
15. Critérios objetivos de aprovação.

### 16.1 Regras de implementação

- Preferir composição em vez de heranças extensas.
- Usar IDs estáveis para entidades persistentes.
- Evitar dependências circulares.
- Não ampliar indefinidamente scripts monolíticos.
- Não duplicar fórmulas ou estados oficiais.
- Não recalcular informações imutáveis a cada quadro.
- Não realizar cópias profundas desnecessárias.
- Não usar tempo real de renderização como relógio esportivo.
- Utilizar RNG controlado e com ordem de consumo reproduzível.
- Definir limites de memória e retenção para caches.
- Separar valores reais, previstos, percebidos e históricos.
- Validar comandos antes de alterar o estado.
- Registrar erros com contexto suficiente para reproduzi-los.

### 16.2 Critério de profundidade funcional

Uma nova funcionalidade importante só será considerada madura quando demonstrar:

**Decisão → Execução → Consequência → Registro → Persistência → Teste.**

Se uma dessas etapas essencial estiver ausente, registrar explicitamente a limitação.

---

## 17. ESTRATÉGIA DE DESEMPENHO

### 17.1 Medições

Medir separadamente:

- Tempo de tick esportivo.
- Ticks por segundo.
- Tempo de quadro visual.
- FPS de apresentação.
- Memória RSS.
- Memória reportada pelo Godot.
- Alocações relevantes.
- Custo de replay.
- Custo de busca.
- Tamanho de saves.
- Tempo de carregamento.
- Latência de comandos.

### 17.2 Regras de otimização

Antes de otimizar:

1. Reproduzir o problema.
2. Medir.
3. Identificar a função ou estrutura responsável.
4. Criar benchmark.
5. Alterar apenas o necessário.
6. Medir novamente.
7. Comparar hashes e resultados.
8. Verificar se houve regressão em outros cenários.

### 17.3 Velocidades elevadas

O scheduler deve processar todos os ticks necessários ou aplicar somente estratégias comprovadamente equivalentes.

Não pular ticks esportivos para alcançar 32x.

Se a CPU não sustentar a velocidade solicitada, a interface deverá refletir o desempenho real, sem falsear a progressão da corrida.

Otimizações de apresentação e do núcleo esportivo devem ser avaliadas separadamente.

---

## 18. QA — MATRIZ MÍNIMA DE REGRESSÃO

| Área | Teste obrigatório |
|---|---|
| Determinismo | Mesma seed e comandos em diferentes velocidades |
| Corrida longa | Monza 53 voltas e replay conforme escopo |
| Circuitos | Silverstone, Spa, Monza, Singapura |
| Chuva | Condições secas e chuva intensa |
| Racecraft | Ataque, defesa, contato e corredor estreito |
| Pit Wall | Ordem V21 não executa na V4 |
| Garagem | Double stack, conflitos e filas |
| Replay | Gravação, importação, exportação, seek e retorno à corrida |
| Visual | 2D, 3D, HUD e Diretor TV |
| Salvamento | Integridade, migração e rollback |
| Fábrica | Não duplicar peças ou trabalhos |
| Staff | Contratos, relacionamentos e migração |
| Mercado | Consistência de transferências |
| Carreira | Persistência entre temporadas |
| Desempenho | CPU, memória e tamanho de arquivos |

### 18.1 Status obrigatórios

Cada resultado deve receber exatamente uma classificação aplicável:

- **PASS:** execução concluída e critério atendido.
- **FAIL:** execução concluída e critério violado.
- **NOT_RUN:** não executado.
- **INCONCLUSIVE:** execução insuficiente para concluir.
- **BLOCKED:** impedimento técnico documentado.

Não chamar teste interrompido de aprovado.

### 18.2 Separação de evidências

Distinguir:

- Teste unitário.
- Fixture controlada.
- Simulação real de corrida.
- Reprodução histórica.
- Captura visual real.
- Benchmark headless.
- Teste gráfico no PC do usuário.

Uma captura ou fixture não comprova que a corrida completa funciona corretamente.

---

## 19. ROADMAP REORGANIZADO POR DEPENDÊNCIAS

**A numeração seguinte é proposta, não uma declaração de versões já produzidas.**

A última evidência documental localizada nesta revisão é a v0.6.6.7.2.2. Antes de desenvolver, identificar o maior ZIP efetivamente íntegro e validado.

### Fase A — Consolidar desempenho e qualidade

**Prioridade máxima.**

- Auditar a versão mais recente.
- Investigar gargalos esportivos em alta velocidade.
- Validar replay de distância oficial.
- Medir desempenho no PC-alvo.
- Corrigir problemas comprovados de animação.
- Revisar testes legados que não acompanham a semântica dos comandos enfileirados.
- Preservar física e resultados durante otimizações.

### Fase B — Refinar a simulação de pista

Implementações independentes e sequenciais:

1. Largada realista.
2. Acertos climáticos mais profundos.
3. Refinamento dos duelos em curvas.
4. Comportamento de piloto em tráfego.
5. Erros individuais e recuperação.
6. Race Engineer contextual.

Cada incremento terá seus próprios testes e seu próprio rollback.

### Fase C — Engenharia e operação

1. Auditoria do estado atual da fábrica.
2. Refinamento dos componentes individualizados.
3. Capacidade e planejamento de produção.
4. Protótipos e testes.
5. Correlação entre engenharia e pista.
6. Qualidade e confiabilidade.
7. Decisões dos funcionários técnicos.

### Fase D — Mercado e organização

1. Modelo de contratação.
2. IA de transferências.
3. Academia.
4. Troca consistente de assentos.
5. Contratos e expectativas.
6. Finanças operacionais.
7. Decisões dos rivais.

### Fase E — Carreira duradoura

1. Autosave robusto.
2. Histórico estruturado.
3. Career Desk integrado.
4. Progressão entre temporadas.
5. Aposentadorias e sucessões.
6. Mudanças regulatórias versionadas.
7. Recordes e Hall da Fama.
8. Simulações e testes prolongados.

### Fase F — Integração e experiência final

- Refinamento de UX.
- Qualidade gráfica por hardware.
- Acessibilidade.
- Controle de erros.
- Ferramentas de diagnóstico.
- Estabilidade de saves.
- Balanceamento.
- Preparação de builds distribuíveis.

**Regra:** não iniciar uma fase inteira em um único release. Cada etapa deve ser dividida em funcionalidades principais pequenas e verificáveis.

---

## 20. PROCEDIMENTO OBRIGATÓRIO PARA CADA NOVA VERSÃO

### Antes de programar

1. Identificar o ZIP-base mais recente.
2. Validar CRC e SHA-256.
3. Extrair em diretório limpo.
4. Ler changelog e relatório.
5. Mapear scripts e dependências.
6. Executar regressões de referência.
7. Definir uma funcionalidade principal.
8. Estabelecer critérios de aprovação e orçamento de desempenho.

### Durante a implementação

1. Criar testes capazes de demonstrar o problema ou requisito.
2. Implementar em módulos apropriados.
3. Evitar alterações fora do escopo.
4. Registrar decisões de arquitetura.
5. Instrumentar desempenho quando necessário.
6. Verificar determinismo e persistência.
7. Corrigir falhas antes de ampliar funcionalidades.

### Antes da entrega

1. Importar no Godot 4.7.2.
2. Executar testes unitários.
3. Executar testes de integração.
4. Executar regressões esportivas.
5. Comparar hashes e métricas.
6. Conferir integridade de saves.
7. Produzir capturas reais quando exigidas.
8. Preparar changelog.
9. Gerar relatório técnico.
10. Compactar projeto completo.
11. Testar novamente o ZIP extraído.
12. Registrar rollback e limitações.

### Estrutura da entrega

Cada versão deve oferecer:

- ZIP completo do Godot.
- Relatório técnico.
- Changelog.
- Arquivos modificados.
- Matriz de testes.
- Logs.
- Métricas e benchmarks, quando pertinentes.
- Hash SHA-256.
- Capturas reais, quando aplicáveis.
- Instruções de execução.
- Orientações de rollback.

Não entregar apenas trechos de código quando a solicitação exigir o jogo completo.

---

## 21. MODELO DE PROMPT PARA NOVAS IMPLEMENTAÇÕES

Atue como arquiteto de software e engenheiro sênior de simulação automobilística especializado em Godot 4.7.2 e GDScript.

Utilize o ZIP completo mais recente do APEX Motorsport Manager, seu changelog e esta Fonte Mestra 2.0.

Antes de programar, realize uma auditoria do código realmente existente, identifique funcionalidades implementadas, limitações e riscos de regressão.

Implemente somente a funcionalidade principal autorizada para a versão solicitada.

Aplique a filosofia de engenharia profunda: cada novo sistema deve possuir comportamento causal, responsabilidades claras, contratos de dados, condições de falha, integração com subsistemas, persistência quando necessária, telemetria e testes reproduzíveis.

Não simplifique funcionalidades existentes para facilitar a implementação. Não crie multiplicadores artificiais nem recursos meramente decorativos.

Preserve o determinismo do motor, os replays, os saves e a coerência da temporada de 2012.

Teste no Godot 4.7.2, documente evidências reais e entregue ZIP completo com relatório técnico.

Não avance automaticamente à próxima versão.

---

## 22. QUESTÕES TÉCNICAS AINDA ABERTAS

As próximas auditorias devem determinar:

- Qual é a versão mais recente realmente disponível e íntegra.
- Quais subsistemas já possuem testes suficientes.
- Qual é o gargalo dominante em 32x.
- Qual política de retenção de replay melhor atende aos casos de uso reais.
- Qual é a estrutura atual de persistência de carreira.
- Quanto da fábrica e do P&D está efetivamente implementado.
- Quais atributos de pilotos e funcionários já produzem consequências.
- Quais decisões da IA são registradas e explicáveis.
- Quais telas ainda possuem backend incompleto.
- Como os módulos podem evoluir sem quebrar saves históricos.

Questões não respondidas devem permanecer registradas, nunca ser preenchidas com suposições apresentadas como fatos.

---

## 23. FONTES TÉCNICAS DE CONTINUIDADE

Documentos-base consultados nesta reconstrução:

- `APEX_SIMULATION_FONTE_MESTRA_2026-11-13.md`
- Registros recuperados da auditoria e otimização da v0.6.6.3
- `APEX_RELATORIO_TECNICO_v0.6.6.5.md`
- `APEX_CHANGELOG_v0.6.6.5.md`
- `APEX_AUDITORIA_RETESTES_v0.6.6.7.json`
- `APEX_TESTES_v0.6.6.7.2.json`
- `APEX_TESTES_v0.6.6.7.2.1.json`
- `APEX_RELATORIO_TECNICO_v0.6.6.7.2.2.md`
- `APEX_TESTES_v0.6.6.7.2.2.json`
- As sete referências recentes do OverTake.gg

A fonte mestre anterior permanece disponível como histórico e contexto. O documento novo prevalece nas prioridades de planejamento, mas nunca substitui a verificação do código real.

---

## DECLARAÇÃO FINAL DE ENGENHARIA

O APEX Motorsport Manager deverá evoluir como um simulador de sistemas interligados.

Uma decisão de engenharia deve poder afetar a pista. Uma decisão de estratégia deve ter consequências reais. Um piloto deve agir segundo sua percepção e personalidade. Um funcionário deve contribuir por meio de competência e limitações. Uma escuderia deve carregar as consequências das próprias escolhas entre corridas e temporadas.

Essa profundidade será criada por código estruturado, modelos consistentes, eventos verificáveis, persistência e testes.

**Cada versão deve tornar o APEX mais profundo, mais confiável ou mais eficiente — preferencialmente sem aumentar desnecessariamente sua complexidade de manutenção.**

**FIM — FONTE MESTRA UNIFICADA 2.0 — 16/11/2026**
