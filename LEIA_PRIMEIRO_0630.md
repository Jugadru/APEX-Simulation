# Como abrir o Apex v0.6.3.0 no Linux Mint

1. Faça backup da pasta atual da v0.6.2.9. Não extraia esta versão por cima de uma instalação antiga.
2. Extraia **o ZIP inteiro**.
3. Abra **Godot 4.7.2**, importe `APEX_GODOT_0.6.3.0_ESTRATEGIA/project.godot` e pressione **F5**.
4. Selecione equipe e circuito da temporada 2012. Inicie uma corrida. Abra **Rádio** e escolha o filtro da equipe.
5. As mensagens do piloto dependem dos fatos da corrida; normalmente surgem após desgaste, trânsito próximo ou mudança de condições. Nem toda volta produz mensagem.
6. Pit manual continua manual. Um pedido por rádio é só recomendação e **não** executa box. Pode continuar usando os modos de câmera já aprovados.

## Testes para reproduzir

Com o executável do Godot acessível no terminal, na pasta do projeto:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/core_0630_driver_radio_smoke_test.gd
godot --headless --path . --script res://tests/core_0625_dry_strategy_smoke_test.gd
godot --headless --path . --script res://tests/core_0627_tv_director_smoke_test.gd
godot --headless --path . --script res://tests/core_0629_environment_smoke_test.gd
```

## Limitações

O teste comparativo automatizado completou nove voltas idênticas nas versões 0.6.2.9 e 0.6.3.0 (mesmo seed, 24 pilotos). O teste comparativo de 800 passos excedeu o limite de execução deste ambiente, então **não se afirma que provas completas tenham sido validadas nesta entrega**. Avisos antigos de âncoras e `SubViewportContainer` persistem no Linux com Xvfb; sem erros novos de GDScript na abertura testada.
