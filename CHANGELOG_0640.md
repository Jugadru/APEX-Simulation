# APEX MOTORSPORT MANAGER — v0.6.4.0 / Pit Wall Intelligence

Base de evolução: **v0.6.3.9 Race Engineer**, recuperada do ZIP completo. Não houve reconstrução do jogo.

## O que mudou

- **Controle por piloto:** além do botão global Manual/Automático, cada piloto pode escolher **Manual**, **Assistido** (STAFF decide ritmo e KERS; box permanece manual) ou **Automático** (ritmo, KERS e pits delegados). Trocar o modo de um carro não altera o outro.
- **Respeito às ordens:** uma parada marcada V21 ou V23 continua válida independentemente do modo. O botão "Aceitar BOX" recusa ordens quando já existe agendamento ou quando o motor não recomenda pit imediato.
- **Novo módulo `scripts/core/race_pitwall_intelligence_0640.gd`:** explica as sugestões com composto, idade e desgaste dos pneus, umidade, comparativo última/melhor volta quando disponível, KERS restante e tendência climática estimada.
- **Alerta de double stack** se os dois pilotos tiverem box marcado para a mesma volta, sem simular parada adicional nem alterar o motor.
- **Diário por piloto:** transições relevantes, mudanças de modo, aprovações e consultas ao engenheiro durante o GP, limitado a 12 registros por piloto.
- **HUD real:** o botão `ENG.` abre a central, agora com menu de delegação independente para cada carro, detalhes de análise, consulta de rádio, confirmação de ritmo/KERS e de box. Se faltar algum dado, declara a limitação; não inventa sensores.
- **Continuidade:** `scripts/race_engine.gd`, pneus, KERS/DRS, pit lane, física, grid de 2012, pistas, transmissão 2D/3D e carreira preservados. O SHA-256 do motor é exatamente o mesmo da v0.6.3.9.

## Arquivos modificados/adicionados

- `scripts/main.gd` — armazenamento e wrappers de política por piloto.
- `scripts/apex_race_commands.gd` — política por carro e acionamento do STAFF no modo assistido, mesmo com equipe em Manual.
- `scripts/apex_race_session_controller.gd` — limpa modos anteriores antes de cada corrida.
- `scripts/apex_race_hud_0622.gd` — janela e lógica de histórico, comandos com validação na hora do clique, análise técnica e escolha individual.
- `scripts/apex_race_ui_legacy_cards.gd` — permissões coerentes para widgets legados.
- `scripts/core/race_pitwall_intelligence_0640.gd` — explicações puramente consultivas.
- `project.godot` — versão e descrição.
- `tests/core_0640_pitwall_intelligence_test.gd` — novo teste funcional.
- `tests/core_0640_mixed_71_gp_test.gd` — novo teste completo de 71 voltas com modos diferentes nos dois carros.
- `tests/native_capture_0640.gd` — captura visual do projeto nativo no Godot.

## Não incluído nesta etapa

Áudio gravado de pilotos, vozes sintéticas, modelo generativo de conversas, contratações avançadas de engenheiros ou novas simulações de sensores. Mensagens de rádio representam **ficção do universo do simulador**, não falas reais dos pilotos históricos.
