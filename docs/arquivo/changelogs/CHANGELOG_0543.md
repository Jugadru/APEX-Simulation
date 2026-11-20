> Documento histórico de versão anterior. Leia CHANGELOG_0550.md para as mudanças atuais.

# v0.5.4.3 — Core 2 Combat, motor único

## Remoções
- Excluída seleção Clássico/Core 2 da tela inicial.
- Excluídas fórmulas condicionais do perfil Clássico em `race_performance.gd`, `race_strategy.gd`, `race_rules.gd` e `race_combat.gd`.
- Excluídos testes e snapshots que distribuíam motores antigos dentro do projeto atual.

## Nova dinâmica
- Avaliação de desempenho de todos os carros com instantâneo do mesmo tick.
- Ataque preparado conforme vantagem de ritmo e distância para o carro à frente.
- Tentativa com tempo de duelo, resistência defensiva e cooldown; sem sorteio adicional e sem perturbar o RNG dos incidentes.
- Limitação de bloqueio para evitar congelamento artificial do carro perseguidor.
- Eventos de batalha no histórico/rádio; contadores de tentativas e ultrapassagens após duelo.
- Ajustes visuais mínimos: indicador de combate no Live Timing e status nos cartões.

## Preservação
- `race_pit_lane.gd`, `race_pit_math.gd`, geometria 3D, garagens, pneus históricos, Pit Wall e comandos de boxes não foram alterados.
- Clima permanece informativo.

## Limites e validação
- Não é IA roda a roda ou física lateral. Zonas de ataque são proxies e carecem de ajustes por circuito.
- Testes Python e teste Godot incluídos; rodar `bash linux/validar_core_0543.sh`.
- **Sem Godot instalado no ambiente de montagem, a execução real da cena não pôde ser comprovada aqui.**
