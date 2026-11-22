# APEX — Regras de Desenvolvimento 2.0

Revisão: 22/11/2026. Documento normativo complementar ao Plano Mestre e ao Roadmap. O ZIP/código e os testes executados prevalecem sobre afirmações documentais. Base inicial: temporada 2012, Godot 4.7.2 e Core 2.

## Contrato de cada versão

1. Uma única funcionalidade principal ou correção temática por release. Refatorações extensas requerem entrega independente.
2. Reutilizar responsabilidades existentes; manter motor, IA, eventos, persistência e apresentação separados. Nada de cálculos imutáveis a cada tick sem medição.
3. Todo módulo novo registra critérios determinísticos e testes realmente executáveis; não usar sucesso simulado nem ignorar arquivos desconhecidos.
4. Preservar saves versionados, replays, fábrica, Garage, Pit Wall, HUD e os comandos Manual/Assistido/IA; migrações e rollback são verificáveis.
5. Respeitar a temporada 2012 (V8, KERS, DRS, compostos e regras históricas); ordem manual BOX V21 não pode ser antecipada pela IA para V4.
6. Medir CPU, RSS, tick p50/p95, FPS quando visual, latência, tempo de carregamento e tamanho de saves em hardware e cenários comparáveis. Não alegar melhoria sem números.
7. Escalonar testes pelo risco; mudanças em física, RNG, scheduler, persistência, replays e regulamento exigem homologação ampliada.
8. Não integrar checks reprovados; deixar branch estável recuperável. Branch rulesets / required checks precisam ser configurados pelos administradores; somente workflows verdes não bloqueiam merge automaticamente.
9. Validar corridas reais e experiência visual 2D/3D e comportamento dos pilotos, não apenas testes unitários.
10. Anexar changelog, lista de arquivos, provas de testes, métricas, falhas, limites e rollback ao release.

## Níveis de testes

- FAST: em cada PR/commit; invariantes essenciais e seleção determinística pelo diff. Mudanças em scripts Core desconhecidos ativam todas as categorias históricas FAST. Teste declarado e inexistente bloqueia.
- TARGETED: regressões específicas de todos os subsistemas tocados, inclusive integração entre eles; nenhum workflow skipped equivale a PASS.
- FULL-20: 20 circuitos (uma combinação representativa por circuito), repetidos de forma determinística. Exigir antes de integrar release funcional/relevante, junto com o Quality Gate do SHA exato.
- FULL-180: 20 circuitos x 3 climas x 3 modos. Obrigatório para mudanças no motor, RNG, scheduler, pit/estratégia centrais, pneus/clima, replay, saves ou regras; também para homologação de grandes marcos e quando FULL-20 revela inconsistência. Usar a etiqueta ci:extended no PR com ci:full; confirmar nos artefatos que o perfil efetivo foi full e não smoke. **Até a validação automatizada de perfil entrar no gate, a confirmação do FULL-180 continua sendo uma exigência manual documentada, não prova automática.**
- Visual/real-play: capturas Godot reais para HUD, câmera e render; corrida completa para IA, pit, balanceamento e estratégias. Separar fixture de observação real.

## Manifesto de novos sistemas

Arquivo: .github/apex-quality-suites.json. Schema 1; cada suite declara id, paths (globs), fast_tests (script + marcador) e checks FULL (chave, arquivo do workflow, nome exato do job, área e flag de comparação PR). Registre novas funcionalidades aqui, com novos workflows/testes independentes, sem reescrever o gate.

O seletor FAST usa o manifesto automaticamente quando o diff aciona um padrão. Testes FAST obrigatórios não encontrados causam FAIL, em vez de serem omitidos. O Gate FULL soma aos dez controles históricos todos os jobs declarados; hoje também requer os quatro shards da matriz de 20 circuitos. Um candidato não pode retirar exigências do manifesto confiável da base: o gate combina os dois registros de maneira aditiva.

A execução do gate usa ferramenta confiável da branch padrão e dados candidatos de outra pasta; o status READY exige jobs com conclusão success, SHA exato e contexto de PR nos comparadores. Um novo arquivo pode ser coberto imediatamente mediante inclusão no manifesto, mas o gate seguro da branch padrão só passa a interpretar a versão nova da ferramenta após a integração de bootstrap. Nunca tratar isso como validação antecipada.

## Critérios operacionais

Evidência: PASS, FAIL, NOT_RUN, INCONCLUSIVE ou BLOCKED, nunca um PASS inventado. Guardar logs, commits, hashes, parâmetros de semente, saídas e link de Actions. Alterações de infraestrutura não modificam estados esportivos.

A aprovação exige: importação Godot, testes FAST/TARGETED, FULL proporcional ao risco, Gate do mesmo commit, compatibilidade de saves e replays, benchmarks aplicáveis, relatório de jogabilidade, changelog e referência de rollback. A ausência de evidência bloqueia homologação; não aprovar pela quantidade de código.

## Proteção e publicação

Propor alterações em branch isolada com PR; não forçar merge. Após integrar o bootstrap e validar checks estáveis, configurar Ruleset na main com checks necessários (incluindo o veredito final do gate para o release). O job atual em modo AUDIT é informativo: não deve ser cadastrado como bloqueio único de merge. Publicação exige FULL + checklist humano de jogabilidade.

Este documento não certifica o jogo como estável nem declara executados testes que não ocorreram.
