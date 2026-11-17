# APEX 0.6.2.1 — primeira extração de responsabilidades de `main.gd`

A separação foi feita **sem trocar o motor de corrida**. O `main.gd` continua sendo o ponto de entrada da cena e preserva os callbacks antigos (`_load_hud_prefs`, `_update_garage`, `_resume_championship` etc.), mas encaminha cada responsabilidade para módulos separados.

| Arquivo | Responsabilidade |
|---|---|
| `scripts/main.gd` | Orquestração da cena, fluxo de corrida e pontes de compatibilidade |
| `scripts/apex_session_settings.gd` | Dados iniciais da temporada, preferências persistentes de HUD e cartões |
| `scripts/apex_championship_flow.gd` | Criar/retomar temporada, classificação, pontos, progressão e prêmio |
| `scripts/apex_garage_presentation.gd` | Atualização da interface da garagem, investimentos e STAFF |
| `scripts/apex_race_formatting.gd` | Formatação de voltas, indicadores e telemetria da interface antiga |
| `scripts/apex_race_hud_0620.gd` | HUD nova: classificação, cartões de piloto, janelas e comandos rápidos |
| `scripts/apex_strategy_planner_0620.gd` | Desenho da timeline de stints e ordens agendadas |
| `scripts/race_engine.gd` + `scripts/core/` | Motor de corrida e regras: **não alterados nesta entrega** |

## Justificativa da abordagem

- Antes: `main.gd` tinha **2.703 linhas**.
- Agora: `main.gd` tem **2.441 linhas**.
- As funções movidas mantêm o corpo lógico equivalente; o módulo recebe a cena como `host` para acesso ao estado já existente. Isso é uma transição de compatibilidade, não a arquitetura final ideal.
- As quatro funções/modulações de apresentação não devem inventar tempos, desgaste, danos ou posições; devem consultar o estado da corrida.
- A HUD nova continua em módulo separado, sem reescrever a IA.

## Próxima extração, **depois da verificação no Godot do usuário**

1. Extrair construtores de interface do menu, garagem e corrida que ainda ocupam centenas de linhas de `main.gd`.
2. Separar o ciclo de câmera/apresentação da lógica `_process` da corrida.
3. Remover apenas após testes os componentes legados desativados pela HUD 0.6.2, evitando duplicação de processamento.
4. Reduzir acesso direto ao `host` com uma interface de dados tipada (`RaceViewModel`) e sinais para comandos de HUD.

**Não confundir esta separação inicial com a conclusão da refatoração integral.**
