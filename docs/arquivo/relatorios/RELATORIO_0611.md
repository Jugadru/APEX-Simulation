# Relatório — Apex 0.6.1.1 Hotfix mapa e previsão

Data: 06/11/2026. Projeto copiado do ZIP v0.6.1 fornecido nesta conversa.

## Feedback do teste no Linux Mint
- Temporada acumulou pontos corretamente: confirmado pelo jogador.
- Melbourne 2012 com seis paradas: comportamento considerado incompatível com o padrão histórico de duas paradas; **não corrigido neste hotfix** para preservar a IA funcional.
- Mapa 2D com grades/setores e HUD ocupando espaço: alteração feita no renderizador e layout para mapa de cima com bolinhas e menos sobreposição.
- Probabilidade para próximos 15 minutos constante: corrigido por nova função de previsão móvel, que usa o relógio e episódios climáticos sorteados.
- Desgaste por volta de 50%: verificar a política de pit e ritmo da IA; não há limite de desgaste de 50% imposto no código (há limiar preditivo de 54%).

## Validação executada neste ambiente
- Python 3: disponível.
- Integridade da fonte ZIP anterior: verificada.
- Teste novo `tests/test_0611_static.py`: PASSOU.
- Comparação SHA-256 de nove arquivos críticos com a v0.6.1 anterior: todos idênticos.
- Bateria histórica não migrada: 22/31 PASSAM; nove falhas são checagens de arquivos antigos imutáveis (mapa 2D), nomes antigos da HUD ou arquivo de preferências legado, itens intencionalmente alterados. Não foram removidas nem mascaradas.
- Godot headless: não disponível neste ambiente. Renderização da HUD, cálculo real da previsão e teste de 58 voltas ainda pendentes no Linux Mint.

## Testar no Linux Mint
1. Abra o `project.godot` do novo diretório pelo Godot 4 e pressione F5.
2. Selecione GP avulso de Spa, visual `Mapa estratégico` e 5x: circuito inteiro, carros como bolinhas, sem setor neon.
3. Confira HUD compacta, cartões recolhidos, painel de posições à esquerda, Pit Wall à direita.
4. Na aba CHUVA, avance 10–20 minutos simulados e observe o risco de 15 minutos variar; repita com semente diferente.
5. Para testes automatizados: `bash linux/validar_0611.sh`.
6. Para medir a quantidade de pits no cenário seco: `godot --headless --path . --script res://tests/diagnostico_melbourne_pits.gd` (ou use o caminho do executável Godot 4).

## Próximo trabalho planejado: reforma da IA
- Registrar por piloto/pit a causa da parada, desgaste e voltas desde último pit.
- Avaliar custo de pit vs ritmo perdido até a chegada e capacidade de completar os stints.
- Ajustar influência do ritmo Atacar no desgaste; hoje o coeficiente de desgaste é 1.34.
- Evitar trocas repetidas antes do limite real, sem forçar máximo de paradas por código.
- Cobrir Melbourne/2012 com sementes e cenários variados, distinguindo corrida seca, chuva e incidentes.
