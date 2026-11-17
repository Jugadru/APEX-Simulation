# APEX v0.6.6.8.8 — Racecraft 2.0 (Core 2)

- **Mudança única de jogabilidade:** cautela de defesa antecipada na chuva. Um defensor com pneus desgastados e percepção espacial limitada reduz a disposição de mudar de linha para fechar a passagem; na pista seca, a decisão original é preservada.
- A mudança só se aplica antes do emparelhamento; depois que o duelo está estabelecido, a trajetória defensiva permanece travada.
- Não há mudanças em potência, ritmo base, desgaste, DRS, decisões de box, IA de pit, save ou apresentação 3D.
- Atualizada **somente a identificação das regras esportivas do replay** para `06688_grip_aware_defense`; replays antigos são explicitamente incompatíveis e recusados antes da reprodução.
- Teste de contrato novo: defesa cautelosa, determinismo, sem teleporte, integridade de snapshots, replay e BOX V21. Regressões legadas de Driver Dynamics, HUD, Racecraft, double stack e replay foram aprovadas.
- Silverstone e Monza secos mantiveram os hashes da v8.7 nos 750 ticks; Spa e Singapura chuvosos apresentam divergências esportivas esperadas, com classificação igual após 750 ticks.
- FPS em hardware real e temporadas completas não foram homologados nesta versão.
