# Apex Motorsport Manager v0.6.3.6 — Personalidade Dinâmica (Apex Soul Driver)

Base: **v0.6.3.5** enviada pelo jogador. Godot **4.7.2**. Data: 07/11/2026.

## Implementado

- Perfil **ficcional, determinístico e por piloto** para a corrida: confiança no engenheiro, autoconfiança, propensão ao risco e sensibilidade à degradação. Estes valores **não são fatos sobre pilotos reais de 2012**.
- Sensação de desgaste subjetiva calculada separadamente da telemetria. Se o piloto está otimista demais, pode pedir para ficar na pista; o engenheiro continua alertando sobre o desgaste medido e clima.
- Na janela de **RÁDIO**, a ação **DISCUTIR STINT** agora leva em conta a personalidade. O usuário pode responder **APOIAR PILOTO** ou **PRIORIZAR DADOS**.
- Respostas modificam apenas confiança/autoconfiança e histórico do diálogo, **não** a estratégia, o ritmo, a IA ou ordens de box.
- A conversa seguinte pode recuperar o alinhamento anterior. Conversas repetidas em menos de 60s simulados e sem alteração relevante continuam bloqueadas.
- Um alinhamento por conversa evita incrementar confiança clicando repetidamente. Memória curta, restrita ao GP atual, zerada no início de nova corrida.
- Indicador na janela de rádio distingue **sensação de desgaste** e **telemetria real**, com aviso de ficção. Informação atualizada sem sobrecarga (a cada 5s simulados).
- Histórico da rádio mantém filtros TODOS, TRANSMISSÃO, EQUIPE e PILOTOS; comunicações privadas não entram na transmissão.

## Mudanças no código

- `scripts/core/race_soul_driver_0636.gd` — novo, perfil e evolução de diálogo.
- `scripts/core/race_stint_dialogue_0635.gd` — aceita percepção opcional e mantém as respostas técnicas baseadas em dados reais.
- `scripts/apex_race_hud_0622.gd` — novos controles, consulta subjetiva, estado Soul por GP.
- `scripts/apex_commentary.gd` — histórico de alinhamento com três papéis (CHEFE/PILOTO/ENGENHEIRO).
- `project.godot` — identificação da versão.
- `tests/core_0636_soul_personality_smoke_test.gd` e `tests/native_capture_0636.gd` — testes de lógica, UI e captura.

## Compatibilidade e limites

- `scripts/race_engine.gd`, pneus, pit lane, IA, DRS/KERS, câmera, 2D/3D e circuitos **sem alterações**.
- Não há dublagem, vozes oficiais, personalidade persistente entre GPs nem novo modelo de IA generativa.
- A personalidade é uma camada narrativa consultiva, não simulação psicológica de pessoas reais.
- Os warnings históricos de layout e o áudio ausente no ambiente virtual de teste não são novos erros do jogo.
- Corrida completa até a bandeirada e instalação no Linux Mint do usuário ainda não foram testadas nesta entrega.
