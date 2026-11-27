# APEX — prevenção de falhas antes do push (REV1)

Objetivo: reduzir retrabalho, não adicionar workflow, FULL ou proteção de merge.
A análise de 26/11 relatou 5/8 falhas recentes relacionadas aos testes, 2/8 à compilação e 1/8 à exportação. É uma amostra, não uma classificação das 318 falhas históricas.

## Procedimento local

1. Atualizar a referência de main, ler AGENTS.md e mapear o código, dependências e contratos dos testes antes de editar.
2. Preparar uma alteração coerente; adicionar ao índice somente os arquivos revisados (git add). Não enviar commits intermediários incompletos.
3. Em checkout local ou worktree descartável, executar:
   ```sh
   git fetch origin main
   python3 tools/apex_preflight.py --base origin/main
   python3 tools/apex_preflight.py --base origin/main --native
   ```
   O modo estático reaproveita inventário e seletor FAST, verifica arquivos e marcadores literais, diff e indentação suspeita. A checagem de indentação é heurística e não substitui o parser. A presença de um literal não prova sua emissão. O modo nativo usa Godot 4.7.2 e o executor isolado existente (fixtures gráficas precisam de xvfb-run e Mesa). Pode levar vários minutos; use um ambiente local de desenvolvimento, não o runner pessoal sem autorização.
4. Revisar logs (diretório temporário impresso pelo script) e referências não resolvidas do inventário; referências dinâmicas precisam de revisão. Usar o Advanced Code Analyzer do Development Lab quando necessário, com o SHA exato, sem tratar seu diagnóstico como aprovação esportiva.
5. Só então criar commit/push/PR e verificar o FAST real no SHA correto, conforme AGENTS.md. Se o ambiente local não estiver disponível, declarar NOT_RUN/BLOCKED; não inventar evidência.

## Contratos de teste

- Marcadores: preservar os contratos existentes, conferir manifesto, seletor e emissão real; não alterar assertivas para obter verde.
- Separar identidade de versão (metadados/schema) de invariantes esportivos. Testar identidade isoladamente; não fixar prefixo de versão em testes de comportamento sem requisito real. Migrações de replay/save têm política própria.
- Cenários gráficos: aguardar inicialização e quadros necessários, verificar pré-condições e falhar com diagnóstico; não usar espera ilimitada nem esconder falha.
- Save/load: distinguir integridade/imutabilidade da comparação numérica. Tolerância explícita justificada somente para floats serializados; IDs, estados, contadores e invariantes permanecem exatos. Testar antes e depois de salvar.
- Exportação: verificar ferramentas/templates/recursos e saída real quando exportação for solicitada; não impor exportação ao merge cotidiano.
- Se houver falha: guardar primeiro log, SHA e cenário, classificar produto/fixture/infraestrutura, reproduzir, corrigir causa, preservar regressão.

## Auditoria inicial de redundância (main 5de188d)

Foram observados 36 arquivos de workflow. Quantidade de runs não equivale a quantidade de testes executados. O FAST é automático em PR/push main. Toolkit GDScript, GdUnit4, Scenario Matrix e Quality Gate são manuais. Exportação é por tag, dispatch ou etiqueta build:preview. Aero Wake tem filtro de caminhos, mas job condicionado à PR histórica #126 ou etiqueta ci:aero-full; isso pode produzir registros skipped. Race Engineer 9.22 tem gatilho por caminhos e não tem condição de job; comparar suas fixtures e configuração com o FAST antes de alterar gatilhos. Não desativar nenhum workflow sem comprovar equivalência de cobertura e verificar checks exigidos. Investigar duração, sobreposição de testes e skipped/cancelled separadamente.

Escopo REV1: ferramenta local e disciplina de trabalho. Não modifica jogo, manifesto, critérios FAST ou workflows. Auditoria individual de todas as falhas históricas, comparação integral de workflows e validação nativa do candidato são pendências até execução comprovada.
