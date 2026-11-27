
# AGENTS.md — APEX Motorsport Manager

## 1. IDENTIDADE DO PROJETO

O APEX Motorsport Manager é um simulador profundo
de gerenciamento de equipes automobilísticas.

Motor: Godot 4.7.2
Linguagem: GDScript
Plataforma: PC / Linux Mint
Temporada inicial: Fórmula 1 de 2012

O jogador administra uma equipe, contrata pilotos
e funcionários, desenvolve componentes e toma
decisões estratégicas. Não é um jogo de pilotagem.

## 2. REGRAS OBRIGATÓRIAS

1. Examinar o código existente antes de programar.
2. Nunca substituir sistemas funcionais sem necessidade.
3. Implementar uma funcionalidade principal por versão.
4. Preservar a arquitetura modular.
5. Evitar duplicação de códigos e sistemas.
6. Não criar funcionalidades apenas decorativas.
7. Manter compatibilidade com saves e replays.
8. Preservar o determinismo da simulação.
9. Não alterar a física ao melhorar o visual.
10. Não copiar código ou assets sem licença adequada.

## 3. SISTEMAS A PRESERVAR

- Motor de corrida e Core 2.
- Driver Dynamics e Soul Driver.
- Soul Staff.
- Pit Wall e Strategy Simulator.
- Living Factory.
- Sim Racecraft.
- Replay determinístico.
- Telemetria e Performance Profiler.
- HUD unificada.
- Mapa estratégico 2D.
- Corridas 3D e Diretor TV.

Verificar a implementação real antes de modificar
qualquer um desses sistemas.

## 4. SIMULAÇÃO REALISTA

O resultado esportivo deve ser calculado pelo motor.

A apresentação 2D e 3D apenas representa os
acontecimentos da simulação.

A mesma seed, estado inicial e sequência de comandos
devem produzir resultados iguais.

Respeitar as regras históricas de 2012:
motores V8, KERS, DRS e pneus correspondentes.

## 5. POLÍTICA OFICIAL DE HOMOLOGAÇÃO — FAST + APEX TEST LAB

**Decisão permanente do APEX (23/11/2026): FAST + APEX Test Lab +
regressões direcionadas são o padrão obrigatório de validação para cada
versão comum. A homologação FULL não é pré-requisito de merge.**

Para colaborar, programar, revisar ou integrar uma versão:

1. Verificar a `main` atual e o escopo; uma funcionalidade principal por versão.
2. Importar o projeto no **Godot 4.7.2**; falhas reais de parse ou recurso
   impedem aprovação. Só crashes nativos transitórios permitem retentativa
   controlada, sem ocultar falhas reais.
3. Exigir **FAST** do workflow consolidado
   `.github/workflows/godot-setup.yml`, com **APEX Test Lab** e testes
   direcionados selecionados por `tools/apex_ci_tiers.py` e
   `.github/apex-quality-suites.json`.
4. Usar o Lab para 24 carros, clima seco/chuva, determinismo/hashes,
   CPU e memória; testar regressões do subsistema alterado em pit stops,
   estratégia, IA, saves e replay quando aplicável.
5. Aprovar merge somente com o FAST obrigatório **PASS no SHA exato**,
   sem falhas ou cobertura essencial ausente. Não considerar `skipped`,
   `NOT_RUN`, `INCONCLUSIVE` ou `BLOCKED` como aprovados.
6. **Não** adicionar automaticamente etiqueta `ci:full`, nem exigir
   matriz 20/180, endurance longo, benchmark completo, exportação ou
   Quality Gate histórico como condições universais de merge.
   Homologações ampliadas são **manuais e opcionais**, acionadas
   **apenas com pedido explícito do responsável pelo projeto**.
7. Se a alteração envolver física, segurança de saves, revisão de replay,
   clima ou bug de pista real, adicionar testes direcionados adequados
   ao risco; não impor FULL por reflexo. Na ausência de prova suficiente,
   não integrar a PR.
8. Manter separado o processo de **merge de código** e a
   **publicação de binários**; builds de teste e releases requerem
   verificação dos respectivos executáveis e arquivos `.pck`.

Exemplos de regressões reais: Silverstone, Monza, Spa e Singapura quando
a falha depende de suas características. A checagem rápida de cadastro
das 20 pistas NÃO significa simular uma matriz de 20 GPs.

Uma ordem manual BOX V21 não pode virar uma parada na volta 4 por
decisão automática. Preservar determinismo e compatibilidade com
saves/replays mesmo em alterações visuais e de performance.

Classificar os testes como PASS, FAIL, NOT_RUN, INCONCLUSIVE ou BLOCKED.
Nunca declarar teste aprovado sem executá-lo nem prometer ganho de
FPS/GPU com base só em benchmark sintético/headless.

Esta regra substitui instruções antigas de FULL obrigatório presentes
em relatórios históricos. Referência detalhada:
`docs/APEX_CI_INTELIGENTE_TRES_NIVEIS.md`.

### 5.1. Integração operacional do agente com o Development Lab (26/11/2026)

Base de desenvolvimento consolidada: REV1, PR #142, merge
`abc8f8618c856c951decf15eadae09cdc036e13a`. As decisões anteriores e
os resultados inconclusivos históricos permanecem preservados. A REV2
(#143) não foi integrada.

- Para cada versão comum, trabalhar no repositório APEX-Simulation,
  abrir PR, consultar os workflows do SHA exato, ler os logs em caso
  de falha, corrigir e validar novamente. O FAST e os testes direcionados
  do APEX Test Lab já são disparados pelo GitHub; não pedir ao jogador
  que abra o Lab ou baixe relatórios quando os logs já forem suficientes.
- O Development Lab complementar fica no repositório
  `Jugadru/apex-godot-simulation-architect`. Usar seu analisador estático
  somente como diagnóstico, e seus testes de contrato e ferramentas de
  investigação quando o risco da alteração justificar.
- O ABC v1 é um estudo histórico de três SHAs fixos; não executá-lo
  automaticamente para versões novas nem tratar o PASS de execução
  como homologação de um candidato diferente.
- Para nova comparação de desempenho, definir previamente baseline e
  candidato exatos, workload e critérios, preservar todas as medições.
  Benchmark em runner pessoal requer confirmação de ociosidade e
  autorização do responsável; nunca simular essa confirmação, repetir
  para obter verde ou executar código de PR não revisada no runner.
- O conector GitHub permite ler PRs, logs e artefatos por run ID e editar
  branches/PRs; não oferece dispatch geral de workflow. Se uma execução
  manual for indispensável, fornecer o link e pedir somente a ação
  necessária. Não solicitar token pessoal em chat nem instalar serviços
  permanentes para contornar essa limitação.
- Separar validação headless, inspeção gráfica e release. A aceleração
  efetiva de aproximadamente 14x no ensaio GTX 1650 da REV1 é limitação
  conhecida, não uma meta de 32x cumprida.
- Manter a arquitetura do Lab estável. Não refatorar o Lab nem exigir
  FULL/benchmarks pesados para versões rotineiras sem motivo técnico.
  Não modificar critérios depois de ver os resultados para aprovar uma PR.

### 5.2. Uso do Engineering Lab após sua expansão

Consultar `docs/APEX_AUTONOMOUS_ENGINEERING_LAB.md` e
`docs/APEX_LAB_KNOWLEDGE_INDEX.md` para comandos, escopo, evidências,
decisões e limitações de cada ferramenta. O Hub #141 aceita comandos
restritos ao proprietário e SHA exato; o analisador avançado permanece
no Hub privado do Development Lab. Consultar o status efetivo, não
inferir PASS pela existência de uma ferramenta.

O Lab é complementar ao FAST. Usar apenas o diagnóstico necessário
à mudança esportiva, visual ou técnica. Build de teste não é publicação;
não distribuir binários/assets sem autorização e verificação de direitos.
Não estender indefinidamente a infraestrutura em detrimento do jogo.

### 5.3. Pre-Merge Integrity Guard — procedimento obrigatório

Antes de qualquer merge, consultar novamente a PR e a main pelo GitHub:

1. Confirmar PR aberta, não draft, destino main, repositório correto,
   ausência de conflitos, bloqueios de revisão e pendências relevantes.
   `mergeable=true` sozinho NÃO significa que os testes passaram.
2. Registrar SHA atual da main, SHA da candidata e SHA de merge temporário.
   O FAST valida a árvore de integração, não somente a branch isolada.
   Exigir a execução mais recente aplicável à combinação exata, concluída
   com sucesso, incluindo importação, Test Lab, regressões e
   `APEX_PREMERGE_PASS` / `premerge-receipt.json`. Conferir PR, run,
   tentativa, base, head, merge, tree e lista de testes do comprovante.
   Uma aprovação anterior a novo commit ou mudança da base não vale.
3. Conferir também todos os testes direcionados obrigatórios do escopo.
   Falha, cancelamento, teste necessário ausente, execução em andamento
   ou evidência inconclusiva bloqueia o merge. Skipped só é aceitável
   quando o teste é realmente opcional e não aplicável; explicar.
   Não repetir até ficar verde, não diminuir critérios e não ignorar
   regressões. FULL continua manual, não é condição universal.
4. Se a main avançou, resolver conflitos/sincronizar a candidata de forma
   não destrutiva e obter nova validação da integração. Não usar força,
   bypass de proteção, aprovação de outro SHA ou merge de draft.
5. Imediatamente antes do merge, consultar novamente main, PR e checks.
   Usar `expected_head_sha` igual ao candidato aprovado e merge normal.
   Se a API negar a operação ou o estado mudar, parar e investigar,
   sem contornar regras. O head protegido não torna a base atômica:
   a proteção estrita de branch é recomendada para fechar essa janela.
6. Confirmar resposta merged=true, SHA resultante e árvore do commit
   integrado; acompanhar o FAST de main. Se a árvore divergir ou o
   pós-merge falhar, não promover nem iniciar uma cadeia de novas versões
   a partir de uma base não validada; abrir correção direcionada e
   preservar evidências. Não reverter automaticamente trabalho alheio.

O comprovante do FAST atesta os testes executados, não a inexistência de
bugs, aprovação humana ou homologação FULL. O gate não faz merge, não
muda a proteção do GitHub, não usa runner pessoal e não publica releases.
Manter a main estável; uma integração de cada vez quando houver mudanças
concorrentes. Consultar `docs/APEX_PREMERGE_INTEGRITY_GUARD.md`.

## 6. DESEMPENHO

Otimizar com medições reais.

Monitorar:
- FPS.
- Tempo de processamento por tick.
- CPU e memória.
- Desempenho em 1x, 10x, 16x e 32x.
- Tempo de carregamento.
- Tamanho dos saves.
- Custo dos replays.

Não sacrificar a qualidade da simulação para
aumentar artificialmente a velocidade.

## 7. CONTROLE DE VERSÕES

Antes de modificar:
1. Identificar a versão mais recente validada.
2. Ler changelog e documentação.
3. Examinar os arquivos envolvidos.
4. Identificar possíveis regressões.

Depois de modificar:
1. Executar testes.
2. Registrar arquivos alterados.
3. Atualizar o changelog.
4. Documentar resultados reais.
5. Preservar possibilidade de rollback.

## 8. FILOSOFIA DE DESENVOLVIMENTO

Profundidade antes de quantidade.

Causalidade antes de aleatoriedade.

Código modular e bem documentado.

Pilotos e funcionários devem possuir decisões
coerentes, limitações e consequências reais.

A fábrica deve utilizar componentes e processos
persistentes, não simples pontos de upgrade.

Nenhum sistema deve ser declarado completo
sem implementação e testes verificáveis.

## 9. OBJETIVO FINAL

Criar um simulador automobilístico profundo,
realista, eficiente e sustentável.

Cada atualização deve melhorar o APEX
sem destruir funcionalidades anteriores.

Consultar o Plano Mestre Unificado 2.0
e o código-fonte real para orientar decisões.
