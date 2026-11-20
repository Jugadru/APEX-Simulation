# APEX MOTORSPORT MANAGER — v0.6.4.3 / DYNAMIC TRACK WEATHER

## Instalar / importar no Godot 4.7.2 (Linux Mint)

1. Extraia o ZIP **inteiro** em uma nova pasta. Evite sobrepor a pasta do projeto antigo.
2. No **Godot 4.7.2**, clique em **Importar** e selecione `project.godot` dentro da pasta extraída.
3. Abra o projeto e pressione **F5**.
4. Para conferir as melhorias: abra um GP, selecione clima **Variável**, **Automático** ou **Chuva intensa**, pressione **DADOS** na barra superior e veja a seção **CLIMA E PISTA**.
5. A caixa de clima no canto direito informa **mm na pista**, **umidade residual do asfalto**, **intensidade atual da chuva** e **previsão**. A Central de Dados compara ainda a linha de corrida e a área fora dela, com previsão para ~3 voltas.

**Importante:** faça backup dos salvamentos da versão anterior. Não alteramos deliberadamente o formato do save, mas toda migração para uma nova versão deve ser testada no computador do jogador.

## Novos indicadores

- `rain_intensity`: intensidade da chuva em andamento (0–100%).
- `surface_moisture`: umidade residual do asfalto (0–100%), continua após o fim da chuva.
- `water_mm`: água acumulada na **linha de corrida**, em milímetros fictícios calibrados para gameplay.
- `off_line_water_mm`: água fora da linha de corrida; em geral seca mais devagar.
- `wetness_factor`: valor normalizado usado pelo motor de pneus/aderência, agora baseado **na água existente**, e não diretamente na chuva.
- `forecast()`: projeção usando o mesmo integrador climático da corrida, com tendência da água na linha.

## IA de pit stops

No automático, o engenheiro precisa de **água na pista e tendência coerente** para recomendar trocar slicks→intermediários→chuva. Chuva no céu, sozinha, não justifica troca. As regras de desgaste crítico, ordens manuais agendadas e double stack da versão anterior continuam ativas.

## Limitações do modelo

É um **modelo original simplificado**, não reproduz o código de F1 Manager ou Codemasters. Ainda não há sensores de temperatura físicos, poças simuladas por curva, hidrodinâmica real nem trilha de pneus 3D molhada. A umidade é global com uma aproximação de linha de corrida versus fora da linha. Os valores em milímetros são internos ao simulador; não foram medidos em provas históricas da F1.

Leia `RELATORIO_0643_TESTES.md` para resultados efetivamente executados e limites da validação.
