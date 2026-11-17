> Documento histórico de versão anterior. Leia CHANGELOG_0550.md para as mudanças atuais.

# 0.5.4.2 — PNEUS 2012 / CORE 2

Base: **APEX 0.5.4.1 HOTFIX PERFORMANCE** (abre no Godot 4.7.2 do usuário).

- Novo catálogo `data/tyres_2012.json` com 20 seleções oficiais de slicks de 2012; Supermacio, Macio, Médio e Duro com cores e nomes corretos.
- Modo **Core 2**: somente os dois slicks indicados em cada GP aparecem no menu de box; perfil de desgaste ajustado pela exigência estimada de cada circuito.
- Grid inicial do Core 2 agora usa apenas os slicks disponíveis, sem consumir a semente aleatória da simulação de incidentes.
- IA seleciona apenas compostos válidos no Core 2 e dá preferência a não repetir o mesmo slick antes de usar os dois.
- Regras de pit no motor rejeitam ordens incompatíveis com o GP; uma ordem válida continua pela mesma máquina de estados de 0.5.4.1.
- HUD inferior mantém a escolha de pneus e **CHAMAR BOX** e passa a exibir nomes e códigos adequados (SS/S/M/H).
- Menu informa quais compostos estão disponíveis para o GP no Core 2.
- Clássico conserva os compostos C4/C3/C2 e os cálculos antigos para servir de referência.
- Nenhum ajuste feito na geometria 2D/3D, double stack, incidentes ou na máquina de estados dos boxes.

**Importante:** diferenças de desempenho e desgaste são de *balanceamento experimental*; não representam números medidos em 2012. A física da chuva, estoques por fim de semana e penalidades de uso de dois compostos ainda não existem.

Testes: `tests/test_0542_static.py`, `tests/tyres_0542_smoke_test.gd`, testes anteriores de paridade de box e Core 2.
