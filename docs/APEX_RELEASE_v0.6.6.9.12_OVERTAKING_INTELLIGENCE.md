# APEX v0.6.6.9.12 — Overtaking Intelligence 1.0

**Estado:** candidato em branch/PR; aguardando homologação real.  
**Base:** `main` após v0.6.6.9.11.  
**Escopo:** decisões iniciais de ultrapassagem; não altera gaps, velocidade, física de colisão nem largada.

## Mudanças

- `race_overtaking_intelligence_066912.gd` avalia, de maneira pura/determinística, se há corredor lateral livre, incluindo terceiros carros próximos (separação modular na linha de chegada).
- Só considera trocar o lado de ataque **antes** de o piloto sair da linha central. Em duelo/overlap preserva a trajetória já comprometida; o `RaceSpace` continua resolvendo limites, defesa e progresso.
- Desiste de tentativas bloqueadas por carros em ambos os lados. Maior chuva, pneus muito gastos ou baixa percepção espacial exigem pequena margem extra de ritmo na fase inicial.
- O limiar de ultrapassagem preexistente (`DriverDynamics`) permanece como condição obrigatória. Não há bônus de posição, aceleração, teleporte, colisão inventada, RNG adicional nem novo comando de pit.
- Distâncias e coeficientes são **aproximações de jogo**, não telemetria FIA.
- `RaceSpace.plan` recebe flag opcional ao fim da assinatura. Quem a omite mantém o comportamento anterior.
- Ativação em novas sessões reais pelo `RaceEngine`, com flag somente de sessão e excluída de save/checkpoint/hashes; nenhuma migração de estado persistido.

## Replays e rollback

- Novas gravações: `023_overtaking_intelligence_v1`.
- Gravações `022_race_start_intelligence_v1` mantêm a largada da 9.11 e a lógica anterior de ultrapassagem.
- Gravações 021 e anteriores preservam todas as opções históricas (staff, chuva, Soul, largada e regras de tráfego).
- `load_data`, `load_live_session`, `seek` e controle de revisão durante `RaceEngine.step` devem manter paridade estrita, inclusive para sessões antigas criadas manualmente.
- Rollback: reverter integralmente o PR. As regras anteriores de `RaceSpace` e `DriverDynamics` permanecem acessíveis desativando a flag.

## Critérios objetivos

1. Import Godot **4.7.2** sem parse errors.
2. Testes com terceiro carro no lado do ataque, dois lados bloqueados, chuva, ocupação/duelo e determinismo da decisão.
3. Integração real: solver com/sem regra 9.12, 24 pilotos, Silverstone, Monaco, testes de regressão de defesa e corrida.
4. Replays 023 e 022: importação, hash e seek; SaveGuard e formato de checkpoint inalterados.
5. Regra manual BOX V21 protegida na chuva.
6. Gates FAST, TARGETED e FULL; matriz de 20 circuitos, visual, exportações e longa duração.
7. GPU/FPS/qualidade visual no PC do jogador exigem avaliação própria e não são atestados por CI headless.

**Resultado na criação:** testes locais e CI ainda **NOT_RUN**. Não marcar como homologado nem integrar à `main` antes de conferir os resultados reais.
