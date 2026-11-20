# APEX Motorsport Manager v0.6.4.2 — Rival Development & Oficina

**Projeto completo em Godot 4.7.2.** Esta versão atualiza a v0.6.4.1; não é um remake.

## Instalar e iniciar no Linux Mint

1. Extraia o ZIP INTEIRO em uma pasta nova. Não copie apenas um `.gd`.
2. Abra **Godot 4.7.2** → **Importar** → selecione `project.godot` na pasta `APEX_GODOT_0.6.4.2_RIVAL_DEVELOPMENT`.
3. Clique **Importar e editar**, aguarde a importação, depois pressione **F5**.
4. No modo **Temporada**, escolha uma equipe e clique em **OFICINA** para abrir os novos projetos e acompanhar as equipes rivais.

## Oficina e P&D

- Compras **imediatas** de Motor, Asa e Chassi continuam disponíveis com custos e efeitos anteriores.
- P&D custa **85%** do preço da próxima melhoria, com débito imediato e entrega **depois de duas etapas concluídas** da temporada.
- Um projeto por vez; não se pode comprar instantaneamente a mesma melhoria enquanto ela está em pesquisa.
- Cancelar um projeto devolve **75% do valor reservado**; orçamento e histórico são salvos em `user://apex_garage_050.json`.
- Ao entregar, o nível passa a valer para o próximo GP; mudanças são aplicadas no próprio motor de corrida.

## IA de desenvolvimento das rivais

- As 11 equipes rivais possuem orçamentos de **gameplay**, receitas entre etapas, investimentos e níveis próprios de Motor, Asa e Chassi.
- Os investimentos são concluídos após o GP e afetam os GPs seguintes, persistidos com a temporada em `user://apex_championship_2012_v060.json`.
- O modo GP avulso mantém comportamento histórico legado; o sistema de rivais é do modo Temporada.
- Ganhos e cifras não são medidas históricas oficiais de 2012.

## IA de chuva

- O clima físico de v0.6.4.1 não foi modificado. O novo filtro de decisão evita trocas com água insuficiente, salvo chuva forte chegando ou desgaste crítico.
- Os resultados variam com a semente. Confira `RELATORIO_0642_TESTES.md`: China melhorou, mas Sepang ainda teve muitas trocas.

## Pastas importantes

`scenes/`: cena principal; `scripts/`: motor, interface e oficinas; `data/`: temporada; `tests/`: testes; `docs/`: capturas reais do Godot.

## Comandos de teste

```bash
godot --headless --path /CAMINHO/DA/PASTA --script res://tests/core_0642_rival_workshop_weather_test.gd
godot --headless --path /CAMINHO/DA/PASTA --script res://tests/core_0642_save_migration_test.gd
```

**A pasta `.godot` é apenas cache local e se recria na importação.** O ZIP contém o código e os recursos, mas não o executável do Godot.
