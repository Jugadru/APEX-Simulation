# Instalação e rollback — APEX v0.6.6.7.2.4

1. Extraia o ZIP completo numa **nova pasta**, sem sobrescrever a v0.6.6.7.2.3.
2. Abra `project.godot` no Godot 4.7.2 e execute o jogo em uma janela independente.
3. Comece em 1x (3D) e teste 10x, 16x e 32x (2D no modo Auto). Veja na barra superior a **velocidade efetiva**; o valor selecionado continua aparecendo no controle inferior.
4. Em 32x, se vir `21x real • CPU`, isso significa que a CPU não sustentou os 32x naquele período. O jogo reduz o avanço real para manter a interface responsiva, sem pular ticks.
5. Em Monza, use a câmera livre para conferir que as mesas de engenharia estão junto às garagens e que as paradas continuam funcionando.

**Rollback:** feche o Godot e abra a pasta intacta da v0.6.6.7.2.3. Não copie scripts individualmente entre as versões; preserve seus saves e replays antes de qualquer substituição.

**Não resolvidos:** FPS reais de 32x em hardware lento, picos do motor durante boxes e erro externo de X11 `BadWindow`. Não confundir velocidade solicitada com efetiva.
