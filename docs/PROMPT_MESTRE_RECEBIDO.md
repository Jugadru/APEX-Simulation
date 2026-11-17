# APEX MOTORSPORT MANAGER — PROMPT MESTRE DE DESENVOLVIMENTO CONTÍNUO

## MISSÃO PRINCIPAL

Você será o engenheiro-chefe e arquiteto de software do APEX Motorsport Manager, desenvolvido em Godot 4.7.2.

Sua missão é transformar o APEX em um dos simuladores de gerenciamento de automobilismo mais completos e profundos possíveis, priorizando:

- Inteligência artificial realista dos pilotos e equipes.
- Corridas 3D vivas, com disputas e ultrapassagens visíveis.
- Simulação avançada de pneus, combustível, clima e estratégia.
- Pilotos com personalidade, comportamento próprio e comunicação por rádio.
- Gerenciamento completo de funcionários e departamentos.
- Fábrica dinâmica, desenvolvimento e manutenção de carros.
- Modo carreira de várias temporadas.
- Desempenho otimizado, estabilidade e compatibilidade de saves.

Não quero apenas adicionar funcionalidades superficialmente. Quero que cada sistema seja bem desenvolvido, integrado aos sistemas existentes e tenha consequências reais na simulação.

## ETAPA 1 — IDENTIFICAR A VERSÃO ATUAL

Antes de iniciar:

1. Extraia o ZIP mais recente do APEX disponibilizado.
2. Identifique a versão real pelo conteúdo do projeto e seus metadados.
3. Leia os planos de engenharia e relatórios técnicos anexados.
4. Verifique quais funcionalidades já foram implementadas.
5. Execute os testes existentes.
6. Faça uma cópia de segurança do projeto.

Se a v0.6.5.7 já estiver completa e aprovada, comece pela v0.6.5.8.

Se não estiver, finalize e valide primeiro a funcionalidade pendente.

Nunca sobrescreva uma versão mais recente com código antigo.

## ETAPA 2 — PESQUISA PERMANENTE NO GITHUB

Antes de implementar cada sistema, pesquise no GitHub soluções técnicas relacionadas a Godot 4, GDScript, simulação de corridas, algoritmos de inteligência artificial e otimização.

Estude também a documentação oficial do Godot.

Investigue especialmente:

- Máquinas de estados para IA de corrida.
- Planejamento de trajetórias e manobras.
- Simulação determinística.
- Sistemas de eventos e telemetria.
- Algoritmos de estratégias de automobilismo.
- Otimização de renderização 3D.
- LOD, MultiMesh, cache e object pooling.
- Simulação de temporadas e mercado de pilotos.
- Testes automatizados e análise de desempenho.

Priorize repositórios bem estruturados e com licenças compatíveis. Não copie código proprietário nem introduza dependências desnecessárias.

Documente quais técnicas foram aproveitadas e explique seus benefícios.

# CRONOGRAMA DAS PRÓXIMAS ATUALIZAÇÕES

## FASE 1 — DESEMPENHO E ARQUITETURA

### v0.6.5.8 — Race State Optimization

Objetivo: reduzir processamento desnecessário e melhorar a comunicação entre o motor de corrida, os carros 3D e o HUD.

Implementar:

- Estados da corrida organizados.
- Redução de cópias profundas de estruturas de dados.
- Atualizações visuais somente quando necessárias.
- Separação entre resultados da simulação e animações.
- Interpolação suave de posição.
- Medição de desempenho antes e depois das alterações.

Não modificar as regras esportivas nem os resultados da corrida.

### v0.6.5.9 — Track Geometry Optimization

Objetivo: otimizar o processamento das pistas.

Implementar:

- Cache das trajetórias das pistas.
- Amostragem eficiente de posições e direções.
- Redução de cálculos geométricos repetidos.
- Melhor gerenciamento dos carros distantes.
- Otimização das atualizações das câmeras.
- Testes em Silverstone e pistas aleatórias.

A aparência e o comportamento dos carros devem permanecer consistentes.

### v0.6.6.0 — Deterministic Simulation & Replay

Objetivo: permitir testes reproduzíveis, simulação acelerada e replays confiáveis.

Implementar:

- Seeds controladas para geração de eventos aleatórios.
- Registro estruturado de acontecimentos da corrida.
- Reprodução de estados e eventos.
- Comparação entre simulações em velocidades diferentes.
- Testes automatizados de corridas completas.

Evitar diferenças nos resultados provocadas apenas pela taxa de FPS.

## FASE 2 — INTELIGÊNCIA ARTIFICIAL E CORRIDAS VIVAS

### v0.6.6.1 — Advanced Racing AI

Desenvolver um sistema avançado de disputas e ultrapassagens.

Os pilotos deverão:

- Aproximar-se do carro da frente.
- Avaliar oportunidades reais de ultrapassagem.
- Procurar espaços por dentro ou por fora.
- Sair da linha ideal para atacar.
- Disputar posições lado a lado.
- Defender posições sem movimentos irreais.
- Desistir de manobras perigosas.
- Aproveitar DRS, vácuo e diferenças de pneus.
- Cometer erros proporcionais às próprias habilidades.

Integrar a decisão esportiva às animações 3D.

A inspiração visual é Backseat Champions e a transmissão de corridas reais.

Os carros não podem simplesmente trocar de posição instantaneamente sem uma representação visual coerente.

### v0.6.6.2 — Driver Personality & Radio 2.0

Cada piloto deverá apresentar características individuais:

- Agressividade.
- Consistência.
- Inteligência de corrida.
- Capacidade de preservar pneus.
- Habilidade na chuva.
- Confiança.
- Controle emocional.
- Capacidade de ultrapassar.
- Cooperação com o companheiro.
- Tolerância ao risco.

Essas características devem influenciar decisões reais.

Exemplos:

Um piloto pode pedir para continuar na pista porque sente que os pneus ainda estão bons.

Outro pode pedir para entrar nos boxes porque perdeu aderência.

Um piloto mais rápido pode solicitar autorização para ultrapassar o companheiro.

Um piloto pode discordar da estratégia da equipe.

Desenvolva rádios contextuais, com mensagens variadas e coerentes com a corrida. Inicialmente, priorize eventos e mensagens textuais bem construídos, deixando o sistema preparado para futuras vozes licenciadas ou originais.

Não copie gravações reais de rádio protegidas por direitos autorais.

### v0.6.6.3 — Pit Wall & Strategy Intelligence

Melhorar profundamente a estratégia das equipes.

Implementar:

- Previsão dinâmica de pit stops.
- Cálculo de undercut e overcut.
- Estratégias alternativas.
- Reação a mudanças de clima.
- Previsão de degradação de pneus.
- Avaliação de tráfego após o pit.
- Coordenação de dois pilotos.
- Comunicação entre engenheiro, estrategista e piloto.

Corrigir comportamentos irreais.

Exemplo obrigatório de teste:

Se um piloto estiver na volta 4, começar uma chuva muito intensa e o pit planejado for na volta 21, a IA deverá reavaliar imediatamente a estratégia, em vez de seguir cegamente a programação inicial.

A decisão deve considerar aderência, pneus atuais, previsão meteorológica, condições de segurança e tempo perdido no pit.

O jogador deverá escolher entre controle manual e automático antes da corrida, mantendo a possibilidade de intervenção quando apropriado.

## FASE 3 — REALISMO VISUAL E GESTÃO

### Próximas versões após v0.6.6.3

Planeje versões individuais para:

**3D Racing Presentation 3.0**

- Disputas lado a lado.
- Animações de aproximação e defesa.
- Rodas e suspensão mais convincentes.
- Melhor iluminação.
- Asfalto e condições de pista.
- Câmeras de transmissão.
- Efeitos visuais de chuva, spray e pneus.

**Staff Intelligence 2.0**

- Estrategistas com diferentes habilidades.
- Chefes de mecânica.
- Engenheiros de corrida.
- Especialistas em aerodinâmica.
- Diretores técnicos.
- Funcionários com experiência e evolução.
- Influência da qualidade dos funcionários nos resultados.

**Living Factory 3.0**

- Departamentos interligados.
- Filas de desenvolvimento e produção.
- Confiabilidade de peças.
- Recursos e orçamento.
- Melhorias aerodinâmicas.
- Evolução do carro ao longo da temporada.
- Decisões automáticas ou manuais.

Não crie versões gigantes que misturem todas essas funcionalidades. Divida os sistemas em atualizações pequenas e verificáveis.

## FASE 4 — CARREIRA COMPLETA

A partir da linha v0.6.7.x, desenvolver progressivamente:

- Criação e personalização de equipes.
- Carreira de múltiplas temporadas.
- Contratação e demissão de pilotos.
- Mercado de funcionários.
- Academia de jovens pilotos.
- Scouting.
- Desenvolvimento de carros.
- Mudanças de regulamento.
- Patrocinadores.
- Finanças.
- Contratos.
- Histórico dos campeonatos.
- Recordes.
- Rivalidades.
- Dinastias.
- Aposentadorias.
- Entrada de novos talentos.
- Simulação rápida de temporadas.

Estudar como referências conceituais F1 Manager, Motorsport Manager, F1 Dynasty, Cockpit Simulator e Backseat Champions.

Não reproduzir código, identidade visual ou recursos protegidos desses jogos.

# REGRAS DE PROGRAMAÇÃO

1. Cada atualização terá uma funcionalidade principal.
2. Preserve todas as funcionalidades anteriores.
3. Não reconstrua o jogo do zero.
4. Reutilize a arquitetura existente sempre que possível.
5. Não remova funcionalidades para obter mais FPS.
6. Evite duplicação de código.
7. Utilize tipagem em GDScript quando apropriado.
8. Evite processamento desnecessário a cada frame.
9. Não introduza threads sem garantir segurança e determinismo.
10. Preserve compatibilidade com saves antigos.
11. Teste em Godot 4.7.2.
12. Não invente resultados de testes.
13. Não declare melhorias de FPS sem medições comparáveis.
14. Não altere a física ou o balanceamento sem necessidade justificada.
15. Mantenha o código modular, legível e documentado.

# TESTES OBRIGATÓRIOS

Após cada atualização:

- Importar e validar o projeto no Godot.
- Executar os testes automatizados disponíveis.
- Testar uma corrida em Silverstone.
- Testar pistas aleatórias.
- Testar corrida com chuva.
- Verificar estratégias e pit stops.
- Verificar classificação e tempos de volta.
- Verificar os dois pilotos da equipe.
- Testar os módulos de gestão e fábrica.
- Testar compatibilidade de saves.
- Identificar erros e warnings relevantes.
- Comparar resultados com a versão anterior.

Criar testes novos sempre que a implementação introduzir novas regras.

Se um teste falhar, investigar e corrigir antes de aprovar a versão. Se não puder executá-lo, informar a limitação sem afirmar que passou.

# MÉTODO DE DESENVOLVIMENTO

Para cada versão, siga esta sequência:

1. Analisar o código existente.
2. Pesquisar técnicas e referências.
3. Definir arquivos e funções a modificar.
4. Criar testes para o comportamento esperado.
5. Implementar a funcionalidade principal.
6. Executar testes.
7. Corrigir problemas encontrados.
8. Verificar regressões.
9. Atualizar documentação.
10. Gerar um ZIP completo e validado.

Não avance para outra versão enquanto a atual não estiver aprovada.

# ENTREGAS

Entregar, para cada versão concluída:

**1. Projeto completo**

Um arquivo ZIP do jogo, com o número correto da versão, código-fonte, cenas, recursos e funcionalidades anteriores.

**2. Relatório técnico**

Arquivos criados, arquivos modificados, problemas corrigidos e resultados dos testes.

**3. Desempenho**

Comparação de benchmarks antes e depois, quando a alteração envolver otimização.

**4. Próxima atualização**

Plano técnico detalhado da versão seguinte, incluindo classes, funções, algoritmos, dependências e riscos.

**5. Diário de engenharia**

Manter um registro de decisões técnicas e descobertas para que as versões futuras aproveitem o conhecimento acumulado.

# ORDEM DE EXECUÇÃO

Comece pela primeira versão pendente depois da versão-base recebida.

Implemente e entregue uma versão completa por vez.

Se o ambiente e o tempo de execução permitirem continuar, avance sequencialmente, sempre realizando testes e preservando um ZIP independente de cada versão.

Se não for possível concluir todas as versões, priorize terminar uma versão realmente funcional e entregar um relatório preciso do que falta.

Nunca pule etapas apenas para aumentar o número de versão.

# OBJETIVO FINAL

Quero que o APEX Motorsport Manager se torne um jogo no qual:

- Os pilotos pareçam indivíduos, e não apenas números.
- Os carros disputem posições de maneira convincente.
- As equipes adversárias tomem decisões inteligentes.
- Os funcionários tenham importância real.
- O jogador possa administrar ou delegar decisões.
- Cada temporada conte uma história diferente.
- O jogo rode de maneira eficiente.
- Os sistemas sejam profundos, coerentes e estáveis.

**COMECE EXAMINANDO A ÚLTIMA VERSÃO ANEXADA. IDENTIFIQUE A PRÓXIMA ATUALIZAÇÃO PENDENTE, IMPLEMENTE-A, TESTE-A E ENTREGUE O ZIP COMPLETO.**