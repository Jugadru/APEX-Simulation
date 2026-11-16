# Godot 4.7.2 — executar verificações 0.6.4.9.9

Linux: ajuste a variável `GODOT` conforme o caminho local do executável 4.7.2.

```sh
GODOT=/caminho/Godot_v4.7.2-stable_linux.x86_64
$GODOT --headless --path . --script res://tests/strategy_simulator_06499_model_test.gd
$GODOT --headless --path . --script res://tests/strategy_simulator_06499_three_gp_test.gd
# Para capturas reais: ambiente com X11 ou Xvfb (não headless)
xvfb-run -a -s '-screen 0 1920x1080x24' "$GODOT" --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://tests/strategy_simulator_06499_ui_test.gd
```

O teste visual grava capturas PNG dentro de `docs/`. Os resultados das corridas são registrados em `qa/06499/`. A validação de projeções compara previsões cacheadas com a classificação no instante da parada, **não** representa um modelo de previsão perfeito ou calibrado para todos os GPs.
