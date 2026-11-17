# Relatório de validação — Apex 0.6.2.2

**Implementação:** alteração real de scripts GDScript e arquivo `project.godot`, derivada da versão 0.6.2.1.

- `tests/test_0622_hud_layout.py`: passou (geometria de cartões e overlays nos breakpoints 1600×900, 1920×1080, 1366×768 e 1280×720, pré-carregamentos e integridade do motor).
- `tests/test_0612_indent_static.py`: passou (indentação e mapa estratégico).
- Suíte legada `tests/run_all_static.py`: **21/35** passaram. As 14 falhas incluem hashes congelados do mapa de versões antigas, referências a códigos movidos para módulos e verificações exatas de versões 0.6.2.0/0.6.2.1. São testes históricos que precisam ser atualizados; não são automaticamente defeitos novos, nem provam ausência de regressões.
- Godot 4.7.2 indisponível aqui. **Não foram executados** parsing GDScript nativo, `tests/core_0622_corner_hud_smoke_test.gd`, execução ou inspeção visual renderizada.
- O motor de simulação, clima, pneus, geometria 2D/3D e dados de temporada estão inalterados **byte por byte** frente à 0.6.2.1.

## Validação no computador do jogador

1. Importar `project.godot` em pasta separada e executar com F5.
2. Abrir Corrida > alternar 2D / aérea / TV, zoom e Manual/Auto; testar retorno ao menu.
3. Abrir T, D, E e C do piloto 1 e depois piloto 2; em especial Estratégia nos dois cartões e painel geral, agendamento de pit e chamada imediata.
4. Verificar pausa/velocidade, 1600×900 e 1920×1080, competição entre o mapa e o painel aberto, e legibilidade das informações.
5. Se houver erro vermelho, fornecer primeira linha com arquivo/linha do parser.
