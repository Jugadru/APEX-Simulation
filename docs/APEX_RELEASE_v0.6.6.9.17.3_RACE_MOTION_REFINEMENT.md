# APEX v0.6.6.9.17.3 — Race Motion Refinement (candidata)
Base: 7e94535350fccd5724c4a7f1281c009673723c2e (PR #115, v9.17.2). Escopo exclusivamente visual.

## Evidência de referência
GitHub Actions 45309590616, benchmark visual de 125 amostras, 0,5 s:
| Pista | held | stationary_samples | resynced | max_resync_step (unidades visuais) | overlaps |
| --- | ---: | ---: | ---: | ---: | ---: |
| GBR | 52 | 0 | 0 | 0 | 0 |
| MON | 489 | 43 | 13 | 26.8231 | 0 |
| BEL | 154 | 23 | 6 | 19.2356 | 0 |
| SIN | 33 | 0 | 0 | 0 | 0 |

## Alteração
Após resolver a ocupação pelo algoritmo anterior, tentar reduzir o salto de cada carro atrasado individualmente, com limite de 125% do avanço oficial corrente. Validar o candidato contra todos os vizinhos e preservar a solução anterior se inseguro. O fator é uma hipótese visual, não esportiva. O fallback ainda pode produzir saltos.
A instrumentação distingue recuperações graduais e ressincronizações. Nenhuma mudança no motor, RNG, revisão de replay ou classificação.

## Critérios para homologar
- Godot 4.7.2: teste unitário de recuperação limitada, rejeição de colisão, regressões 3D e replay 025/024.
- Comparar benchmark no mesmo cenário, sem relaxar gates existentes: zero overlaps, no máximo dois quadros imóveis consecutivos.
- Exigir melhora observada de retenções ou saltos em MON/BEL, sem regressão relevante em GBR/SIN, e verificar custo p95.
- Testar múltiplas seeds e obter captura gráfica real em Mônaco. Se não houver melhora, revisar ou reverter.
- Confirmar corrida esportiva inalterada por hash e teste competitivo, pit V21.
- Exportar apenas após homologação; não declarar candidata estável antes disso.

Status inicial: implementação e fixtures propostas; execução, desempenho e inspeção gráfica pendentes. Rollback: reverter o commit desta PR ou descartar a branch; main não é alterada.

## Segunda tentativa — após CI 45420829487
A primeira implementação passou nas fixtures e no gate de segurança, mas o benchmark nativo apresentou zero recuperações graduais, salto máximo MON de 35,79 versus 27,98 no run anterior. Não homologada. Comparações de runs distintos não isolam seed/carga; nesta revisão o benchmark roda o solver legado e o candidato sobre os mesmos snapshots oficiais. A recuperação passa a ser local, aplicada após a resolução normal e aceita somente quando diminui o salto e não colide com nenhuma trajetória vizinha. O fator 125% permanece experimental. Não modificar critérios anteriores.

### Gate A/B pareado obrigatório
As duas variantes começam com a mesma ocupação inicial e recebem os mesmos snapshots, sem simular novamente a corrida. O benchmark registra seed, maior salto total, maior salto de resync, retenções e amostras estacionárias do legado. Reprovar se o maior salto crescer em qualquer pista (tolerância numérica 0,01), se em MON a recuperação gradual nunca atuar, se não houver redução de resyncs ou do maior salto, ou se crescerem as amostras estacionárias em MON. Esses critérios complementam, não substituem, os gates de segurança já existentes. Múltiplas seeds e inspeção gráfica ainda são exigidas antes de merge.

## Terceira tentativa — CI 45422533037 reprovado
Seed 42, A/B pareado: MON 6 recuperações graduais, resync 11→9, salto resync 27,84→25,27, salto total 35,79→36,74, retenções 481→545, sequência máxima 94, overlaps 0. Não homologada.
A hipótese agora é dupla: a recuperação de 125% prolonga a dívida visual e a projeção euclidiana pode selecionar um ramo errado em curvas/cruzamentos. A candidata usa o segmento por comprimento de arco quando a posição oficial corresponde à polilinha (tolerância 0,01 unidade); os pontos sintéticos mantêm o fallback de projeção. A velocidade adicional recupera 25% do atraso por atualização, limitada a 125–250% do avanço oficial; considera também liberações sem flag de resync. Preserva SAT, footprints e fallback. Benchmark mede algoritmo legado e política 125% anterior separadamente, registra divergências de âncora e maior salto com tick/ID. Gate inclui sequência máxima de retenções, sem afrouxar critérios prévios. Nenhuma dessas hipóteses está comprovada até a execução.

### QA adicional
Benchmark aceita APEX_MOTION_SEED; seed 42 mantém exigência de melhora efetiva e uso de recuperação. Seeds adicionais 6617 e 6558 verificam não regressão de salto em todas as pistas, sobreposição e retenções em MON; não se exige recuperação quando não há oportunidade. O workflow candidato reutiliza o benchmark e a captura visual existente com Mônaco aos ~30 s de atualizações solicitadas em 1x, 1600x900 e 1920x1080 via Xvfb, sem confundir captura com validação de fluidez ou hardware real. Os resultados são independentes da CI principal, e não autorizam merge por si só.

## Quarta tentativa — causa geométrica, não recuperação pós-atraso
CI 45426975529: as três seeds reprovaram, 0 divergências significativas de projeção (limiar 0,01; máximos abaixo de 0,001); a captura gráfica passou. CI 45426975240 confirmou largada 424 checks e revelou falha histórica em driver_traffic_06693_test, que precisa ser reproduzida separadamente no commit base. As alterações experimentais de projeção e recuperação foram removidas do caminho ativo, preservadas no histórico Git. O solver original é mantido, mas a pose live agora fornece o footprint do modelo com escala 0,78: sem alterar mesh, largura de pista ou dimensão esportiva. Hipótese: o envelope antigo 5,6 x 2,8 era maior do que a carroceria; novo candidato 4,8 x 2,5 precisa demonstrar margem mínima de 0,10 em cada semi-eixo via inspeção dos AABBs das malhas com amostras de extremos de animação. AABBs são uma aproximação conservadora, não prova contínua de todas as rotações. Testes antigos sem dimensão explícita e baseline A/B mantêm envelope anterior. Não há mais exigência de executar recuperação gradual porque essa implementação foi retirada; permanece a exigência de melhora real, sem aumento do pior salto, zero overlaps com envelope validado e limites de retenção. Nenhum critério esportivo foi alterado.

## Quinta revisão — isolamento do replay e grid
Controle base/candidate confirmou a mesma falha 015 em ambos; não é regressão do envelope. A fixture driver_traffic_06693 construía um grid moderno e desabilitava apenas três dos dez flags de revisão antiga. Corrigida a preparação do produtor para corresponder ao consumidor; não constitui validação de arquivo histórico autêntico. Em jogo normal a gravação fica desativada por padrão, F9 inativo, sem hashes/checkpoints por tick nem histórico de comandos consumidos; mantém relógio, fila, autonomia, radio, auditoria racecraft e interpolação. Replay original permanece opt-in para QA. Nova fixture compara hashes externos do mesmo estado esportivo com gravação on/off e mede CPU sem impor ganho artificial. Grid 3D ganha boxes numerados P1–P24 derivados do progresso/lane oficial pelo mesmo sampler; não muda classificação ou regras de largada. A pole oficial ainda tem progress=0 (centro no plano de chegada); não deslocar a física ou a linha de chegada silenciosamente. Testar alinhamento nominal x ocupação x modelo; divergências devem permanecer visíveis no relatório.

## Sexta revisão — evidência do replay e diagnóstico de grid
CI 45429591767, job 138571067787: 310 ticks, 2.024.475 us com gravação e 1.475.188 us sem (redução 27,1% no teste do núcleo), zero divergências externas, pit V21 e comandos aprovados. Não é ganho comprovado de FPS. Fixture 015 corrigida PASS (56 checks); base reproduziu a falha anterior, por isso o controle negativo não precisa ser executado em todas as revisões. Captura MON PASS. Grid e Core2 não executados por crash nativo de importação de CSV de relatórios (134/139), não por falha de posicionamento. Os diretórios de relatórios recebem .gdignore (dados preservados) e o workflow de diagnóstico adota retry limitado apenas para crash nativo, mantendo falha fatal para erros de script. Grid testa também o nó físico pintado, lane e progress. Novo A/B percorre o pipeline host._process com 3D ativo, delta fixo, mesma seed, gravação on/off e estados finais comparados. Não mede FPS real da GPU; não modificar geometria esportiva de Mônaco até medir a diferença.

## Revisão 7 — inventário de recursos
CI 45430455339: grid 120/120, erros nominais/modelo/marca/lane/progress zero e overlaps zero; A/B 360 frames, 60 ticks por pista, hashes esportivos e poses iguais; CPU p95 GBR 11,042→9,055 ms, MON 11,270→9,495 ms, BEL 11,422→9,706 ms. Núcleo 310 ticks: 1.457.176→1.029.414 us (29,4% menos). Importação aprovada na primeira tentativa em todos os jobs. FAST 45430455388 ainda reprovou pelo gate MON. Não é ganho de GPU. Inventário Git: docs 129,3 MB, qa 26,2 MB; cinco partes ZIP antigas ~114,1 MB; 42 arquivos de tradução gerados de CSV. Duplicatas exatas observadas em relatórios QA. .gdignore em docs e relatório Strategy Simulator; export exclui experimental/linux/relatório legado. Preservar arquivos históricos e evidências; validar referências de runtime antes de homologar.
