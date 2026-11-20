# Apex Motorsport Manager v0.6.4.9.5 — Planejador Pré-Corrida

Base: v0.6.4.9.4 (Confiança Estratégica). Projeto Godot 4.7.2 completo.

## O que mudou nesta versão

**Uma única funcionalidade nova:** planejamento estratégico de stints **antes** da largada.

- Botão `PLANEJADOR DE STINTS / ANTES DA LARGADA` no menu de preparação.
- Dois painéis lado a lado, um por piloto, com **curvas de condição estimada dos pneus**, composto de cada stint, volta prevista de troca e janela aproximada (±2 voltas).
- Otimização determinística **indicativa**, respeitando os **dois compostos secos nomeados para o circuito em 2012**, desgaste máximo previsto de 86%, tempo de pit do circuito e regra de uso de ambos os compostos.
- A primeira janela dos dois carros pode ser separada por 1–2 voltas se a alternativa estiver dentro de uma margem estimada de 4 segundos, evitando conflito inicialmente previsível. Isso **não é** a coordenação automática ao vivo, que fica para a futura v0.6.4.9.7.
- Em **MANUAL**, `APLICAR PRIMEIRAS PARADAS` agenda apenas a **primeira** parada de cada piloto ao entrar no grid. É escolha explícita do jogador; todos os demais stints são sugestões visuais, não novas ordens.
- Em **AUTOMÁTICO**, o botão de aplicação fica desativado, e o motor mantém controle integral sobre seus pits. Visualização apenas.
- Mudança de equipe, circuito, seed, clima, modo ou níveis do carro **invalida** as reservas do plano aprovado. Nenhuma parada é executada automaticamente ao abrir o planejador.
- Largada com intermediário ou chuva: planos secos não são aplicáveis. A interface informa que é preciso avaliar a chuva durante a prova.
- Saves independentes: `ApexMotorsportManager_PitWall_06495`.

## Uso

1. Extraia o ZIP em uma nova pasta e abra `project.godot` no Godot **4.7.2**.
2. Selecione equipe, circuito, seed e cenário de clima.
3. Clique em `PLANEJADOR DE STINTS / ANTES DA LARGADA`.
4. Compare os dois planos, curvas estimadas e janelas iniciais.
5. Se estiver no **Manual** e desejar agendar as primeiras paradas, clique `APLICAR PRIMEIRAS PARADAS (MANUAL)`; depois inicie a corrida. Se não confirmar, nada será agendado.
6. Durante a corrida, altere/cancele os agendamentos manualmente se o clima, tráfego ou pneus exigirem. **Uma ordem manual confirmada não é alterada automaticamente pelo engenheiro.**

## Limites importantes

- **Não é previsão perfeita de corrida.** O cálculo pré-GP aproxima degradação a partir de parâmetros de jogo. Não prevê ultrapassagens, tráfego, adversários entrando nos boxes, incidentes, Safety Car nem a chuva futura.
- Curvas mostram **condição prevista**, não telemetria medida. As voltas consideradas ideais são estimativas sem tráfego; a IA de ajuste dinâmico **a cada volta** será implementada apenas na v0.6.4.9.6.
- A programação manual cobre **somente a primeira parada**, não o restante da estratégia. É preciso escolher/corrigir os stints seguintes durante a corrida.
- Não foram alterados: `scripts/race_engine.gd`, `scripts/core/race_pitwall_strategy_0649.gd`, modelos de pneus, clima, física, estratégia automática, rádio, Soul Driver, Staff e HUD de corrida.

## Testes executados

Godot 4.7.2, Linux / Xvfb Mesa software:
- Importação editor: exit 0.
- `pre_race_06495_planner_test.gd`: PASS / exit 0, Silverstone seco/molhado e integridade dos cálculos.
- `pre_race_06495_scene_ui_test.gd`: PASS / exit 0; tela real 1600×900 e 1920×1080; confirmação MANUAL, descarte por seed alterada, modo AUTO e captura.
- `pre_race_06495_first_laps_test.gd`: PASS / exit 0; passos nativos de 0,20s até a V5, duas reservas mantidas, nenhum pit antecipado.
- `pre_race_06495_real_first_pits_test.gd`: registrou **PASS** ao alcançar V21, com trocas efetivas em V16 e V17 e pneus corretos após 9.542 ticks. O executor externo excedeu seu limite durante o encerramento; não há código de saída do executor para registrar como saída limpa.
- Onze regressões legadas (IA 0645, Soul 0647, Staff 0648, Pit Wall 0649, reset de memória 06491, double stack 06492, desgaste 06493, confiança 06494, HUD 0622, pista 0644): todos exit 0.
- Não foi reexecutada uma corrida completa de 52 voltas nesta atualização.

Leia `RELATORIO_TESTES_06495.md` para evidências e limites.
