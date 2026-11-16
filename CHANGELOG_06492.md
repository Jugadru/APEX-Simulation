# v0.6.4.9.2 — Double Stack / coordenação final da garagem

- Novo gate determinístico, acionado apenas na entrada do pit lane, para dois carros com solicitações automáticas já registradas.
- Estima tempo restante de ocupação até a **liberação da garagem** em cada etapa do serviço; a saída do box, por si só, não conta como ocupação.
- Adia somente a segunda entrada opcional se a espera prevista for significativa e se houver condições realmente seguras.
- Mantém a memória de 0.6.4.9.1 (um adiamento por stint, reset só após troca real).
- Ordens manuais, V21 e pit de emergência têm precedência, mesmo quando geram fila real.
- Nenhuma alteração de desgaste, temperatura, física, clima, Staff, Soul, HUD ou pit-service.
- Corrida GBR seed 6403: 52 voltas, 24 carros, 90 paradas e mesma classificação. A nova condição não foi acionada nesse GP de chuva variável; teste separado em pista seca demonstrou prevenção de 7,4s de espera.
- 18 testes específicos/de regressão PASS; duas baterias *legadas* de double stack não são contadas (assertions preexistentes também na versão 0.6.4.9.1).
