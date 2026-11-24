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

## Revisão 2 — investigação do movimento visual e custo de tráfego
Base de comparação: primeira candidata `d14fb206035b3d44296d9e7bc70215faae8e6248`. Nenhuma alteração de revisão esportiva, RNG, pneus, clima, Pit Wall, saves, HUD ou retratos.

- A/B usa as mesmas 312 observações de ticks fixos do motor por cenário e o mesmo sampler, a 30 Hz, 6 Hz e intervalo de 0,5 s. Mônaco: duas seeds (42/6558), equipe stock/desenvolvida; GBR/ITA/BEL: stock 42. O guard reprova aumento de imobilizações, duração, pior salto (tolerância 0,01 unidade), reversões e sobreposições; Mônaco exige melhora real. Hash do estado e da timeline não podem mudar.
- Duas tentativas de recuperação pós-solver reduziram imobilizações, mas aumentaram o maior salto a 30 Hz; foram rejeitadas. A terceira preservou o caminho curto, recuperou quadros mais longos sem mudar o pior salto. Na quarta, o recuo mínimo original de 0,8 unidade podia ultrapassar o pequeno avanço disponível: tenta recuos fracionários de 25/50/75% apenas quando bloqueado, sem retroceder nem dispensar testes de ocupação/sweep. A recuperação pós-solver fica restrita a intervalos >=0,10 s; aceita apenas poses intermediárias seguras entre o progresso anterior e o nominal. Os fallbacks permanecem.
- Otimização de RaceSpace: descarta vizinhos de faixa insuficientemente separada antes da distância circular, encerra a busca de nova invasão quando a faixa não muda. A/B usa 100 snapshots de quatro pistas, quatro repetições, 026/027 e ordem alternada. Exige igualdade completa dos resultados, mede tempo do solver (não FPS). As cópias históricas em tests/legacy são oráculos do SHA anterior, não código de runtime.
- Profiler F8, quando habilitado, registra `visual.traffic_nominal_advancing_stalled` e `visual.traffic_nominal_low_advance`, distinguindo retenção de apresentação de avanço nominal baixo (inclui interpolação de tick e pausa; não é prova de parada esportiva). Sem alteração de layout.
- O teste histórico `view_0658_motion` acusou cruzamento pelo chord entre quadros também na candidata anterior. Não desativado, não declarado PASS; investigar varredura em 16x separadamente. A matriz A/B de endpoints não prova ausência de todos cruzamentos, corridas completas ou comportamento em GPU física.

CI dedicada mantém os jobs originais e acrescenta 4 jobs A/B de movimento e 1 A/B esportivo. Os resultados são vinculados ao SHA exato no PR #122. Não fazer merge até homologação.
