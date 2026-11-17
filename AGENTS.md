
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

## 5. TESTES OBRIGATÓRIOS

Antes de aprovar qualquer atualização:

- Executar a importação do projeto no Godot.
- Verificar erros de scripts e recursos.
- Executar os testes existentes com GdUnit4.
- Testar determinismo e replays.
- Verificar pit stops e estratégias.
- Testar salvamento e carregamento.
- Verificar regressões de física e IA.
- Avaliar desempenho quando aplicável.

Cenários prioritários:
Silverstone, Monza, Spa e Singapura.

Uma ordem manual de pit na volta 21 não pode
ser executada na volta 4 por decisão automática.

Classificar os testes como:
PASS, FAIL, NOT_RUN, INCONCLUSIVE ou BLOCKED.

Nunca declarar um teste aprovado sem executá-lo.

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
