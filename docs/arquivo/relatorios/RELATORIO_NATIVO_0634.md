# Relatório técnico — APEX 0.6.3.4

**Ambiente:** Godot 4.7.2.stable.official, Linux x86_64 no ambiente de execução. Não é uma execução no computador do usuário.

| Verificação | Resultado |
|---|---|
| Importação do editor Godot (`--headless --editor --quit`) | PASS (código sem erro de parser) |
| `core_0634_radio_memory_smoke_test.gd` | PASS |
| `core_0633_radio_categories_soul_smoke_test.gd` | PASS |
| `core_0632_engineer_interactive_smoke_test.gd` | PASS |
| `core_0631_radio_engineer_smoke_test.gd` | PASS |
| `core_0630_driver_radio_smoke_test.gd` | PASS |
| `core_0625_dry_strategy_smoke_test.gd` | PASS |
| `core_0627_tv_director_smoke_test.gd` | PASS |
| `core_0629_environment_smoke_test.gd` | PASS |
| `core_0629_calendar_smoke_test.gd` | PASS |
| Captura gráfica real no Xvfb/OpenGL, 1600×900 (`native_capture_0634.gd`) | PASS, PNG criado |
| Simulação comparada com v0.6.3.3 (seed 141, 240 passos × 4 s) | IGUAL: 24 carros, volta 9 |
| Janela prevista ultrapassada (V9 em andamento após V11) | PASS: resposta não apresenta V9 como futura |
| Troca de piloto, consulta repetida, filtro TV/equipe | PASS |

### Limitações

- Não foi concluída uma corrida inteira até a bandeirada nem testado o jogo no PC do usuário.
- Os avisos de âncoras e SubViewportController preexistentes continuam no log. Nenhuma alteração foi feita para mascará-los nesta versão.
- O novo estado de memória do rádio vive na interface até o final do GP; não persiste entre sessões.
- Filtro individual se aplica aos eventos identificados com o ID do carro. Mensagens antigas sem esse ID podem não aparecer quando o filtro está ativado, por design.
- Não houve importação de mods comerciais de Assetto Corsa para o pacote.
