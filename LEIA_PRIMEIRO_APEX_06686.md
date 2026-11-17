# Instalação da v0.6.6.8.6

1. Mantenha sua v0.6.6.8.5 e faça backup da pasta de saves.
2. Extraia este ZIP em uma pasta **nova**, sem sobrescrever a anterior.
3. Abra o `project.godot` no Godot 4.7.2. Se precisar importar via terminal no Linux: `godot --headless --single-threaded-scene --editor --path . --import --quit`.
4. Inicie uma corrida em 3D e acompanhe FPS, Pit Wall e replay com a mesma resolução/câmera da versão anterior.
5. Se ocorrer qualquer regressão, feche o jogo e volte à pasta v0.6.6.8.5; a nova versão não faz migração de saves.

Código principal: `scripts/core/race_space_0655.gd`. Dados de testes e capturas: `qa/core2_06686/`. Matriz e benchmark na raiz do projeto.
