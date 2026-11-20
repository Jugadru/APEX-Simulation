# Relatório de validação nativa — Apex v0.6.3.1

**Ambiente:** Godot 4.7.2.stable.official.ed1daf0bf (Linux x86_64), executável fornecido. Testes no ambiente de execução desta conversa; experiência no Linux Mint do usuário não foi verificada aqui.

| Verificação | Resultado |
|---|---|
| Importação `--headless --editor --quit` | PASS, exit 0; nenhum erro de parser |
| Teste novo `core_0631_radio_engineer_smoke_test.gd` | PASS: troca piloto/engenheiro, prioridade por clima, cooldown, filtro equipe e transmissão |
| Regressão `core_0630_driver_radio_smoke_test.gd` | PASS |
| Estratégia seca `core_0625_dry_strategy_smoke_test.gd` | PASS |
| Diretor TV `core_0627_tv_director_smoke_test.gd` | PASS |
| Cenários de circuito `core_0629_environment_smoke_test.gd` | PASS |
| Calendário `core_0629_calendar_smoke_test.gd` | PASS (20 de 20) |
| Paridade v0.6.3.0 vs v0.6.3.1 | IGUAL em 24/24 carros após 240 etapas de 4 segundos (960s / volta 9), mesma seed 141 e Spa com clima variável; tempo, posição, desgaste, pneu, pits e solicitações idênticos |
| Abertura gráfica com Xvfb/OpenGL software | PASS, exit 0, `--quit-after 120`; nenhum erro de GDScript |

**Avisos de ambiente e layout já existentes:** driver ALSA indisponível no servidor de testes (Godot usa áudio dummy); avisos de âncoras e dimensionamento de SubViewport. Nenhum desses avisos foi resolvido nesta entrega porque a HUD e as câmeras aprovadas foram preservadas.

**Pendências:** corrida inteira até bandeirada com cenários variados, testes na instalação Linux Mint do usuário, checagem visual da janela de rádio aberta durante disputa prolongada. A comparação de 9 voltas não equivale a uma prova completa.

## Como executar os testes

```bash
./Godot_v4.7.2-stable_linux.x86_64 --headless --path /caminho/para/APEX_GODOT_0.6.3.1_RADIO_INTELIGENTE --script res://tests/core_0631_radio_engineer_smoke_test.gd
```

Para jogar, importar `project.godot` no Godot 4.7.2 e pressionar F5. Em corrida, acessar **RÁDIO → EQUIPE** para focar nas conversas da própria equipe.
