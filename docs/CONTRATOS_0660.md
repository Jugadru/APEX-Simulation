# Contratos 0660 — 14/11/2026
Base 0659 verificada por SHA-256, CRC e 1995 hashes. Escopo principal: ticks fixos de 0,20 s (passo máximo já usado pelo Core 2), comandos ordenados, codec com RNG, checkpoints e replay isolado. Complemento autorizado pelo usuário: cenário/boxes/equipe/zebras, sem efeito esportivo; medir custo nativo.

Motor continua autoritativo. Chamadas externas de comandos são validadas e enfileiradas para o próximo tick; chamadas internas durante tick não são reenfileiradas. Controle de Staff pertence à sessão determinística. Autonomia é recalculada em cada tick com estado/configuração congelados; não é simultaneamente gravada e reaplicada. Input Manual/Assistido/Automático explicitado no log.

Estado capturado inclui variáveis de script do motor e subobjetos de clima, pista e telemetria, seed/state do RNG. Reflexão é limitada a objetos conhecidos; arquivo Variant sem objetos, schema/runtime e checksum. running e cache de aconselhamento não integram o hash esportivo. Sem serializar cenas, Callables ou referências externas. Restauração deve ser atômica após validação.

Replay usa motor separado e nunca chama inventário ou commit de campeonato. Ao sair, restaura a sessão ao vivo e preferências. Checkpoint inicial e a cada 300 ticks (60 s), retenção de oito checkpoints mais inicial; comandos e hashes mantidos até 400000 ticks (~22,2 h), gravação deve sinalizar limite. Seek pode reconstruir do inicial quando checkpoint antigo foi descartado. CPU/memória e limites serão medidos.

Aceitação: round-trip, mutação isolada, RNG, comandos na fronteira, pausa/backlog, diferentes FPS e velocidades, chuva/pit/serviço/reparo, classificação, rejeição de arquivos inválidos sem mudar corrida/save. Não prometer igualdade entre plataformas. Passo fixo altera sequência numérica da base variável; registrar divergência como mudança de contrato, não alegar paridade 0659.

Medição inicial a 0,05 s: ~3,98 ms de motor e 2,65 ms de hash por tick em headless. Adotado 0,20 s para manter o passo nominal existente e orçamento em aceleração; cap de 16 ticks por frame sem descarte de backlog. Sem prometer 32× em toda carga.
