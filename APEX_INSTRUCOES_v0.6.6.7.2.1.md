# Instruções e rollback — APEX v0.6.6.7.2.1

1. Extraia o ZIP completo em pasta nova (não misture diretórios de versões).
2. Abra `project.godot` no **Godot 4.7.2**.
3. Inicie um GP. Confira o seletor central em **1×** e mude para 5× no próprio menu.
4. Teste em 3D tanto com a câmera Diretor TV quanto acompanhando um piloto; a câmera não deve mudar apenas pela velocidade.
5. Se 5x ainda parecer engasgado, acione o profiler **F8** para observar se o processamento do motor ou da apresentação está atrasando os quadros. Informe CPU, GPU, taxa real de FPS, modo de janela e, se possível, o JSON exportado.
6. Para o erro `XServer BadWindow`, compare a execução do jogo fora do editor com a janela incorporada ao editor (Linux/X11); não trate este hotfix como solução comprovada para esse erro.

**Rollback:** preserve e execute em pasta separada o ZIP íntegro da **v0.6.6.7.2**. As versões usam o mesmo formato de replay; faça backup de seus saves antes de experimentar.

**Testes reproduzíveis:** `godot --headless --path . --script res://tests/speed_visual_066721.gd` e `res://tests/speed_control_066721.gd`. A matriz completa está em `qa/speed_visual_066721/matriz_testes.json`.
