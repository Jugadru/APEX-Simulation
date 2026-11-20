# Validação nativa — Apex v0.6.3.3

**Ambiente:** executável Godot 4.7.2.stable.official, Linux x86_64 deste ambiente (não é teste no computador do usuário).

| Verificação | Resultado |
|---|---|
| Importação do projeto via `--headless --editor --quit` | PASS (exit 0, sem erros de parser) |
| `core_0633_radio_categories_soul_smoke_test.gd` | PASS |
| `core_0632_engineer_interactive_smoke_test.gd` | PASS |
| `core_0631_radio_engineer_smoke_test.gd` | PASS |
| `core_0630_driver_radio_smoke_test.gd` | PASS |
| `core_0625_dry_strategy_smoke_test.gd` | PASS |
| `core_0627_tv_director_smoke_test.gd` | PASS (exit 0) |
| `core_0629_environment_smoke_test.gd` | PASS (exit 0) |
| `core_0629_calendar_smoke_test.gd` | PASS (exit 0) |
| Captura gráfica no Xvfb/OpenGL, 1600×900, `native_capture_0633.gd` | PASS, PNG de 1600×900 |
| Paridade com v0.6.3.2: `core_0630_parity.gd`, seed 141, 240 passos de 4 s | IGUAL, dados dos 24 carros após ~9 voltas |

## Escopo dos testes
- Os filtros rejeitam comunicações privadas no modo Transmissão. Equipe exclui TV e boxes de equipes rivais. Pilotos inclui somente falas dos pilotos da equipe do jogador.
- A consulta ao piloto e as perguntas ao engenheiro preservaram exatamente o estado de corrida antes/depois nos testes de GUI. A ordem manual de box V21 permaneceu válida.
- A camada de percepção é textual e determinística; não modifica desgaste ou atributos de pilotagem, nem usa números aleatórios do motor.
- As câmeras e o motor permanecem iguais; nenhuma pista externa ou novo modelo comercial foi adicionado.

## Limitações e pendências
- Ainda não foi testada uma corrida inteira até a bandeirada no Godot 4.7.2 nem a execução no Linux Mint do usuário.
- Há avisos antigos de âncoras/`SubViewportContainer` na inicialização. Um teste antigo de expansão vertical da HUD em headless já falhava na versão anterior; não foi alterado nesta entrega.
- As percepções dos pilotos ainda não persistem como traços de personalidade ao longo de uma carreira; são um primeiro recurso subjetivo de rádio, sem alegação sobre pessoas reais.
- As falas são templates baseados no estado da corrida, não IA generativa nem gravação sonora.

## Reproduzir

```sh
GODOT=/caminho/para/Godot_v4.7.2-stable_linux.x86_64
"$GODOT" --headless --path . --editor --quit
"$GODOT" --headless --path . --script res://tests/core_0633_radio_categories_soul_smoke_test.gd
```
