# APEX Motorsport Manager v0.6.6.7.2 — Relatório técnico de estabilização visual

## Escopo e diagnóstico

**Base real:** pacote completo v0.6.6.7.1. **Única funcionalidade corretiva:** retenção de pose no módulo de ocupação visual 3D (`scripts/apex_racecraft_0654.gd`). O jogador relatou carros aparentemente congelados e quadros lentos durante disputas. O motor esportivo continuava progredindo enquanto o solucionador visual reutilizava posições antigas. A ordenação baseada nessas posições podia bloquear um carro por dezenas de atualizações.

**Alteração:** registrar `hold_frames` somente quando o carro fica realmente retido; depois de duas retenções consecutivas, descartar **apenas o histórico visual daquele carro** na próxima resolução para permitir reordenação conforme o progresso autoritativo. Nenhum dicionário de corrida é modificado e nenhum parâmetro de defesa, ataque, pneus ou velocidade é alterado. Adicionar os contadores opcionais do profiler F8 `visual.occupancy_stalled_car_frames` e `visual.occupancy_recovered_car_frames` (`scripts/track_3d.gd`). Manter `project.godot` com a identificação da versão.

## Benchmark A/B medido

Ambas as versões usam Godot 4.7.2 headless, o mesmo cenário de cada circuito com 24 carros e 125 passos de simulação de 0,5s por pista. Os números de p95 são **tempos de CPU por atualização visual**, NÃO FPS da placa de vídeo nem tempo total de frame. O primeiro quadro e a criação dos modelos têm custo de inicialização, e a carga da máquina pode causar variações. Mesmo método em ambos os códigos:

| Pista | Maior sequência de frames imóveis (antes → depois) | Amostras estacionárias (antes → depois) | p95 visual CPU ms (antes → depois) | Sobreposição após |
|---|---:|---:|---:|---:|
| GBR | 0 → 0 | 0 → 0 | 3.60 → 3.92 | 0 |
| MON | 26 → 2 | 285 → 61 | 36.37 → 11.64 | 0 |
| BEL | 96 → 2 | 1168 → 11 | 95.66 → 6.60 | 0 |
| SIN | 0 → 0 | 0 → 0 | 3.30 → 5.83 | 0 |

A correção reduziu substancialmente a retenção persistente em **Monza** e **Spa**. Silverstone e Singapura não apresentavam congelamento nesse cenário, e não houve redução universal do tempo de CPU nessas duas pistas. O profiler opcional foi efetivamente testado com 100 chamadas: 32 frames/carro retidos e 11 recuperações.

**Limitação residual:** o reinício de um histórico visual bloqueado pode produzir um salto para alcançar a posição autoritativa. No benchmark de Monza em passos grandes (0,5s), o maior deslocamento numa recuperação foi de 43.0m. A renderização em 60 FPS e o comportamento de câmera em GPU real requerem validação manual. Não foi certificada ausência absoluta de saltos visuais em todas as circunstâncias. A simulação de duelo prolongado entre Button/Vettel e as preferências de espaço nas curvas exigem versões esportivas próprias, e a HUD limpa pertence ao roteiro posterior.

## Regressões concluídas

- Unitário Racecraft 0654 (ocupação, colisão, pista estreita, varredura temporal, pausa, imutabilidade dos dados); integração 3D nativa GBR/MON; Racecraft 0662 com 1.027 verificações e 500 ticks.
- Dynamics 0661, Diretor TV, Pit Wall contra duas ordens conflitantes no mesmo tick e teste pesado de integração do replay 0660 aprovados.
- **Quatro corridas de três voltas e seus replays integrais:** GBR seco (1668 ticks), BEL chuva intensa (2067), ITA seco (1553) e SIN chuva intensa (2050); SHA-256 esportivos idênticos aos baselines históricos.
- Importação no Godot 4.7.2 sem parser errors; capturas reais em janela independente 1600×900 / 1920×1080 usando Xvfb + OpenGL/Mesa llvmpipe. Aviso de saída de áudio ALSA, com fallback dummy, durante a captura — não bloqueou a execução.
- Todos os 2563 arquivos originais do pacote v0.6.6.7.1 presentes. Somente três arquivos existentes foram modificados intencionalmente: `project.godot`, `scripts/apex_racecraft_0654.gd`, `scripts/track_3d.gd`. Não foram modificados `scripts/race_engine.gd`, o `RaceSpace`, o `RaceDriverDynamics`, a IA, os pneus, o Pit Wall e o Diretor TV.

## Não concluído / não corrigido nesta versão

1. **FPS no computador do jogador:** não foi medido. Os testes headless medem a CPU de preparação visual, não GPU/driver/compositor/VSYNC.
2. **Erro XServer `BadWindow`:** não reapareceu no Xvfb em janela independente, mas isso não isola o editor incorporado ao processo na máquina do jogador; suspeita ambiental continua a ser investigada. Rodar jogo como janela separada e coletar log completo do driver e display server.
3. **Nova corrida longa Monza com 53 voltas:** não repetida neste hotfix; os quatro GPs curtos com replay integral preservam os hashes existentes.
4. **Duelos travados por várias voltas e direito de espaço:** comportamento esportivo não alterado de propósito; próximo módulo 0.6.6.7.3.
5. **HUD e menus poluídos:** nenhum layout foi modificado de propósito; limpeza de interface prevista para v0.6.6.7.4.

## QA e arquivos

Ver `qa/visual_stutter_06672` para logs, JSON A/B, scripts em `tests/visual_stutter_06672_benchmark.gd` e `tests/visual_stutter_06672_profiler.gd`, imagens e dados de regressão. A versão 0.6.6.7.1 deve permanecer como rollback.
