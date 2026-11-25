# APEX 9.20 — Driver Traffic Intelligence 1.0

Base integrada 9.19 REV4, PR 129, merge b234d600; nova revisão 038. Escopo: retardatários e interação com terceiros, não reescrita de corridas entre carros na mesma volta.

- Reconhece uma volta física completa via distância modular e progresso esportivo, inclusive na linha de cronometragem; ignora carros finalizados ou nos boxes. Não muda a classificação.
- Cede passagem antecipadamente apenas se houver aproximação real, pista larga, baixa carga de curva e margem de chuva/consciência espacial. Projeta a ocupação de terceiros ao longo do tempo de deslocamento lateral, sem fazer ultrapassagem por teleporte.
- Mantém faixa já reservada para o mesmo piloto, não troca de lado se a preferência do perseguidor mudar. Em aproximação tardia, curva ou terceiro carro, mantém faixa efetivamente ocupada. Estreitamento e manobra já estabelecida prevalecem. Uma reserva azul válida tem prioridade sobre nova tentativa de ataque ainda não comprometida.
- Solver, aero, KERS/DRS, pit, setup, antioscilação 9.19 e decisões normais por posição mantidos. Não há bônus de ritmo, nova punição esportiva, rádio ou mudanças visuais. Coeficientes esquemáticos, não telemetria FIA.
- Memória por carro no dicionário esportivo existente; flag de versão fora do schema. Replays 037 e anteriores usam regras históricas.
- FAST + Lab, fixtures de tráfego (inclusive 24 carros com retardatário semeado, não GP completo), compatibilidade histórica 037 hash 9190524493e933da0ce1268ebaaeea89d601f1ba6c1136dd1247643d684b440d, 12 A/B de 1800 ticks 037/038, 3 circuitos x 2 climas x 2 seeds, regressões 9.19, 9.18 e 9.3. Sem relaxar limites. Resultados inicialmente NOT_RUN. Rollback b234d600. Sem merge antes da homologação no SHA exato e autorização.
