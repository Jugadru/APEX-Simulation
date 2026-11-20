# Relatório de validação — APEX 0.6.3.5

Data: 07/11/2026. **Ambiente:** Godot 4.7.2.stable.official no Linux x86_64, disponível ao assistente, não no PC do jogador.

## Validações concluídas

- [x] Importação nativa em Godot (`--headless --editor --quit`) sem novos erros de parser.
- [x] `core_0635_soul_stint_smoke_test.gd`: diálogo, divergência racional, preferência de piloto, repetição, filtros, reinício de memória, HUD e não alteração do estado.
- [x] `core_0634_radio_memory_smoke_test.gd`
- [x] `core_0633_radio_categories_soul_smoke_test.gd`
- [x] `core_0632_engineer_interactive_smoke_test.gd`
- [x] `core_0631_radio_engineer_smoke_test.gd`
- [x] `core_0630_driver_radio_smoke_test.gd`
- [x] `core_0625_dry_strategy_smoke_test.gd`
- [x] `core_0627_tv_director_smoke_test.gd`
- [x] `core_0629_environment_smoke_test.gd`
- [x] `core_0629_calendar_smoke_test.gd`
- [x] Execução gráfica com Xvfb/OpenGL (1600×900), incluindo novo botão e registro CHEFE/PILOTO/ENGENHEIRO.
- [x] **Paridade:** seed 141, 240 passos × 4 s, GP de Spa; instantâneo da v0.6.3.4 e da v0.6.3.5 idênticos para 24 carros na volta 9.
- [x] Nenhuma mudança no arquivo `scripts/race_engine.gd` nem nos sistemas de câmeras e pista.

## Cenários de proteção

- Divergência com desgaste 67% e aquecimento 70%, sem alterar estratégia.
- Chuva com pneus de seco: o piloto manifesta preocupação, não propõe extensão automática.
- Plano estimado ultrapassado: não é mostrado como janela futura.
- Ordem manual V21 mantém-se válida.
- Conversas internas não são exibidas em Transmissão; filtros por piloto continuam funcionando.

## Pendências e limites

- Ainda não foi validada uma corrida completa até a bandeirada nesta versão.
- Avisos preexistentes de âncoras de `Control` e tamanho de `SubViewportContainer` continuam nos logs; a correção está fora do escopo desta entrega.
- Modelos externos de Assetto Corsa não foram distribuídos.
- O comportamento psicológico é ficcional e não histórico; memória limitada a um GP.
