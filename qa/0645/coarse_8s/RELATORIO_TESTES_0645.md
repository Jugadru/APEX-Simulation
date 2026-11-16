# Relatório de testes — v0.6.4.5

Data: 09/11/2026. Executado no binário fornecido: `4.7.2.stable.official.ed1daf0bf`.

## Resultado

- Importação/editor sem erros de script.
- Novo teste `race_0645_intelligence_test.gd`: PASS. Decisão pura, adiamento de uma volta, proibição de repetição, proteções para chuva/desgaste/ordem manual/final de corrida, undercut, memória Soul limitada e idempotente, ausência de consumo de RNG, integração real do motor, V21 e conteúdo da HUD.
- 13 regressões anteriores: PASS na execução final de cada teste. Física e pneus; 640 segundos simulados pelo passo nativo de 0,20s; HUD térmica; hotfix de cronometragem; clima; oficina/rivais; migração de saves; engenheiro; Pit Wall; rádio reativo; personalidade; memória de rádio; controle da equipe.
- Renderização real OpenGL/NVIDIA no Godot, 1600×900: PASS. Captura `qa/0645/HUD_UI03.png` inspecionada visualmente: cartões dos dois pilotos, táticas, Soul, alternativas e controles visíveis, diário com rolagem.
- Oito GPs completos com 24 carros, controle de box IA para os dois carros do jogador: PASS. Todos classificados como finalizados, nenhuma violação de compostos sinalizada, relógio crescente e estados térmicos dentro dos limites verificados.

## Oito GPs automáticos

São corridas independentes, seeds 6400–6407, circuitos e distâncias do calendário herdado. Não é uma temporada sequencial. A suíte usa `_advance(8.0)` para acelerar o laboratório. O jogo continua usando subpassos de 0,20s; a bateria longa não comprova equivalência de resultados com oito GPs completos nesse passo nativo.

| GP | Voltas | Tempo simulado (s) | Paradas do grid | Vencedor |
|---|---:|---:|---:|---|
| AUS | 58 | 5320 | 48 | Fernando Alonso |
| MAL | 56 | 6704 | 76 | Fernando Alonso |
| MON | 78 | 6192 | 72 | Sebastian Vettel |
| GBR | 52 | 5352 | 91 | Fernando Alonso |
| BEL | 44 | 5824 | 70 | Sebastian Vettel |
| ITA | 53 | 4720 | 24 | Fernando Alonso |
| SIN | 59 | 6944 | 112 | Fernando Alonso |
| BRA | 71 | 5632 | 42 | Sebastian Vettel |

Climas: AUS seco; MAL chuva intensa; MON seco; GBR variável; BEL chuva intensa; ITA seco; SIN variável; BRA seco. O CSV inclui temperaturas, aderência e borracha. As paradas nas provas variáveis, especialmente SIN (112 no grid), ainda merecem acompanhamento de balanceamento; conclusão e limites de segurança não demonstram estratégia ótima.

## Ocorrências resolvidas e rastreabilidade

O teste novo chamou inicialmente um nome incorreto de método de HUD; foi corrigido para `_open_window` e executado novamente com PASS. A primeira execução da regressão Pit Wall compartilhou o diretório de saves com o teste de campeonato; a carreira herdada selecionou outro circuito. Reexecução em dados isolados passou, sem mudar código do jogo ou enfraquecer a asserção de Interlagos/71. `suite_status.txt` conserva o código inicial 1 e o resultado isolado 0. O script de revalidação usa diretório temporário independente para cada teste.

Os logs finais estão em `qa/0645/`. Arquivos QA de outras versões são histórico. A mudança final no rádio foi validada novamente pelo teste integrado da HUD; não altera o motor utilizado nos oito GPs.

## Preservação e integridade

Comparação direta com o ZIP v0.6.4.4: 140 arquivos de scripts, dados e cenas preservados byte a byte. Somente quatro scripts anteriores foram alterados: `race_engine.gd`, `apex_race_hud_0622.gd`, `main.gd`, `apex_menu_screen.gd`; além de README e configuração do projeto. Foram acrescentados três módulos de implementação. O bloco de cronometragem permanece idêntico ao original, exceto pela chamada observacional do Soul após registrar a volta.

O manifesto registra SHA-256 de cada arquivo distribuído, exceto ele próprio, e a relação de arquivos preservados. O empacotamento valida CRC ZIP, ausência de nomes duplicados/caminhos inseguros e todos os hashes internos. O SHA-256 externo identifica o ZIP completo. Caches `.godot` e dados temporários/saves dos testes são excluídos.
