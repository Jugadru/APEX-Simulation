# APEX Motorsport Manager v0.6.5.9 — Track Geometry Optimization
Entrega de 14/11/2026, seguindo o plano mestre unificado. Base: ZIP completo validado da v0.6.5.8, preservado sem alterações.

## Alterações
Índice espacial exato em blocos de 16 segmentos para projetar carros na pista 3D; caixas delimitadoras conservadoras descartam blocos distantes. A dica por carro inicializa a distância, mas a busca continua global e mantém o desempate original. Comprimentos e vetores são pré-calculados.

Cache 2D limitado a 256 posições e 256 direções, com busca/interpolação e diferença central originais. Revisão da geometria invalida os snapshots mesmo com a corrida pausada. Consultas de fallback desnecessárias foram removidas.

Três scripts existentes modificados: track_map.gd, track_3d.gd e race_view_snapshot_0658.gd. Dois módulos adicionados: track_projection_index_0659.gd e track_geometry_sampler_0659.gd. Outros 103 scripts existentes permanecem idênticos; nenhum removido. Motor esportivo, disputa de espaço, defesa, ultrapassagem, HUD, modelos, shaders e saves não foram modificados. Não houve redução de qualidade, LOD novo ou reescrita de câmera.

## Desempenho e investigação
Na máquina i5-7500/GTX 1650, Godot 4.7.2, três repetições por versão/resolução: em 1080p, CPU principal 13,676 → 9,830 ms e quadros/tempo de parede 48,39 → 59,68. Em 1600×900: 13,832 → 9,829 ms e 47,62 → 59,33. São medições locais de trechos curtos, próximas do limite de 60 Hz, não garantia de FPS em outros computadores. Não foi medido tempo de GPU isolado.

A regressão anterior de 1080p não se reproduziu em seis novos ensaios alternados de 0657/0658. Causa não isolada; não atribuir a driver ou temperatura sem evidência. Metodologia, dados completos e custos de construção/memória em docs/BENCHMARK_0659.md.

## Testes executados
- Importação e 28 scripts selecionados aprovados: geometria, apresentação, lifecycle, profiler/RNG, racecraft/ocupação, pit/double stack, oficina, save legado, inventário, HUD, Staff/Soul, estratégia e clima. Matriz: qa/geometry_0659/checks.json. Cinco testes de apresentação/geometria repetidos após a revisão final.
- 6.000 consultas em 20 pistas comparadas com o algoritmo anterior: segmento projetado idêntico, tolerâncias de posição/direção verificadas; 400.400 candidatos examinados contra 4.056.000 na busca anterior. Empates, degenerados, rota vazia, caches limitados e troca de pista pausada cobertos.
- Sete corridas comparativas de três voltas com 24 carros, pits e seed fixa: GBR seco/chuva, BEL, ITA, SIN chuva e sorteadas CHN/GER. Todos os hashes esportivos idênticos à base. Incidentes desativados nesses cenários; não são sete GPs integrais.
- GP integral de Silverstone, 52 voltas, 24 carros: aprovado em 203,47 s de execução headless, com classificação única, progresso monotônico, tempos válidos e paradas. Executado somente na versão nova; não foi uma comparação pareada de GP integral.
- 12 benchmarks nativos antes/depois, com resolução real 1600×900 e 1920×1080 e capturas. Smoke nativo Compatibility/OpenGL aprovado em 1600×900; não equivale a GP completo nesse renderer.
- 240 frames de movimento em 1×/16× sem sobreposição/atravessamento; 12 alternâncias de vista com nós estáveis. Não representa teste de temporadas longas.

## Pendência visual conhecida
A captura nativa e a Compatibility ainda mostram um leque escuro na junção da pista/boxes. O ensaio de ablação de sombras terminou, mas enquadrou outro trecho; portanto não isolou a causa do artefato. Não foi corrigido nesta versão e sombras não foram desabilitadas no produto. Reproduzir no mesmo enquadramento antes de alterar malha/material/sombras. Evidências em qa/geometry_0659/shadow_*.png e compatibility.json.png.

## Conteúdo e reprodução
Projeto Godot completo, assets, cenas, scripts, testes, documentação, logs, JSONs e capturas. Abra project.godot no Godot 4.7.2 e pressione F5; linux/run_apex.sh aceita GODOT_BIN. F8 abre o profiler. Saves de testes foram isolados, sem usar os do jogador.

BUILD_MANIFEST_0659.json registra SHA-256 dos arquivos distribuídos. A verificação externa VERIFICACAO_ZIP_0659.json registra CRC, hash do ZIP, importação e regressões em extração limpa. Essa verificação é posterior ao empacotamento; consulte seu resultado antes de considerar o pacote validado.

## Próxima versão
v0.6.6.0: Deterministic Simulation & Replay, conforme docs/PLANO_ENGENHARIA_0660.md. Não implementada nesta entrega. Pesquisa técnica e diário acompanham o projeto. Não foi incorporado código ou asset de F1 Manager/Motorsport Manager.
