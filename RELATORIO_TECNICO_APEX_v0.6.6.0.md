# Relatório técnico — APEX Motorsport Manager v0.6.6.0

Entrega de 14/11/2026. Principal: **Deterministic Simulation & Replay**. Complemento visual autorizado explicitamente pelo usuário: boxes, equipe, zebras e entorno do circuito. Base: ZIP 0659 SHA-256 `7092a9c2a79f429ba5820fd5f9cbfead8e276940dd6f641589513420cba255e7`, conferido por CRC e manifesto antes da extração; release anterior preservada.

## Simulação e replay
- Sessão com ticks fixos de 0,20 s, acumulador de tempo, limite de 16 ticks por frame e backlog preservado. Pausa não avança relógio nem consome RNG. Velocidades/FPS alteram quantidade de ticks, não sua duração.
- Comandos esportivos centralizados na entrada do motor, incluindo chamadas diretas da HUD. Ordem por tick/sequence, validação de jogador/tipo/parâmetros, modo individual e anotações manuais. Ação só é aplicada na próxima fronteira e é revalidada pelo motor.
- Autonomia de Staff e avisos periódicos seguem o relógio da simulação. Cache de aconselhamento não depende mais de consultas da HUD. Autonomia é recalculada no replay sob o mesmo contrato, nunca gravada e reaplicada em duplicidade.
- Codec versionado captura variáveis do motor, seed/state do RNG, clima, dinâmica da pista, filas/serviço/reparo, carros e telemetria. Apenas dados de objetos conhecidos; sem serializar nós/Callables. Restauração cria outro motor, sem sinais de gestão.
- Hash de cada tick cobre estado autoritativo, RNG, clima/pista e política. Running e cache derivado não entram no hash esportivo; telemetria é comparada separadamente no round-trip e na reprodução. O hot path usa ordem de serialização fixa; canonical_hash existe para auditorias independentes da ordem de Dictionary.
- Checkpoints a cada 60 s, inicial mais oito recentes. Seek verifica checkpoint e hashes subsequentes; falha informa tick divergente. Teste de corrupção detectou divergência exatamente no tick 18.
- **F9**: assistir à gravação atual, play/pause, seek, exportar/importar e voltar à sessão ao vivo. Arquivos com schema/runtime/checksum, sem objetos desserializados. Falha de importação não troca a corrida. Replay esportivamente bloqueado e isolado de inventário/campeonato, com guardas também na saída/menu.
- Observação de quilometragem por tick, sem depender dos frames. Replay não duplica desgaste, prêmio ou salário. Saves existentes continuam em `APEX_0650_SOUL_STAFF`.

## Alteração de contrato esportivo
A 0659 usava deltas variáveis, portanto a mesma seed com FPS diferentes já não era reproduzível. A 0660 normaliza o passo e a frequência de decisão; seus resultados podem mudar em relação à base. Não houve recalibração deliberada de pilotos, aderência ou IA de combate. O contrato determinístico vale para a sessão RaceReplay.advance/step_tick, no mesmo runtime/plataforma e com mesmos comandos; a API legada RaceEngine.step mantém semântica variável para compatibilidade com fixtures antigas.

## Visual
Campus procedural com edifícios de apoio, estacionamento e veículos; terreno com manchas/variação; consoles e monitores, 24 engenheiros com headsets, molduras/luzes de boxes; capacetes arredondados e viseiras; zebras com cores e normal de relevo. Geometria decorativa agrupada em MultiMeshes, com colocação fora do traçado e sem RNG esportivo.

O artefato preto no acesso ao pit persistia mesmo com sombras desligadas: a causa estava na orientação dos triângulos e nas seções desconectadas. A faixa agora compartilha seções e usa faces orientadas corretamente; a captura final confirma a junção contínua. Somente a faixa de chão deixa de projetar sombras. HUD e câmeras existentes preservadas. Cenário ilustrativo, não reconstrução histórica exata nem realismo equivalente a F1 Manager; não incorpora modelos/código de jogos proprietários. A fase ampla de apresentação continua reservada à 0664.

## Evidências
- Testes unitários: round-trip isolado, RNG, arquivo, corrupção, pause/backlog, comandos na fronteira e 1×/2×/5×/16×/32× com FPS variados. Observador de inventário chamado por tick e quilometragens iguais entre essas execuções.
- Integração com cena real: render 2D/3D e consultas de UI iguais ao headless; replay/seek/retorno preservam corrida e inventário. Guards no commit e no observador de inventário exercitados.
- Seis provas de três voltas: GBR, BEL, ITA, SIN, CHN e GER (duas últimas mantêm a seleção aleatória da auditoria anterior). Seco, chuva intensa e automático. Reprodução integral dessas provas com hashes por tick e telemetria iguais. Restauração em approach/dock/service/queue/repair/safety_hold/exit, incluindo double stack e falhas de serviço forçadas na fixture.
- Silverstone **52 voltas**, 26855 ticks: corrida em 515.28 s de execução headless; reprodução desde o checkpoint inicial em 502.17 s. Classificação completa/única e hash final igual. Pacote serializado em memória: 86.71 MiB.
- Fronteiras: ordem manual V21 protegida sob chuva V4, múltiplos comandos no mesmo tick, entradas inválidas e checkpoint adulterado. Transição controlada sem chuva/chuva/sem chuva e restore durante chuva em fixture específica.
- Regressões selecionadas: apresentação/ocupação/lifecycle, geometria 20 pistas, motor espacial, boxes/double stack, HUD, profiler/RNG, oficina/save legado e Soul/Staff. Logs distinguem tentativas anteriores e matriz final; não se declara execução de todos os testes históricos.
- 12 execuções nativas comparativas (três por versão/resolução), 1600×900 e 1920×1080 reais. Compatibility/OpenGL separado. Capturas de corrida, box, campus e replay. Resultados detalhados em docs/BENCHMARK_0660.md.

## Resultado de desempenho local
Em 1080p, CPU principal 11.066 → 6.228 ms/frame; frames/parede 52.54 → 59.91. Mesmo hardware, trechos curtos; não é medição de GPU nem garantia de FPS universal. O novo passo acumula 3,4 s contra ~3,5 s antigos no roteiro curto, portanto não se usam as capturas como comparação esportiva pareada.

## Verificação após os ajustes finais
O GP integral foi executado antes da otimização final do cache visual. Depois dela, os testes unitários, a integração com cena real e o GP de três voltas foram repetidos; este manteve exatamente o hash anterior. O cache consultado pela HUD permanece aquecido, enquanto cada tick esportivo usa um cache novo e isolado. A primeira matriz nativa, com regressão de desempenho, foi preservada em qa/replay_0660/before_cache_fix. Não se declara uma segunda execução integral de 52 voltas após esse ajuste.

Inspeção das capturas finais: junção do pit sem o leque preto, boxes com consoles/equipe, zebras e edifícios de apoio presentes. O estilo continua procedural e simplificado. A amostra do processo do teste integral registrou VmRSS/VmHWM de 1310412 KiB; é uma observação desse processo, não orçamento universal de memória do jogo.

## Limitações
Identidade cross-platform não testada. Seek é síncrono; trecho antigo pode exigir simular desde o grid e demorar. Só um GP integral foi ensaiado, não temporadas longas. Retenção limitada de checkpoints não limita os históricos originais do motor; memória pode crescer durante uma corrida longa. 32× pode não acompanhar em tempo real. Importação limitada a 256 MiB; gravação limitada a 400000 ticks. Comparações de FPS/speeds usam fixtures controladas; o GP integral valida replay, não cinco execuções renderizadas completas em cada velocidade.

## Pacote e próxima etapa
Projeto completo com cenas/assets/scripts/testes/documentação e evidências. Manifesto SHA-256, CRC, reextração limpa, importação e testes registrados externamente em VERIFICACAO_ZIP_0660.json. Próxima versão: **0.6.6.1 — Advanced Racing AI / Driver Dynamics**, conforme plano específico. Não iniciada nesta entrega.
