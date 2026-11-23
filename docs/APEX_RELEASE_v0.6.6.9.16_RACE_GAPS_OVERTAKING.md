# APEX v0.6.6.9.16 — Race Gaps & Overtaking 2.0 (primeiro incremento)

## Uma funcionalidade: radar de proximidade na HUD

A tela da corrida passa a oferecer uma **oitava métrica de classificação, `DIST. PISTA`**.
Ela consulta as posições reais (progresso da volta) dos **24 carros** e informa,
para cada piloto ativo, o veículo fisicamente mais próximo **à frente** ou,
se não houver um à frente dentro da janela, **atrás**. Não altera a métrica
de `INTERVALO`, `LÍDER` ou `ATRÁS`, que continuam mostrando os valores
cronométricos/estimados do RaceEngine.

A nova métrica **não é um intervalo de segundos nem uma posição de classificação**.
O modelo RaceSpace usa **unidades esquemáticas de circuito**, não metros GPS/FIA.
Por isso o resultado curto aparece como `F 4u`, `T 20u`, `LIVRE` ou `—`.
O tooltip identifica o carro físico à frente e atrás, com a distância estimada
e a explicação das unidades. Um piloto uma volta atrás ainda pode ser um obstáculo
físico na pista. A busca usa distância circular módulo uma volta, inclusive
em travessias da linha de chegada. A janela de observação é 38 unidades,
igual à janela já usada pelo planejamento de tráfego.

Os relatórios são exclusivamente de **apresentação**, calculados a partir
da mesma ordem imutável recebida no começo do refresh da HUD. O radar não
envia rádio, ordens, velocidade, DRS, KERS ou instruções de ultrapassagem.
Carros nos boxes, desclassificados ou finalizados não aparecem como rivais ativos.
Nenhuma variável é salva ou entra nos hashes. **Replay continua `023_overtaking_intelligence_v1`**.
A heurística de ataque/defesa 9.12 não foi modificada nesta versão.

## Arquivos

- `scripts/presentation/apex_hud_race_gaps_066916.gd`: cálculo puro da proximidade circular, sem RNG ou mutação.
- `scripts/apex_race_hud_0622.gd`: integração na seleção de métricas existente e tooltip informativo.
- `tests/race_gaps_066916_test.gd`: travessia da linha de chegada, retardatário, boxes, final de prova, disputa por posição, empates determinísticos, HUD real e hashes de 24 pilotos.
- `tools/apex_ci_tiers.py`, `.github/apex-quality-suites.json`, `.github/workflows/godot-setup.yml`: seleção e execução no pipeline FAST consolidado, sem workflow por versão.

## Aceite — política FAST permanente

**Somente FAST + APEX Test Lab + regressões direcionadas**, conforme
`AGENTS.md` e `docs/APEX_CI_INTELIGENTE_TRES_NIVEIS.md`. O teste
`RACE_GAPS_066916_PASS` e `OVERTAKING_066912_PASS` são exigidos
no SHA exato, junto ao FAST do Godot 4.7.2. Não executar FULL automaticamente.

A verificação deve preservar o BOX manual V21, o determinismo do replay
e os intervalos de classificação antigos. Esta versão **não é uma promessa de
overtaking físico mais frequente**: a melhoria é tornar o estado de aproximação
dos carros visível ao jogador, preparando futuros refinamentos esportivos
com revisão de replay própria.

**Distribuição binária:** integrar o código na main não gera por si só ZIP
jogável da 9.16. A última compilação distribuída continua a 9.15 até novo build.
