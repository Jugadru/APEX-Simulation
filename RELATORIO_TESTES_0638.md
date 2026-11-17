# Apex Motorsport Manager v0.6.3.8 — Relatório de testes

**Ambiente:** Godot oficial 4.7.2 estável (Linux x86_64), projeto Godot real em execução headless; interface em tela virtual OpenGL de 1600×900. **Não se trata de resultados históricos de F1 2012.**

## Testes completos do motor

| Cenário | Distância | Clima | Pits totais | Gaps | Resultado |
|---|---:|---|---:|---|---|
| Interlagos (BRA) | 71/71 voltas, 24 pilotos | Seco | 48 | P2 +6,00 s | PASSOU |
| Sepang (MAL) | 56/56 voltas, 24 pilotos | Chuva intensa | 72 | P2 +8,20 s | PASSOU |

- Interlagos: quatro paradas de Ferrari executadas nas voltas **23, 25, 48, 50**; duas melhores voltas implausíveis rejeitadas; 72 eventos de ultrapassagem em pista separados de 151 mudanças de posição por outros motivos. Treze carros completaram 71 voltas e 11 foram classificados como retardatários. Vencedor Fernando Alonso no cenário de teste com melhorias; o resultado é criado pelo motor e não corresponde à corrida histórica.
- Sepang chuva forte: **72 paradas após recalibração**, antes da recalibração **113** no mesmo cenário. A versão anterior v0.6.3.7 registrou **126 em Sepang**, mas sob um perfil meteorológico diferente; não são testes controlados com a mesma configuração. Seis registros de volta implausível foram filtrados e devem continuar sendo investigados na origem. Vencedor Sebastian Vettel (simulação).
- Nenhum erro de script reportado nesses dois GPs completos. A duração integral preservou as voltas oficiais e o motor não usou resultados pré-definidos.

## Regressões

- `core_0638_integrity_test.gd`: GP de 12 voltas com 24 pilotos, pits nas voltas 5 e 7, gap de chegada, six métricas da HUD, bônus de desenvolvimento das rivais — PASSOU.
- `core_0638_manual_warning_test.gd`: alerta a 92% de desgaste em modo Manual, sem chamar box automaticamente — PASSOU.
- `core_0637_reactive_radio_smoke_test.gd`: gatilhos, incidentes, desgaste, chuva, cooldown e privacidade — PASSOU.
- `core_0636_soul_personality_smoke_test.gd`: confiança, memória, percepção do desgaste e UI — PASSOU.
- `core_0600_championship_smoke_test.gd`: calendário com 20 etapas, pontuação, retomada do save e ausência de GP duplicado — PASSOU.
- `core_0629_calendar_smoke_test.gd`: 20 pistas — PASSOU.
- `core_0570_ai_director_smoke_test.gd`, `core_0625_dry_strategy_smoke_test.gd`: planejamento de box/estratégia, ordem V21 e IA — PASSARAM.
- `pit_lane_regression_test.gd`: entrada, saída, garagem e continuidade dos boxes — PASSOU.
- `core_0561_energy_balance_test.gd`: KERS Economizar/Equilibrado/Atacar e DRS — PASSOU.
- Verificação de scripts no editor `godot --headless --editor --quit`: sem erros de compilação — PASSOU.
- Cena real sob `xvfb-run` a 1600×900, OpenGL Mesa (captura e alerta de rádio): PASSOU; o ambiente não possui dispositivo ALSA de som e usou driver de áudio simulado.

## Pendências e limites

- Não reexecutei toda a sequência de **oito GPs de temporada** após as alterações: a lógica da carreira e o save tiveram regressão automatizada, mas a campanha inteira ainda precisa de validação.
- Sem teste gráfico direto no Linux Mint do jogador; testada a cena no Linux virtual.
- A telemetria ainda registra eventos de cruzamento inválidos em raras situações; a **melhor volta agora rejeita** tais valores, mas a causa estrutural da captura precisa de investigação adicional.
- A durabilidade dos pneus e a evolução das rivais são parâmetros de balanceamento do APEX, não reprodução exata do regulamento ou telemetria real de 2012.
- O segundo GP testado usou **chuva forte contínua**, não um temporal variável seguido de pista seca; testar transições adicionais.
- O teste de cena usa comandos programáticos via métodos públicos do jogo; não equivale a oito corridas visualizadas integralmente em 3D.
