# Relatório técnico — APEX Motorsport Manager v0.6.6.1

Data: 14/11/2026. Entrega: **Driver Dynamics 1.0 — Ataque e Defesa de Posição**.

## Origem e controle de escopo

Base extraída do arquivo `APEX_MOTORSPORT_MANAGER_v0.6.6.0_DETERMINISTIC_REPLAY_COMPLETO.zip`,
com CRC verificado antes de qualquer edição. SHA-256 do ZIP original:
`5276fc8f887fb51f57b5ad3eec098740cef268405eabb2a74fb52ea5c2d4d5f1`.
A v0.6.6.0 permanece intacta como rollback. Fonte de requisitos:
`docs/APEX_SIMULATION_FONTE_MESTRA_2026-11-13.md`.

Uma funcionalidade esportiva nova: **tomada de decisões táticas de ataque e defesa**.
Não foram refatorados HUD, Pit Wall, gerenciamento de peças, staff, trajetória 3D ou física de pneus.
A progressão continua calculada por `RaceSpace.plan`, sem sorteios novos nem bônus oculto de
velocidade para completar ultrapassagens.

## Código modificado

- `scripts/core/race_driver_dynamics_0661.gd` **NOVO**. Política pura:
  compara vantagem de ritmo já calculada pelo motor (inclusive efeitos existentes de pneus,
  clima, KERS/DRS), desgaste relativo, habilidades, tolerância ao risco, consciência espacial,
  agressividade defensiva e largura disponível. O piloto mantém o lado da manobra;
  escolhe uma alternativa apenas antes da sobreposição e se houver espaço real.
- `scripts/core/race_space_0655.gd` **EDITADO**. Integra a política ao planejador do
  campo congelado; preserva a resolução de corredores e o progresso contínuo. 
  A defesa pode fazer **uma antecipação** e, ao aproximar-se da sobreposição,
  o defensor mantém a linha atual. Em pista estreita, recusa o ataque em vez de
  impulsionar a posição. Eventos táticos alimentam o mesmo stream do motor.
- `scripts/race_engine.gd` **EDITADO**. Passa o snapshot real de clima ao planejador
  e registra o evento de defesa pelo barramento existente.
- `scripts/core/race_replay_0660.gd` **EDITADO**. Mantém ticks de 0,20s, hashes e
  checkpoints do sistema existente; grava `simulation_revision=0661_driver_dynamics`.
  Replays antigos da v0.6.6.0 são recusados **com mensagem clara** porque os novos
  algoritmos mudam os hashes esportivos. Não há falsa compatibilidade nem reprodução silenciosa.
- `project.godot` **EDITADO** apenas nome/descrição da versão.
- `tests/driver_dynamics_0661_test.gd` e `tests/driver_dynamics_0661_visual.gd` **NOVOS**.
- `qa/driver_dynamics_0661/` **NOVO**: logs finais, métricas e imagens reais.

## Contrato determinístico preservado

Mesma seed + mesmo estado + mesmas entradas no mesmo tick + mesmo runtime => mesmo resultado
esportivo, independentemente de consultas da UI, quadros renderizados ou velocidade 1×–32×.
`RaceSpace.plan` não consome RNG e trabalha sobre snapshots. Apenas o motor decide posição,
eventos e tempos, não a câmera. A versão explícita do contrato de replay evita carregar
registros da física anterior como se fossem de 0661.

## Testes realizados — evidência nativa Godot 4.7.2 (Linux)

1. **Teste tático**: 17 verificações PASS, incluindo defesa antecipada e travamento de linha
   no duelo, pista estreita, clima, risco, consciência espacial, pureza do planejador
   e rejeição segura do replay anterior.
2. **Regressões de espaço**: corredor livre passa, corredor estreito bloqueia,
   defensor forte segura atacante marginal, defensor fraco pode ser superado,
   terceiro carro não é atravessado, carro retardatário é respeitado e ordem do array
   não altera o resultado: PASS.
3. **Integração de motor**: eventos, classificação e tomada de posição: PASS.
4. **Replay unitário**: 200 ticks gravados/reproduzidos; 1×, 2×, 5×, 16× e 32×
   com diferentes durações de frame, pausas e backlog: PASS.
5. **Proteção de comandos**: pit V21 não executado sob chuva V4;
   checagem de ordenação de comandos/checkpoint alterado: PASS.
6. **Corridas completas de 3 voltas, a partir do grid, com replay integral dos ticks**:
   Silverstone (GBR, seco), Spa (BEL, chuva intensa), Monza (ITA, seco),
   Singapura (SIN, chuva intensa). PASS; os resultados e hashes estão em
   `qa/driver_dynamics_0661/test_results.json`.
   O teste inclui parada dupla forçada, estágios approach/dock/service/queue/repair/safety_hold/exit,
   classificação única, telemetria e checkpoints intermediários.
7. **Corrida curta do motor com 24 carros e pit**: PASS.
8. **Integração UI/Replay**: cena real 2D/3D, seek, retorno ao vivo e isolamento de
   inventário: PASS. Save legado da oficina v0655: PASS.
9. **Importação Godot 4.7.2**: PASS, sem erros de parser.
10. **Interface e circuito reais, via Godot Compatibility/OpenGL em Xvfb**:
   screenshots 1600×900 e 1920×1080, salvos em `qa/driver_dynamics_0661/`.
   Essas imagens comprovam render da interface; não demonstram, por si só,
   todas as decisões táticas. Aviso ALSA sem dispositivo físico foi contornado
   pelo fallback de áudio do motor.

## Limites / riscos

- Não foi repetida uma **corrida oficial de 52 voltas** nem uma temporada completa
  nesta versão. Portanto a entrega é **release candidate funcional testada**,
  não certificação global de estabilidade/balanceamento.
- Não houve comparação calibrada de quantidade de ultrapassagens ou incidentes
  em temporadas de F1 2012. Os coeficientes táticos são de gameplay, não telemetria da FIA.
- Não se verificou compatibilidade determinística entre Linux e outras plataformas.
- Replay 0660 criado anteriormente não pode ser reproduzido pela física 0661;
  para assistir à gravação anterior, utilizar o ZIP 0660 arquivado.
- Um teste **histórico de migração Soul Staff 0650 (9.9 → 6.5.0)** falhou:
  não localizou orçamento e dados do staff no caminho legado e encerrou com
  erro ao ler `Estrategista`. O teste não é marcado como PASS. Ele não foi
  corrigido nesta versão porque os módulos de contratos/garagem não fazem
  parte da alteração esportiva; a auditoria completa de migração permanece
  pendente. Log em `qa/driver_dynamics_0661/logs/soul_staff_0650_migration_test.log`.
- Testes de save/load da campanha e da oficina não foram repetidos
  integralmente; o teste específico de leitura da oficina v0655 PASSOU.
- Capturas exigiram software rasterizer llvmpipe; não são benchmark GPU/CPU de jogador.

## Próximo passo sugerido (NÃO incluído)

Repetir corrida oficial integral e avaliar estatisticamente taxa de disputas,
defesas, recuos e erros por tipo de pista e por personalidade antes de mudar
parâmetros de física. Não avançar automaticamente à v0.6.6.2.
