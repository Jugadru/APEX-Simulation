# APEX 0.6.2.8.1 — como testar

1. Extraia em uma pasta nova e importe `project.godot` no Godot 4.7.2.
2. Abra Bahrain e selecione a câmera Livre; afaste o zoom para observar o traçado inteiro e compare com a v0.6.2.8.
3. Inspecione a faixa lateral do terreno e as partes da pista que pareciam recortadas.
4. Teste uma corrida em Diretor TV; confirme que o enquadramento e a estratégia permanecem os mesmos.
5. No terminal, use `godot --headless --path . --script res://tests/core_0628_1_visual_smoke_test.gd`.
