# Apex v0.6.3.4 — Como abrir e testar no Linux Mint

1. Extraia todo o ZIP em uma pasta nova; não sobrescreva a v0.6.3.3.
2. Abra o Godot 4.7.2, clique em **Importar** e selecione o `project.godot` da pasta `APEX_GODOT_0.6.3.4_SOUL_MEMORIA`.
3. Pressione **F5** para iniciar. Escolha uma equipe, um circuito e comece a corrida.
4. No canto superior direito, abra **RÁDIO**. Escolha um dos pilotos e use `OUVIR PILOTO`.
5. No **HISTÓRICO DE RÁDIO**, selecione **EQUIPE** ou **PILOTOS** e alterne `SÓ ESTE: NÃO/SIM`. O filtro precisa mostrar apenas mensagens do piloto escolhido quando ativado. Troque o piloto no seletor para testar.
6. Faça perguntas sobre **pneus**, **ritmo**, **tráfego** e **boxes**. A conversa aparecerá na aba **EQUIPE**.
7. Teste uma nova corrida: a memória do piloto anterior deve ser reiniciada, assim como o filtro individual.

**Importante:** o teste automatizado confirma que o rádio não altera a simulação, mas uma corrida completa e a execução no seu Linux Mint ainda precisam de teste manual. Em resoluções muito pequenas pode haver limites preexistentes no layout.

Testes técnicos executáveis:
```
./Godot_v4.7.2-stable_linux.x86_64 --headless --path PASTA_DO_APEX --script res://tests/core_0634_radio_memory_smoke_test.gd
```
