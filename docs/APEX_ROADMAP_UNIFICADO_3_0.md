# APEX — Roadmap Unificado 3.0 / numeração simplificada

Decisão do responsável: encerrar a sequência longa v0.6.6.9.* e usar v0.6.7, v0.6.8, v0.6.9, v0.7.0 e seguintes. Somente os números do planejamento futuro mudam; não há remoção, reordenação de funcionalidades ou reescrita de versões históricas. A nova numeração é uma convenção de desenvolvimento, não certificação de maturidade ou promessa de release. O Plano Mestre Unificado 2.0 continua como arquitetura e escopo. Este documento consolida a sequência de 40 atualizações (32 anteriores + 8 complementares) aprovada na conversa, incluindo as quatro atualizações 9.36–9.39. A ordem histórica de 9.17.5/9.17.6 é reproduzida conforme o roadmap informado, não como auditoria dos títulos reais de releases; consultar changelog para histórico efetivo.

## Fase 1 — Estabilização e refinamento
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.17.3 | v0.6.6.9.17.3 | Race Motion Refinement | Histórico do roadmap |
| 9.17.4 | v0.6.6.9.17.4 | Largada competitiva — múltiplas sementes | Histórico do roadmap |
| 9.17.5 | v0.6.6.9.17.5 | Navigation Hotfix | Histórico do roadmap |
| 9.17.6 | v0.6.6.9.17.6 | Driver HUD Restoration | Histórico do roadmap |
| 9.17.7 | v0.6.6.9.17.7 | Race Traffic Hotfix | Histórico do roadmap |
| 9.17.8 | v0.6.6.9.17.8 | Main Menu Rework | Histórico do roadmap |
| 9.17.9 | v0.6.6.9.17.9 | Season Preparation Rework | Histórico do roadmap |
| 9.17.10 | v0.6.6.9.17.10 | Racing Line Intelligence 1.0 | Histórico do roadmap |
| 9.17.11 | v0.6.6.9.17.11 | Slipstream & Dirty Air 1.0 | Histórico do roadmap |
| 9.17.12 | v0.6.6.9.17.12 | Coordenação entre trajetória, ataque e defesa | Histórico do roadmap |

## Fase 2 — Inteligência esportiva
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.18 | v0.6.6.9.18 | Wet Weather Setups | Histórico do roadmap |
| 9.19 | v0.6.6.9.19 | Corner Battle Intelligence | Histórico do roadmap |
| 9.20 | v0.6.6.9.20 | Driver Traffic Intelligence | Histórico do roadmap |
| 9.21 | v0.6.6.9.21 | Driver Error & Recovery | Histórico do roadmap |
| 9.22 | v0.6.6.9.22 | Race Engineer | Histórico do roadmap |
| 9.23 | v0.6.6.9.23 | Race Quality & Performance | Histórico do roadmap |
| 9.23.1 (PR #166 provisoriamente 9.24) | v0.6.7 | Living Factory — Integridade operacional | Código integrado, FAST PASS |
| 9.24 | v0.6.8 | Race Randomness & Simulation Integrity 1.0 | Candidato em homologação FAST |

## Fase 3 — Física e dinâmica veicular
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.25 | v0.6.9 | Braking & Acceleration Physics 1.0 | Planejada |
| 9.26 | v0.7.0 | Gearbox, Torque & Power Delivery | Planejada |
| 9.27 | v0.7.1 | Tyre Grip & Load Transfer | Planejada |
| 9.28 | v0.7.2 | Vehicle Dynamics Integration | Planejada |

## Fase 4 — Inteligência competitiva avançada
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.29 | v0.7.3 | Overtaking Preparation | Planejada |
| 9.30 | v0.7.4 | Braking Intelligence | Planejada |
| 9.31 | v0.7.5 | Side-by-Side Dynamics | Planejada |
| 9.32 | v0.7.6 | Defensive Intelligence | Planejada |
| 9.33 | v0.7.7 | Driver Mistakes & Recovery 2.0 | Planejada |
| 9.34 | v0.7.8 | Tyre Thermal Dynamics | Planejada |
| 9.35 | v0.7.9 | Racecraft Quality | Planejada |

## Fase 5 — Realismo mecânico, esportivo e estrutural
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.36 | v0.8.0 | Mechanical Reliability & Damage | Planejada |
| 9.37 | v0.8.1 | Race Control Intelligence | Planejada |
| 9.38 | v0.8.2 | Sporting Regulations | Planejada |
| 9.39 | v0.8.3 | Engineering & Factory Evolution | Planejada |

## Fase 6 — Engenharia profunda e fábrica inteligente
| Referência anterior | Versão | Funcionalidade | Estado |
|---|---|---|---|
| 9.40 | v0.8.4 | Individual Component Engineering | Planejada |
| 9.41 | v0.8.5 | Manufacturing & Production Planning | Planejada |
| 9.42 | v0.8.6 | Engineering Prototypes | Planejada |
| 9.43 | v0.8.7 | Component Testing & Validation | Planejada |
| 9.44 | v0.8.8 | Factory-to-Track Correlation | Planejada |
| 9.45 | v0.8.9 | Quality Control & Reliability Management | Planejada |
| 9.46 | v0.9.0 | Technical Staff Intelligence | Planejada |

## Escopo preservado

- Integridade probabilística: RNG controlado, causalidade, incerteza e hashes/replay.
- Realismo mecânico: V8/câmbio, temperatura de motor/freios, hidráulica/elétrica, KERS/DRS, danos de asas/suspensão/assoalho/pneus, perda de ritmo, abandono, reparos e histórico.
- Race Control: bandeiras amarela/azul/vermelha, Safety Car, neutralização, relargada, investigação e segurança; estratégia condicionada aos eventos reais.
- Regulamentos: limites de pista, vantagem indevida, colisões/defesa, bandeiras, pit lane, drive-through, stop-and-go, grid, pneus, parque fechado, classificação e desclassificação; regras de 2012, sem VSC moderno.
- Engenharia: componentes individuais, produção com capacidade/filas/custos/recursos, protótipos com riscos, testes, instalação e correlação com pista, controle de qualidade, desgaste e inteligência do staff técnico. Evoluir Living Factory e Soul Staff, sem substituí-los.
- Escopo futuro sem numeração ainda: Soul Driver, Soul Staff, mercado de pilotos, academia, contratos/expectativas, patrocínios, finanças e economia, gestão dos rivais, Career Desk, Simulation Mode (Manual/Assistido/Automático quando aplicável), carreira multitemporada, Hall da Fama. Preservar também as demais metas e dependências do Plano Mestre Unificado 2.0.

## Regras de continuidade

- Versão integrada mais recente de gameplay: v0.6.7, PR #166, merge 2abe40cfdd86f161ef2dbe64fb2f12f8fd6f7822, FAST 45896250747 PASS. Nome de fixtures e revisão esportiva 040 não mudam.
- Próxima atualização: v0.6.8 — Race Randomness & Simulation Integrity 1.0. Candidato em homologação; ver [contrato técnico](APEX_068_RANDOMNESS_INTEGRITY.md).
- Uma funcionalidade por versão, PR própria, FAST exato e regressões direcionadas, preservar saves/replays/determinismo/2012. FULL e runner pessoal não são automáticos; seguir AGENTS.md.
- Nenhum novo binário, tag ou release publicado pela mudança de identificação. Histórico e arquivos de referência do Plano Mestre permanecem intactos.
