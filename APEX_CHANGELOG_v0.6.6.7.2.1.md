# Changelog — APEX v0.6.6.7.2.1

- Corrigida velocidade inicial da corrida de 5x para 1x.
- Restabelecido 1x no início de cada novo GP, mesmo depois de uma corrida em 5x/16x/32x.
- Adicionado seletor visível de velocidades no transporte compacto (1x/2x/5x/10x/16x/32x).
- Removida troca involuntária de 3D para mapa 2D ao mudar a velocidade.
- Implementada interpolação visual entre estados concluídos consecutivos do motor, usando a fase do tick de 0,20s.
- Preservada compatibilidade de chamadas anteriores ao construtor de apresentação e do replay APEX_REPLAY_0660.
- Acrescentados testes de velocidade, continuidade, pausa, seek, interface e regressões esportivas em quatro pistas.
- Nenhuma alteração de física, IA, boxes, pneus, clima ou resultados esportivos.
