# APEX Motorsport Manager v0.6.4.1 — Como abrir e testar

1. Extraia **todo o ZIP** em uma pasta separada das versões anteriores.
2. Abra o **Godot 4.7.2**, escolha **Importar** e selecione o arquivo `project.godot` dentro de `APEX_GODOT_0.6.4.1_WEATHER_STRATEGY`.
3. Clique em **Importar e editar**, depois **F5** para abrir o Apex.
4. Para testar a temporada, selecione Ferrari, modo **Automático**, clima **Automático**. A interface preserva a central **ENG.** e os modos por piloto Manual/Assistido/Automático.
5. Para testar o equilíbrio de chuva, execute o cenário de Malásia/China/Espanha; um piloto ainda pode parar várias vezes se houver transições de pneus necessárias ou desgaste crítico.

### Linha de comando (Linux)

```bash
# Executar o projeto (substitua o caminho e o nome do executável)
./Godot_v4.7.2-stable_linux.x86_64 --path "/CAMINHO/APEX_GODOT_0.6.4.1_WEATHER_STRATEGY"

# Teste rápido do equilíbrio meteorológico e IA
./Godot_v4.7.2-stable_linux.x86_64 --headless --path "/CAMINHO/APEX_GODOT_0.6.4.1_WEATHER_STRATEGY" --script res://tests/core_0641_weather_strategy_test.gd
```

**Importante:** o ZIP contém o projeto Godot (cenas, scripts, dados, 2012 e testes), e não inclui o executável de 140 MB do Godot. O Godot recria a pasta `.godot` de cache ao importar.

O relatório de desempenho se refere a testes em Linux de laboratório; a abertura em seu computador pessoal precisa ser confirmada. Este jogo usa pilotos e temporadas históricos de maneira simulada, não registra falas ou dados reais de F1.
