# APEX Motorsport Manager v0.6.4.9 — Pit Wall & Estratégia 3.0

**Base integral:** v0.6.4.8 Team & Staff Manager, mantendo Soul Driver 2.0 (0.6.4.7), Race Engineer 3.0 (0.6.4.6), física e HUD híbrida.
**Motor:** Godot 4.7.2. Projeto completo, não apenas imagens ou um patch.

## Como abrir

1. Descompacte o ZIP inteiro em uma pasta NOVA.
2. Abra `project.godot` no Godot 4.7.2 e pressione **F5**.
3. Configure um GP e inicie a corrida 3D.
4. No topo da HUD, abra **ENG. → PIT WALL 3.0**; ou **ESTRAT. → ABRIR PIT WALL 3.0 · CENÁRIOS**.
5. Compare **MANTER STINT**, **BOX NA PRÓXIMA ENTRADA** e **ESTENDER +1 VOLTA** para seus dois pilotos.
6. Para executar uma ação, clique em **AGENDAR PRÓX. ENTRADA**, **ESTENDER +1V / AGENDAR** ou **BOX NA JANELA**. Abrir o painel, ler ou atualizar **não envia** ordem.
7. Para cancelar/modificar uma parada já marcada, entre na tela **ESTRATÉGIA / AGENDAMENTO LIVRE**; a HUD nova **não sobrescreve** uma ordem existente.

## Sistemas implementados

- `scripts/core/race_pitwall_strategy_0649.gd`: análise determinística e somente leitura, com base no `race_engine` real, progresso de cada carro, perdas no pit, última volta válida, informações de pneus, previsão de água em 3/6 voltas e plano de stints existente.
- Três cenários por carro; retorno projetado `~P`, estimativa de proximidade a tráfego na saída, informação de incerteza, undercut/overcut sugeridos **apenas nas condições compatíveis com o plano do motor**.
- Alertas de **double stack** por agendamento na mesma volta, chamada do companheiro ou serviço em andamento; botões de agendamento rápido recusam volta em conflito diretamente identificado.
- Um **adiamento automático condicionado de no máximo uma vez** pode ser aplicado quando o outro carro já tem chamada/agendamento para a mesma entrada e o carro avaliado possui pneus e tempo restantes para uma volta adicional com pista seca estável. Este ajuste é complementar às proteções do diretor de estratégia; situações críticas/chuva/urgência NÃO são atrasadas por essa rotina. Em outras situações, o controle automático existente é mantido.
- Os controles Manual, Assistido e Automático são preservados. Em Automático, o jogador NÃO pode criar ordens manuais pelo novo painel. Em Manual/Assistido, um agendamento passa sempre pelo `race.schedule_pit` do motor; uma chamada imediata pelo `Race Engineer 3.0` revalida a janela no momento do clique.
- O resumo clássico lateral de estratégia também apresenta a tática e a projeção do Pit Wall 3.0.

## Importante sobre a estimativa

Os dados são simulados, sem telemetria oficial de F1. A posição de retorno usa progresso atual, tempo-base, custo do pit e tendência limitada de ritmo quando existir volta válida. **Não prevê** incidentes, pit stops futuros de rivais, evolução precisa de pneus ou Safety Car. Não significa garantia de ganhar posições; undercut e overcut só são alternativas. O motor principal continua sendo a autoridade sobre pneus, calendário, chuva, pit lane e regulamento.

## Salvamentos

Usa diretório separado `ApexMotorsportManager_PitWall_0649`; arquivos anteriores não são apagados ou automaticamente importados. Se desejar continuar uma carreira 0.6.4.8, faça backup e copie os dois saves da carreira/oficina entre as pastas de dados correspondentes (veja instruções em `LEIA_PRIMEIRO_0648.md`). O formato dos saves não foi alterado por esta versão.

## Testes efetivamente executados

**PASS:** Godot editor/importação; `pitwall_0649_strategy_test.gd` (dados reais, V21, chuva, double stack, pureza/sem RNG); `pitwall_0649_ui_test.gd` (tela real, agendamento/duplicidade, F5, 1600×900 e 1920×1080); `race_0645_intelligence_test.gd`; `race_0646_engineer_3_test.gd`; `race_0647_soul2_test.gd`; `race_0647_soul2_ui_test.gd` (Xvfb); `staff_0648_contracts_test.gd`, `staff_0648_career_integration_test.gd`, `staff_0648_ui_test.gd` (Xvfb); `core_0640_pitwall_intelligence_test.gd`; `core_0622_corner_hud_smoke_test.gd`; `core_0635_soul_stint_smoke_test.gd`; `core_0642_save_migration_test.gd`; `track_0644_hud_integration_test.gd`.

**Não executado nesta atualização:** temporada completa de oito GPs com regras e economia, teste de performance em GPU física ou teste de configuração de controle no computador do jogador. Testes curtos não substituem a validação prolongada; relatórios antigos no ZIP pertencem às versões respectivas.

O ambiente Linux/Xvfb pode apresentar aviso de áudio ALSA indisponível e usar o driver dummy; isso não indica falha do sistema de estratégia.

## Arquivos alterados/adicionados

- **Novo:** `scripts/core/race_pitwall_strategy_0649.gd`.
- **Alterado:** `scripts/race_engine.gd` (apenas porta de coordenação protegida da IA), `scripts/apex_race_hud_0622.gd` (nova janela e comandos manuais), `scripts/apex_race_ui_presenter.gd` (resumo de estratégia), `project.godot` (identificação e isolamento dos saves).
- **Testes:** `tests/pitwall_0649_strategy_test.gd`, `tests/pitwall_0649_ui_test.gd`.
- **Capturas nativas:** `docs/APEX_0649_PITWALL_1600.png` e `docs/APEX_0649_PITWALL_1920.png`.
- **Evidências:** `RELATORIO_TESTES_0649.md` e `qa/0649/`.

Não foram alterados os módulos de física de pneus, chuva, pista, geometria 3D, componentes de Staff, Soul Driver, nem o fluxo de campeonato.
