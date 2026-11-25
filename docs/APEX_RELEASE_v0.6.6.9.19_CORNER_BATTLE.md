# APEX 9.19 — Corner Battle Intelligence 1.0

Base integrada 9.18, PR 128, merge 957a1420, revisão 036. Nova revisão 037. Uma funcionalidade: julgamento de compromisso competitivo em curvas usando carga local e antecipada existentes.

- Fases esquemáticas: reta, entrada, ápice, saída por magnitude e tendência de carga; não identificação exata de curvas FIA.
- Entrada/ápice: vetar ataque tardio ainda sem corredor estabelecido quando exige deslocamento lateral elevado; janela de preparação aumenta com carga e água. Saída retorna ao julgamento anterior.
- Manobra estabelecida ao mesmo rival, separação lateral suficiente e corredor dentro do limite: manter posição atual em disputa próxima; não criar novo ataque nem defesa tardia. Estreitamentos, terceira viatura, flags, cooldown, coordenação 036 e solver têm prioridade.
- Sem bônus de velocidade, alteração de aderência, pneus, DRS, KERS, geometria ou pit; setup 9.18 intacto. Motivos observáveis na memória esportiva apenas em 037.
- Replays antigos mantêm flags e hashes; novo flag excluído do schema existente. Comparativos 036/037 de 1800 ticks em 3 circuitos x 2 climas x 2 seeds; hash histórico 036, determinismo e seek, 18 fixtures incluindo RaceSpace real, regressões aero/coordenação/setup e FAST+Lab. Sem FULL obrigatório, sem ativos privados, sem binário.
- Coeficientes são heurísticas a calibrar. Estado inicial NOT_RUN. Sem merge antes de aprovação no SHA exato e autorização. Rollback 957a1420.
