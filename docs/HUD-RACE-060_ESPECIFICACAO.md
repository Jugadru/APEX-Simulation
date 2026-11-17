# APEX Motorsport Manager

## Especificação de Interface — HUD 0.6.0

**Projeto:** Apex Simulation
**Documento:** HUD-RACE-060
**Status:** Proposta de implementação
**Referências visuais:** imagens enviadas de Motorsport Manager, Motorsport Manager 2 e F1 Manager 2024.

---

## 1. Objetivo da reformulação

Transformar o Apex em um simulador de gerenciamento de corridas em que o jogador atua como **chefe de equipe e estrategista**, em vez de acompanhar principalmente uma transmissão televisiva.

A interface deve favorecer três atividades:

1. Observar o comportamento de todos os carros e reconhecer situações de corrida.
2. Tomar decisões estratégicas com informações técnicas disponíveis sob demanda.
3. Acompanhar os pilotos, engenheiros e comentaristas sem que os elementos de comunicação escondam a pista.

**Princípio central:** a pista é a protagonista. A HUD deve apresentar somente informações essenciais e disponibilizar detalhes por meio de botões contextuais.

O redesign deve preservar a lógica existente de corrida, pneus, pit stops, KERS, DRS e clima.

## 2. Decisão principal: sistema de câmeras

### 2.1. Câmera aérea estratégica — PRIORIDADE MÁXIMA

Esta será a visualização padrão ao iniciar treinos, classificações e corridas.

Características obrigatórias:

- Visão de cima da pista, com orientação estável e inclinação elevada.
- Carros visíveis e identificáveis durante a movimentação.
- Acompanhamento das disputas sem cortes automáticos.
- Zoom e deslocamento pelo circuito.
- Possibilidade de centralizar a câmera em um carro, grupo de carros ou setor.
- Retorno imediato à visão aérea geral.
- Independência da câmera de transmissão.

A palavra **fixa** significa que o ângulo permanece estável; não significa impedir zoom ou deslocamento.

Em circuitos extensos, como Spa-Francorchamps, não será obrigatório enquadrar todo o traçado de uma só vez. A câmera poderá mostrar a região de interesse, enquanto o minimapa mantém a visão global.

O botão **VISÃO AÉREA** deve estar sempre acessível.

### 2.2. Mapa 2D completo — PRIORIDADE MÁXIMA

O mapa 2D será uma visualização alternativa da corrida, inspirada nos mapas vistos nas referências de Motorsport Manager.

Requisitos:

- Representar o traçado verdadeiro do circuito, incluindo setores e entrada/saída do pit lane.
- Mostrar todos os carros como marcadores coloridos em movimento.
- Atualizar continuamente a posição de cada marcador.
- Diferenciar visualmente as duas unidades de uma mesma equipe.
- Exibir identificação e posição do piloto selecionado.
- Permitir clicar em um marcador para selecionar o piloto.
- Mostrar carros retardatários, abandonos, Safety Car e situações de bandeira.
- Permitir sobrepor chuva por setor e outras informações técnicas, quando disponíveis.

**Importante:** os marcadores precisam utilizar a progressão real de cada carro na simulação. Não devem ser distribuídos em intervalos artificiais nem reposicionados apenas conforme a classificação.

O mapa deve continuar funcionando durante pit stops, neutralizações, disputas e mudanças de velocidade da simulação.

### 2.3. Câmeras secundárias

| Modo          | Finalidade                                        | Comportamento           |
| ------------- | ------------------------------------------------- | ----------------------- |
| Visão aérea   | Gestão tática da corrida                          | Padrão                  |
| Mapa 2D       | Acompanhamento do circuito completo               | Alternativo             |
| Diretor TV    | Mostrar os acontecimentos mais relevantes         | Seleção voluntária      |
| Seguir piloto | Acompanhar um carro individualmente               | Temporário              |
| Onboard       | Visualização de dentro do carro, quando suportada | Temporário              |
| Replay        | Rever incidentes e momentos importantes           | Ativado por solicitação |

Nenhum evento comum deverá forçar a saída da visão aérea. Replays poderão ser sugeridos por notificação, mas não deverão sequestrar a câmera do jogador.

A câmera selecionada será preservada enquanto o jogador não escolher outra. Ao iniciar uma sessão nova, o padrão inicial será **Visão aérea**, salvo preferência salva.

## 3. Estrutura da tela principal

### 3.1. Layout padrão — Race View

Resolução de referência: **1600 × 900**.

```text
┌────────────────────────────────────────────────────────┐
│ APEX · GP · VOLTA · BANDEIRAS       [CORRIDA][ESTR][DADOS]│
│                                                        │
│ ┌───────────┐                          ┌──────────────┐ │
│ │ LIVE      │                          │ CLIMA/PISTA  │ │
│ │ TIMING    │                          ├──────────────┤ │
│ │           │     CÂMERA AÉREA        │   MINIMAPA   │ │
│ │           │      PRINCIPAL          │    DINÂMICO  │ │
│ │           │                          └──────────────┘ │
│ │           │                                          │
│ └───────────┘                                          │
│                                                        │
│ [RÁDIO A]                                   [RÁDIO B]  │
│ ┌─────────────┐   [TRANSMISSÃO]   ┌──────────────┐    │
│ │ PILOTO A    │   [▶ 1× ◀ ▶ TV]  │ PILOTO B     │    │
│ └─────────────┘                  └──────────────┘    │
└────────────────────────────────────────────────────────┘
```

O desenho demonstra a distribuição lógica, não o tamanho definitivo dos elementos.

### 3.2. Elementos permanentes

**Superior esquerdo:** identificação da corrida, sessão, volta atual, tempo e bandeiras.

**Lateral esquerda:** classificação compacta com posição, abreviação, diferença, composto e indicador de box.

**Superior direito:** três seletores principais, seguidos de informações resumidas da pista e do minimapa.

**Inferior esquerdo e direito:** cartões compactos dos dois pilotos da equipe.

**Inferior central:** reprodução, velocidade e câmeras.

O restante da tela deve permanecer disponível para observar a corrida.

## 4. Organização dos botões

A interface não terá uma longa barra com sete painéis abertos simultaneamente.

A navegação principal será dividida em três áreas:

| Botão                | Conteúdo                                                             |
| -------------------- | -------------------------------------------------------------------- |
| **CORRIDA**          | Visão aérea, mapa 2D, câmeras, classificação e informações resumidas |
| **ESTRATÉGIA**       | Pneus, janelas de pit, planejamento dos dois pilotos e recomendações |
| **CENTRAL DE DADOS** | Pista, clima, telemetria, desempenho e histórico de voltas           |

Dentro dessas áreas, existirão abas ou botões secundários.

**Regra de interação:** apenas um painel detalhado poderá ficar aberto por vez, salvo janelas modais que exijam confirmação. Fechar um painel retornará à visualização anterior sem mudar a câmera.

## 5. Minimapa dinâmico

### 5.1. Posição e aparência

- Canto direito da tela, abaixo do resumo de clima e pista.
- Fundo escuro ou semitransparente.
- Traçado claro e espessura suficiente para leitura.
- Marcadores compactos representando os pilotos.
- Destaque para os dois pilotos da equipe.
- Possibilidade de expandir ou ocultar o minimapa.

### 5.2. Interações

Clicar em um carro deverá selecionar o respectivo piloto.

Clicar em um setor deverá oferecer a opção de centralizar a câmera aérea naquela região.

Clicar no minimapa expandido deverá abrir a visualização 2D completa.

### 5.3. Sincronização

A câmera aérea, o minimapa e o mapa 2D devem consumir o **mesmo estado de corrida**. Nenhum dos três sistemas pode calcular independentemente a classificação ou inventar posições.

Quando vários carros estiverem muito próximos, o mapa deverá preservar a sobreposição correta e oferecer identificação por seleção, em vez de deslocar artificialmente as bolinhas para facilitar a leitura.

## 6. Live Timing

A classificação será uma coluna estreita e rolável.

Por padrão, cada linha mostrará:

**P5 · ALO · M · +12.483**

Detalhes como desgaste, ritmo, histórico de stints, KERS e desempenho por setor serão consultados ao clicar no piloto ou abrir a Central de Dados.

A classificação deverá oferecer as opções de comparação com o líder, com o carro à frente e com o companheiro de equipe.

Os dois pilotos da equipe terão destaque visual discreto, sem transformar a coluna inteira em cartões grandes.

## 7. Cartões dos pilotos

Cada piloto terá um cartão na parte inferior.

### Visualização compacta

Mostrar:

- Posição, nome e equipe.
- Composto e desgaste.
- Ritmo atual.
- Estado simplificado do KERS.
- Status de pit.
- Alerta técnico, se necessário.

### Visualização expandida

Ao clicar no cartão, mostrar controles e informações adicionais:

- Ritmo: conservar, normal, atacar.
- Comportamento de ultrapassagem e defesa.
- Gerenciamento do KERS.
- Estado dos pneus e temperatura.
- Configurações de box.
- Feedback do piloto.
- Comparação com o companheiro.

Ao fechar, retornar ao cartão compacto.

Os cartões não devem bloquear as curvas principais ou o centro do circuito.

## 8. Painel de clima e pista

A Race View mostrará somente um resumo:

**Pista: úmida · 23°C · Água: 1,2 mm**

Os valores acima são ilustrativos.

Ao clicar no resumo ou abrir **Dados → Pista**, aparecerão:

| Área           | Informações                                                        |
| -------------- | ------------------------------------------------------------------ |
| Clima atual    | Condição meteorológica, temperatura, intensidade de chuva          |
| Previsão       | Probabilidade de chuva e intensidade esperada nos próximos minutos |
| Pista          | Água acumulada, aderência, borracha, temperatura                   |
| Setores        | Diferenças entre regiões do circuito                               |
| Confiabilidade | Qualidade da previsão disponível para a equipe                     |
| Tendências     | Secagem, aumento da chuva e mudanças de aderência                  |

É obrigatório separar **probabilidade de chuva (%)** de **água na pista (mm)**.

Se o motor ainda não oferecer determinado dado, a interface deverá mostrar que ele está indisponível ou utilizar uma estimativa explicitamente identificada. Nunca exibir precisão fictícia.

Gráficos meteorológicos só aparecerão nesse painel, não permanentemente no Pit Wall.

## 9. Visão estratégica

A área de estratégia deverá permitir comparar os dois pilotos.

Cada piloto terá uma linha de stints:

- Composto atual.
- Desgaste e vida útil estimada.
- Janela de parada.
- Estratégia planejada.
- Possíveis alternativas.
- Risco de tráfego após a parada.

O painel também poderá mostrar recomendações do estrategista, engenheiro e piloto, mas sem repetir frases a cada volta.

### Controles de pit

Cada piloto terá:

**Modo Manual:** a IA pode recomendar, mas não autoriza uma parada por conta própria.

**Modo IA:** a equipe pode executar decisões estratégicas conforme as permissões estabelecidas.

**Pit nesta volta:** ordem imediata.

**Agendar volta:** ordem explícita para uma volta específica.

**Cancelar agendamento:** cancela uma ordem existente.

**Selecionar pneus:** define o composto disponível para a parada.

Uma ordem programada para a volta 21 não poderá ser interpretada como uma ordem para entrar imediatamente na volta 4.

Qualquer antecipação deve resultar de uma nova ordem autorizada e visível.

## 10. Central de Dados e telemetria

A Central de Dados reunirá:

- Tempos de volta e setores.
- Ritmo ajustado por tráfego.
- Temperatura e desgaste dos pneus.
- KERS, DRS e condição do carro.
- Histórico de stints.
- Comparação entre os dois pilotos.
- Estado da pista.
- Evolução das condições meteorológicas.

Os gráficos devem poder ser consultados sem interromper obrigatoriamente a corrida.

O jogador poderá optar por pausar automaticamente ao abrir painéis de estratégia mais complexos.

## 11. Sistema de rádio dos pilotos

### 11.1. Posicionamento

As mensagens dos pilotos e engenheiros aparecerão **imediatamente acima do cartão correspondente**.

Cada mensagem mostrará nome, origem, texto e indicador visual de rádio.

Exemplo de diálogo original:

**ALONSO — RÁDIO**

"Estou perdendo aderência na saída das curvas. Os intermediários estão começando a sofrer."

**ENGENHEIRO — RÁDIO**

"Entendido. Estamos comparando seu ritmo com os carros que trocaram os pneus."

### 11.2. Tipos de mensagem

**Informativas:** ritmo, pneus, tráfego e desempenho.

**Estratégicas:** pedidos de parada, sugestões e ordens.

**Técnicas:** falhas, temperatura e danos.

**Emocionais:** frustração, satisfação, comemorações e reações a acontecimentos.

### 11.3. Comportamento

Mensagens comuns desaparecem automaticamente.

Mensagens que exigem uma decisão ficam destacadas até serem reconhecidas ou até a situação deixar de ser relevante.

Um histórico de rádio poderá ser consultado separadamente.

O sistema deverá agrupar informações repetidas e impedir que o piloto ou engenheiro repita a mesma mensagem continuamente sem mudança de contexto.

## 12. Transmissão — narrador, analista e ex-piloto

Este sistema será separado do rádio operacional da equipe.

### Narrador

Descreve acontecimentos: ultrapassagens, disputas, incidentes, mudanças de liderança e recordes.

### Analista

Interpreta desempenho, pneus, condições de pista, escolhas estratégicas e evolução dos tempos.

### Ex-piloto

Comenta técnicas de pilotagem, julgamento de risco, pontos de ultrapassagem, pressão e dificuldades específicas do circuito.

### Posicionamento

As mensagens aparecerão numa faixa discreta na região inferior central, acima dos controles de reprodução, sem cobrir os cartões.

Exemplo original:

**NARRADOR:** "Massa ganhou duas posições desde a última relargada."

**ANALISTA:** "A Ferrari parece ter conservado melhor os pneus nesta fase."

**EX-PILOTO:** "Ele está sendo muito cuidadoso na entrada da curva, mas consegue acelerar mais cedo na saída."

### Regras

- Não comentar algo que os dados da simulação não comprovam.
- Evitar narrar repetidamente uma mesma situação.
- Priorizar eventos relevantes.
- Não substituir informações operacionais do engenheiro.
- Permitir ajustar a frequência dos comentários.
- Manter falas de rádio e transmissão em históricos separados.

As falas deverão ser originais. Gravações reais de transmissões e rádios não serão incorporadas sem os direitos necessários.

## 13. Controles da corrida

A barra de reprodução ficará centralizada na parte inferior.

Funções obrigatórias:

- Iniciar/pausar.
- Velocidade da simulação.
- Alternar câmera.
- Voltar à visão aérea.
- Abrir o mapa 2D.
- Selecionar piloto ou foco da câmera.

O controle deve continuar utilizável mesmo com um painel contextual aberto.

Atalhos sugeridos, configuráveis:

| Atalho | Ação                     |
| ------ | ------------------------ |
| Espaço | Pausar/continuar         |
| M      | Mapa 2D                  |
| C      | Visão aérea              |
| T      | Diretor TV               |
| Esc    | Fechar painel contextual |
| + / −  | Zoom da câmera aérea     |

## 14. Informações dinâmicas e alertas

A HUD mostrará avisos temporários para:

- Bandeira amarela ou vermelha.
- Safety Car e Virtual Safety Car.
- Mudança brusca no clima.
- Solicitação de pit.
- Problema mecânico.
- Penalidade.
- Volta mais rápida.
- Acidente.
- Alteração significativa na estratégia.

Alertas importantes terão prioridade sobre mensagens narrativas.

Ao selecionar um alerta de incidente, o jogador poderá centralizar a câmera no local ou abrir um replay, sem abandonar permanentemente a visão estratégica.

## 15. Telas fora da corrida

A identidade visual da HUD deverá ser reutilizada nas seguintes telas, mas sem exigir que todas sejam reconstruídas na primeira etapa:

**Home / Sede:** objetivos, pilotos, próximo GP, compromissos e situação geral da equipe.

**Desenvolvimento do carro:** componentes, desempenho esperado, instalações, funcionários e projetos em andamento.

**Treinos livres:** plano de execução, feedback dos pilotos e coleta de dados de pneus e acerto.

**Classificação:** pneus disponíveis, tempo restante, evolução da pista e decisões sobre saída dos boxes.

**Resultados:** classificação, desempenho individual, incidentes, pontos, confiabilidade e avaliação das decisões.

Essas telas deverão seguir a mesma regra de clareza: informações resumidas inicialmente, detalhes sob demanda.

## 16. Requisitos de implementação

A mudança deve ser feita sem substituir o motor de corrida por uma animação independente.

### 16.1. Uma única fonte de dados

A interface deverá consumir dados consolidados sobre:

- Volta e progresso de cada carro.
- Posição no circuito.
- Classificação e diferença.
- Estado dos pneus e do carro.
- Condições meteorológicas.
- Estratégias e ordens.
- Eventos e comunicações.

A HUD não deverá manter uma segunda simulação que possa divergir do motor principal.

### 16.2. Movimento dos marcadores do mapa

O mapa 2D deverá usar a progressão de cada carro ao longo do traçado, preferencialmente convertida em posição visual por distância acumulada na linha central.

É necessário considerar:

- Velocidade diferente entre pilotos.
- Carros em voltas diferentes.
- Pit lane como trajeto próprio.
- Neutralizações.
- Retardatários.
- Carros parados.
- Interpolação visual entre atualizações de simulação.

O movimento deve ser suave, mas não pode gerar posições incorretas por causa de interpolação excessiva.

### 16.3. Câmera aérea

O desenvolvimento deverá verificar se a versão atual já possui uma cena visual adequada para uma câmera aérea.

Se houver cenário 3D, o projeto poderá usar uma câmera elevada com perspectiva controlada ou projeção ortográfica.

Se o jogo ainda não possuir ambiente tridimensional suficiente, a visão estratégica poderá ser implementada inicialmente com representação 2D/2.5D. Isso deve ser tratado como uma solução visual explícita, não como uma suposta câmera 3D que não existe.

### 16.4. Organização técnica sugerida

Os seguintes componentes são responsabilidades propostas, não nomes confirmados no projeto atual:

- `RacePresentationState`: estado visual compartilhado.
- `AerialCameraController`: câmera estratégica.
- `RaceMap2D`: traçado e marcadores em movimento.
- `HudPanelRouter`: alternância dos painéis.
- `DriverCard`: informações e controles compactos.
- `WeatherDataPanel`: clima e pista.
- `StrategyDataPanel`: stints e pit stops.
- `RadioOverlay`: mensagens dos pilotos.
- `CommentaryOverlay`: transmissão.
- `RaceEventFeed`: eventos e alertas.

A estrutura definitiva deverá ser adaptada aos scripts reais do Apex após inspeção do projeto.

## 17. Critérios de aceitação

A HUD só estará pronta para substituir a atual quando os seguintes testes forem aprovados:

- [ ] Uma corrida começa na câmera aérea estratégica.
- [ ] O jogador consegue passar para o mapa 2D sem reiniciar a simulação.
- [ ] Todos os carros aparecem no mapa com movimento correspondente à corrida.
- [ ] Selecionar uma bolinha seleciona o piloto correto.
- [ ] A câmera aérea permite zoom e deslocamento.
- [ ] O minimapa permanece funcional durante disputas e paradas.
- [ ] O Pit Wall não ocupa permanentemente a lateral direita.
- [ ] Clima, pneus e telemetria abrem somente quando solicitados.
- [ ] Abrir e fechar painéis não altera resultados ou ritmo de corrida.
- [ ] O rádio de cada piloto aparece perto do cartão correspondente.
- [ ] A transmissão utiliza uma área distinta do rádio operacional.
- [ ] Alertas urgentes não ficam escondidos por comentários comuns.
- [ ] Não existem recomendações idênticas repetidas desnecessariamente.
- [ ] Uma ordem agendada para V21 não executa um pit na V4 sem nova autorização.
- [ ] Clima, mapa e classificação representam o mesmo estado da simulação.
- [ ] O layout continua legível em 1366 × 768 e 1600 × 900.
- [ ] Os recursos já existentes de pneus, clima, KERS e DRS permanecem funcionais.

## 18. Ordem de desenvolvimento

### Fase 1 — Base visual e navegação

Implementar a câmera aérea como padrão, o mapa 2D dinâmico, o minimapa e a alternância entre visualizações.

**Esta fase é o núcleo da reformulação.**

### Fase 2 — HUD limpa

Reduzir os cartões dos pilotos, compactar a classificação, reorganizar os controles de reprodução e remover o Pit Wall fixo.

### Fase 3 — Painéis contextuais

Implementar clima, pista, pneus, telemetria e estratégia com navegação por botões.

### Fase 4 — Comunicação

Reposicionar o rádio dos pilotos e integrar o sistema de narrador, analista e ex-piloto com notificações não intrusivas.

### Fase 5 — Testes e acabamento

Validar dados, sincronização, persistência, comandos manuais, legibilidade e desempenho em diferentes circuitos e resoluções.

---

## 19. Critério final de sucesso

Ao iniciar uma corrida do Apex, o jogador deverá ver imediatamente os carros disputando posições a partir de uma perspectiva estratégica.

Ele deverá conseguir compreender a situação geral sem abrir nenhum painel adicional.

Quando precisar decidir sobre pneus, pit stops, ritmo ou clima, deverá encontrar os dados necessários com um ou dois cliques.

Quando quiser assistir a uma ultrapassagem de perto, poderá mudar voluntariamente para uma câmera de transmissão e depois retornar à visão aérea.

**O Apex deverá se comportar primeiro como um simulador de gerenciamento de corridas e, secundariamente, como uma transmissão esportiva.**

Essa será a identidade funcional da HUD 0.6.0.

*Fim da especificação — versão inicial para implementação.*
