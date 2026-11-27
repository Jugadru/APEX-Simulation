# APEX — redução de redundância das matrizes (sem redução de cenários)

Base: 3611e7d9df2cd1df0ddca6f7366e85e0a4ba3522. Decisão do responsável: reduzir retrabalho preservando cobertura.

Cinco workflows usam a mesma fixture fixa em cada uma de 12 combinações (ITA/GBR/MON, seco/chuva intensa, seeds 42/123). As fixtures dedicadas foram inspecionadas: não leem as variáveis da matriz; quando instanciam Race, usam seed e pista fixas. Busca no código pelos identificadores APEX_COORDINATION, APEX_CORNER_BATTLE, APEX_DRIVER_TRAFFIC, APEX_TRAFFIC_MEGA, APEX_DRIVER_ERROR e APEX_AERO_TRACK localizou consumo no teste aero_wake_091711_test.gd, não nas fixtures dedicadas. Busca indexada tem limitações; a execução nativa do candidato deve confirmar.

| Workflow | Fixture fixa | Cenários preservados |
|---|---|---:|
| Tactical Coordination | tactical_coordination_091712_test.gd | 12 |
| Corner Battle | corner_battle_0919_test.gd | 12 |
| Driver Traffic | driver_traffic_0920_test.gd | 12 |
| Traffic Mega | traffic_mega_09201_test.gd | 12 |
| Driver Error | driver_error_0921_test.gd | 12 |

Em cada workflow, apenas ITA/Seco/42 executa a fixture fixa. Seu exit code, marcador e erros do motor continuam obrigatórios. Todos os jobs executam o cenário esportivo com as variáveis de modo, seed, clima, pista e 1800 ticks originais, exceto se uma etapa anterior falhar (comportamento normal de CI). A matriz, fail-fast false, trigger, runner, timeout, nome do job, setup e artefatos permanecem. A variável da matriz passa do job para o passo esportivo para tornar o isolamento explícito. Outros jobs não geram fixture.log; a execução fixa é comprovada pelo job canônico, não por um PASS artificial. Não há novos workflows.

Quando os cinco workflows forem acionados, o número de execuções fixas cai de 60 para 5 (55 a menos); 60 cenários esportivos continuam. O número de jobs não muda, nem se promete ganho de tempo sem medir. Não consolidar seeds, desativar matrizes ou alterar checks exigidos sem equivalência e acesso suficiente às regras. Aero Wake e Race Engineer mantêm as suas matrizes específicas e o trabalho gráfico distinto.

Validação: FAST com comprovante e cinco matrizes reais no SHA exato; conferir os 60 jobs, os cinco marcadores de fixture e todos os marcadores AERO_WAKE_091711_PASS. Se o workflow estiver skipped, cancelado ou incompleto, não declarar equivalência confirmada. A redução é uma mudança de execução, não alteração esportiva, nem homologação FULL geral.

## Histórico Core 2 (54 runs com failure, consulta 26/11/2026 BRT)

Classificação por etapa (não por causa raiz): 31 smoke tests; 13 importações; 10 sem etapas retornadas pela API e logs indisponíveis (HTTP 404 BlobNotFound). Os 44 logs restantes foram consultados. Dos 13 erros de importação, sete contêm erros de parse/compilação e seis crashes nativos. Nos 31 smoke tests há também dois erros de parse (rainy duplicado e Skin sombreando classe nativa), marcadores, identidade, inicialização gráfica, áudio, limpeza, invariantes esportivos e históricos. Mensagens de assertiva não provam que o produto, em vez da fixture, estava incorreto.

| Run | Sintoma observado no log (não diagnóstico definitivo) |
|---|---|
| 45915233146 | marcador Gearbox V21 ausente |
| 45903960834 | ordem bloqueada / imutabilidade |
| 45903374835 | identidade de versão acoplada à chuva |
| 45902176675 | identidade de versão acoplada à chuva |
| 45900078068 | preload de randomness / compilação |
| 45881418318 | 24 carros/modelos |
| 45684683665 | áudio ALSA, captura Pit Wall passou mas ERROR |
| 45617285885 | save_png em textura nula |
| 45544536377 | hash histórico REV1 028 |
| 45526149033 | limpeza XDG pulse: diretório não vazio após PASS |
| 45515864788 | identidade de versão acoplada à chuva |
| 45504056082 | inflação de ultrapassagens |
| 45496060790 | HUD entrega de projeto/histórico |
| 45458064587 | Skin sombreia classe nativa |
| 45439221782 | inferência exact_pair/pair_continuous |
| 45434373218 | salto visual MON / resync |
| 45432438302 | salto visual MON / resync |
| 45430455388 | salto visual MON / atraso consecutivo |
| 45429591683 | segfault na importação |
| 45428428602 | segfault na importação |
| 45426975240 | hashes replay 9.2 |
| 45422533037 | salto visual MON |
| 45308926540 | identidade de versão acoplada à chuva |
| 45308255928 | corredor único Monaco |
| 45307782885 | setup advisory / arquivo 023 |
| 45298804395 | hold visual MON |
| 45298305812 | hashes replay 9.2 |
| 45297228172 | sobreposição/hold visual MON |
| 45274773131 | variável rainy duplicada |
| 45075359467 | preload HUD 0622 |
| 45075164963 | preload HUD 0622 |
| 45068283277 | gate de revisão RaceSpace |
| 45068147768 | gate de revisão RaceSpace |
| 45061771105 | segfault na importação |
| 45061339680 | hashes históricos 016 |
| 45056491385 | segfault na importação |
| 45053942057 | segfault na importação |
| 44974219107 | erro de thread e segfault |
| 44943424596 | revisão meteorológica do replay |
| 44910747252 | Skin sombreia classe nativa |
| 44839373007 | log 404; causa inconclusiva |
| 44837810243 | log 404; causa inconclusiva |
| 44832052145 | log 404; causa inconclusiva |
| 44810791360 | log 404; causa inconclusiva |
| 44810548134 | log 404; causa inconclusiva |
| 44810499683 | log 404; causa inconclusiva |
| 44809248901 | log 404; causa inconclusiva |
| 44809188561 | log 404; causa inconclusiva |
| 44809170916 | log 404; causa inconclusiva |
| 44806332482 | log 404; causa inconclusiva |
| 44405387635 | reference() conflita com RefCounted |
| 44366097663 | número histórico não visível |
| 44365795704 | formatação % inválida |
| 44208543126 | assertiva de revisão replay |

Ação: preflight nativo + marcador antes de push; identidade isolada (PR #182); runner Xvfb/Dummy e limpeza isolada existentes; retry somente de crash nativo já previsto; não reabrir defeitos históricos sem reprodução no código atual. Retenção curta não permite reconstruir causas apagadas. Os 318 runs foram agrupados por workflow na REV2; este aprofundamento cobre todos os 54 do Core 2. Não afirmar análise individual dos outros 264. 
