# RELATÓRIO TÉCNICO — APEX Motorsport Manager v0.6.5.0

**Título da fase:** Living Factory & Soul Staff  
**Entrega desta versão:** etapa 1, **Soul Staff 1.0** (uma única mecânica principal)  
**Base:** `APEX_MOTORSPORT_MANAGER_v0.6.4.9.9_STRATEGY_SIMULATOR_COMPLETO.zip`  
**Motor:** Godot 4.7.2.stable.official.ed1daf0bf, Linux, renderizador Compatibility/OpenGL para testes visuais  
**Escopo:** camada de gerenciamento de funcionários; não introduz simulação 3D de fábrica ou de peças individuais

## 1. Implementação — gameplay

| Elemento | Implementação e origem dos dados |
|---|---|
| Profissionais | Os 12 candidatos existentes no mercado da 9.9, preservando cargos, habilidades, salários, custos de contratação e prazo do contrato. |
| Perfil de pessoa | Personalidade, estilo e tendência de reação **ficcionais**, determinísticos por ID de candidato; perfil neutro para contratos antigos sem ID reconhecido. |
| Indicadores | Moral, energia e confiança entre 0 e 100, persistidos no contrato individual. Valores iniciais convencionados para gameplay (70, 78, 65), não estimativas históricas. |
| Relações | Pares entre departamentos contratados; a coesão é a média simples das relações válidas. Sem dois titulares, coesão é N/D na HUD. |
| Reação pós-GP | Melhor colocação observada da equipe, registrada em `championship_2012.gd`, afeta moral, energia, confiança e vínculos, com variação por temperamento. |
| Voz contextual | Texto gerencial específico por pessoa e alertas de baixa energia/moral/confiança ou relacionamento. Não é rádio da corrida nem gravação real de piloto. |
| Ações do jogador | Briefing técnico, Descanso & Suporte e Integração de Áreas: uma ação por GP futuro de temporada, dependente de orçamento. |
| Proteção de save | Chaves de etapas e ações impedem atualizações ou pagamentos duplicados após reabrir a temporada. Não recalcula o Soul Staff em etapas antigas com folha salarial 9.9 já paga. |

### Custos e efeitos internos das ações

| Ação | Custo | Moral | Energia | Confiança | Relação de áreas |
|---|---:|---:|---:|---:|---:|
| Briefing técnico | R$ 85.000 | +3 | -3 | +7 | +3 |
| Descanso & Suporte | R$ 55.000 | +6 | +15 | +2 | 0 |
| Integração de áreas | R$ 120.000 | +4 | -2 | +3 | +9 |

Esses números são **parâmetros explícitos de jogo**; os efeitos são limitados ao intervalo [0,100]. A decisão reduz o saldo econômico real da equipe, mas **não altera a IA de pit, a física ou a classificação da corrida**.

## 2. Integração com sistemas existentes

`staff_soul_0650.gd` e `apex_save_migration_0650.gd` são novos. A apresentação do staff e funções da garagem foram ampliadas. `apex_championship_flow.gd` processa o Soul Staff imediatamente antes da folha da etapa. `championship_2012.gd` só foi alterado para copiar saves válidos de um diretório anterior, sem mudar a pontuação, premiação, calendário, critérios ou simulação.

A visão **OFICINA VIVA** exibe níveis de Motor, Asa, Chassi e projeto atual de pesquisa, lidos da garagem existente. **Nenhuma** nova lógica de P&D, peças físicas, prototipagem, reparos, rivalidade de contratação ou instalação foi criada nesta versão. Essas frentes devem ser desenvolvidas apenas quando uma nova versão for autorizada.

### Migração real de arquivos de usuário

Foi criado um teste com um save de **v0.6.4.9.9** em `XDG_DATA_HOME/APEX_06499_STRATEGY_SIMULATOR`, incluindo orçamento, níveis da oficina, contrato e campeonato. O Godot importou os dois arquivos para `APEX_0650_SOUL_STAFF` sem mudar o conteúdo do diretório anterior. Dados inválidos não são copiados como campeonatos. Contratos antigos recebem os novos indicadores sem cobrança ou expiração antecipada.

## 3. Testes nativos

Todos os testes e capturas foram executados com o executável **Godot 4.7.2** fornecido, sem mockups ou imagens de interface inventadas. Os testes de interface usaram Xvfb + llvmpipe/OpenGL em ambiente Linux. Os testes de simulador usaram o motor `scripts/race_engine.gd` original.

| Teste | Resultado |
|---|---|
| `soul_staff_0650_model_test.gd` | APROVADO — contratação, perfis, indicadores, custos, limites e save |
| `soul_staff_0650_migration_test.gd` | APROVADO — cópia 9.9 → 6.5.0 de garagem e temporada, origem intacta |
| `soul_staff_0650_ui_test.gd` | APROVADO — 1600×900, 1920×1080, ações habilitadas e desabilitadas, HUD 9.9 acessível |
| `soul_staff_0650_season_test.gd` | APROVADO — **GP de campeonato completo, 58 voltas e 1.328 atualizações do motor**, resultado, salário, Soul Staff e idempotência |
| `staff_0648_ui_test.gd` | APROVADO — contratos, orçamento, mecânica anterior, acesso ao Race Engineer 3.0 |
| `team_pit_06497_unit_test.gd` | APROVADO — coordenação de equipe e proteção de ordens |
| `pitwall_0649_strategy_test.gd` | APROVADO — janelas, tráfego, clima e double stack |
| `lap_strategy_06496_auto_gate_test.gd` | APROVADO — decisões da IA por volta e controle manual |
| `pre_race_06495_planner_test.gd` | APROVADO — planejamento real de Silverstone |
| `dynamic_strategy_06498_data_test.gd` | APROVADO — origem dos gráficos 9.8 |
| `dynamic_strategy_06498_parity_test.gd` | APROVADO — paridade de 360 ticks nativos sem alteração de física/IA/RNG |
| `race_0646_engineer_3_test.gd` | APROVADO — Race Engineer 3.0, rádio, pit manual, chuva |
| `strategy_simulator_06499_model_test.gd` | APROVADO — simulação consultiva em três circuitos |
| `soul_staff_0650_three_tracks_test.gd` | APROVADO — paridade A/B, duas corridas por pista, **115 ticks em GBR (5 voltas), ITA (6) e SIN (5)** |

**GP completo da 9.9 reexecutado na 6.5.0:** Silverstone 52/52 voltas, **78 pit stops reais**, 588 cenários consultivos, 6 paradas da equipe e paridade inicial A/B. A tentativa de repetir os 3 GPs completos em uma única rodada automática **foi interrompida pelo limite operacional de 240 segundos após Silverstone**. Não se declara Monza ou Singapura como GPs completos reexecutados na 6.5.0. Os testes de modelo e de paridade curta nessas pistas verificam a manutenção das interfaces.

Um teste inicial de paridade 9.8 atingiu o limite de 35 segundos quando executado concorrentemente com as corridas completas; ele foi reexecutado isoladamente com sucesso (360 ticks).

## 4. Capturas nativas reais

- `docs/APEX_0650_SOUL_STAFF_1600.png`: tela de gestão, 1600×900.
- `docs/APEX_0650_SOUL_STAFF_1920.png`: tela de gestão, 1920×1080.
- `docs/APEX_0650_TEMPORADA_ACOES_1600.png`: as três opções habilitadas antes de GP de campeonato, 1600×900.
- `docs/APEX_0650_POS_BRIEFING_1600.png`: custo abatido, moral, confiança e coesão recalculados, 1600×900.

## 5. Integridade da v0.6.4.9.9 e limites

A comparação por SHA-256 entre os arquivos da fonte 9.9 e os arquivos entregues na 6.5.0 será registrada em `BUILD_MANIFEST_0650.json`. O motor `scripts/race_engine.gd`, os módulos de pit lane, física, pneus, chuva, IA, Pit Wall 3.0, Race Engineer 3.0, Soul Driver, Strategy Simulator 1.0 e HUD de corrida v0.6.4.9.9 permanecem **idênticos byte a byte**. Alterações estão restritas a apresentação de equipe, ciclo gerencial e suporte à migração de saves.

**Limites explícitos:** o impacto emocional não afeta o desempenho de corrida; os custos e indicadores humanos são convencionados para o gameplay. Não há fábricas 3D, estoque individual de peças, teste aerodinâmico adicional, novas decisões automáticas de estratégia, nem calibração psicológica. Um GP avulso não habilita ações de gestão.

**Próximo desenvolvimento:** nenhuma versão posterior foi iniciada.

### Comparação SHA-256 concluída

**1234 arquivos originais mantidos byte a byte; 7 arquivos originais alterados; 0 arquivos originais removidos.**

Arquivos preexistentes alterados: `project.godot`, `scripts/apex_championship_flow.gd`, `scripts/apex_menu_screen.gd`, `scripts/apex_staff_screen_0648.gd`, `scripts/championship_2012.gd`, `scripts/garage.gd`, `scripts/main.gd`.

Todos os arquivos de corrida e física auditados (incluindo `race_engine.gd`, pneus, Pit Lane, Pit Wall, a HUD híbrida e Strategy Simulator 9.9) têm SHA-256 exatamente igual à base 9.9.

Os testes e evidências de execução ficam em `qa/0650/`. Na importação com Godot em ambiente sem acelerador gráfico físico houve avisos de driver Vulkan/áudio; o processo de importação com Xvfb retornou código zero e os testes renderizaram em OpenGL Compatibility.
