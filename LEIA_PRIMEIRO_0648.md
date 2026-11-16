# APEX Motorsport Manager v0.6.4.8 — Team & Staff Manager

**Base do projeto:** v0.6.4.7 Soul Driver 2.0, Race Engineer 3.0 da v0.6.4.6 e HUD híbrida UI01/UI03.

Esta é uma entrega funcional incremental, não apenas um mockup. A física da corrida, os pneus, a IA de box e as ordens de piloto foram preservados.

## Como abrir no Godot 4.7.2

1. Extraia **todo** este ZIP em uma nova pasta.
2. Abra `project.godot` no **Godot 4.7.2** e pressione **F5**.
3. No menu, escolha **TEAM & STAFF MANAGER / MERCADO DE CONTRATOS**.
4. Veja os quatro departamentos, cada um com três candidatos fictícios e atributos de gameplay.
5. Contrate um titular por departamento; bônus de assinatura sai do orçamento imediatamente.
6. Na **temporada 2012**, cada GP registrado debita o salário contratado e reduz a duração do contrato. GPs avulsos não cobram salários.

## Departamentos e efeitos reais

| Departamento | Efeito implementado |
|---|---|
| Estrategista | Nível efetivo 1–3 alimenta o controle delegado de ritmo/KERS e o Race Engineer 3.0 (planejamento/antecedência). |
| Engenheiro | Nível efetivo 1–3 afeta o controle delegado de ritmo/KERS e análise do engenheiro. |
| Chefe de Mecânica | Nos níveis 2/3, soma +1/+2 aos níveis efetivos de Agilidade, Precisão e Coordenação, limitados a 3; o motor de box usa estes níveis na sessão. |
| Chefe de Aerodinâmica | Nos níveis 2/3, oferece 4%/8% de desconto adicional no custo do P&D **da Asa**. Não altera performance física sem desenvolvimento de peça. |

Os níveis de formação técnica anteriores da oficina são mantidos e combinados aos níveis dos contratados; não são apagados.

## Mercado e contratos

- 12 candidatos ficcionais fixos (três por departamento), com nome, especialidade, habilidade, bônus de contratação e salário por GP.
- Um titular ativo por departamento; para trocar, rescinda o anterior, com multa de duas vezes o salário por GP.
- Contratos de oito GPs de campeonato, com prazo restante e encerramento automático.
- Folha de pagamento idempotente por temporada/rodada/cargo; recarregar o save ou reconciliar os resultados não duplica cobranças.
- A contratação após o GP 3 não cobra salários de GPs 1–3. Contratos de outra temporada continuam até expirar.
- O orçamento pode ficar negativo após a folha e é salvo assim; novas compras e contratações permanecem bloqueadas até haver caixa.
- Histórico recente de contratações, salários, rescisões e vencimentos na tela de Staff e histórico persistido no save.

## Salvamento e compatibilidade

O projeto usa `ApexMotorsportManager_Staff_0648` como pasta de dados, separado da v0.6.4.7 para evitar sobrescrever saves antigos. **O estado da carreira da versão anterior não é importado automaticamente entre as duas pastas de dados**; para continuar a carreira anterior, faça backup antes de transferir os arquivos `apex_garage_050.json` e `apex_championship_2012_v060.json` da pasta de dados da versão anterior para a nova. A estrutura anterior do save é migrada sem inventar titulares nem pagamentos.

## Validado no Godot 4.7.2

- Editor/importação de scripts: PASS.
- `tests/staff_0648_contracts_test.gd`: PASS — contratar, impedir dupla ocupação, salários, rescisão, efeitos, prazo de 8 GPs, save e migração.
- `tests/staff_0648_career_integration_test.gd`: PASS — folha e premiação pelo fluxo real de campanha, idempotência, efeito no algoritmo de estratégia e início de corrida.
- `tests/staff_0648_ui_test.gd`: PASS — tela renderizada, economia, organograma, interface, 1600×900 / 1920×1080, abertura do GP e engenheiro.
- `race_0647_soul2_test.gd`, `race_0647_soul2_ui_test.gd`: PASS.
- `race_0646_engineer_3_test.gd`, `race_0645_intelligence_test.gd`: PASS.
- `track_0644_hud_integration_test.gd`, `core_0640_pitwall_intelligence_test.gd`,
  `core_0622_corner_hud_smoke_test.gd`, `core_0642_save_migration_test.gd`: PASS.

A bateria completa de 8 GPs nativos não foi reexecutada nesta edição; testes curtos e de integração não garantem o comportamento de uma temporada inteira na máquina do jogador. O Xvfb/Mesa usado nos testes renderiza a interface, mas não comprova FPS em GPU real. Em ambiente de teste sem ALSA é normal aparecer erro do dispositivo de áudio e fallback para driver dummy.

## Limites explícitos desta atualização

**Ainda não há** mercado dinâmico da IA, negociação de cláusulas, headhunting, lealdade/moral individual de Staff, treinamentos complexos por funcionário, hierarquia contratual de muitos subdepartamentos ou pessoas reais da F1. Os níveis de habilidade dos candidatos são parâmetros ficcionais de balanceamento.

Os módulos Driver Soul 2.0, Race Engineer 3.0, sistemas físicos e eventos de pit são preservados. O jogo não executa decisões de estratégia ou box só porque o usuário abriu a tela de Staff.

**Arquivos centrais:** `scripts/core/staff_market_0648.gd`, `scripts/apex_staff_screen_0648.gd`, `scripts/garage.gd`, `scripts/main.gd`, `scripts/apex_race_session_controller.gd`, `scripts/apex_race_commands.gd`, `scripts/apex_race_hud_0622.gd`, `scripts/apex_championship_flow.gd`, `scripts/apex_menu_screen.gd`, `scripts/apex_garage_screen.gd`, `scripts/apex_race_ui_layout.gd` e `project.godot`.

A prévia verdadeira está em `docs/APEX_0648_TEAM_STAFF_REAL.png`.
