# Execução e rollback da v0.6.6.8.1

Extraia todo o ZIP numa pasta isolada e abra `project.godot` pelo Godot **4.7.2**. Não sobreponha a pasta v0.6.6.8. O launcher permanece a cena `res://scenes/main.tscn`.

Para repetir os testes nativos em Linux, dentro do diretório que contém `project.godot`:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/hud_rebroadcast_06681_pending_orders.gd
godot --headless --path . --script res://tests/hud_rebroadcast_06681_race_scenarios.gd
godot --headless --path . --script res://tests/replay_0660_boundaries.gd
godot --headless --path . --script res://tests/pitwall_0667_same_tick_regression.gd
```

O teste `tests/hud_rebroadcast_06681_restart.gd` usa duas invocações, respectivamente `APEX_PREF_PHASE=write` e `APEX_PREF_PHASE=read` (o segundo restaura COMPACT).

Capturas: com display X11/Xvfb e driver gráfico, execute `godot --path . --script res://tests/hud_rebroadcast_06681_graphics.gd`. O script salva capturas na pasta `qa/hud_rebroadcast_06681`.

Se receber a versão em partes menores que 25 MB, una-as **na mesma pasta**, em ordem:

```bash
cat APEX_v0.6.6.8.1.zip.part* > APEX_MOTORSPORT_MANAGER_v0.6.6.8.1_HUD_REBROADCAST_QA_COMPLETO.zip
```

Confira o SHA-256 fornecido antes de extrair.

Rollback: não modifique os arquivos antigos. Faça backup dos saves e abra `project.godot` da v0.6.6.8 ou v0.6.6.7.2.4. O diretório persistente original `APEX_0650_SOUL_STAFF` não foi alterado.
