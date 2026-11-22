# CI inteligente do APEX — três níveis

A infraestrutura de testes é separada do código esportivo: **nenhuma alteração
de física, RNG, regras de 2012, saves ou replay** é introduzida nesta PR.

**FAST — cada commit/PR.** `godot-setup.yml` importa o projeto e executa
invariantes de largada, replay e pit. O seletor `tools/apex_ci_tiers.py`
usa o diff real entre SHAs para escolher regressões extras de estratégia,
chuva, Soul Driver, rádio, HUD e Pit Wall. Erro no diff bloqueia a execução.
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

O **Quality Gate 1.0** não deve gerar uma auditoria prematura com status
`BLOCKED` para cada pequeno commit. Na PR, só roda com `ci:full`.
Sua auditoria automática é informativa; o modo manual `enforce` deve ser
executado **depois** de todos os workflows necessários concluírem no
mesmo SHA, com o número de PR e SHA da base informados. Resultado
`BLOCKED` impede homologação, ainda que o diagnóstico tenha sido
executado corretamente.

Não confundir `skipped` (teste pesado propositalmente omitido na fase
rápida) com `PASSED` (evidência válida de homologação). As regras de
proteção da branch são gerenciadas no GitHub e não são alteradas aqui.

## Critérios mínimos para lançar uma versão

Executar FULL e conferir a matriz de 20 circuitos, replay completo,
segurança de BOX manual V21, determinismo das sementes, saves antigos,
ausência de novos problemas de CPU/visual, e exportação Windows/Linux.
As execuções são evidências técnicas; não substituem testes manuais
de jogabilidade.
