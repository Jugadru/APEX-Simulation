# CI do APEX — fluxo leve (a partir de 22/11/2026)

O desenvolvimento do APEX é incremental: um módulo/script por vez, merge rápido
quando o Godot consegue importar e os testes locais do módulo passam.

## Automático: uma única verificação principal

`.github/workflows/godot-setup.yml` executa em Pull Requests e pushes
para `main` no modo FAST, independentemente de etiquetas.

1. Testa o seletor de scripts Python e a existência do projeto.
2. Importa o projeto real no Godot 4.7.2 (erros de sintaxe bloqueiam).
3. Executa o APEX Test Lab e invariantes básicos de pit/replay/largada.
4. Seleciona com `tools/apex_ci_tiers.py` apenas os testes afetados pelo diff
   (sistemas desconhecidos recebem cobertura FAST ampliada).
5. Publica um log curto. Nunca declara PASS inventado.

**Nada de auditoria de 10/16 provas por SHA, 20 pistas, 180 cenários, endurance,
capturas, exportação ou comparadores por padrão.** As verificações históricas
não são apagadas: ficam em Actions > workflow correspondente > Run workflow.
`ci:full` deixa de disparar homologações automaticamente.

## Quando usar testes manuais?

Se uma alteração apresentar sintomas relevantes, execute o teste apropriado:
pistas reais para geometry/chuva, SaveGuard para migração, A/B para desempenho,
export para pacotes finais e endurance para problemas que só aparecem após muitas
voltas. Isso é uma decisão técnica pontual, não uma barreira obrigatória a cada
script.

O `workflow_dispatch` do Core 2 também oferece `tier=full` para executar
a suíte ampliada, sem iniciar os outros workflows.

## O que não estamos prometendo

O Test Lab é uma pista sintética para medir o motor em condições repetíveis.
Não substitui um GP real quando o problema depende da geometria, nem mede
FPS na GPU do jogador. Nenhum check opcional que foi pulado conta como PASS.
`main` continua restaurável por commit/PR e não deve receber mudanças
com erros conhecidos que o FAST já detectou.

## Por que mudamos

A revisão longa da v9.13 aguardou ~70 minutos por evidências que o gate não
conseguia reconhecer. A 9.14 teve um gate que encerrou antes dos trabalhos
paralelos. Os quatro grupos da matriz são paralelos e a execução real
observada durou ~7 minutos; mesmo assim, não faz sentido repeti-la em toda
mudança pequena.

Preferimos testar e corrigir rapidamente, com resultados reproduzíveis,
sem transformar cada commit em uma homologação de lançamento.
