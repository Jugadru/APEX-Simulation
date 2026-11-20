# APEX Motorsport Manager — v0.6.4.9.9

## Strategy Simulator 1.0 — CONSULTIVO

Base integral: **v0.6.4.9.8 Gráficos Dinâmicos**. Uma única funcionalidade principal nesta versão: **comparação de cenários de pit stop entre a entrada seguinte e as cinco voltas posteriores**, para ambos os carros da equipe.

### Abrir e usar

1. Extrair o ZIP completo e abrir o `project.godot` no **Godot 4.7.2**.
2. Iniciar um GP. Na HUD híbrida, clicar **ESTRAT. → SIMULADOR 9.9**. Alternativamente, usar o atalho no **Pit Wall 3.0**, **Race Engineer 3.0** ou nos **Gráficos 9.8**.
3. Em cada cartão, selecionar **AGORA**, **+1V**, **+2V**, **+3V**, **+4V** ou **+5V**. O painel calcula a posição de retorno estimada, tráfego próximo, desgaste futuro, clima e risco de garagem.
4. Consultar a explicação do Race Engineer. A comparação **não agenda parada nem muda de pneus**. Para agir manualmente, usar os controles originais de **ESTRATÉGIA**.

### Origem dos dados e limitações

- **Progresso e classificação**: posições reais dos 24 carros e progresso contínuo do motor.
- **Ritmo futuro**: último tempo de volta válido de cada carro; até existir tempo válido, recorre-se à volta-base *real do circuito no motor* e marca-se baixa confiança.
- **Pit stop**: perda de box calculada para o circuito pelo motor, aplicada uma vez a cada cenário. As entradas respeitam a fração da volta do pit lane (95%) usada pela simulação.
- **Pneus**: desgaste real do carro, taxa medida entre voltas da 9.8 quando disponível ou taxa do modelo do Race Engineer, e cliff da especificação de pneu do GP.
- **Clima**: água atual e previsões nativas do motor para 3 e 6 voltas, interpoladas dentro de uma janela de até cinco voltas.
- **Garagem**: ordem confirmada do companheiro, serviço em andamento e janela recomendada pelo engenheiro; aviso potencial não é double stack confirmado.
- **Rival**: adversário mais próximo à frente no instante da consulta. O texto descreve o confronto relativo e, quando suportado pelos números, potencial de undercut/overcut.
- **Não modelados**: futuras paradas dos rivais, acidentes, mudanças estocásticas de desempenho, erros de equipe, evolução exata do ritmo, reordenações por ultrapassagem e precisão além do horizonte. A classificação pós-box é uma **projeção**, não um resultado de corrida garantido.

O sistema não chama `schedule_pit`, `request_pit`, `step`, modifica a IA, reescreve carros ou consome RNG. Selecionar um cartão só muda o que é destacado no painel de consulta. O modo Automático continua sob controle da v0.6.4.9.7.

### Arquivos de implementação

- `scripts/core/race_strategy_simulator_06499.gd` — projeções puras, com seis alternativas por carro.
- `scripts/apex_race_hud_0622.gd` — nova janela vinculada à HUD híbrida e aos painéis existentes.
- `tests/strategy_simulator_06499_model_test.gd` — limites, pureza e conflitos nos três circuitos.
- `tests/strategy_simulator_06499_ui_test.gd` — validação nativa visual 1600×900 e 1920×1080.
- `tests/strategy_simulator_06499_three_gp_test.gd` — corridas completas e comparação de projeções com pits reais, quando disponíveis.
- `qa/06499/` — resultados reais da verificação por circuito.
- `docs/APEX_06499_*.png` — capturas geradas a partir da janela real do Godot.
- `BUILD_MANIFEST_06499.json` — comparação SHA-256 com a base 9.8.

### Estado do projeto

A v0.6.4.9.9 não habilita uma nova IA de execução. Nenhuma funcionalidade da 0.6.4.9.10 é iniciada. Os arquivos anteriores foram preservados e o motor de corrida é byte a byte o mesmo da v0.6.4.9.8.
