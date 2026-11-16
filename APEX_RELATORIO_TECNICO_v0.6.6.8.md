# APEX Motorsport Manager — Relatório técnico v0.6.6.8
## HUD ReBroadcast 2.0 — atualização experimental, não release estável homologada

**Motor:** Godot 4.7.2.stable.official.ed1daf0bf (Linux x86_64).  
**Projeto-base:** v0.6.6.7.2.4 PITLANE CPU COMPLETO.  
**Escopo autorizado:** apresentação da HUD. Nenhum sistema da Next Engine foi iniciado.  
**Estado de qualidade:** implementação funcional com testes nativos e capturas reais; validação integral de corridas e hardware-alvo ainda pendente.

## 1. Integridade e auditoria

O arquivo recebido foi reconstituído a partir de `APEX.zip.part000`, `APEX.zip.part001` e `APEX.zip.part002`, totalizando **110.205.203 bytes**.

- SHA-256 do ZIP-base: `f5087e1e6b27b3acad7305fae8bf8eed4f8477b434961d6162e6bbfef290e594`.
- Verificação ZIP/CRC: `PASS` em **2710** entradas.
- Extração isolada: `PASS`.
- Importação inicial no Editor Godot 4.7.2 em modo headless: `PASS`, retorno 0.
- Encontrados 362 scripts `.gd` e apenas 1 cena `.tscn` no ZIP original; a maior parte da interface é criada programaticamente.

A interface visível real nasce de `scripts/apex_race_hud_0622.gd` via `scripts/apex_race_ui_legacy_builder.gd`. A HUD legada permanece criada por compatibilidade, mas é escondida por `scripts/apex_race_ui_layout.gd`. A integração **não** altera a interface desativada em paralelo.

## 2. Modificações funcionais

- `scripts/apex_hud_rebroadcast_0668.gd` (novo): modos nomeados, persistência em `user://hud_rebroadcast_0668.cfg`, atualização incremental da classificação, estados de box e cores de compostos.
- `scripts/apex_race_hud_0622.gd`: seletor BROADCAST/COMPACT/FULL, novas colunas de pneus e situação, fonte e espaçamento de classificação, modo ÚLTIMA VOLTA, status de sessão, clima real x previsão, links funcionais para Pit Wall 3.0/estratégia/engenharia/gráficos, layout responsivo e cards exibidos por modo.
- `scripts/apex_race_hud_skin_ui01.gd`: identidade ReBroadcast (laranja APEX `#FF8A21`, superfícies `#212B35` / `#303842`, branco `#F3F5F6` etc.), reutilizando tema existente.
- `scripts/main.gd` e `project.godot`: identificação da versão. O diretório customizado de saves **não foi alterado**.

A tabela de classificação mantém 24 linhas construídas uma vez. Em cada atualização, compara valores e atualiza somente campos que mudaram. A classificação esportiva continua vindo de `race.get_sorted()` e seus dados `interval`, `gap`, `last_lap`, `tire`, `pit_scheduled_lap`, `pit_left` e outros campos existentes. Nenhuma classificação, lacuna, pneu ou ocorrência foi calculada a partir de dados visuais inventados.

Os botões das telas de controle mantêm callbacks existentes (`host.race.order_pit`, `host.race.schedule_pit`, `host._change_pace`, `host._focus_driver` etc.). Esses métodos preservam o processamento atual via fila de comandos e validações. Não foram introduzidas alterações de física, estratégia, IA, replay, minimapa ou regras esportivas.

## 3. Contratos, segurança e regressões

- A HUD consome estado da corrida e chama os validadores originais ao enviar comandos.
- Não foram editados `scripts/race_engine.gd`, `scripts/core/**`, replay oficial ou as rotinas de renderização 2D/3D.
- Seleção de piloto e destaque do leaderboard usam o identificador existente (`manual_driver`), sem reordenar a corrida.
- Uma reserva manual de pit na V21 foi preservada sob chuva na regressão `replay_0660_boundaries.gd`; também passaram `race_0645_intelligence_test.gd` e o teste de comandos simultâneos `pitwall_0667_same_tick_regression.gd`.
- O teste `hud_rebroadcast_0668_integration.gd` confirmou **34 verificações** e imutabilidade de `race.cars` após mudanças de modo, refresh da classificação e abertura de painéis.
- O Replay oficial passou no teste de **200 ticks** com velocidades 1, 2, 5, 16 e 32, checkpoint, seek e arquivo. Corrida integral de Monza 53 voltas: `NOT_RUN`.

## 4. Testes reais

Foram registrados **18 PASS** na matriz de 27 itens do arquivo `APEX_TESTES_v0.6.6.8.json`. Os PASS de pista significam **smoke tests de 12 ticks**, não GPs completos.

| Ensaio | Estado | Evidência |
|---|---|---|
| Unitário do helper e do design system | PASS | `hud_rebroadcast_0668_unit.gd` |
| HUD real, 24 pilotos, 3 modos, preferência local | PASS | `hud_rebroadcast_0668_integration.gd` |
| Silverstone seco, Spa chuva forte, Monza seco, Singapura chuva forte — 12 ticks cada | PASS | `hud_rebroadcast_0668_scenarios.gd` |
| V21 não antecipada para V4, chuva | PASS | `replay_0660_boundaries.gd` |
| Conflitos do mesmo tick / pit wall | PASS | `pitwall_0667_same_tick_regression.gd` |
| Speed 1x/5x | PASS | `speed_control_066721.gd` |
| Replay 200 ticks / 1x, 2x, 5x, 16x, 32x | PASS | `replay_0660_test.gd` |
| HUD antiga: cards, painéis e janelas existentes | PASS | `core_0622_corner_hud_smoke_test.gd` |
| Capturas nativas Godot Xvfb 1600×900, 1920×1080 em 2D; COMPACT 3D a 1600×900 | PASS | `qa/hud_rebroadcast_0668/*.png` |
| Resolução exata 1366×768 | INCONCLUSIVE | Virtual X11 retorna 1365×768; três capturas nessa resolução real estão incluídas |
| Corridas completas das quatro pistas, comparação FPS em GPU real, Diretor TV integral, saves legados | NOT_RUN | Limitações documentadas na matriz |

Capturas foram geradas **pelo Godot 4.7.2 com Xvfb e Mesa llvmpipe**; são telas reais da simulação no começo da sessão, não mockups. O backend de áudio virtual emitiu aviso ALSA e utilizou driver dummy; isso não afetou os resultados gráficos. As capturas mostram o grid inicial e **não** provam sozinhas uma corrida completa.

## 5. Benchmark A/B — CPU da atualização da HUD

Condições iguais: Silverstone seco, seed 1208, 1600×900, 200 chamadas `refresh_hud()` com estado esportivo inalterado. Modo **headless**, logo não mede FPS ou apresentação GPU.

| Métrica | Base | ReBroadcast |
|---|---:|---:|
| Tempo total 200 refreshes | **431,721 μs** | **236,875 μs** |
| Tempo médio por refresh | **2158.605 μs** | **1184.375 μs** |
| Godot `Performance.MEMORY_STATIC` | **103,897,972 B** | **105,149,775 B** |
| Estado esportivo alterado pela leitura | Não | Não |

Redução observada no ensaio de refresh: **45.13%**. Memória estática observada foi **+1,251,803 bytes**. Trata-se de **uma única amostra de carga estacionária**, sem FPS, RSS, GPU, corrida longa ou inferência geral de superioridade do motor.

## 6. Limitações e pendências

1. Testar GPs completos de Silverstone, Spa, Monza e Singapura, inclusive chuva forte e pit stops reais em muitas voltas.
2. Validar FPS, RSS, consumo de CPU e qualidade visual no PC Linux Mint do usuário, sem depender exclusivamente de llvmpipe.
3. Exercitar interativamente o Diretor TV, rádio, seek/replay e entradas manuais durante uma corrida longa.
4. Executar verificação de compatibilidade com saves legados e preferência da HUD após reinício completo do jogo.
5. Validar 1366×768 em display real; Xvfb presente aplicou diferença de um pixel.
6. Os protótipos Next Engine 1.0 foram intencionalmente deixados fora deste release.

## 7. Rollback

1. **Guardar o ZIP-base v0.6.6.7.2.4.** Este release não sobrescreveu seu arquivo original.
2. Se necessário, fechar o Godot, manter backup dos saves e extrair o ZIP-base numa pasta separada.
3. Executar o `project.godot` da pasta antiga. A configuração `config/custom_user_dir_name="APEX_0650_SOUL_STAFF"` foi preservada em ambas as versões.
4. As escolhas de modo da v0.6.6.8 usam apenas `user://hud_rebroadcast_0668.cfg`; não exigem migração de saves antigos.
5. Não substituir saves de carreira sem backup; este pacote não altera o esquema de salvamento.

**Conclusão:** entrega experimental de HUD com código integrado e evidência de testes. Não classificar como **ESTÁVEL** até validar GPs completos e ambiente gráfico do PC-alvo.
