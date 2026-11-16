# Long Race Performance 1.0 — Decisão arquitetural

A v0.6.6.2 utilizava o checkpoint inicial mais oito estados intermediários, descartando checkpoints antigos à medida que o controlador avançava. Cada checkpoint intermediário continha cópias profundas do estado completo, incluindo **toda a telemetria acumulada** até o tick. Em corridas longas, uma fatia crescente de histórico era duplicada diversas vezes na memória.

Na v0.6.6.3, cada checkpoint periódico é transformado imediatamente em um `PackedByteArray` comprimido via ZSTD, acompanhado do tamanho do estado descomprimido. `Codec.capture()` continua sendo a fonte oficial; `seek()` reconstrói o mesmo dicionário antes de `Codec.restore()`. A forma pública de `checkpoint()` e o envelope de replay em disco não mudam. `load_data` valida primeiro o arquivo legado, depois compacta os checkpoints intermediários para retenção durante a reprodução.

O limite de descompressão (`MAX_STATE_BYTES=128 MiB`) evita tentar decodificar estados internos com tamanhos absurdos; esse limite não altera resultados de corrida. Não houve poda dos logs, nem exclusão de telemetria histórica, mudança de hash, redução de resolução temporal, de número de carros, de regras ou da lógica de ultrapassagem.

O observador de eventos do Racecraft utiliza o `event_id` monotônico e o buffer `race.events` em ordem temporal. Procura retroativamente a primeira posição com evento novo e em seguida percorre **para a frente** todos os eventos relevantes. Assim mantém a ordem dos contadores e evita uma varredura de até 140 eventos em ticks sem novidade.

A redução no consumo de memória não garante, por si só, que todos os circuitos/distâncias terminem em tempo aceitável. O desempenho de corrida longa e a fidelidade do replay são auditados separadamente. Reproduções antigas só são declaradas compatíveis quando o estado é carregado e os hashes de todos os ticks percorridos coincidem.
