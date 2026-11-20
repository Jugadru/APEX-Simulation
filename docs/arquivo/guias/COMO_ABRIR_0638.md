# Instalar / abrir o APEX v0.6.3.8 no Linux Mint

1. **Guarde um backup** da pasta anterior `APEX_GODOT_0.6.3.7_SOUL_REACTIVE` e seus saves.
2. Extraia **todo** o ZIP `APEX_0638_GODOT.zip` em uma pasta separada.
3. Abra o **Godot 4.7.2**, clique **Importar** e selecione o arquivo `project.godot` que está dentro da pasta `APEX_GODOT_0.6.3.8_CORRECOES`.
4. Clique **Importar e editar**; quando o editor abrir, pressione **F5**.
5. Teste um GP avulso em Interlagos, a métrica **ATRÁS** na tabela, a tela da estratégia e as ordens manuais.

Este pacote é o **projeto completo editável**, não um `.deb` e não um executável autônomo. Não é preciso substituir a versão anterior: mantenha-a em outra pasta.

Se quiser atualizar apenas os scripts, o pacote `APEX_0638_PATCH.zip` contém os arquivos alterados com seus respectivos caminhos relativos. **Recomendamos o ZIP completo**, para evitar mistura de versões.

As carreiras do Godot costumam ser armazenadas em `user://` (pasta de dados do usuário), fora do ZIP do projeto. Não apague os saves anteriores sem fazer cópia.
