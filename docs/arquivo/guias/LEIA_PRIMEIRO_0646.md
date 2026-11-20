# APEX Motorsport Manager — v0.6.4.6
## RACE ENGINEER 3.0 | HUD híbrida 0635 + base 0645
**Godot 4.7.2** | **09/11/2026**

## O que há nesta entrega

1. **Painel Race Engineer 3.0 funcional durante o GP:** alertas de risco (pneu e pista incompatíveis, desgaste, tendência de água, condições térmicas), indicador da ação recomendada e da situação do box.
2. **Comparação de cenários, usando dados do motor:** manter o stint (vida estimada e voltas restantes) ou parar (custo de pit, composto do plano, posição projetada de retorno e proximidade do tráfego). Essas são estimativas condicionais, não uma simulação paralela nem promessa de posição final.
3. **Proteção de ordens:** BOX manual agendado (ex.: V21), box já chamado/em curso, pneus não disponíveis, fim da corrida e ausência de recomendação válida bloqueiam o botão de aceitar pit. A IA 2.0 e a física continuam como fontes de verdade.
4. **Conflito de boxes dos companheiros:** alerta quando estão agendados na mesma volta ou quando o box do outro piloto pode criar fila/double stack. O alerta é consultivo, não altera unilateralmente ordens.
5. **Rádio contextual interativo:** botões PLANO, PNEUS, CHUVA e TRÁFEGO/BOX fornecem respostas distintas calculadas com dados atuais. Cada pergunta gera um evento real na transmissão/radio do Apex e aparece na própria janela. Repetição da mesma pergunta é limitada a um evento a cada 4 segundos simulados; a tela ainda atualiza a resposta.
6. **Integração com o STAFF existente:** nível do Estrategista altera a antecedência de alertas de janela de pit (mais preparação). Nível do Engenheiro é exibido, mas **não** melhora pneus/física diretamente nesta atualização. Sistema de contratação e habilidades futuras não foi implementado.
7. **HUD híbrida preservada:** estilo grafite + laranja da 0.6.3.5 com seis botões da 0.6.4.5 (incluindo ENG.), dois pilotos, dados térmicos, telemetria real e rádio Apex Soul já existente.

### Como abrir no Linux / Godot

Extraia todo o ZIP em uma nova pasta, **sem sobrepor arquivos de versões antigas**.
Abra `project.godot` no **Godot 4.7.2** e execute com **F5**.
Entre numa corrida e clique **ENG.** no topo direito.
Role o painel para visualizar o segundo piloto e o diário completo.
O botão **ACEITAR BOX** só fica habilitado quando a estratégia do motor recomenda pit imediato e não existe impedimento.
**MANUAL** requer sua confirmação; **ASSISTIDO** automatiza apenas ritmo/KERS; **AUTOMÁTICO** mantém o pit controlado pela IA 0.6.4.5.

### Saves

Como atualização da HUD híbrida anterior, o projeto continua usando a pasta de dados `ApexMotorsportManager_HUD_Hibrida` do Godot. O formato de saves não foi alterado. Faça backup da pasta de saves antes de abrir o projeto atualizado. A base v0.6.4.5 original, fora da linha híbrida, tinha outra pasta de dados.

### O que foi preservado

Sem modificações em `scripts/race_engine.gd`, `scripts/core/race_intelligence_0645.gd`, física de pneus e pista, 3D, calendário, oficina, campeonato, P&D, saves ou demais módulos de IA.
A v0.6.4.6 adiciona `scripts/core/race_engineer_0646.gd` e conecta seu diagnóstico ao HUD existente. Alterações de comportamento automático não foram introduzidas sem testes específicos.

### Limites honestos

- Ainda não há **vozes sintetizadas**: rádio contextual é textual, com eventos reais dentro do jogo, sem reproduzir áudios históricos da Fórmula 1.
- Retorno projetado usa progresso instantâneo e custo de parada; não contempla eventos futuros, acidentes ou pits rivais futuros.
- `life_laps` e previsão do clima são estimativas do motor, não dados medidos da F1 real.
- Não foi executada uma temporada completa de oito GPs novamente nesta atualização; o motor de corrida é binariamente idêntico ao da 0.6.4.5. Tests incrementais e regressões reais executados, descritos em `RELATORIO_TESTES_0646.md`.
- Renderização Xvfb/Mesa verifica interface e erros; FPS em GPU local deve ser avaliado na máquina do jogador.

### Mapa da atualização

- `scripts/core/race_engineer_0646.gd` — lógica pura do diagnóstico e geração de respostas por tema.
- `scripts/apex_race_hud_0622.gd` — interface, estados, perguntas e proteção ao pit.
- `project.godot` — identificação da nova versão, mantendo mesma pasta de saves híbrida.
- `tests/race_0646_engineer_3_test.gd` — testes nativos do módulo, rádio, proteção e integração.
- `tests/race_0646_visual_render_test.gd` — capturas do painel real em 1600×900 e 1920×1080.
- `docs/RACE_ENGINEER_3_0_*.png` — screenshots nativos da v0.6.4.6.

**Atualizações futuras (não incluídas):** Apex Soul Driver 2.0, Team & Staff Manager expandido e Pit Wall & Estratégia 3.0.
