# Limitação conhecida: testes legados de double stack

Executados `double_stack_smoke_test.gd` e `pit_incidents_double_stack_test.gd` nas versões 0.6.4.9.1 e 0.6.4.9.2. Ambos exibem falhas de asserção no cenário sintético antigo, porque não observam a sobreposição esperada. As asserções interrompem o script de teste e o processo precisa ser encerrado por timeout. Esses dois testes **não são PASS**, nem evidência de regressão causada pela 0.6.4.9.2. O novo teste `double_stack_06492_entry_test.gd` e o cenário controlado antes/depois foram adicionados para exercitar o estado de fila real e o comportamento seguro.

Importante: os casos sintéticos com fila forçada não substituem testes variados de corrida e estratégias reais. O GP completo de Silverstone em clima variável passou, mas permaneceu igual ao da versão anterior.
