# CI inteligente do APEX — três níveis

A infraestrutura de testes é separada do código esportivo: **nenhuma alteração
de física, RNG, regras de 2012, saves ou replay** é introduzida nesta PR.

**FAST — cada commit/PR.** `godot-setup.yml` importa o projeto e executa
invariantes de largada, replay e pit. O seletor `tools/apex_ci_tiers.py`
usa o diff real entre SHAs para escolher regressões extras de estratégia,
chuva, Soul Driver, rádio, HUD, saves e Pit Wall. Erro no diff bloqueia a execução.
O plano selecionado é arquivado.

**TARGETED — mudanças no subsistema.** Workflows de rádio, Soul Driver,
coordenação de pit, predição e chuva têm gatilhos limitados aos módulos
pertinentes. Alterações no `race_engine.gd` ainda executam regressões
cruzadas para evitar perda de cobertura.

**FULL — antes de homologação/release.** Colocar a etiqueta `ci:full`
no PR ativa, no SHA atualizado, os trabalhos longos: endurance, matriz de
circuitos, benchmark A/B, capturas, SaveGuard, exportação Linux/Windows e
regressão visual. Se houver novo commit enquanto a etiqueta estiver ativa,
os testes full voltam a executar no commit novo. A maioria desses workflows
também permite `workflow_dispatch`, e o endurance mantém seu agendamento.

O **Quality Gate 1.0** não roda em commits FAST comuns. Em `ci:full`,
o gate **aguarda até 70 minutos pelas dez evidências obrigatórias no SHA
exato**, falha imediatamente diante de uma verificação definitivamente
reprovada e encerra como falha se as demais não terminarem. Status técnico
`BLOCKED` nunca passa como homologação. O avaliador roda da branch
padrão confiável, não do código candidato com acesso ao token.
`workflow_dispatch` continua disponível com `audit` (informativo) e
`enforce` (estrito).

Os workflows pesados agora usam o status da etiqueta, e não filtros de
caminhos, para ativar a fase FULL — incluindo PRs apenas de documentação.
Sem a etiqueta, os jobs pesados permanecem `skipped` e não consomem
minutos de execução. O job de segurança Python continua verificando
cada PR para poder contribuir para a evidência FULL.


Não confundir `skipped` (teste pesado propositalmente omitido na fase
rápida) com `PASSED` (evidência válida de homologação). As regras de
proteção da branch são gerenciadas no GitHub e não são alteradas aqui.

## Critérios mínimos para lançar uma versão

Executar FULL e conferir a matriz de 20 circuitos, replay completo,
segurança de BOX manual V21, determinismo das sementes, saves antigos,
ausência de novos problemas de CPU/visual, e exportação Windows/Linux.
As execuções são evidências técnicas; não substituem testes manuais
de jogabilidade.

## Dynamic Quality Gate 2.0

O registro .github/apex-quality-suites.json incorpora automaticamente testes FAST e verificações FULL de funcionalidades novas. O gate exige as dez verificações históricas e os quatro shards da matriz de circuitos, sem contagem fixa de READY. O manifesto confiável da branch padrão é combinado com o candidato para impedir remoção de exigências. Para FULL-180, aplicar ci:full e ci:extended; leia as condições de obrigatoriedade e a ressalva de validação manual em docs/APEX_REGRAS_DESENVOLVIMENTO_2_0.md.

## Correção de espera excessiva e de proveniência após merge (Gate 2.1)

O GitHub pode esvaziar `run.pull_requests` ao integrar um PR; a auditoria
anterior repetia `NO_RUN` para todos os controles por até 70 minutos, mesmo
após os workflows efetivamente concluírem. A correção recupera esse caso
**apenas** consultando o PR real e verificando SHA, base, repositório, branch
e data do run no intervalo entre abertura e merge. Continua proibido aproveitar
execuções de outro PR, manual dispatch ou SHA divergente.

Os dez checks históricos permanecem obrigatórios. Os checks FULL de cada
módulo registrado são selecionados pelo diff exato base/candidato, evitando
exigir workflows específicos não acionados pelo próprio PR. Para mudanças no
Core, permanecem exigidos os quatro grupos da matriz de pistas. Se faltar
qualquer evidência obrigatória, o veredito continua BLOCKED.

O polling anterior de 70 tentativas (~70 min) foi reduzido para 20 tentativas,
uma por minuto, com falha explícita quando a evidência não se materializa.
A duração do gate não representa simulação de pista. Um circuito sintético é
útil para smoke/FAST e benchmarks controlados, mas não substitui testes em
Mônaco, Silverstone, chuva ou as 20 pistas para homologação FULL.
