# Instalação e rollback — APEX v0.6.6.7.2.2

1. Faça backup da pasta da sua v0.6.6.7.2.1 (não sobrescreva os arquivos existentes).
2. Extraia **o ZIP completo** em uma nova pasta e abra `project.godot` pelo **Godot 4.7.2**.
3. Inicie GP 2012; confira 1x no 3D, 5x no 3D, 10x no 2D, 16x/32x no 2D.
4. Em CORRIDA, experimente MAPA 2D ou AÉREA 3D manualmente e depois **AUTO** para restaurar troca inteligente.
5. Caso identifique regressão, feche o jogo e volte a abrir o `project.godot` da versão anterior. Não misture scripts de versões diferentes.
6. Para comparar desempenho, abra o F8 antes do GP e registre tempos de quadro e ticks de simulação em velocidade equivalente. Não suponha que velocidade 32x equivalha a 60 FPS.

O projeto deve ser iniciado em janela própria se o Godot embutido no editor reportar `BadWindow`; isso é diagnóstico, não correção definitiva do X11.
