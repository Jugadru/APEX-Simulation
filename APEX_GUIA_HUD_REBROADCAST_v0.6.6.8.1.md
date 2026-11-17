# Guia rápido — ReBroadcast 2.0 QA (v0.6.6.8.1)

A HUD de corrida tem três modos no seletor do canto superior direito:

- **BROADCAST**: classificação, clima e minimapa com o maior espaço de pista.
- **COMPACT**: o modo padrão com cards e comandos dos dois pilotos.
- **FULL**: além dos cards, acesso direto às janelas reais de resumo, plano, decisão e análise do Pit Wall.

## Ordens de box na fila

- **P21**: ordem de parada na volta 21 **pendente de aplicação**, não é uma confirmação.
- **V21**: parada na volta 21 aceita pelo motor.
- **PBOX**: comando de chamar box **pendente**; após aplicação, o status real é **BOX**.
- **CANC**: cancelamento do agendamento ainda na fila; aguarde a aplicação no próximo tick.
- **PIT**: carro em atendimento ou passagem pelos boxes.
- **FIN / DSQ**: finalizado/desclassificado conforme estado real.

O usuário deve conferir a dica ao passar o mouse sobre a classificação ou botão para detalhes da ordem. Uma recomendação automática não substitui o agendamento V21 protegido.

## Comandos

Selecionar piloto na tabela ou usar SEGUIR nos cards. Para box, use CHAMAR BOX ou abra o contexto Estratégia e selecione pneu/volta. **Uma ordem pendente é mostrada, mas só passa a confirmada após o tick da simulação.** Todos os comandos continuam nos validadores existentes.

O modo fica salvo em `user://hud_rebroadcast_0668.cfg`, separado do save de carreira.

## Limitações conhecidas

No ambiente Xvfb, o pedido 1366×768 gerou imagem real de 1365×768; validar num monitor real. Capturas e testes virtuais não garantem FPS no hardware do usuário.
