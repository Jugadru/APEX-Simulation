# APEX v0.6.4.4 — Como abrir (Linux Mint)

1. Extraia **o ZIP inteiro** em uma pasta sua. A pasta inclui `project.godot`, `scenes/`, `scripts/`, `assets/`, `data/`, `tests/` e todos os arquivos originais de versões anteriores.
2. Abra o **Godot 4.7.2**, clique em **Importar** e selecione o `project.godot` dentro de `APEX_GODOT_0.6.4.4_TRACK_DYNAMICS`.
3. Pressione **F5**. Não abra somente um script `.gd`.
4. Comece uma corrida, escolha o perfil meteorológico, observe a Central de Dados e selecione **Pneus** no painel do piloto. Alterne 2D/3D e consulte a oficina no menu.
5. Para testar pelo terminal na pasta extraída:

```bash
/path/para/godot472 --headless --path . --script res://tests/track_0644_unit_test.gd
/path/para/godot472 --headless --path . --script res://tests/track_0644_native_tick_smoke_test.gd
/path/para/godot472 --headless --path . --script res://tests/track_0644_hud_integration_test.gd
/path/para/godot472 --headless --path . --script res://tests/track_0644_eight_gp_test.gd
```

O teste de oito GPs usa integração de 8 s somente para a bateria de validação demorada, não para o jogo. Não é necessário instalar uma versão antiga `.deb`; projeto Godot completo.
