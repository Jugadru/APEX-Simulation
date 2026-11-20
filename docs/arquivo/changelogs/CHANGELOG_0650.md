# CHANGELOG v0.6.5.0 — Living Factory & Soul Staff: etapa 1

**Funcionalidade principal:** Soul Staff 1.0 — gerenciamento de equipe humana.

## Novo
- `scripts/core/staff_soul_0650.gd`: 12 perfis de staff, moral, energia, confiança, coesão, falas contextuais, atualização pós-GP, ações de gestão e chaves de idempotência.
- Tela Soul Staff reformulada no gerenciador de contratos existente, com indicadores nativos, estilo de cada pessoa, relacionamentos entre os quatro departamentos e decisões antes de cada GP.
- Persiste o novo campo `staff_soul` no JSON da garagem sem alterar os contratos 0648 pré-existentes.
- O campeonato usa o resultado registrado em cada GP para evoluir os perfis antes de abater salários e expirar contratos. Não reprocessa etapas antigas após a migração.
- `scripts/core/apex_save_migration_0650.gd`: preservação read-only dos saves anteriores de garagem **e** campeonato da v0.6.4.9.9.
- Resumo informativo de oficina: Motor / Asa / Chassi e P&D corrente. Produção de peças e fábrica 3D serão fases separadas.

## Mantido
- `scripts/race_engine.gd` e `scripts/core/race_*`: nenhuma mudança de física, IA, pneus, pit lane, pit wall ou reavaliação estratégica.
- Todos os sistemas v0.6.4.9.9, inclusive Strategy Simulator 1.0, HUB de corrida, pit stops e HUD híbrida.
- Mercado original de 12 candidatos, contratos de 8 GPs, salário por GP, efeitos antigos de experiência dos cargos.

## Limites
- Os atributos humanos são ficção de gameplay, não indicadores clínicos ou métricas históricas de profissionais reais.
- Esta v1.0 registra consequências gerenciais e orçamentárias; **não usa moral/coesão para modificar desempenho em pista**.
- Uma ação por etapa de temporada; nenhuma ação de gestão em GP avulso.
