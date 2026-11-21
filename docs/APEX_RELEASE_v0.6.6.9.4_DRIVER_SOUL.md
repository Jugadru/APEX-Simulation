# APEX v0.6.6.9.4 — Driver Soul 3.0 (integrada)

**Implementação:** [PR #76](https://github.com/Jugadru/APEX-Simulation/pull/76), integrada à `main` no commit `17ad31b1402d67b239d148e7fb2f5e9c5013b8d0`.

**Commit testado/exportado:** `63d7953cc21184d6902ebc8cc34b7e696ec927ba`. A árvore de arquivos do merge é idêntica à do commit testado. Base anterior v0.6.6.9.3: `53c0adf0da87a93e4b79c8a2c240c063b7c201f2`.

## Funcionalidade

- `race_driver_soul_06694.gd`: evolução de Soul 2.0, com estado/intenções `ATACAR`, `GERIR_PNEUS`, `CAUTELA`, `MANTER` a cada volta concluída. Baseia-se em pressão, foco, confiança, iniciativa, sensação e desgaste medido, além da chuva.
- `race_driver_dynamics_0661.gd`: o estado emocional influencia o *limiar de comprometimento* de um ataque. **Não** modifica diretamente velocidade, grip, posição ou tempo de volta.
- `race_engine.gd`: integração determinística do Soul3 ao estado do piloto; rádio fictício contextual, preservando controle manual/IA e ordens de box (incluindo V21).
- `apex_race_hud_0622.gd`: mostra Soul3/intenções no HUD e evita mensagens duplicadas.
- `race_replay_0660.gd`: revisão nova `017_driver_soul_v1`; replays 016/015/014 e legados usam as regras antigas com flags de sessão, fora dos snapshots/hash em `race_state_codec_0660.gd`.
- Mantém o solucionador de corredores, tráfego v9.3, regras de pneus, pit lane, IA de Pit Wall, ordens manuais e replay completo.

## Evidências reais no GitHub

| Verificação | Resultado |
|---|---|
| Workflows no commit testado | **17/17 PASS** |
| [Quality Gate por SHA](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950949960) | **READY 10/10**, auditoria reexecutada após todos os workflows |
| [Driver Soul dedicado](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950949935) | **PASS**, 28 verificações, além de regressões Soul2/Driver Dynamics/Driver Traffic |
| [SaveGuard](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950072) | **PASS**, carreira, garagem, replay 9.3 e verificações de integridade |
| [Scenario Matrix](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950949920) | **PASS**, 20 circuitos, quatro grupos, mesmo commit; grupo 1 repetido por falhas de importação Godot 139 |
| [Endurance](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950061) | **PASS**, Monza 53 voltas, 24 carros classificados, **24.229 ticks** ao vivo e em replay, hash final idêntico |
| [Export Windows/Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950040) | **PASS**, Godot 4.7.2, identificação PCK v9.4, inicialização básica Linux |
| [A/B visual](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950047) | **PASS**, zero colisões e nenhuma piora visual diante da v9.3, três repetições, 4 pistas |
| Pit Wall, Race Intelligence, GdUnit4, regressão visual, auditoria e segurança | PASS |

### CPU e replay

Monza na CI sem GPU: **191,58 s** para a corrida ao vivo, mais **205,44 s** para reprodução completa, no commit testado. A velocidade simulada equivalente variou: primeira janela de 2.000 ticks **32,07×**, janela central **23,73×** e janela final parcial **37,55×**. Essa variação mostra que **32× sustentados no PC do jogador não foram demonstrados**; valores de throughput são do runner headless e não equivalem ao FPS no PC.

Comparação visual A/B headless de 4 pistas, três repetições: soma mediana de tempos por atualização, **21.871,34 μs** v9.3 versus **21.804,76 μs** v9.4 (**−0,30%**). O relatório marca `INCOMPARABLE_SPORTING_REVISION` porque as regras esportivas diferem; não afirma equivalência de poses nem ganho real de FPS.

A v9.3 já tinha ressincronizações e lags em Mônaco e Spa nos cenários visualizados; a v9.4 não piorou os indicadores nesses benchmarks. A questão está isolada na [issue #77](https://github.com/Jugadru/APEX-Simulation/issues/77). O gargalo de 32× continua na [issue #74](https://github.com/Jugadru/APEX-Simulation/issues/74).

## Pacotes e limites

- [Executáveis v9.4 Windows/Linux — artefato temporário](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950040/artifacts/14725252948), disponível até **05/12/2026**, sem Release pública permanente v9.4.
- [Fonte exata integrada da v9.4](https://github.com/Jugadru/APEX-Simulation/archive/17ad31b1402d67b239d148e7fb2f5e9c5013b8d0.zip).
- Rollback histórico: `53c0adf0da87a93e4b79c8a2c240c063b7c201f2` (v9.3).
- Testes Windows cobrem pacote binário e metadados, **não** execução gráfica em hardware Windows. Testes headless não representam FPS real com HUD/3D.
- Este é um modelo ficcional de personalidade, não reproduz características reais de pilotos nem áudio/radios protegidos da Fórmula 1.
