# Apex Motorsport Manager v0.6.3.1 — Rádio Inteligente

**Base preservada:** Godot 4.7.2, v0.6.3.0. **Escopo:** diálogo piloto/engenheiro e redução de mensagens repetidas no histórico de rádio. Nenhuma geometria, HUD, câmera, física, IA de box, pneus ou temporada foi substituída.

## Alterações

1. `scripts/core/race_engineer_reply.gd` (novo): resposta do engenheiro baseada na condição reportada, desgaste, umidade estimada, planejamento existente e ordem de box já agendada. É apenas texto; não executa ordens.
2. `scripts/race_engine.gd`: quando o piloto informa uma condição, o engenheiro responde no mesmo histórico. Se já houve diálogo naquela volta, não duplica a antiga recomendação espontânea. Ordens manuais, em especial V21, não são antecipadas.
3. `scripts/core/race_driver_feedback.gd`: um mesmo tipo de queixa tem agora espaçamento mínimo de oito voltas; problemas diferentes continuam elegíveis pelo espaçamento anterior de quatro voltas.
4. `scripts/apex_commentary.gd`: mensagens internas do engenheiro visíveis no filtro EQUIPE e ocultas no filtro TV; avisos de tentativa de ultrapassagem limitados a um a cada 30 segundos da simulação; desistências de ataque deixam de ser anunciadas como manobras iminentes; comentário ambiente passa a ocorrer após aproximadamente 115 segundos em corrida, não imediatamente na largada. Mudanças reais de posição/liderança seguem visíveis.
5. `scripts/main.gd`, `project.godot`: identificação v0.6.3.1.
6. `tests/core_0631_radio_engineer_smoke_test.gd` (novo): verifica diálogo, desgaste, mudança de condição, box V21, filtros, spam e ultrapassagens.

## Mantido sem alteração

Todos os circuitos procedurais e os 20 GPs de 2012, câmeras Livre/Seguir/Diretor TV, mini-mapa, HUD, DRS/KERS, cálculos de desgaste, clima, pit lane, estratégias e todos os modelos 3D procedurais. Os mods de Assetto Corsa e os laboratórios de Bahrain/carros externos continuam fora deste projeto.

## Limites

- Rádio fictício criado por regras, sem áudio nem personalidade histórica atribuída a pilotos reais.
- Recomendações são consultivas; não existe botão novo para aceitar uma sugestão diretamente no rádio.
- A análise de estratégia pré-existente continua sendo a responsável por sugerir composto. A resposta não faz previsão exata de ganho de tempo de parada.
- A simulação completa de uma prova ainda não foi revalidada especificamente nesta entrega.
