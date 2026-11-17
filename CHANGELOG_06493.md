# Apex v0.6.4.9.3 — Balanceamento pontual de Pit Stops

Base: v0.6.4.9.2 Double Stack (com memória de pit 0.6.4.9.1).

## Uma mudança de comportamento nesta versão

Em `scripts/core/race_ai_director.gd`, a IA deixa de tratar um ganho **apenas preditivo** como ordem imediata para trocar **intermediário por intermediário** ou **chuva por chuva** quando todas as condições a seguir são verdadeiras:

- Troca por exatamente o mesmo composto de chuva;
- Desgaste atual menor que 64%;
- Vida restante até o cliff estimado acima de 2 voltas;
- Pneu não classificado como crítico.

Nesse caso a recomendação é reavaliada na volta seguinte. O gatilho `Strategy.pit_choice` por proximidade do cliff ou desgaste crítico, a histerese de chuva e o crossover entre compostos continuam autoritativos. Paradas manuais, agendamentos e pitwall49_held permanecem intactos.

**Não mudou:** curvas de desgaste, física térmica, clima, tempo de boxes, dupla parada, staff, modo de rádio, Soul Driver, Race Engineer ou indicador de confiança.

## Por que

Em Silverstone de clima variável, o horizonte de nove voltas da IA provocava 12 trocas de intermediários por intermediários em torno de 52% de desgaste pouco antes de o circuito secar. A proteção evita gastar uma parada sem benefício suficiente quando o pneu ainda dispõe de margem segura. O limiar 64% é um parâmetro de balanceamento original APEX, não dado real da Pirelli.

## Evidências

- `tests/pit_balance_06493_threshold_test.gd`: cenário de 57% / 62%, desgaste alto 72% e crítico 91%, validação do planejador seco e V21.
- `tests/pit_balance_06493_silverstone_full_gp_test.gd`: Silverstone 52v / 24 carros / seed 6403 / 0.20s, GP completo.
- `qa/06493/GBR_COMPARACAO.json`, `qa/06493/SILVERSTONE_COMPARACAO_06492_06493.csv` e `qa/06493/native_020/GBR.json`.

A classificação de Silverstone permaneceu válida. As filas de double stack observadas anteriormente não foram corrigidas aqui; o ajuste de confiança estratégica fica para a v0.6.4.9.4.
