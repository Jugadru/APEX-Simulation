# v0.5.5.2 — Desgaste e estratégia de pneus em chuva

- Correção do caso de IA mantendo W gasto até 100% durante dezenas de voltas.
- Repetição permitida do mesmo composto no pit (W→W e I→I), sem alterar as escolhas de tempo seco de cada GP.
- Estimativa de vida útil em voltas até o limite do composto, incluindo água e severidade.
- Failsafe de 93% de desgaste durante a volta para qualquer carro da IA, respeitando ordens já feitas e proximidade do final.
- Modesto arrefecimento térmico dependente da água; curva I/W de v0.5.5.1 inalterada.
- Eventos `strategy` registrados no rádio/telemetria quando a IA faz uma chamada de box.
- Regressão offline e roteiro de teste nativo incluídos.

Nenhuma modificação: motor dos boxes, double stack, mundo 3D, câmeras, HUD.
