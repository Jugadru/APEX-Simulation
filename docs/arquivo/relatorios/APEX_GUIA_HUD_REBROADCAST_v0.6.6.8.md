# Guia rápido — HUD ReBroadcast 2.0

Abra `project.godot` no Godot **4.7.2** e inicie uma corrida. O seletor no alto à direita permite escolher:

| Modo | O que muda |
|---|---|
| **BROADCAST** | Pista, leaderboard de 24 pilotos, cronômetro, previsão do clima e minimapa; cards dos pilotos ocultos |
| **COMPACT** | Modo padrão. Mantém os dois cards da equipe com **SEGUIR**, **CHAMAR BOX**, estado de pneus e ritmo |
| **FULL** | Acrescenta um painel de acesso rápido a **Resumo, Plano, Decisão e Análise** sem substituir os sistemas já existentes |

## Comandos reais disponíveis

- **Classificação:** clique na sigla de um piloto para selecionar/seguir. O botão ‹/› na tabela alterna entre intervalo, líder, pits, melhor volta, pneus, atrás e última volta.
- **Cards dos pilotos:** **SEGUIR** seleciona a câmera; **CHAMAR BOX** usa o comando oficial. Os botões T/D/E/C abrem contextos de Telemetria, Desempenho, Estratégia e Carro.
- **Planejamento de paradas:** em **ESTRAT.**, selecione o composto e a volta e pressione **AGENDAR**. A ordem passa pelos validadores/filas existentes; o modo visual não altera prioridade.
- **Modo FULL:** Resumo (Pit Wall 3.0), Plano (Estratégia), Decisão (Engenheiro), Análise (Gráficos).
- **Velocidade:** controle central 1×, 2×, 5×, 10×, 16× e 32×. O modo automático mantém a política existente: 3D até 5× e mapa 2D acima disso.
- **Persistência:** o último modo é salvo em `user://hud_rebroadcast_0668.cfg`. Se o arquivo não existir, o padrão é **COMPACT**.

O status **V21** ao lado de um piloto representa uma parada **agendada** para a volta 21, não uma ordem para entrar imediatamente. Ordens automáticas não podem substituir indevidamente uma reserva manual protegida. A legenda detalhada pode ser consultada no tooltip do piloto.

## Requisitos e limitações

- Compatível com o projeto Godot original; engine oficial não foi modificada.
- Capturas fornecidas correspondem à abertura de Silverstone, 2D ou 3D, não a GPs completos.
- Cada corrida real deve ser validada no PC do usuário antes de usar esta versão como distribuição estável.
