# Próxima versão — 0.6.6.0 Deterministic Simulation & Replay

## Entrada e escopo
Usar ZIP 0659 validado, plano mestre unificado, logs e limitações. Uma funcionalidade principal: reprodução determinística de corrida e comandos. Não refazer geometria nem alterar equilíbrio de pilotos/estratégia nesta entrega. Pesquisa específica GitHub/Godot antes da implementação.

## Auditoria obrigatória
Mapear race_engine.step/_advance, chamadas de autonomia em main, RaceCommands, RaceSessionController, clima, estratégia, telemetria, RNG e todos os pontos em que UI ou callbacks podem executar decisões. Atualmente mesma sequência de chamadas tem paridade, mas velocidade/FPS podem mudar a sequência de dt e de decisões. Não declarar essa diferença resolvida pela seed.

## Contratos propostos (novos, a confirmar após auditoria)
- RaceCommandLog: eventos imutáveis {tick, sequence, actor, type, payload}; input validado, ordem estável e origem Manual/Assistido/Automático.
- RaceTickScheduler: acumulador de tempo e tick lógico; render/sim_speed decidem quantos ticks consumir, não o tamanho nem a ordem lógica de cada atualização. Tratar pausa, avanço rápido, conclusão e backlog sem perder ticks.
- RaceStateCodec: capture_state/restore_state/canonical_hash; schema versionado, IDs, RNG state/seed, relógio, clima, pneus, filas, recursos e decisões pendentes. Nada de referências a nós de apresentação.
- RaceReplay: checkpoint, comandos posteriores, seek, comparação de hashes e primeiro tick divergente. Restaurar sem duplicar eventos, efeitos financeiros ou observações de inventário.

## Integração
Motor mantém autoridade; apresentação consome snapshots compactos. Geometria é derivada e reconstruída por revisão, não serializada como nós ou caches. Rádio/TV não consomem RNG esportivo. Estratégia automática é gravada ou recalculada sob contrato explícito, nunca as duas coisas na reprodução. Interfaces de gerenciamento recebem transações/eventos idempotentes.

## Implementação em etapas dentro da mesma entrega
1. Baseline reproduzível 0659 com mesma seed/ordens e sequências atuais; identificar diferenças entre taxas antes de corrigir.
2. Codec e hash canônico com teste de round-trip; separar estados necessários de dados derivados.
3. Log de comandos/ordem temporal; fixture com comando exatamente na fronteira de tick.
4. Scheduler fixo, com política explícita para autonomia/clima e callbacks. Registrar qualquer diferença esportiva causada por normalizar dt em vez de escondê-la.
5. Replay e checkpoints; testes no meio de fila de box, reparo, chuva, duelo, volta e término.
6. UI mínima de diagnóstico/replay apenas se backend funcional; preservar HUD aprovada.
7. Import, regressões, benchmark, save legado, ZIP/manifesto e extração limpa.

## Aceitação
Mesma configuração e log de comandos → mesmos hashes por tick e resultado no mesmo runtime/plataforma, com 1×/2×/5×/16×/32×, pausa/resume e render headless/2D/3D. Taxas de frames variadas não podem modificar a ordem dos comandos. Não prometer igualdade cross-platform de ponto flutuante sem teste.

Silverstone, Spa, Monza, Singapura e duas pistas sorteadas; seco, chuva/transição, dois pilotos, double stack e ordem manual V21 sob chuva V4. Reproduzir classificação, tempos, RNG, estratégias e inventário sem efeitos duplicados. Testar replay inválido/incompatível com mensagem clara e sem sobrescrever save.

## Riscos e métricas
Estado omitido, ordem instável de Dictionary, callback reexecutado, RNG compartilhado, dependência de wall-clock e salvar referências vivas. Medir bytes/checkpoint e log, tempo de captura/restore/seek, CPU por tick, carregamento e memória. Não armazenar cópia profunda de todo o mundo a cada frame. Definir retenção e frequência com evidências, não valores arbitrários.

Depois: 0661 IA de disputas; 0662 personalidade/rádio; 0663 estratégia; 0664 apresentação; 0665 P&D; 0666 Staff; 0667 fábrica; 067x carreira. Não iniciar esses sistemas na 0660.
