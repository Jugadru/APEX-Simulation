# Apex Motorsport Manager — v0.6.4.0 Pit Wall Intelligence

**Projeto Godot completo, atualizado da v0.6.3.9. Não é apenas um patch.**

## Instalação no Linux Mint / Godot 4.7.2

1. Extraia o arquivo `APEX_0640_PIT_WALL_INTELLIGENCE_GODOT.zip` inteiro em uma pasta nova.
2. Abra o **Godot 4.7.2**. Clique em **Importar**, e selecione **`APEX_GODOT_0.6.4.0_PITWALL_INTELLIGENCE/project.godot`**.
3. Clique em **Importar e editar**, aguarde a importação dos recursos e pressione **F5**.
4. Inicie uma corrida. Para repetir os testes, escolha **Ferrari, Interlagos (BRA), 71 voltas**.
5. No canto superior direito da HUD, clique no botão **ENG.** para abrir o painel **PIT WALL INTELLIGENCE**.

## Controle dos pilotos

- **Manual:** o engenheiro recomenda; ritmo e KERS continuam sob seu comando, com BOX conforme controle individual do piloto.
- **Assistido:** o STAFF ajusta ritmo e KERS automaticamente, enquanto a parada fica MANUAL (só com sua ordem ou agendamento).
- **Automático:** STAFF ajusta ritmo e KERS; a **IA de pit do RaceEngine** executa a estratégia, respeitando qualquer ordem manual agendada.
- **Controle global:** MANUAL/AUTO redefine os **dois** pilotos ao mesmo tempo. O seletor no cartão de cada piloto pode sobrescrever apenas aquele carro.
- **Perguntar no rádio:** uma pergunta registra diálogo textual fictício baseado no estado da corrida, sem alterar a física.
- **Aceitar BOX:** somente quando a recomendação atual diz para parar, não existe agendamento manual ativo e a autorização do piloto permite o comando. Nunca substitui uma V21 já marcada.

## Testes integrados

Os testes são scripts Godot e estão em `tests/`.

```
/path/para/Godot_v4.7.2-stable_linux.x86_64 --headless --path /CAMINHO/PROJETO --script res://tests/core_0640_pitwall_intelligence_test.gd
/path/para/Godot_v4.7.2-stable_linux.x86_64 --headless --path /CAMINHO/PROJETO --script res://tests/core_0640_mixed_71_gp_test.gd
```

Para todos os comandos, a pasta do projeto é a pasta que contém `project.godot`.

### Sobre recursos e limitações

O pacote **não inclui o executável Godot** (ele já foi fornecido pelo usuário). A pasta `.godot` gerada pelo editor é reconstruída ao importar. A central de engenheiros usa heurísticas determinísticas do próprio simulador, não IA generativa. Ainda é necessário validar a experiência na máquina do jogador, apesar de terem passado os testes de execução e os testes gráficos em tela virtual Linux.

Ver `RELATORIO_0640_TESTES.md` para os resultados documentados.
