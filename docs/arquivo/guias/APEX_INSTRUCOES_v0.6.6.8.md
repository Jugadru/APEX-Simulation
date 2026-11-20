# Instalação, execução e rollback — v0.6.6.8

1. Preserve uma cópia externa intacta do ZIP `APEX_MOTORSPORT_MANAGER_v0.6.6.7.2.4_PITLANE_CPU_COMPLETO.zip`.
2. Extraia **todo** o pacote v0.6.6.8 numa pasta nova (não misture as duas versões).
3. No Godot **4.7.2** (Linux/PC), importe `project.godot` da nova pasta; execute a cena principal normalmente.
4. Abra uma corrida e teste o seletor **BROADCAST / COMPACT / FULL** no canto superior direito.
5. Para repetir os testes nativos (ajuste o caminho do binário conforme sua instalação):

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/hud_rebroadcast_0668_unit.gd
godot --headless --path . --script res://tests/hud_rebroadcast_0668_integration.gd
godot --headless --path . --script res://tests/hud_rebroadcast_0668_scenarios.gd
godot --headless --path . --script res://tests/replay_0660_boundaries.gd
```

6. **Rollback:** feche o jogo, guarde os saves, abra a versão v0.6.6.7.2.4 que ficou salva separadamente. O caminho de dados da carreira `APEX_0650_SOUL_STAFF` foi mantido.
7. Para zerar apenas a preferência visual do ReBroadcast, remova o arquivo `hud_rebroadcast_0668.cfg` **dentro do diretório de dados do usuário**, sem tocar em arquivos de save ou da carreira.

**Estado desta versão:** experimental. Confira primeiro o relatório `APEX_RELATORIO_TECNICO_v0.6.6.8.md` e a matriz `APEX_TESTES_v0.6.6.8.json`.
