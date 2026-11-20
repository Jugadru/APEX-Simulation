# Relatório técnico — APEX Motorsport Manager v0.6.5.8

Race State Optimization concluída sobre o ZIP validado da 0.6.5.7. A atualização reduz cópias de dados e trabalho de apresentação, preservando o motor esportivo e a HUD atual.

## Implementação
- Novo scripts/race_view_snapshot_0658.gd: contrato visual com 23 campos simples, player e amostras de rota; snapshots imutáveis, revisão, cache por ID e reset por sessão. Históricos e containers do motor não são copiados nem compartilhados.
- scripts/main.gd: integra o contrato; atualiza 3D pausado somente por mudança de estado, foco ou reentrada. Mantém processamento de corrida e frequência do HUD anteriores.
- scripts/track_map.gd e scripts/apex_mini_map.gd: ignoram atualizações ocultas/iguais; reentrada recebe a apresentação atual.
- Interpolação exponencial de progress/race_lane (constante de 40 ms) antes da ocupação 3D. Não há extrapolação. Pausa congela pose; entrada/saída de pit, término, retrocesso e saltos grandes são tratados como descontinuidades. O solver de ocupação continua evitando sobreposições/varreduras; não há lerp de transforms depois dele.
- tests/pit_incidents_double_stack_test.gd: fixture corrigida para solicitar composto disponível em Spa. Motor de boxes intacto.
- Metadados, README, documentação e testes view_0658_* adicionados. Três scripts de produção existentes modificados; 102 byte a byte iguais à base. Nenhum removido. race_engine.gd, RaceSpace, BattleMotion, estratégias, modelos 3D e saves não alterados.

## Validação
Godot 4.7.2.stable.official.ed1daf0bf, saves isolados em /tmp; nenhum save do jogador usado. Matriz final com **30 verificações/scripts aprovados**, incluindo o microbenchmark de cópia. Detalhes e logs em qa/race_state_0658/final_test_matrix.json.

- Contrato imutável, isolamento, emenda da volta, pausa, descontinuidades, remoção de IDs e reset.
- Cena real: seleção, mapas ocultos/reentrada e 24 estados compactos; motor/RNG sem mutação pela apresentação.
- 240 frames em 1×/16×: nenhum overlap nem atravessamento na varredura entre poses.
- 12 alternâncias mapa/3D com número de nós estável; nova corrida limpa o estado visual.
- Profiler (unidade, painel/F8 e RNG), racecraft/ocupação, GP, double stack, equipe de pit, estratégia, clima, KERS/DRS e Soul.
- Living Factory (unidade, bordas, integração e save real legado), inventário/interface, HUD unificada e contratos/Staff/Soul.
- O teste KERS/DRS inicialmente excedeu 90 s; passou sem mudança de código com limite de 300 s. Erros iniciais nas fixtures novas de tipo/foco foram corrigidos; matriz final registra resultados posteriores. Histórico de tentativas preservado em regressions.json e diário.

**Paridade esportiva:** quatro cenários, cada um rodado na base e na nova: GBR seco/chuva intensa, UAE seco e GER chuva intensa. Os dois últimos sorteados com seed 6558. Cada corrida tem 3 voltas/24 carros, seed 6557 e parada dos dois pilotos Ferrari. Todos finalizaram, posições únicas, tempos válidos e hashes idênticos de carros/eventos/clock/pits. Os 12 cenários de medição nativa também têm hash idêntico, incluindo RNG.

**Desempenho:** ver docs/BENCHMARK_0658.md e JSONs brutos. Três repetições por versão em 1600×900 e 1920×1080 real. A série inicialmente limitada a 1786×1005 foi excluída e arquivada. Montagem visual caiu cerca de 33–35%, mas em 1080p a taxa frames/parede regrediu 7.3% e CPU main aumentou 3.7%. A causa não foi isolada; não se declara ganho global de FPS.

## Limitações e pendências
A matriz executada é a seleção de regressões pertinente a esta atualização, não todos os scripts históricos/manuais de captura do repositório. Não foi executada temporada ou GP integral de 52 voltas. Testes de colisão cobrem os cenários registrados, não uma prova matemática para qualquer pista. Interpolação adiciona pequeno atraso visual e não resolve determinismo entre FPS; 0.6.6.0 tratará isso.

HUD e dois pilotos foram inspecionados nas capturas nativas. Há artefato escuro serrilhado na junção da pista, também reproduzido na base 0657 (base_visual_diagnostic.json.png); não foi introduzido por esta mudança. A geometria/material deverá ser investigada na próxima etapa. Não houve remodelagem gráfica nesta versão.

O import e a verificação do pacote usam logs próprios. VERIFICACAO_ZIP_0658.json, junto ao ZIP, registra CRC, SHA256, manifesto, import e testes de extração limpa. O ZIP anterior permanece disponível como backup. Não se iniciou 0.6.5.9 nesta entrega.

## Entregas
ZIP completo com código/cenas/recursos/histórico preservados, este relatório, docs/BENCHMARK_0658.md, docs/PLANO_ENGENHARIA_0659.md, docs/DIARIO_ENGENHARIA_0658.md e docs/PESQUISA_TECNICA_0658.md. BUILD_MANIFEST_0658.json é o manifesto desta versão; o 0657 é histórico.
