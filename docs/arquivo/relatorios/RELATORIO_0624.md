# APEX 0.6.2.4 — Relatório de validação

**Escopo:** refatoração organizacional, sem mudanças de aparência ou física.

| Verificação | Resultado |
|---|---|
| Testes específicos novos | **10/10 PASS** |
| Indentação GDScript e regressão estática do mapa | **PASS, 92 scripts** |
| Integridade e referências de preloads | **PASS** (testes novos) |
| HUD visível, motor, câmera, cena principal | **SHA-256 idêntico à 0.6.2.3** |
| Suíte antiga `run_all_static.py` | **6/37 PASS**, 31 falhas (maioria procura implementação dentro de `main.gd`, agora em módulos) |
| Parser real Godot 4.7.2 | **NÃO EXECUTADO** (binário indisponível) |
| Teste visual e interação no jogo | **NÃO EXECUTADO**, depende de F5 no computador do jogador |

A suíte legada é mantida no pacote para rastreabilidade; não marque falhas antigas como testes aprovados. Os testes estáticos não garantem ausência de falhas em runtime.

**Risco restante:** a extração moveu blocos grandes para módulos estáticos que usam a cena como `host`. O teste crucial é iniciar a corrida e exercitar menus, HUD e retorno ao menu no Godot. Se o editor apresentar Parse error, o primeiro erro e número da linha devem ser usados para diagnóstico.

**Não abrangido:** qualidade visual das câmeras, lógica de pit, incidência de chuva ou melhora de IA.
