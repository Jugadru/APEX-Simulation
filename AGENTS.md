
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

## 10. ACERVO VISUAL REUTILIZÁVEL

Antes de recriar retratos de pilotos, fundos ou outros recursos visuais, consultar `docs/ASSET_LIBRARY.md`. Preservar os arquivos-mestre privados e criar variantes separadas. Não publicar fotografias sem verificar direitos de redistribuição. Não usar o backup histórico como substituto da main atual.
