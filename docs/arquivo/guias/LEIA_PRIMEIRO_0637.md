# APEX v0.6.3.7 — COMO ABRIR

1. Extraia o arquivo `APEX_0637_GODOT.zip` inteiro.
2. No Godot **4.7.2**, clique em **Importar**.
3. Selecione `APEX_GODOT_0.6.3.7_SOUL_REACTIVE/project.godot`.
4. Pressione **F5**, escolha a equipe e inicie um GP de 2012.
5. Durante a corrida, o piloto pode enviar mensagens sem você abrir o rádio. Clique no aviso para ver o histórico, ou abra **RÁDIO** e escolha **EQUIPE/PILOTOS**.

Você não precisa instalar o `.deb` antigo ou o editor Blender. Esta é uma atualização do projeto Godot. Para manter um backup, importe em pasta diferente da v0.6.3.6.

**Avisos não são ordens**: nenhuma mensagem espontânea envia o carro aos boxes. A oficina, o calendário 2012 e a HUD v0.6.3.6 continuam presentes.

## Teste de compatibilidade
Abra `tests/core_0637_reactive_radio_smoke_test.gd` com o comando: 
`godot --headless --path /caminho/da/pasta --script res://tests/core_0637_reactive_radio_smoke_test.gd`.
Caso `godot` não esteja no PATH, abra o projeto normalmente pelo editor.

Código-fonte original do Apex incluído. Veja `CHANGELOG_0637.md` e `RELATORIO_NATIVO_0637.md`.
