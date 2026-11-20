# APEX MOTORSPORT MANAGER — v0.6.3.9 RACE ENGINEER

## Abrir no Linux Mint com o Godot 4.7.2

1. **Extraia o ZIP inteiro** em uma pasta (não abra apenas um script).
2. No Godot, escolha **Importar**, localize `project.godot` na pasta `APEX_GODOT_0.6.3.9_RACE_ENGINEER` e clique em *Importar e editar*.
3. Pressione **F5** para executar.
4. Escolha a equipe Ferrari e a pista **Interlagos (BRA)** para o cenário de 71 voltas. O menu continua com as demais opções existentes no projeto.
5. Durante a corrida, clique em **ENG.** no canto superior direito para abrir o novo Race Engineer.

### Controles

- **MANUAL / CONFIRMAR:** os engenheiros recomendam ritmo, KERS e estratégia; cada ação precisa de aprovação (e o controle individual de box permanece disponível).
- **AUTOMÁTICO / DELEGAR:** os funcionários configuram ritmo/KERS via a IA de STAFF preexistente, e o RaceEngine decide paradas automáticas conforme as regras.
- **ACEITAR RITMO + KERS:** aplica os dados recomendados ao piloto quando em manual.
- **ACEITAR BOX:** só fica ativo quando o motor de estratégia recomenda parada imediata e **não existe parada manual agendada**.
- **PERGUNTAR AO ENGENHEIRO:** coloca uma resposta textual explicativa no histórico existente do rádio.
- Seu **BOX V21 agendado não será antecipado** apenas porque o engenheiro deseja avaliar outra estratégia.

### Testes de referência

Com a versão oficial Godot 4.7.2 disponível:
```
./Godot_v4.7.2-stable_linux.x86_64 --headless --path /CAMINHO/DO/PROJETO --script res://tests/core_0639_race_engineer_test.gd
```
O projeto contém mais testes em `tests/`. Consulte `RELATORIO_0639_TESTES.md` para resultados realmente obtidos nesta entrega.

**A pasta `.godot` (cache local) não faz parte do ZIP**; é regenerada automaticamente ao importar.
