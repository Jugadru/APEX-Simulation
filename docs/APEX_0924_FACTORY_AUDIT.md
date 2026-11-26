# 9.24 — Living Factory: auditoria e reserva de destino

Base 9.23 consolidada a248dfbd54c5599c76b69e4f69e663b0270215a6. Plano Mestre Unificado 2.0, seção 19, Fase C, passos 1–2: auditar antes de ampliar.

## Estado encontrado no código

- Inventory 0651: IDs persistentes, seis peças iniciais, estados installed/available/stored/unusable, histórico e quilometragem observacional, proteção de sessão e rollback de persistência. Condição/integridade anteriores podem ser desconhecidas.
- Workshop 0656: tarefas persistidas, orçamento, duração, staff, prioridade, bloqueio por peça, cancelamento e recuperação limitada pelo desgaste. Não é fabricação de novas peças.
- Garage: P&D ainda sincroniza specification de todas as peças da categoria por levels (inventory_sync_spec). Não alterar agora: necessita migração e integração separadas antes de correlacionar peça instalada e desempenho.
- Falha concreta: substituição com slot vazio registra old_part vazio. locked() só protege IDs, não destino; uma segunda peça pode ser reservada ou instalada manualmente nesse mesmo carro/categoria. O serviço seguinte pode deslocar silenciosamente o primeiro.

## Correção única

Derivar reserva de slot de tarefas de substituição ativas e categoria da peça, sem outro estado persistido. Bloquear segunda substituição e instalação manual no destino. Confirmar old_part antes de concluir para proteger saves antigos com reservas incompatíveis; usa a política existente de pendência/retry, jogador pode cancelar e replanejar. Não auto-cancelar, alterar orçamento, produzir peça, modificar UI ou motor esportivo. A reserva termina com cancelamento/conclusão. Não atualizar identificação do jogo até homologação. 

Critérios: teste de slot vazio, conflito com outro ID, operação direta, ausência de mutação na rejeição, isolamento de carro/categoria, persistência, cancelamento, conclusão, destino legado divergente, seis peças sem duplicação; regressões anteriores de oficina, inventário, saves e FAST obrigatório. Sem FULL ou benchmark nativo nesta atualização. Rollback: revert PR, nenhum campo novo. Pendências: especificação individual real, planejamento de produção, protótipos, correlação de pista e confiabilidade.
