# APEX 9.19 — Corner Battle Intelligence 1.0

Base integrada 9.18, PR 128, merge 957a1420, revisão 036. Nova revisão 037. Uma funcionalidade: julgamento de compromisso competitivo em curvas usando carga local e antecipada existentes.

- Fases esquemáticas: reta, entrada, ápice, saída por magnitude e tendência de carga; não identificação exata de curvas FIA.
- Entrada/ápice: vetar ataque tardio ainda sem corredor estabelecido quando exige deslocamento lateral elevado; janela de preparação aumenta com carga e água. Saída retorna ao julgamento anterior.
- Manobra estabelecida ao mesmo rival, separação lateral suficiente e corredor dentro do limite: manter posição atual em disputa próxima; não criar novo ataque nem defesa tardia. Estreitamentos, terceira viatura, flags, cooldown, coordenação 036 e solver têm prioridade.
- Sem bônus de velocidade, alteração de aderência, pneus, DRS, KERS, geometria ou pit; setup 9.18 intacto. Motivos observáveis na memória esportiva apenas em 037.
- Replays antigos mantêm flags e hashes; novo flag excluído do schema existente. Comparativos 036/037 de 1800 ticks em 3 circuitos x 2 climas x 2 seeds; hash histórico 036, determinismo e seek, 18 fixtures incluindo RaceSpace real, regressões aero/coordenação/setup e FAST+Lab. Sem FULL obrigatório, sem ativos privados, sem binário.
- Coeficientes são heurísticas a calibrar. Estado inicial NOT_RUN. Sem merge antes de aprovação no SHA exato e autorização. Rollback 957a1420.

## REV2 — correção após homologação inicial
CI inicial: Corner Battle 10/12, falhas reais de inversão em Monza seco seed 123 (11→14) e Mônaco seco seed 42 (56→67), sem sobreposição ou imobilização e sem perda de ultrapassagens nos 12 cenários. CI coordenação 11/12: fixture 13/13 aprovada, mas limpeza XDG/pulse falhou em Silverstone seco seed 42. Core 2 e aero PASS. Não houve merge. REV2 limita o bloqueio tático de corredor já ocupado ao ápice (o solver existente já protege entrada e saída), reduz a janela seca excessivamente conservadora de 4× para 2× carga e restringe veto a deslocamento acima de 1 unidade. Preserva janela adicional de chuva e todos os critérios de segurança/regressão. Limpeza do sandbox recebe três tentativas limitadas e preserva código de saída do teste, sem esconder falha real. Nova homologação obrigatória; resultados REV2 ainda NOT_RUN.
