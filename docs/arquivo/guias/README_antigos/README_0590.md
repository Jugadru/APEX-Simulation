# Apex Motorsport Manager v0.5.9.0 — instruções Linux Mint

Esta versão retoma o roteiro histórico após a v0.5.8.0. **A v0.6.0 continuará reservada à integração da gestão e temporada de 2012**. A HUD 0.6.0 experimental anterior não faz parte deste pacote.

## Para abrir

1. Extraia o ZIP completo para uma pasta nova (não sobrescreva o projeto antigo).
2. No Godot 4.x, importe `APEX_GODOT_0.5.9.0/project.godot`.
3. No menu do Apex, escolha equipe e GP, depois **GESTÃO DA EQUIPE DURANTE A CORRIDA**: Manual ou Automático.
4. Entre no grid. No Automático, a equipe controla ritmo, KERS e pits, mas você pode intervir nos boxes. Use a opção **EQUIPE** na barra inferior para trocar para Manual.
5. Na Oficina, contrate/treine **Estrategista** e **Engenheiro** para melhorar as regras de delegação. Os dados são salvos no arquivo existente da oficina.

## Verificações

Na raiz do projeto extraído:

```bash
python3 tests/test_0590_static.py
python3 tests/test_0580_static.py
bash linux/validar_core_0590.sh
```

`validar_core_0590.sh` requer o comando `godot` ou `GODOT_BIN=/caminho/para/o/Godot`. Sem Godot, termina com código 2 depois das verificações Python, indicando *runtime não testado*.

Para rodar diretamente o novo smoke teste:

```bash
godot --headless --path . --script res://tests/core_0590_team_control_smoke_test.gd
```

O teste confirma agendamento V21, alternância IA/Manual e decisões automáticas de ritmo/KERS no cenário preparado. **Não prova equilíbrio de uma corrida completa.**

## Observação

Não houve atualização da engine gráfica, da HUD de 1600×900 nem da simulação Core 2 neste pacote. A contratação de STAFF é inicialmente um modelo de níveis, não um mercado de pessoas individuais.
