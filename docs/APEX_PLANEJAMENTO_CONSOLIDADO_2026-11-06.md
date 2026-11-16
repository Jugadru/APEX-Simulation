# APEX MOTORSPORT MANAGER — PLANEJAMENTO CONSOLIDADO

**Data de planejamento:** 06/11/2026  
**Status:** roteiro de produto e implementação; **não** representa funcionalidades já programadas.  
**Base técnica de referência:** Godot `Apex_0612_Hotfix_Parse_Godot.zip` (v0.6.1.2 experimental).  
**Fontes internas:** conversas de concepção, `Ideia de simulador F1.md`, especificação `HUD-RACE-060` e plano reconstruído de 06/11/2026.

> **Diretriz do projeto:** construir um simulador de F1 em que poucas decisões possam criar consequências profundas, com corridas tecnicamente coerentes e carreiras que contem histórias próprias. O foco imediato é retomar a **HUD de corrida**, antes de avançar para as ideias de carreira.

---

## 1. Identidade e pilares

1. **Corrida e estratégia reais:** pista 2D/3D, timing, clima, desgaste, pits, estratégia, DRS/KERS conforme o regulamento da época, IA e STAFF ligados ao mesmo estado de corrida.
2. **Apex Soul Driver:** pilotos têm percepção, confiança, temperamento, iniciativa e memória; são capazes de recomendar, contestar e comentar decisões, sem controlar a física arbitrariamente.
3. **Apex Soul Staff:** funcionários são pessoas simuladas, não meros multiplicadores numéricos. Possuem competência, filosofia, interesses, ética, transparência, lealdade, reputação, relacionamentos e trajetória.
4. **Gestão com agência:** escolhas geram consequências na pista, nas pessoas, nas finanças e na história da equipe.
5. **Duas experiências:** Standard (chefe de equipe) e Simulation (proprietário/dirigente) usam o **mesmo motor**, alterando a autoridade decisória e o foco da interface.
6. **Carreiras memoráveis:** Sandbox livre, Cenários definidos, notícias e Arquivo Histórico da Carreira.

## 2. Estrutura dos modos — decisões estabelecidas

### 2.1. Dois eixos independentes

**Tipo de experiência**
- **Sandbox:** carreira livre; jogador decide se assume, compra ou funda uma equipe, escolhe a época permitida e define até **10 objetivos pessoais** simultâneos; falhar não encerra automaticamente a carreira. Após falhar, o jogador escolhe continuar, redeterminar suas metas ou encerrar; consequências reais como falência continuam possíveis.
- **Cenários:** desafios pré-definidos pelo jogo; cada um especifica período, condições, objetivos, limite temporal e modo Standard/Simulation aplicável. Cenários de corrida iniciam em situação histórica fiel; a simulação evolui livremente depois desse ponto. Cenários de temporadas ou equipes usam o contexto inicial histórico, mas **não** forçam resultados históricos futuros.

**Papel do jogador**
- **Standard:** jogador ocupa o cargo de chefe de equipe. Contrata e gerencia diretamente STAFF, acompanha telemetria e estratégia, recebe recomendações e autoriza atos conforme controle manual/automático configurado.
- **Simulation:** jogador é dono/presidente/dirigente. Contrata/demite chefe de equipe, define metas, prioridades e orçamento, supervisiona resultados, decide conflitos e pode influenciar diretrizes antes/durante provas. As decisões operacionais cabem ao chefe e STAFF. É a evolução da ideia original de um *Brasfoot de F1* / Cockpit Manager.

**Exemplos aprovados na conversa**
- Sandbox: tentar vencer com Andrea Moda nos anos 1990; fundar uma equipe fictícia BYD F1 em 2027; transformar uma escuderia comprada.
- Cenários: salvar a Toyota; fazer Romain Grosjean vencer com a Lotus no horizonte de 2012–2013 (período exato definido na ficha do cenário); reescrever uma corrida como Abu Dhabi 2021; campanhas alternativas da Williams 2003 ou Ferrari 2022; desafios históricos com personagens/equipes contextualizados.

### 2.2. Intensidade Apex Soul (não é dificuldade de pilotagem)

- **Low-Cortisol:** sem grandes crises extraordinárias; relacionamentos e gestão ainda importam; investigações podem ocorrer sem punição relacional pela supervisão.
- **Medium:** crises e disputas *podem* ocorrer, com opções secundárias selecionadas pelo jogador antes da carreira; ex.: permitir o recrutamento em bloco de técnicos por uma rival e reação dos funcionários a auditorias.
- **Simulação Total:** todas as possibilidades Soul habilitadas, sem frequência compulsória de escândalos. Uma campanha pode atravessar décadas sem crise; outra, com o mesmo cenário e configuração, pode enfrentar dificuldades intensas.
- **Regra fixa:** dificuldade e opções secundárias bloqueadas durante a campanha. Para trocar, é necessário iniciar carreira nova.
- **Separação:** a IA esportiva continua competente em Low-Cortisol; escolher Simulação Total não piora artificialmente o desempenho dos carros.

## 3. Áreas de produto

### 3.1. Corridas / Motor compartilhado

- Temporadas/eras usam regulamentos e componentes coerentes com seu período.
- A câmera 3D, mapa estratégico 2D e minimapa consomem o mesmo progresso dos carros.
- A IA de box compara estratégias, desgaste, clima, tráfego e perdas esperadas, não apenas limiar fixo de desgaste.
- Ordens manuais têm precedência conforme permissões; ordem agendada para V21 não pode virar pit em V4 sem novo comando explícito.
- Melhorar problemas conhecidos: paradas excessivas em pista seca, interpretações de chuva, gaps e consistência temporal. **Não marcar corrigido sem testar.**

### 3.2. Apex Soul Driver

- Percepção de desgaste distinta do desgaste físico, feedback, moral, paciência, agressividade, iniciativa no rádio e confiança no engenheiro.
- Comentários gerados dos fatos simulados, sem mensagens repetitivas.
- Relações com companheiros, engenheiros e chefia influenciam comunicação e preferências, sem resultados predeterminados.

### 3.3. Apex Soul Staff

- Funcionários com carreira própria, competência por função, personalidade, filosofia de gestão, memória, lealdade, transparência, reputação e relacionamentos.
- Chefes de equipe podem responder diferentemente ao mesmo problema: recrutamento agressivo, desenvolvimento interno, organização, gestão de riscos ou relações institucionais.
- O proprietário não vê o estado interno perfeito da equipe; recebe relatórios potencialmente incompletos, otimistas ou, em casos específicos, deliberadamente enganosos.
- Ferramentas: funcionário de confiança, visita ao departamento, entrevistas, relatórios independentes e auditorias. O efeito das auditorias sobre a confiança depende das regras da dificuldade.
- Disputas de talentos, conflito de interesses, crises de patrocínio, denúncias, investigações e punições nascem de condições do mundo, **não** de eventos obrigatórios. Denúncia não equivale a culpa comprovada.
- Memória: demitidos, ex-colegas e relações passadas continuam relevantes anos depois; funcionários podem aceitar novos empregos e tentar levar colegas por negociações independentes.
- Em conteúdo histórico com pessoas reais, distinguir dados públicos verificados de temperamentos ou alegações fictícias. Para cenários dramáticos, privilegiar funcionários fictícios e fatos simulados claramente identificados.

### 3.4. Mercado vivo de pilotos e funcionários

Referências de design: Football Manager 2024/26, F1 Manager 2024 e conceito Apex Soul.

Quatro etapas: **descobrir → avaliar → negociar → integrar**.

- Equipes rivais recrutam, renovam e demitem sem esperar pelo jogador.
- Agentes/intermediários, recrutadores, observação de pilotos/engenheiros e informações de qualidade variável.
- Candidatos têm objetivos próprios e podem recusar propostas.
- Contratos contemplam salário, duração, bônus, cláusulas, autonomia, promessas, orçamento de departamento e eventual permissão para trazer colegas.
- Contratações afetam a estrutura existente e geram efeitos em cadeia; integração leva tempo.
- No Simulation, o proprietário contrata principalmente a liderança e aprova/delega demais negociações; no Standard pode participar diretamente das funções operacionais.
- Histórico profissional acompanha indivíduos inclusive após saírem da equipe.

### 3.5. Simulation: menu de proprietário

Inspirado visualmente no F1 Manager 2024, adaptado para dirigente:

1. **Início:** visão do campeonato, situação da equipe, próxima etapa, decisões pendentes e alertas.
2. **Paddock:** notícias, rumores (com confiabilidade), rádios, reputação, conflitos e investigações.
3. **Equipe:** chefe de equipe, pilotos, diretores, departamentos, confiança e relações.
4. **Mercado:** talentos, pesquisas, negociações e oportunidades das rivais.
5. **Engenharia:** prioridades, orçamento, projetos e relatórios (podem ter incertezas).
6. **Finanças:** caixa, salários, dívidas, patrocinadores, compromissos e sustentabilidade.
7. **Calendário:** corridas, reuniões, projetos, prazos, avanços rápidos.
8. **Histórico/Objetivos:** até dez metas pessoais, conquistas, fracassos e linha do tempo da carreira.

O Simulation deve permitir assistir à corrida ou simulá-la rapidamente; decisões ocasionais podem ser dadas à direção (ex.: proteger pontos, assumir riscos, priorizar um piloto) sem microgerenciar cada box.

### 3.6. Cenários e arquivo histórico

- Cenários individuais possuem estado inicial, modo exigido, tempo disponível, condições de vitória/fracasso e o contexto histórico correspondente.
- Desafios de corrida podem carregar uma situação fiel até o instante inicial; dali em diante o motor é livre. Desafios de temporada não roteirizam futuros resultados.
- Arquivo da carreira guarda contratações, títulos, rivalidades, decisões, crises, notícias importantes, temporadas e objetivos; compara história alternativa com o registro histórico sem misturar os dois.
- Criar/carregar equipes fictícias deve ser claramente distinto de alegar participação real de uma empresa em determinada temporada.

---

## 4. PRIORIDADE IMEDIATA: HUD DE CORRIDA — próximo trabalho

### 4.1. Estado técnico antes da reformulação

- Base conhecida: **v0.6.1.2 hotfix de parse** (ZIP já fornecido), com `scripts/main.gd`, `track_map.gd`, `apex_mini_map.gd`, `apex_stint_timeline.gd`, `apex_telemetry.gd`, `apex_hud_theme.gd`, `race_engine.gd` e cenas Godot.
- O hotfix anterior corrigiu indentação do script do mapa em inspeção estática. **O funcionamento em Godot não está confirmado neste ambiente**; validar na máquina do jogador.
- A especificação HUD-RACE-060 permanece referência para câmera aérea, mapa 2D com bolinhas, minimapa, rádio e separação da pista/controles, mas esta seção **substitui suas propostas antigas de layout e navegação quando houver conflito**.
- Os mockups gerados até aqui são imagens conceituais; **não constituem HUD implementada**.

### 4.2. Princípios definitivos para a nova HUD

1. **Pista é protagonista**; câmera aérea alta com zoom e pan deve oferecer enquadramento útil. Não resolver erro de enquadramento só escondendo widgets; avaliar HUD e câmera separadamente.
2. **Sem barra grande no topo**, sem exibir permanentemente nome do jogo, temporada/circuito redundantes e previsão meteorológica duplicada.
3. **Canto superior direito:** cinco acessos compactos, propostos como Corrida, Estratégia, Central de Dados, Eventos e Histórico de Rádio (o rádio deve ser discreto). Definir ícones/rótulos na implementação.
4. **Classificação estreita à esquerda**, sem título "CLASSIFICAÇÃO", sem espaço artificial entre sigla, dado e tempo. Apenas posição, abreviação de três letras, destaque de equipe e **uma coluna dinâmica**. Setas alternam: intervalo à frente, diferença para o líder, número de pits, melhor volta da sessão do piloto e pneus (composto + número de voltas de uso, como `M 18`, sem chaves). Não mostrar todas as colunas simultaneamente.
5. **Dois cartões compactos de pilotos na parte inferior**, com o mínimo operacional, e quatro botões contextuais na lateral de cada cartão. **Os botões abrem/alternam um único painel de detalhes que cresce para cima**. Não duplicar abas no painel e botões no cartão; não expandir para baixo ou sair da tela.
6. **Quatro contextos por piloto:** Telemetria (voltas/setores), Desempenho (ritmo real/esperado, tráfego e comportamento), Estratégia (plano, janela de pit e ordens rápidas) e Carro (condição técnica e pneus atuais). Em cada contexto priorizar 3–4 dados realmente úteis; detalhes sob demanda. Composto futuro na estratégia não é o mesmo dado que integridade/idade do pneu atual no estado do carro.
7. **Chamar box em dois lugares é duplicação intencional e aprovada:** ação rápida no cartão do piloto e planejamento detalhado na área geral de Estratégia. Não replicar todas as outras opções em ambos.
8. **Controle de tempo inferior compacto**, com pausa e setinhas para alternar velocidades (incluindo até 32× quando suportado), sem vários botões de velocidade individuais.
9. **Resumo de clima/pista discreto**, com detalhes apenas na Central de Dados; evitar prever chuva duas vezes em áreas diferentes da tela.
10. **Minimapa 2D simples e funcional:** traçado correto, pontos coloridos por carro e posições provenientes do motor; sem miniaturas 3D, grades ou gráficos decorativos.
11. **Rádio próximo ao piloto**, respeitando visibilidade e sem criar um grande overlay permanente.
12. **Janelas não se sobrepõem de forma incoerente**: painel de piloto cresce para cima, pode ter altura variável para conteúdo complexo, mas mantém controles acessíveis; grande painel central contextual fecha/gerencia outros detalhes para não esconder o circuito inteiro.

### 4.3. Estratégia completa da corrida — desenho acordado

- Tela dedicada exibe **os dois pilotos juntos**, com timeline de stints planejados, realizados e futuros, marcadores de voltas e pit stops.
- Permite comparar opções de pneu, janela, tráfego após o pit, desgaste, projeções e incerteza da previsão.
- Pode manter propostas de Plano A/B/C **editáveis**, sugeridas pelo estrategista e não perfis rígidos sempre iguais.
- STAFF no Manual recomenda e aguarda aprovação; no Automático executa conforme permissões claras. Uma ordem pré-agendada não pode ser antecipada implicitamente.
- Sem apresentar como cálculo exato qualquer dado que o motor ainda não forneça. Informações estimadas são identificadas como tais.

### 4.4. Entrega imediata da HUD: sequência e aceitação

**Passo 0 — validar e congelar base**
- Confirmar pasta Godot, versão do editor, parser, entrada `main.tscn` e ambiente gráfico real. Fazer cópia de segurança v0.6.1.2.
- Identificar os nós e estruturas da HUD em `main.gd`; registrar quais dados vêm do motor e quais são placeholders.

**Passo 1 — estruturar a HUD sem alterar o motor**
- Reorganizar controle principal em componentes simples reutilizáveis, preservando o motor de corrida, chuva, pneus e IA.
- Implementar a classificação dinâmica com seletor de métrica.
- Implementar cartões compactos + painel único superior contextual para cada piloto, com quatro botões laterais e sem controles duplicados.
- Implementar cinco ícones compactos no canto superior direito; remover a antiga barra superior redundante.
- Refinar controles de pausa/velocidade com setas.

**Passo 2 — câmera e painéis informativos**
- Ajustar câmera aérea e espaço reservado aos painéis para que a corrida continue visível.
- Integrar minimapa e modo 2D simples com pontos coloridos e sincronizados.
- Refinar clima/pista, rádio/histórico e janela completa de estratégia, sem replicar dados desnecessariamente.

**Passo 3 — testes de regressão e entrega experimental**
- Validar parser Godot quando executável disponível, smoke tests da cena e interface, cliques/toggles, transição 2D↔3D e preservação do estado de corrida.
- Rodar casos de pits e chuva: V21 não acontece em V4; checar paradas excessivas, especialmente em Melbourne. Se não forem corrigidos nesta entrega, indicar explicitamente que continuam pendentes.
- Validar visualmente nas resoluções de referência 1600×900 e 1920×1080; simular expansão de dois pilotos, diferentes categorias e telas de estratégia.
- Entregar ZIP completo, changelog e lista separada de funcionalidades testadas/pendentes. **Não afirmar compilação nativa nem testes gráficos sem execução real.**

**Critérios de aprovação visual da próxima etapa:** sem faixa grande no topo; classificação condensada; setas funcionando; quatro botões por piloto; painel expandindo exclusivamente para cima; sem duplicação de abas; câmera mostrando a disputa; controles de velocidade compactos; mapa com bolinhas simples; acesso rápido e geral ao box; nenhum erro vermelho no Godot.

---

## 5. Roadmap depois da HUD (prioridade por dependências, sem prazo prometido)

| Ordem | Sistema | Primeiro resultado verificável |
|---|---|---|
| **Agora** | HUD de corrida | Corrida navegável com layout aprovado, sem regressões |
| **Depois** | Física/IA estratégica | Pit stops e pneus plausíveis em seco/chuva, ordens respeitadas |
| **Em seguida** | STAFF operacional | Estrategista/engenheiro com permissões e decisões auditáveis |
| **Seguinte** | Soul Driver e rádio | Pilotos com percepção, pedidos e comunicações coerentes |
| **Fundação de carreira** | Standard persistente | Calendário, orçamento, evolução e múltiplas temporadas |
| **Expansão** | Mercado vivo | Candidatos, equipes rivais, contratos, propostas e integração |
| **Expansão** | Simulation | Proprietário, chefe de equipe autônomo, painel executivo e simulação rápida |
| **Expansão** | Soul Staff avançado | Memória, relações, confiança, informação imperfeita e acontecimentos condicionais |
| **Longo prazo** | Sandbox e Cenários | Equipes criadas/compradas, até dez metas, contextos históricos e arquivo da carreira |
| **Longo prazo** | Eras e modding | Temporadas adicionais, regras específicas e dados extensíveis |

**Observação:** a base existente já contém componentes de temporada 2012 e algum nível de automação. As etapas acima indicam **aprofundamento e validação**, não ausência absoluta de código anterior. Números de versão das entregas futuras serão decididos após auditar a árvore real.

---

## 6. Diretrizes de engenharia e responsabilidade

- Uma única fonte de verdade para a simulação; interface observa e envia comandos, não inventa classificação, chuva ou tempos.
- Modelar separadamente estado real, estado percebido pelos personagens e estado informado ao jogador.
- Reproduzir resultados a partir de uma semente aleatória quando necessário para testes; partidas diferentes podem gerar histórias distintas mesmo com configurações iguais.
- Eventos seguem pré-condições e probabilidades, não gatilhos de drama obrigatório.
- Não pressupor que contratar um funcionário melhor sempre melhora os resultados; relações e adaptação importam.
- Notícias e radios ficcionais devem ser identificáveis como conteúdo do universo simulado. Não atribuir crimes ou características psicológicas inventadas a pessoas reais.
- Não usar vozes, gravações ou assets protegidos sem direitos; interfaces serão originais, inspiradas nos gêneros de gestão, não cópias pixel a pixel.
- Features com dependências complexas devem ter testes automatizados, cenários de regressão e relatório claro de execução.

## 7. Encaminhamento para a próxima conversa

**Próxima tarefa acertada com o usuário:** voltar à **HUD de corrida do Apex** e implementar uma reformulação real no projeto Godot, a partir da base v0.6.1.2 *após validação*.

O diálogo sobre os modos de carreira, mercado e Soul Staff está **registrado e fora do escopo da próxima entrega**, salvo os pontos necessários para não criar uma HUD incompatível com a futura delegação.

**Não gerar apenas outra imagem conceitual quando o pedido seguinte for implementar a HUD.** Inspecionar a versão Godot, alterar arquivos de verdade, testar dentro do possível e entregar o projeto completo.
