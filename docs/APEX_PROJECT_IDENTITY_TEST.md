# Separação de identidade de build e comportamento esportivo

Base: 4c0f658d164a68b7d350afea729bf45ba12afbcd.

Os runs 45903374835 e 45902176675 falharam com a verificação de nomenclatura no teste de chuva. A política de identificação já foi corrigida na base. Esta alteração move as duas assertivas existentes, com a mesma lógica, para `tests/project_identity_test.gd`; não alarga versões aceitas e não modifica física, previsão, IA ou hashes.

O manifesto FAST seleciona a fixture de identidade para mudanças em project.godot, na própria fixture ou na fixture de estratégia de chuva diretamente alterada. Todas as assertivas esportivas da chuva permanecem. Alterar apenas mecânica de chuva deixa de acoplar a identidade ao teste esportivo; alterar nome/versão/descrição do projeto continua testado. A política de revisão histórica de replay não é uma identidade de build e permanece intocada.

Validação requerida: Godot 4.7.2, FAST na integração exata, PROJECT_IDENTITY_PASS e WET_STRATEGY_06698_PASS. Não declarar aprovação até a execução.
