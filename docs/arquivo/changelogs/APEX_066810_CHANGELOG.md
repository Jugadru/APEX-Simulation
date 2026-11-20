# APEX v0.6.6.8.10 — Ordens de Equipe 1.0

- **Nova ordem real autorizada pelo jogador:** RÁDIO → AUTORIZAR NÃO DEFENDER (o piloto selecionado deve estar atrás de seu companheiro, ser mais rápido por duas voltas e estar em condições seguras).
- A ordem é registrada pelo Replay e aplicada no próximo tick; o piloto da frente evita a primeira defesa agressiva contra **o companheiro autorizado** por até 75 ticks (15 s). Não há teletransporte, vantagem artificial nem garantia de ultrapassagem.
- **CANCELAR AUTORIZAÇÃO** encerra a ordem no tick seguinte; expiração automática após 15 segundos, passagem do companheiro ou fim da corrida.
- Segurança: gap e ritmo comprovados, mesma equipe, posições adjacentes, chuva e pneus considerados; box ativo bloqueia a autorização.
- BOX V21 preservado, com ordem automática de pit nunca inferida do rádio.
- Revisão esportiva do replay `066810_team_yield` impede reprodução de gravações de regras incompatíveis.
- Importação Godot 4.7.2 e 15/15 testes regressivos aprovados localmente; 36 verificações da lógica + 18 da HUD. Teste A/B de 4 circuitos por 150 ticks sem ordens idêntico ao Core 2 v8.9.
