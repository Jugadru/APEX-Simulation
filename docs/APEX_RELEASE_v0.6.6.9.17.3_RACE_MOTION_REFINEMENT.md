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
