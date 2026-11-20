# Apex Motorsport Manager v0.6.0 — Temporada 2012 (experimental)

Base: v0.5.9.0 Hotfix 2, cuja chamada de box pela IA foi confirmada em teste do usuário no Linux Mint.

## Novidades

- Modo **Temporada 2012** com os **20 GPs** no calendário da base original, **12 equipes** e **24 pilotos**.
- **NOVA TEMPORADA**: cria campeonato; **CONTINUAR**: retoma a etapa pendente; **GP AVULSO**: não interfere nos pontos de campeonato; **CLASSIFICAÇÃO/RESULTADOS**: abre pilotos, construtores e calendário.
- Ao concluir uma corrida no modo temporada, resultado da grid completa é registrado **uma única vez** e somado à pontuação **25, 18, 15, 12, 10, 8, 6, 4, 2, 1**, sem ponto de volta mais rápida (regra de 2012).
- Após a bandeirada, **PRÓXIMO GP** devolve ao menu com a pista e equipe corretas, sem iniciar automaticamente a próxima etapa.
- Salvamento de campeonato em `user://apex_championship_2012_v060.json` com escrita temporária e renomeação.
- Orçamento e upgrades continuam usando a oficina existente (`user://apex_garage_050.json`). O campeonato credita valores **fictícios de gameplay** ao caixa por GP, protegidos por identificador para não pagar duas vezes, inclusive após reinicializar o jogo.
- Manual/Automático, IA dos boxes, STAFF inicial, pistas, pneus, 2D, 3D e Diretor TV foram mantidos.

## Abrir no Godot

1. Extraia o ZIP completo em uma pasta nova.
2. Abra Godot 4.x e importe `APEX_GODOT_0.6.0_TEMPORADA_2012_EXPERIMENTAL/project.godot`.
3. Pressione **F5**. Clique **NOVA TEMPORADA** e confirme. No rodapé fixo do menu, clique **DISPUTAR ETAPA 1/20**.
4. Termine o GP da Austrália (pode usar velocidade 16× e IA da equipe no modo AUTO). Após a bandeirada, clique **PRÓXIMO GP** e veja os pontos na classificação.
5. Feche e reabra o jogo. **CONTINUAR** deve mostrar Malásia como segunda etapa, com a classificação e os níveis da oficina preservados.

A temporada é salva **entre corridas concluídas**, não no meio de um GP. Sair antes da bandeirada significa refazer essa etapa. O jogo ainda não possui treino livre/classificação com sessões separadas nem patrocínio/contratos completos; isso fica para atualizações posteriores.

## Validação no Linux Mint

```
cd APEX_GODOT_0.6.0_TEMPORADA_2012_EXPERIMENTAL
bash linux/validar_0600.sh
```

Se o executável Godot não estiver em PATH, use `GODOT_BIN=/caminho/para/Godot bash linux/validar_0600.sh`.

`validar_0600.sh` roda os 29 testes Python, checa o parser nativo com `--headless --editor --quit` e executa `tests/core_0600_championship_smoke_test.gd` em arquivo temporário separado, **sem sobrescrever seu save de campeonato**. Se não houver Godot instalado, termina com código 2, preservando a distinção entre testes Python e runtime.
