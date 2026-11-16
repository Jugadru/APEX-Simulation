# Apex Motorsport Manager v0.6.4.9.4 — Confiança Estratégica

**Atualização pontual sobre a v0.6.4.9.3** (Balanceamento de Pit Stops), Godot 4.7.2.

## Única correção funcional

O Pit Wall 3.0 devolvia sempre `MODERADA` em situações sem chuva significativa, tornando `ALTA` impossível. A calibração heurística agora diferencia:

- `ALTA`: pista seca e previsão estável, retorno sem tráfego projetado, desgaste abaixo de 65%, dados de tempos e rivais disponíveis, sem conflito de garagem.
- `MODERADA`: tráfego próximo, pista úmida, variação moderada da previsão, desgaste elevado porém não crítico, ou telemetria/previsão insuficiente.
- `BAIXA`: mudança forte de chuva, condição/pneu crítico ou conflito de box simultâneo.

A HUD existente apresenta **"Confiança [nível] (qualitativa): [motivo]"** nas informações meteorológicas do Pit Wall. **Não** é probabilidade estatística calibrada, nem prevê incidentes ou o futuro exato de rivais. Estes limites são **parâmetros heurísticos de game design**, não dados oficiais de F1.

## Mudança isolada

Único arquivo de código de jogo modificado: `scripts/core/race_pitwall_strategy_0649.gd`.

Sem alterações em motor de corrida, física, pneus, desgaste, stints, pit stops, rádio, Apex Soul, Staff, Race Engineer, clima ou regras de controle manual/automático. `project.godot` muda apenas a identificação e isola saves em `ApexMotorsportManager_PitWall_06494`.

## Verificação

- 17 testes direcionados/regressão headless: PASS.
- 4 testes gráficos Xvfb, incluindo nova apresentação da confiança, Pit Wall, rádio Soul Driver e Staff: PASS.
- Importação no editor Godot: PASS, sem Parse Error nem Script Error.
- Em testes com o motor real, a consulta foi somente-leitura e a ordem V21 permaneceu protegida.
- **A corrida de Silverstone completa de 52 voltas não foi reexecutada** nesta alteração informativa. A corrida de 52 voltas da v0.6.4.9.3 permanece evidência da base, não desta versão. A bateria de 8 GPs também não foi reexecutada.
- Aviso `ALSA ERR_CANT_OPEN` em Xvfb é ausência de dispositivo de áudio no ambiente de teste, não falha de cena.

Registros em `qa/06494/`. Captura da tela em `docs/APEX_06494_CONFIANCA_PITWALL_1600.png`.

## Abrir no Linux Mint

1. Extraia todo este arquivo ZIP para uma pasta nova.
2. Importe `project.godot` no Godot 4.7.2.
3. Pressione F5, inicie um GP e abra **ENG. → PIT WALL 3.0**.
4. Confira a explicação de confiança junto à previsão da pista.

Os saves da v0.6.4.9.3 não são sobrescritos pela nova configuração de pasta. Copie saves manualmente somente após backup, caso deseje reutilizá-los.
