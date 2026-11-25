# APEX 9.17.12 — Coordenação entre trajetória, ataque e defesa

Base integrada 9.17.11 REV4, PR 126, merge 138bd30a; revisão 035. Candidata 036. Uma funcionalidade: coerência entre intenções competitivas antes do movimento.

- Bloqueio de lado somente durante ataque ativo ao mesmo alvo; não eternizar um lado após desistência.
- Defesa antecipada preserva a linha já escolhida, inclusive zero. Defesa tardia mantém a posição atual respeitando limite.
- Um ataque dianteiro não pode ser sobrescrito por ordem defensiva traseira. Reconciliar propostas após todas as decisões, vetar corredor incompatível, retirar custo artificial do ataque vetado e evitar evento fantasma. Preservar blue flags e proteção física existente.
- Sem teletransporte, alteração de ritmo aero, pneus, KERS, DRS, pit ou geometria; o solver continua autoridade final.
- Flag de sessão 036 excluída do codec para preservar hashes de revisões anteriores; replay antigo mantém lógica exata. Sem novo schema.
- FAST + Test Lab + fixture específica + 12 comparativos de 1800 ticks (Monza, Silverstone, Mônaco, seco/chuva intensa, seeds 42 e 123). Critérios de segurança e direção mantidos e comparação direta 035/036; hash histórico 035 verificado. CI anterior de aero continua validando 031/035.
- Câmera P15 030–036 pela CI aero. GPs completos não são exigência universal, conforme AGENTS.md. Nenhum binário ou retrato privado publicado.
- Status antes da execução: NOT_RUN. Merge somente após CI obrigatória PASS no SHA exato e autorização do responsável. Rollback: 138bd30a.

Revisão interna: veto iterativo monotônico reavalia o corredor traseiro quando um ataque dianteiro é cancelado. Regra 036 depende do conjunto de proteções 035 para preservar comparativos legados sem aero.
