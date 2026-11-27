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

## REV2 — auditoria ampliada e correções da ferramenta

Base: main 4c0f658d164a68b7d350afea729bf45ba12afbcd (PR #179 integrada; FAST 45921798639 PASS).
O FAST de REV1 não executou os testes unitários da própria ferramenta. REV2 inclui sua execução no passo Python já existente, antes de instalar Godot; nenhum novo workflow ou benchmark.
Alterar o manifesto agora amplia apenas a revisão estática, não dispara todos os testes locais. Use `--audit-registry` para inspecionar todos os contratos; achados de marcadores não selecionados não são aprovados pela execução de outros testes. O teste de marcador literal respeita limites de identificadores e permanece uma heurística.

### Histórico: 318 runs com conclusão failure

Consulta paginada (100 por página, 4 páginas, deduplicadas por run ID), de 16/11 a 26/11/2026 no horário de Brasília. Classificação por nome do workflow, não causa raiz:

| Workflow | Falhas |
|---|---:|
| Core 2 FAST e versões anteriores do mesmo workflow | 54 |
| Comparador de Benchmarks A-B | 40 |
| Regressão Visual A-B | 37 |
| Quality Gate 1.0 | 17 |
| Wet Strategy 9.8 | 16 |
| GdUnit4 | 14 |
| Exportação Linux/Windows | 14 |
| GDScript Toolkit | 14 |
| Pit Wall Intelligence Analyzer | 12 |
| Race Motion diagnostics | 11 |
| Segurança Python | 11 |
| Django CI histórico | 9 |
| Demais workflows | 69 |
| Total | 318 |

Não confundir runs com tentativas de job ou defeitos independentes. Comparadores A-B hoje são manuais. Não classificar causas antigas sem logs; a listagem não fornece causa raiz.

### Cobertura ampliada: redundância parcial, não equivalência

- Aero Wake: 30 combinações (3 pistas × 2 climas × 5 seeds), câmera gráfica separada; GP completo e pacote histórico condicionados. Correção da nota REV1: os jobs aero e camera são automáticos por caminhos, não condicionados à PR #126.
- Corner Battle, Driver Traffic 9.20, Traffic Mega 9.20.1, Driver Error 9.21: cada um possui 12 combinações e executa fixture dedicada mais Aero Wake com variável de modo e 1800 ticks. FAST cobre fixtures registradas, mas não reproduz automaticamente todos os climas, seeds, durações e modos.
- Race Engineer 9.22: 12 combinações com 1800 ticks e um job gráfico com regressões de rádio. FAST inclui a fixture contextual (e UI por suites específicas), mas não é equivalente à matriz.
- Race Motion, Competitive Traffic, Racing Line, Independent Racecraft, Racing Completion, Race Traffic Hotfix: jobs condicionados a branches históricas. Registros skipped não provam consumo de runner. Preservar diagnósticos e artefatos; investigar regras de branch e checks obrigatórios antes de mudanças.
- Benchmarks A/B e regressão visual A/B já são manuais; não converter novamente.

Decisão REV2: não desligar nenhum job ou diminuir matriz. Para tornar matrizes ampliadas opt-in, mapear cada caminho, fixture, modo, renderer, ambiente e critério para o FAST e confirmar checks exigidos; branch protection não está acessível via conector. A política vigente exige apenas FAST e regressões direcionadas para merge comum; isso não permite apagar cobertura.

### Fixtures atuais verificadas

Gearbox V21 usa GEARBOX_V21_070_PASS; Smart Graphics aguarda process_frame e frame_post_draw; Race Revision Policy conserva IDs históricos e 044 experimental. São correções/contratos existentes: não os reescrever. Comparações de floats precisam de tolerância motivada e testes independentes de imutabilidade. Export Desktop possui verificações de assinatura, PCK, CRC e permissão de execução em package_desktop_exports.py; manter. Nenhum resultado nativo novo é inferido destas inspeções.
