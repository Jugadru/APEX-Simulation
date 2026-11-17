# APEX — Testes de longa duração (melhoria 8/8)

## Finalidade

Esta melhoria cria uma rotina de **stress e determinismo sem interface gráfica**,
com execuções isoladas de Godot 4.7.2 e preservação do código de produção.

O fluxo reutiliza cenários existentes (sem refatorá-los):

1. `tests/high_speed_growth_066723_benchmark.gd`: 6.000 ticks de Monza,
   seed 660, 24 carros, hashes de replay, amostras a cada 250 ticks e
   memória estática monitorada pelo Godot.
2. `tests/long_race_benchmark_0663.gd`: **GP completo de Monza**, tempo
   seco, seed 660, ordens de pit e replay; exige bandeirada e hash final.
3. A mesma fixture com **GP completo de Silverstone**, chuva intensa,
   seed 661; exige bandeirada e hash final.
4. `tests/career_0667_20_season_data_stress.gd`: 20 temporadas
   **administrativas**, 400 resultados registrados, validação de
   persistência, recargas de arquivo e rejeição de resultados duplicados.

Cada cenário é executado duas vezes com diretórios de usuário Godot
distintos. Divergência nos hashes esportivos, resultados de registros,
falha de carregamento, corrida incompleta ou timeout **reprova** a rotina.

## Limites e métricas

- O script de orquestração coleta logs por execução e JSONs de GP.
- Mostra tamanho da memória estática (monitor Godot) e crescimento
  entre amostras. Telemetria e checkpoints **crescem legitimamente**.
  Crescimento >256 MiB no período ou bloco final 3x mais lento que o
  inicial é sinalizado para investigação, não automaticamente considerado
  vazamento ou regressão de performance.
- Coleta aproximada da memória RSS observável do processo no Linux.
  Se não for possível amostrar, informa `null`, nunca inventa medição.
  RSS observado >2 GiB reprova como limite de proteção do runner.
- O GitHub Actions permite 5 minutos por execução de um cenário e
  timeout total do job de 35 minutos. Esses limites são de CI e
  precisam ser recalibrados conforme hardware e escopo.
- **Não são 400 GPs simulados.** O teste de carreira cobre apenas os dados
  administrativos de 20 campeonatos; não testa carreira multi-ano na UI.
- Não cobre FPS, desempenho da GPU, apresentação 3D, PCs do jogador,
  quantidade arbitrária de temporadas ou desempenho em velocidades
  efetivas 16x/32x.
- Os GPs são física + replay sem apresentação gráfica. O resultado não
  implica que o sistema de pit ou IA está perfeito em todos os cenários.

## Execução e artefatos

No GitHub, abra **Actions → APEX - Testes de Longa Duracao → Run workflow**.

Pode escolher 6.000 ou 10.000 ticks para a simulação de crescimento.
No PR, o padrão é 6.000 ticks. Após integração à branch padrão, também
há execução semanal aos domingos às 12h UTC (9h no Tocantins).

Baixe o artefato `apex-endurance-relatorio` para examinar:
- `report.json` e `report.md` com resultados;
- `growth_monza_*.log` com métricas e hashes por 250 ticks;
- `full_gp_ITA_*.json` e `full_gp_GBR_*.json`, com resultados reais;
- `career_admin_*.log` com validações de escrita/recarga;
- `error.txt` quando o runner rejeitar a execução.

## Preservação

Somente ferramentas de teste, documentação e workflow foram criados.
Não há alteração de física, HUD, IA, salvamento, replay ou recursos do
jogo; não são publicados executáveis ou releases. Cada relatório é
um resultado observável do GitHub Actions, nunca um benchmark inventado.
