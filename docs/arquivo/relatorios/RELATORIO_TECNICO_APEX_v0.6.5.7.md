# APEX v0.6.5.7 — Performance Profiler 1.0
Entrega concluída em 2026-11-13. Uma funcionalidade principal: diagnóstico de desempenho, sem otimizações de simulação/apresentação nesta versão.

## Base e auditoria
Extração direta do ZIP obrigatório `APEX_MOTORSPORT_MANAGER_v0.6.5.6_LIVING_FACTORY_2_COMPLETO.zip`, SHA-256 `ad208cc7fdf93723d56689930ad8f5fd8105b426276eb69d748a22c1eea66882`. CRC e todos os 1.623 hashes do manifesto conferidos antes das alterações. Base anterior preservada. Plano recebido `PLANO_ENGENHARIA_APEX_0657.md` lido e incluído em `docs/PLANO_RECEBIDO_0657.md`.

Auditoria pré-instrumentação em `docs/AUDITORIA_0657.md`: dependências, frequência de atualização, snapshots protegidos, módulos existentes e hipóteses de gargalo. Pesquisa primária no GitHub/documentação em `docs/PESQUISA_TECNICA_0657.md`, com links, licenças consultadas, compatibilidade e decisões. Nenhum código/asset externo foi incorporado.

## Implementação e uso
Abra o projeto no Godot 4.7.2. **F8** abre o painel; também disponível em **Configurações → Performance Profiler 1.0**. Abrir o painel não liga a instrumentação. Marque **Coletar medições**, execute a corrida e depois desmarque para congelar os agregados. **Limpar amostras** inicia uma janela de coleta limpa. **Exportar JSON** grava `user://apex_performance_0657.json` e mostra o caminho; exportações seguintes substituem esse relatório. Fechar o painel mantém a coleta selecionada. Ao reiniciar o jogo, volta desligada.

O profiler mede CPU por chamada de motor, snapshot, performance/térmica/DRS/KERS, racecraft/ultrapassagem, estratégia, decisão de pit, execução do pit, autonomia da equipe, construção de estados visuais, mapas, ocupação visual, atualização 3D, HUD e consultas geométricas 2D/3D. Mostra chamadas, média, mínimo, máximo e total em JSON (painel omite mínimo para legibilidade). FPS, tempo de frame, memória estática Godot e contagem de objetos/nós usam monitores da engine quando disponíveis.

**Escopos inclusivos:** pai contém filhos. Não somar `race.step` com seus subescopos, nem `visual.world_3d` com `visual.occupancy`. `frame.input_delta` é entrada de tempo, não medição CPU. O JSON distingue contexto, ambiente, métricas e limitações.

## Arquivos novos e alterados
Novos:
- `scripts/debug/apex_perf_trace_0657.gd`: serviço estático de diagnóstico, OFF por padrão, cronômetro monotônico, agregados e exportação. Até 64 seções e 64 contadores; sem arrays crescentes de frames/pilotos.
- `scripts/debug/apex_perf_panel_0657.gd`: janela criada sob demanda, tabela, controles e exportação; refresh de 0,5s somente enquanto visível.
- `tests/perf_0657_unit.gd`, `perf_0657_race_cpu.gd`, `perf_0657_visual.gd`, `perf_0657_rng.gd`, `perf_0657_double_stack.gd`.
- Auditoria, pesquisa, baseline, plano futuro e evidências em `docs/` e `qa/profiler_0657/`.

Alterados:
- `race_engine.gd`: instrumentação nos pontos de chamada e retorno. Fórmulas, ordem, condições e RNG preservados.
- `main.gd`: medições da apresentação/autonomia/HUD e abertura do painel F8.
- `track_map.gd`, `track_3d.gd`: temporização de consultas e ocupação, sem mudança geométrica.
- `apex_management_hub.gd`: botão de diagnóstico nas Configurações.
- `project.godot`: identificação da versão; diretório de saves mantido.
- `README.md`: documentação atualizada para 0.6.5.7; README anterior preservado em `docs/README_HISTORICO_0656.md`.

A auditoria de fontes confirma **98 scripts existentes de produção idênticos** à base; apenas cinco existentes foram instrumentados/integrados. Inclui preservação literal de RaceSpace, Staff, Soul Staff/Driver, Garage, oficina, Strategy Simulator, modelos 3D e módulos de pneus/clima/pits. Detalhes em `source_audit.json`.

## Medições comparáveis
Godot 4.7.2.stable.official.ed1daf0bf; Linux, Intel Core i5-7500 @ 3,40 GHz, 4 threads; GTX 1650 no teste gráfico.

18 corridas headless: Silverstone, **3 voltas**, 24 pilotos, seed 6557, Seco/Chuva intensa, 3 repetições por modo base/OFF/ON. Warm-up de 8s simulados; ordem dos modos rotativa; execução serial. O benchmark usa o mesmo motor e os mesmos batches de 4s/subpassos de até 0,2s. Não é benchmark de GP de 52 voltas.

| Clima | Base v0656, mediana s | v0657 OFF, mediana s | v0657 ON, mediana s | OFF/base | ON/OFF |
|---|---:|---:|---:|---:|---:|
| Seco | 6,398326 | 6,492849 | 6,505680 | +1,48% | +0,20% |
| Chuva intensa | 7,120829 | 7,161194 | 7,220606 | +0,57% | +0,83% |

Esses números representam **overhead observado**, não ganho. Variações pequenas podem incluir ruído; três repetições não estabelecem significância estatística. Não há promessa de FPS melhor. OFF mantém branches/variáveis locais, mas não consulta relógio nem acumula amostras nas seções.

Resultados esportivos completos idênticos nas nove execuções de cada clima:
- Seco: `0618280f76d1ea1f1580ccf1381c02521a6900fc651e7da82e9dc6b9212d99ff`.
- Chuva intensa: `fe69acc40c277e05accab0bcc35b73dc14cbd4ed77be94487e634addce58d4a3`.

Classificação de 24 posições distintas, melhores/últimas voltas positivas, chegada de todos, entrada nos boxes e histórico de espera verificados nos 18 arquivos reais. No seco, a Ferrari registrou espera de aproximadamente 2,523s para o segundo carro.

Cena nativa: Forward+/Vulkan em 1600×900, 30 frames de aquecimento e 180 medidos, delta de simulação fixo 1/60. Última amostra de FPS: 48; janela real 3,728001s (~48,28 frames/s). Média CPU `frame.main_cpu` 14,729ms; `hud.update` 9,758ms por chamada (12 chamadas, não 180). Memória estática Godot ~171,67 MiB no JSON. Não é RSS. Capturas do painel em 1600×900 e 1920×1080; somente 1600×900 foi medido como benchmark visual.

Diagnóstico: disputa espacial e snapshot são parcelas relevantes do motor; na cena gráfica, ocupação/projeção 3D custam mais que consultas 2D. Isso orienta investigação posterior, sem autorizar otimizações que mudem resultados. Tabelas completas, faixas e método: `docs/BASELINE_PERFORMANCE_0657.md`.

## Testes e evidências
Executados com saves isolados via `XDG_DATA_HOME`. Matriz em `qa/profiler_0657/regressions.json`.

Aprovados: profiler unitário; oficina (operações, limites, integração e save antigo); inventário LF1 (modelo e UI); HUD unificada; espaço/racecraft/motor/GP curto; pit wall por equipe (unitário e integração); Soul Staff (modelo/migração); contratos; Strategy Simulator; engenheiro; clima dinâmico; KERS/DRS; Soul Driver. Teste nativo confirmou coleta, seções reais, painel, toggle, exportação e duas resoluções. Teste específico OFF/ON verifica estado esportivo, eventos e **estado do RNG a cada batch** em 120s simulados de chuva intensa.

### Falha histórica investigada, sem ocultar resultado
`pit_incidents_double_stack_test.gd` falhou na assertiva de fila e ficou aguardando até timeout. A mesma falha foi reproduzida na **base v0.6.5.6**. O teste solicita `Macio` em Spa, composto ausente da alocação da pista; a ordem do segundo carro é recusada e não forma double stack. A primeira hipótese de interferência de tráfego não explicou a falha e foi descartada.

O arquivo histórico foi preservado. Novo `perf_0657_double_stack.gd` usa composto permitido e verifica explicitamente aceitação da ordem, exclusividade da equipe, espera durante reparo e atraso de 5,5s. Passou na v0657; resultado comparativo da base registrado em `base_legal_double_stack.log`. Não houve ajuste de física, probabilidade ou regra de pit para passar teste. O teste histórico continua constando como falha na matriz, não como aprovado.

## Compatibilidade, limites e riscos
- Nenhuma alteração de schema ou escrita do profiler em saves. Caminho de dados permanece `APEX_0650_SOUL_STAFF`; garagem/oficina/migração continuam idênticas.
- Instrumentação é agregada por processo, podendo incluir mais de uma corrida; limpe amostras antes de comparar cenários. O contexto do painel é informativo, não um log de replay.
- Memória medida é a memória estática informada pelo Godot; FPS/frame podem ter atraso de até ~1s. Métricas indisponíveis são null. Não mede tempo GPU nem RSS. Não foram demonstrados ganhos de GPU, ausência geral de vazamentos ou determinismo entre arquiteturas.
- Captura visual é curta e uma configuração de câmera; não extrapolar os 48 FPS para todos os circuitos/câmeras. Não houve benchmark visual comparativo base/OFF/ON nem GP completo de 52 voltas nesta bateria.
- Instrumentação aumenta o custo quando ligada; suas chamadas ficam inclusas nos tempos de escopos pais. Não se trocou frequência de atualização, snapshot, cache, LOD ou pooling.
- Planejamento de v0658 a v067x em `docs/PLANO_ENGENHARIA_FUTURO_0658_067x.md`: problemas, arquivos, contratos/funções, algoritmos, dependências, riscos, ganhos esperados e testes. Nenhuma dessas versões foi implementada.

## Integridade da entrega
ZIP completo com fontes, recursos, sistemas anteriores, novos testes e documentos. `.godot` e frames intermediários excluídos. Manifesto `BUILD_MANIFEST_0657.json`, checksum do ZIP e `VERIFICACAO_ZIP_0657.json` acompanham a entrega. A verificação final extrai novamente o ZIP, confere hashes e executa import/testes na cópia extraída.

### Observação da verificação extraída
Na primeira importação headless da cópia extraída, o Godot finalizou os recursos e encerrou com código 134, sem erro de script registrado. A repetição da importação terminou com código 0. Os oito testes executados nessa cópia passaram (profiler unitário/painel/RNG/double stack, oficina/legado, racecraft e HUD). A causa do encerramento inicial não foi determinada; as duas tentativas estão registradas, sem considerar a primeira aprovada.
