# Apex Motorsport Manager — v0.6.2.0 (HUD de corrida experimental)

Base: `Apex_0612_Hotfix_Parse_Godot.zip` (v0.6.1.2).

## Implementado em Godot

1. **Nova camada de HUD independente:** `scripts/apex_race_hud_0620.gd`, conectada ao estado real de `race_engine.gd` via `main.gd`. A HUD legada permanece no projeto temporariamente, mas oculta durante as corridas; o menu principal, o garage e o modo campeonato foram preservados.
2. **Sem faixa superior grande:** canto superior esquerdo com volta/relógio, cinco botões pequenos no canto superior direito: Corrida, Estratégia, Dados, Eventos e Rádio.
3. **Classificação compacta:** posição, sigla do piloto, cor da equipe e **somente uma métrica dinâmica**. Setas alternam intervalo à frente, diferença para o líder, paradas, melhor volta e composto + voltas do stint (`M 18`, por exemplo). Tecla `I` também alterna.
4. **Dois cartões fixos compactos:** quatro botões verticais (T/D/E/C). Cada botão expande **um único painel para cima**, independente para cada piloto, sem abas duplicadas: Telemetria, Desempenho, Estratégia e Carro. O cartão base não muda de posição. Fechar ou clicar novamente recolhe.
5. **Pit rápido e planejamento:** botão BOX no cartão para ordem imediata, e janela geral de Estratégia para comparar ambos os pilotos, selecionar composto, agendar/cancelar paradas. O contexto Estratégia do cartão permite definir composto, volta e autonomia do engenheiro de box.
6. **Timeline de stints:** `scripts/apex_strategy_planner_0620.gd`, com stints reais do histórico e visualização semitransparente de paradas **explicitamente agendadas**. Não cria stints futuros fictícios.
7. **Controles inferiores:** pausa/retomar, velocidade com setas `1×, 2×, 5×, 10×, 16×, 32×`, manual/automático, mapa estratégico 2D / câmera aérea 3D / diretor TV, zoom e MENU.
8. **Lateral direita discreta:** clima/pista de forma resumida e minimapa desenhado pelo script já existente, com bolinhas na posição real dos carros. Dados meteorológicos mais detalhados no painel Dados.
9. **Câmera:** nova corrida entra por padrão em câmera aérea 3D. Ao entrar no mapa 2D, enquadramento permite aproveitar melhor a área central, sem alteração na geometria do traçado.
10. **Rádios e eventos:** janelas acessam os registros do motor e do sistema de comentários existente, sem áudios ou eventos inventados.

## Limitações conscientes

- O sistema atual **não calcula danos separados de motor/câmbio/freios**, portanto a aba Carro não inventa percentuais inexistentes.
- O sistema atual não calcula estimativas completas de tráfego e posição após o pit, nem cria propostas A/B/C da IA. A janela indica onde esses cálculos faltam. Não confundir stints explicitamente agendados com planos recomendados.
- Problemas anteriores de IA de pit, desgaste excessivo, paradas prematuras e chuva **não foram corrigidos nesta entrega**.
- O componente anterior continua nos arquivos para preservar a lógica e diminuir risco de regressões. Refatoração/removal só depois de testes reais de Godot.

## Validação realizada

- `tests/test_0620_hud_static.py`: PASS.
- `tests/test_0612_indent_static.py`: PASS para 71 scripts `.gd`.
- Checagem lexical portátil de parênteses/chaves/colchetes: PASS nos scripts novos e `main.gd`.
- Motor `race_engine.gd`, `garage.gd`, `track_map.gd`, `apex_mini_map.gd`, `apex_telemetry.gd`, `championship_2012.gd` e `core/race_team_autonomy.gd`: idênticos aos do ZIP v0.6.1.2.
- Suíte histórica antiga `tests/run_all_static.py`: **24/33**. As nove falhas têm testes amarrados ao hash histórico do mapa alterado em v0.6.1.1, strings/nomes de HUD anteriores ou uma pasta absoluta de código não presente neste ambiente. Ver log no `RELATORIO_TESTES_0620.md`.
- **Godot 4 não disponível nesta máquina**, portanto **não foi possível confirmar importação/parse nativo, cliques ou resultado visual**. Incluído `tests/core_0620_hud_smoke_test.gd` para execução no seu Godot.
