# v0.6.6.9.17.7 — Race Traffic Hotfix (candidata)

Base: `9373a0981570cd85d533d0173e2f48dd617d04b0` / PR #121. Sem merge antes de homologação.

## Diagnóstico reproduzido
- A proteção lateral comparava progresso acumulado, não distância física circular. Na fixture de dois carros separados por exatamente uma volta, a faixa externa mudava de 2,95 para 2,59 apesar da ocupação lateral.
- A convergência podia multiplicar a redução lateral de avanço (0,55) pela redução de fila (0,45). Na fixture de três carros lado a lado, o terceiro avançava 0,000495 para um avanço nominal 0,002; agora avança 0,0009. Não é ganho de velocidade nominal.
- A correção usa distância de arco circular e prioridade estável quando as posições físicas coincidem, com um único redutor de avanço na fila. A restrição de segurança longitudinal permanece.

## Escopo e compatibilidade
Revisão esportiva `027_race_traffic_hotfix_v1`; 026 e anteriores preservam suas regras. Flag de sessão excluída do checkpoint. Sem alterar esquema de saves, pneus, clima, Pit Wall, HUD, retratos, navegação ou solver visual. Resultados de novas corridas podem mudar legitimamente.

## QA obrigatório
Importar em Godot 4.7.2, FAST + APEX Test Lab, `race_traffic_hotfix_09177_test.gd` (fixtures, 3 seeds x 4 pistas x 2 climas, determinismo, regressão de retenção/sobreposição e replay 026/027), testes de movimento visual, BOX V21. Comparar CPU, não confundir amostras de 120s com GP completo. Capturas locais privadas; não publicar fotos sem licença.

Estado: candidata; consultar resultados no PR. Não declarar ausência universal de paradas: frenagem, boxes e bloqueios reais são legítimos, e a ocorrência relatada em jogo 3D ainda requer reprodução. Rollback: `9373a0981570cd85d533d0173e2f48dd617d04b0`.
