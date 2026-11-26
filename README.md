# APEX Motorsport Manager — Core 2 v0.6.7

Simulador de gerenciamento de equipes automobilísticas em **Godot 4.7.2**. O jogador administra pilotos, funcionários, estratégia, engenharia e operações; as corridas de 24 carros são simuladas pelo Core 2, com apresentação 2D/3D. Temporada histórica inicial: Fórmula 1 de 2012. O APEX 2 Next Engine continua experimental e separado.

## Estado atual

| Item | Versão / situação |
| --- | --- |
| Código integrado à main | **v0.6.7 — Living Factory: integridade operacional** |
| Motor esportivo / replay | Core 2, revisão 040 (preservada da 9.21) |
| Integração dos 11 incrementos | PRs #154–[#164](https://github.com/Jugadru/APEX-Simulation/pull/164) · `841cf72b` |
| Integração Living Factory | [PR #166](https://github.com/Jugadru/APEX-Simulation/pull/166) · `2abe40cf` |
| FAST do candidato Living Factory | [PASS](https://github.com/Jugadru/APEX-Simulation/actions/runs/45896250747), 28 testes roteados e 23 verificações novas |
| Validação específica do incremento 11 | [1.322 verificações PASS](https://github.com/Jugadru/APEX-Simulation/actions/runs/45891658057) |
| Último binário permanente de teste | [v0.6.6.9.17.4 (pré-release)](https://github.com/Jugadru/APEX-Simulation/releases/tag/v0.6.6.9.17.4) |
| Última release estável | [v0.6.6.9.9](https://github.com/Jugadru/APEX-Simulation/releases/tag/v0.6.6.9.9) |

A versão integrada não é automaticamente uma release de executáveis. Os resultados acima referem-se aos SHAs testados, não a uma exportação da v0.6.7. FULL, desempenho nativo sustentado e revisão independente da v0.6.7 não comprovados.

## O que há de novo — v0.6.7

- Reserva exclusiva de destino de substituição, proteção de instalação manual, persistência e recuperação de ordens antigas com destino divergente. Sem novo schema ou mudança esportiva.
- Nova numeração curta: v0.6.7, v0.6.8, v0.6.9, v0.7.0 e seguintes. [Roadmap Unificado 3.0](docs/APEX_ROADMAP_UNIFICADO_3_0.md) conserva todas as funcionalidades e sua ordem; números de versões históricas permanecem imutáveis. Próxima funcionalidade: Race Randomness & Simulation Integrity 1.0 (v0.6.8).

## Funcionalidades preservadas — 9.23

- Onze incrementos integrados: scheduler, diagnóstico de qualidade, F8, HUD, rádio, perfis gráficos, observação esportiva, reaproveitamento de setup, geometria espacial, política de revisões e Endurance Laboratory.
- Revisão esportiva 040 e diretório estável de usuário preservados. O teste sintético observou 37,83x de throughput por tick; não comprova 32x sustentados no hardware real.
- [Plano e evidências dos 11 incrementos](docs/APEX_0923_ENGINEERING_PLAN.md). Homologação ampliada autorizada, pendente de execução manual e evidências.

## Funcionalidades preservadas — Race Engineer 4.0

- Diagnóstico contextual de erros do piloto, pneus, temperatura, clima, ar sujo e trânsito, com confiança qualitativa e acompanhamento.
- Engenheiros fictícios com estilos distintos, memória limitada, identidade/competência do STAFF e familiaridade persistente por dupla piloto/engenheiro no campeonato.
- Rádio contextual com fila compartilhada, prioridade, expiração e consultas pelo HUD; 179 traduções das frases originais Radio 3.0, legendas em português.
- Voz local opcional via TTS do sistema operacional, volume independente e fallback textual. Voz disponível depende do sistema; não há vozes gravadas/clonadas nem garantia de sotaque.
- Comunicação observacional: sem novas ordens esportivas, alteração de ritmo, RNG, KERS ou BOX V21. Revisão esportiva 040 preservada.

[Notas técnicas, evidências e limitações da 9.22](docs/APEX_RELEASE_v0.6.6.9.22_RACE_ENGINEER.md). FULL/endurance, GPU física, qualidade de áudio real e exportação da 9.22 não foram comprovados por estes testes.

## Downloads e execução

- **Código-fonte:** [main atual](https://github.com/Jugadru/APEX-Simulation/archive/refs/heads/main.zip); [base de código Living Factory homologada](https://github.com/Jugadru/APEX-Simulation/archive/2abe40cfdd86f161ef2dbe64fb2f12f8fd6f7822.zip) (antes da sincronização do identificador). Não são executáveis.
- **Pré-release jogável 9.17.4:** [Linux e Windows x86_64, manifesto e hashes](https://github.com/Jugadru/APEX-Simulation/releases/tag/v0.6.6.9.17.4).
- **Release estável 9.9:** [Linux e Windows x86_64](https://github.com/Jugadru/APEX-Simulation/releases/tag/v0.6.6.9.9).
- **Todos os downloads:** [GitHub Releases](https://github.com/Jugadru/APEX-Simulation/releases). Para gerar uma prévia atual, consulte [exportação PC via CI](docs/EXPORTACAO_PC_CI.md); exportação é opcional e não equivale a publicação.

Extraia o ZIP específico do seu sistema e mantenha o executável e o arquivo `.pck` juntos. No Linux, se necessário, execute `chmod +x APEX_Motorsport_Manager.x86_64`. No Windows, abra `APEX_Motorsport_Manager.exe`. A exportação cruzada não prova execução nativa ou FPS no computador do jogador.

## Abrir o jogo

1. Instale Godot **4.7.2**.
2. Importe [project.godot](project.godot), aguarde a importação e pressione F5.
3. No Linux, use `./linux/run_apex.sh` ou informe o binário local com `GODOT_BIN=/caminho/para/godot`. Para o renderer Compatibility, use `./linux/run_apex_compatibility.sh`.
4. Faça backup de saves e replays antes de trocar de versão. O diretório de usuário estável permanece `APEX_0650_SOUL_STAFF`.

## Evolução recente

| Versão | Funcionalidade |
| --- | --- |
| 9.17–9.17.4 | [Largada 2.0](docs/APEX_RELEASE_v0.6.6.9.17_LARGADA_2.md), [interpolação](docs/APEX_RELEASE_v0.6.6.9.17.3_RACE_MOTION_REFINEMENT.md) e [trânsito competitivo](docs/APEX_RELEASE_v0.6.6.9.17.4_COMPETITIVE_TRAFFIC.md) |
| 9.17.5–9.17.9 | [HUD dos pilotos](docs/APEX_RELEASE_v0.6.6.9.17.5_DRIVER_HUD.md), [navegação](docs/APEX_RELEASE_v0.6.6.9.17.6_NAVIGATION.md), [trânsito](docs/APEX_RELEASE_v0.6.6.9.17.7_RACE_TRAFFIC.md), [menu](docs/APEX_RELEASE_v0.6.6.9.17.8_MAIN_MENU.md) e [temporada](docs/APEX_RELEASE_v0.6.6.9.17.9_SEASON_PREPARATION.md) |
| 9.17.10–9.17.12 | [Racing line](docs/APEX_RELEASE_v0.6.6.9.17.10_RACING_LINE.md), [vácuo e ar sujo](docs/APEX_RELEASE_v0.6.6.9.17.11_AERO_WAKE.md), [coordenação](docs/APEX_RELEASE_v0.6.6.9.17.12_COORDINATION.md) |
| 9.18 | [Wet Setups](docs/APEX_RELEASE_v0.6.6.9.18_WET_SETUPS.md) |
| 9.19 | [Corner Battle](docs/APEX_RELEASE_v0.6.6.9.19_CORNER_BATTLE.md) |
| 9.20 / 9.20.1 | [Driver Traffic](docs/APEX_RELEASE_v0.6.6.9.20_DRIVER_TRAFFIC.md) / [Traffic Mega](docs/APEX_RELEASE_v0.6.6.9.20.1_TRAFFIC_MEGA.md) |
| 9.21 | [Driver Error & Recovery](docs/APEX_RELEASE_v0.6.6.9.21_DRIVER_ERROR.md) |
| 9.22 | [Race Engineer 4.0](docs/APEX_RELEASE_v0.6.6.9.22_RACE_ENGINEER.md) |
| 9.23 | [Integrated Engineering Update](docs/APEX_0923_ENGINEERING_PLAN.md) |
| **0.6.7** | **[Living Factory — Integridade operacional](docs/APEX_0924_FACTORY_AUDIT.md)** |

As notas históricas preservam o estado e os testes de cada versão. Consulte [CHANGELOG.md](CHANGELOG.md), [arquivo documental](docs/arquivo/README.md) e [README histórico anterior à sincronização](https://github.com/Jugadru/APEX-Simulation/blob/b295e467fc73fdb54d724dc1ee042a771a267f7a/README.md) para resultados, links antigos e instruções de rollback.

## Política permanente: FAST + APEX Test Lab

Decisão de 23/11/2026: uma funcionalidade principal por versão. O workflow automático [APEX Core 2 — Godot 4.7.2 CI](.github/workflows/godot-setup.yml) importa o projeto, executa Test Lab (24 carros, seco/chuva, hashes determinísticos, CPU/memória), replay/double stack e regressões selecionadas pelo diff. Exigir PASS no SHA exato do PR antes de merge; skipped, NOT_RUN, BLOCKED ou INCONCLUSIVE não equivalem a aprovação.

FULL, matriz 20/180, endurance, comparador visual, benchmarks, exportação e Quality Gate histórico são manuais/opcionais, mediante solicitação. Mudanças de física, replay, save, clima ou circuito exigem regressões direcionadas proporcionais ao risco. CPU headless não comprova FPS/GPU real. Preserve BOX manual V21 e regras históricas de 2012.

```bash
godot --headless --single-threaded-scene --path . --import
godot --headless --single-threaded-scene --path . --script res://tests/apex_lab_track_smoke.gd
godot --headless --single-threaded-scene --path . --script res://tests/apex_lab_performance_probe.gd
```

[AGENTS.md](AGENTS.md) · [Guia FAST permanente](docs/APEX_CI_INTELIGENTE_TRES_NIVEIS.md). Pendências de desempenho/visual: [#74](https://github.com/Jugadru/APEX-Simulation/issues/74), [#77](https://github.com/Jugadru/APEX-Simulation/issues/77).

## Estrutura do projeto

| Pasta / arquivo | Finalidade |
| --- | --- |
| [project.godot](project.godot) | Configuração e identificação oficial da build |
| [scripts/](scripts/) e [scenes/](scenes/) | Código, simulação e apresentação |
| [assets/](assets/) e [data/](data/) | Recursos e dados |
| [tests/](tests/) e [tools/](tools/) | Testes e ferramentas |
| [docs/](docs/) | Documentação técnica |
| [docs/arquivo/](docs/arquivo/README.md) | Histórico preservado |
| [export_presets.cfg](export_presets.cfg) | Presets PC, Linux e Windows |

O motor esportivo é a fonte dos resultados; apresentação não altera resultados. Preserve saves, replays, determinismo e arquitetura modular.
