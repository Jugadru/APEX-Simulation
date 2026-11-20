# Auditoria inicial v0.6.5.6
Base: ZIP v0.6.5.5 obrigatório; CRC verificado antes de extrair.

- `component_inventory_0651.gd`: único inventário, IDs aleatórios persistentes, seis peças iniciais (Motor/Asa/Chassi em dois carros). `car` e `status` representam instalação; validação impede slots duplicados. Históricos e km reais acumulados por sessão. Condição e integridade são nulas: não há desgaste físico destas peças no motor.
- `garage.gd`: proprietário dos estados por equipe; gravação temporária, backup e renomeação; transações do inventário revertem em falha. Migração anterior preservada.
- `staff_market_0648.gd` / `staff_contracts.gd`: contratos individuais por departamento, incluindo chefe de mecânica e engenheiro; bônus, salário por GP, expiração e Soul Staff. Não há mecânicos individuais adicionais. Adaptação mínima: os dois profissionais técnicos já contratáveis podem executar serviços; chefe coordena o automático. Sem contratação implícita.
- `apex_management_hub.gd`: página factory já integra HUD única; `apex_component_workshop_0651.gd` oferece consulta e movimentação instantânea. Será preservada a consulta, com serviços operacionais na mesma página.
- Calendário atual é por etapas do campeonato; não existe relógio de horas da gestão nem fila de serviços. Adição mínima: relógio persistido de horas da oficina com avanço explícito na gestão, independente de FPS; prazo operacional configurável até o GP.
- Não alterar motor, pneus, estratégias ou racecraft. Condição de oficina será estimativa diagnosticada a partir dos km registrados; não representar dados anteriores desconhecidos como medidos. Efeito de qualidade limitado à recuperação da peça, sem introduzir nova fórmula de corrida.
