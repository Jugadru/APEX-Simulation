# APEX MOTORSPORT MANAGER — v0.6.3.9 / Race Engineer

Base recuperada: **v0.6.3.8.1 / Hotfix de voltas** (código-fonte Godot completo, não uma reconstrução).
Motor de corrida `scripts/race_engine.gd`: **preservado byte a byte** para proteger a correção do cruzamento único da linha de chegada.

## Mudanças

1. `scripts/core/race_engineer_0639.gd` — módulo novo de avaliação, mantendo o mesmo planejador de pneus e regras de STAFF. A análise compara o estado real de pneu, desgaste, água na pista, tráfego, ordem de pit e previsão.
2. `scripts/apex_race_commands.gd` — modo automático usa o novo relatório, mas **retorna as mesmas ordens de ritmo/KERS do STAFF já existente**. A chamada automática de box continua com o RaceEngine.
3. `scripts/apex_race_hud_0622.gd` — botão compacto `ENG.`; janela real dentro da HUD, com análises para ambos os carros, troca manual/automática de controle, confirmação de ritmo/KERS, box recomendado e consulta ao rádio. Mensagens informativas identificadas como simulação e com controle de repetição.
4. O botão `ACEITAR BOX` exige recomendação válida; ao clicar, reavalia o estado do motor e **NUNCA substitui automaticamente um pit V21 já agendado**. A antiga ordem imediata explicitamente acionada pelo jogador permanece disponível na HUD.
5. Corrigido defeito preexistente no painel expandido de estratégia: a altura mínima real do conteúdo é respeitada ao posicioná-lo acima do cartão.
6. Atualizados título `project.godot`, janela e testes; física de cronometragem, pneus, KERS, pit lane, temporadas e modelos 2D/3D preservados.

## Limitações claras

- “Inteligência” significa decisões heurísticas baseadas em dados do jogo; não há modelo generativo de IA embutido nem áudio sintetizado de pilotos.
- Vozes e mensagens são conteúdo ficcional da simulação. Os pilotos históricos não recebem traços psicológicos reais atribuídos como fatos.
- Ainda não foi validada uma instalação no Linux Mint do jogador nem toda a temporada de 20 GPs após a atualização.
