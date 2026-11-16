# v0.6.6.1 — Advanced Racing AI / Driver Dynamics

Partir exclusivamente do ZIP 0660 validado. Ler limitações de replay, desempenho e cenário. Preservar HUD, geometria otimizada, oficina e formatos de saves. O formato APEX_REPLAY_0660 é restrito ao mesmo runtime e release; qualquer mudança esportiva requer versão de replay nova, sem fingir compatibilidade automática.

## Objetivo principal
Evoluir os estados de aproximação, preparação de ultrapassagem, defesa, sobreposição e desistência no motor autoritativo. Reutilizar RaceSpace, Combat e o log determinístico. Não introduzir controlador visual concorrente nem refazer os gráficos nesta etapa.

## Auditoria e contratos
- Mapear largura/curvatura, velocidade relativa, pneus, frenagem, aderência, espaço lateral e margens de contato.
- Definir transições explicáveis e temporais; distinguir decisão de risco de execução física.
- Defensor pode proteger uma linha de forma antecipada; não deve abrir caminho gratuitamente, bloquear de forma impossível ou atravessar o rival.
- Quem ultrapassa precisa de corredor e vantagem real. Sem espaço: recuar/seguir, sem troca artificial de posição.
- Personalidade influencia decisões moderadamente; separar ajuste calibrado de inferência sobre pilotos reais.

## Evidências de aceitação
Mesmos cenários/seed/inputs reproduzem hashes na própria versão. Cenários com dois carros e pelotão: retas, curvas estreitas, freada lado a lado, carros lentos, aproximação da emenda, pit entry/exit, seco e molhado. Medir ultrapassagens válidas, ataques abortados, defesas, contato/swept overlap, oscilação de faixa e posições ganhas sem espaço.

GBR/BEL/ITA/SIN e duas pistas sorteadas, replay do início e restore durante disputa. Checar 1×/2×/5×/16×/32×, renders 2D/3D e variações de FPS. Custos em 900p/1080p, captura visual real e Compatibility. Publicar mudanças de resultados em relação à 0660: nova IA deve mudar decisões, não ocultar diferenças de comportamento como otimização.

## Entrega
Uma funcionalidade principal, relatório, benchmark, diário, testes e ZIP completo reextraído/importado/verificado. Só depois planejar 0662 (personalidade/rádio), sem iniciar em paralelo. Melhorias maiores de modelos, paisagem, iluminação e câmera continuam na 0664; os detalhes visuais pontuais autorizados na 0660 não equivalem à entrega dessa fase inteira.
