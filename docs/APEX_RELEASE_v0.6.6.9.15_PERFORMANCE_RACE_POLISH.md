# APEX v0.6.6.9.15 — Performance & Race Polish 1.0

**Estado:** em desenvolvimento/homologação; PR draft; **não integrado à main**.

## Gargalo identificado e correção única

O `Race Engineer` da v9.14 consulta `TrackKnowledge.assess()` para os dois carros em cada atualização da HUD. O código original chamava `TrackDynamics.profile_for()`, que relia e reprocessava `res://data/track_physics_2012.json` **a cada consulta**. O catálogo tem 20 circuitos fixos; repetir sua leitura em todas as atualizações cria custo de CPU e alocações sem fornecer informação nova.

A v9.15 usa **cache privado limitado a 20 perfis** dentro de `scripts/core/race_setup_track_knowledge_066914.gd`: leitura do catálogo apenas uma vez por processo e cópia profunda dos dados ao devolver cada perfil. Caso o arquivo não carregue, a primeira leitura falha de maneira conservadora, sem marcar o cache como preenchido. Nenhuma pista desconhecida é criada. `cache_stats()` expõe contadores diagnósticos somente da apresentação.

A solução **não** armazena o estado mutável de pilotos, tempo de volta, pneus, clima ou decisões esportivas; esses dados são sempre observados novamente a cada chamada. `TrackDynamics` e física de corrida não foram modificados. Valores, textos e opções do jogador são preservados.

## Testes obrigatórios

- `PERFORMANCE_POLISH_066915_PASS`: paridade dos 20 perfis com `TrackDynamics.profile_for()`, cache de um único carregamento, cópias imutáveis, clima e desgaste atualizados, pista desconhecida, simulação nativa de 24 pilotos, V21 em chuva, HUD real e revisão de replay `023_overtaking_intelligence_v1`.
- Medição local de **600 consultas do mesmo tipo** com e sem releitura do JSON; números microbenchmark são apenas observações da CPU do CI, **não** FPS/ganho em GPU e **não** limiar universal de aprovação.
- Regressões: `SETUP_TRACK_066914_PASS`, `ENGINEER_066913_PASS`, `RE3_0646_PASS`, `OVERTAKING_066912_PASS`, `REPLAY_UNIT_PASS`.
- FAST, Quality Gate por SHA, matriz de 20 pistas, SaveGuard, endurance, benchmark A/B, exportações Linux/Windows e evidência visual quando aplicável.

## Limitações e segurança

- Uma otimização de parsing no painel não prova que o jogo inteiro ganhou FPS. O efeito global deve ser medido em execução real, preferencialmente repetindo o benchmark antes/depois em hardware idêntico.
- Não altera `RaceEngine`, `RaceSpace`, física do jogo, pneus, estratégia, RNG, dados de pistas, replay, codec, carreira ou arquivos de save.
- Cache é somente para o catálogo estático distribuído com o jogo. Se um futuro editor modificar dados de circuito durante uma sessão, será necessário adicionar invalidação explícita com contrato próprio.
- Um PR DRAFT **não pode ser integrado** antes de evidência FULL READY no commit final.

**Critério de aceite:** paridade observável sem alteração esportiva, melhoria mensurável da consulta específica e todos os testes exigidos aprovados no SHA exato.
