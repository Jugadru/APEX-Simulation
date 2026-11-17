# APEX Motorsport Manager v0.6.6.8.1 — HUD ReBroadcast 2.0 QA

**Escopo único:** correção da apresentação de comandos pendentes e expansão dos testes da HUD existente. **Sem alterações esportivas no Core 2.**

## Alterado

- `scripts/apex_hud_rebroadcast_0668.gd`: projeção **somente leitura** de comandos de pit ainda não aplicados pela fila determinística, com estados P21/PBOX/CANC e descrições contextualizadas.
- `scripts/apex_hud_rebroadcast_0668.gd`: exibição FIN para carro terminado, preservando prioridade de DSQ/NC.
- `scripts/apex_race_hud_0622.gd`: classificação e cards indicam **ordem pendente** antes da confirmação; o botão CHAMAR BOX não fica habilitado enquanto houver pedido em fila.
- `scripts/apex_race_hud_0622.gd`: atualização condicional de texto na barra de volta e relógio, evitando atribuições repetidas quando nada mudou.
- `project.godot` e `scripts/main.gd`: identificação de v0.6.6.8.1, sem mudar save path nem `run/main_scene`.

## Adicionado

- Regressão nativa de 30 verificações para agendamento V21, cancelamento, ordem imediata e inalterabilidade do hash.
- Validação de quatro circuitos com a HUD ativa por pelo menos três voltas de cada GP (sem alegar GP completo).
- Teste de persistência de modo em dois processos Godot separados.
- Novas capturas reais Godot/Xvfb com indicação pendente em BROADCAST, COMPACT, FULL e 3D.
- Relatório técnico, matriz de testes, benchmark com 5 amostras e instruções de rollback.

## Preservado

- Core 2, física, Driver Dynamics, IA, Pit Wall, Strategy Simulator, replay esportivo, telemetria, Factory, rádio, mapa, Diretor TV, circuito 3D e carreira.
- `config/custom_user_dir_name="APEX_0650_SOUL_STAFF"`.

**A versão permanece experimental** enquanto faltarem testes visuais na GPU real do PC-alvo e GPs completos nas outras pistas.
