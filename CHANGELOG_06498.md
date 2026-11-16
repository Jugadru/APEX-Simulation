# Changelog — v0.6.4.9.8

**Função principal única:** visualização dinâmica de desgaste e estratégias dos dois carros da equipe.

## Código novo (somente leitura)
- `scripts/core/race_strategy_graph_data_06498.gd`: captura histórica observada por piloto e volta, projeção com dados reais, plano inicial congelado, relatório de conflitos confirmado/potencial.
- `scripts/apex_dynamic_strategy_chart_06498.gd`: desenho no Godot das curvas reais/previstas, janela indicada, paradas executadas e faixas comparativas.

## Integração mínima
- `scripts/apex_race_hud_0622.gd`: novo painel de gráficos e links em Estratégia, Pit Wall 3.0 e Engineer 3.0. Mantém a HUD híbrida e seis atalhos.
- `scripts/main.gd`: apenas título da janela.
- `project.godot`: identificação e saves isolados da 9.8.
- Testes nativos, relatório e capturas da execução real.

**Nenhuma alteração** em física, estratégia de IA, execução de pits, lógica 9.7, circuitos, pneus, rádio, carreira ou equipes.
