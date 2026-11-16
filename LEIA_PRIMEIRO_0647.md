# APEX MOTORSPORT MANAGER — v0.6.4.7

## Apex Soul Driver 2.0 · Pacote completo (Godot 4.7.2)

**Base real:** Apex v0.6.4.6 Race Engineer 3.0 com HUD híbrida 0.6.3.5/0.6.4.5.

### Mecânicas efetivamente implementadas

- **Traços fictícios por piloto, determinísticos:** temperamento, iniciativa, sensibilidade subjetiva dos pneus e trabalho em equipe. O modelo não atribui essas características como fatos sobre os pilotos históricos.
- **Atualização por volta no motor:** a alma avança em `race_engine.gd` no cruzamento da linha, mesmo com a HUD fechada. Confiança, pressão, foco, moral e percepção de pneus evoluem. Os registros são limitados a dez notas contextuais; o histórico emocional base a oito entradas.
- **Pedidos contextuais por piloto:** revisão do plano confirmado; avaliação de box por pneus/chuva; pedido de troca de posições para avaliação pelo chefe, quando o piloto está imediatamente atrás do companheiro e sustentou maior ritmo; diagnóstico de perda de ritmo; proposta de estender stint em condições limitadas. Pedidos não executam ações.
- **Pedido pelo rádio:** notificação única por pedido e piloto, acesso via `RÁDIO`, mensagem com motivo, fase da volta, status "aguardando/respondido".
- **Interação da direção:** `OUVIR PEDIDO` e `EXPLICAR PLANO` registram resposta apenas no estado Soul, alterando confiança na equipe e moral. São diferentes de `CHAMAR BOX`, de ordem de ritmo ou de troca de posições.
- **Painel ENG.** continua exibindo Race Engineer 3.0 e o resumo SOUL 2.0.
- **Visual:** grafite/laranja da HUD híbrida mantido. Capturas reais em `docs/APEX_SOUL2_*.png`.

### Proteções explícitas

- Não alteramos fórmulas de desgaste, temperatura, clima, aerodinâmica, desempenho, posições, física ou RNG.
- O piloto pode **pedir** para estender stint ou questionar uma parada, mas a IA do motor e ordens manuais preservam autoridade.
- **Pit agendado V21:** o piloto pode pedir revisão, mas nenhum pedido nem resposta antecipam ou cancelam o agendamento.
- **Troca de posições:** apenas pedido de avaliação; nenhuma ordem de equipe ou ultrapassagem forçada foi implementada.
- **Persistência:** estado Soul é de **um GP**, reiniciado ao iniciar outra corrida. Não existe ainda memória de carreira de longo prazo.
- A versão usa a pasta de saves isolada `ApexMotorsportManager_Soul2_0647`; saves da base não são sobrescritos por padrão.

### Arquivos de código modificados

- `scripts/race_engine.gd`: somente troca do módulo Soul para 0647, descoberta de companheiro e chamada da atualização ao cruzar a linha.
- `scripts/apex_race_hud_0622.gd`: rádio contextual, resposta, cartões, painel ENG. e notificações.
- `scripts/core/race_driver_soul_0647.gd`: novo módulo de motor (preserva os cálculos 0645 através de `BaseSoul.update`).
- `project.godot`: nome/descrição, save isolado.
- `tests/race_0647_soul2_test.gd`, `tests/race_0647_soul2_ui_test.gd`: novos testes.

### Como abrir

1. Extraia o ZIP inteiro para uma pasta nova.
2. Importe `project.godot` no **Godot 4.7.2**.
3. Execute com **F5** e comece um GP.
4. Durante a corrida, clique em **RÁDIO** para examinar os pedidos.
5. Clique em **ENG.** para a análise tática e estado emocional atualizado.

### Testes confirmados

Veja `RELATORIO_TESTES_0647.md`. Compilação, testes de interação, regressões 0646/0645/0644/0635/0637 e renderização no Godot 4.7.2 foram executados, com resultados específicos documentados.

**Limitação:** foi iniciada a bateria de um GP completo no passo nativo 0,20 s, mas a execução precisou ser interrompida no ambiente. Portanto, **não afirmamos** que este ZIP passou por um GP inteiro nem por oito GPs de regressão. O teste de **ao menos uma volta nativa** do motor e a suíte de proteção de ordens passaram.

### Próximas versões (não implementadas aqui)

Team & Staff Manager, Pit Wall & Estratégia 3.0 e memória de carreira persistente permanecem para versões futuras.
