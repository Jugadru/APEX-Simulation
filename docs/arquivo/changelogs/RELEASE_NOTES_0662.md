# APEX Motorsport Manager — v0.6.6.2

**Racecraft Telemetry 1.0** — análise passiva das disputas e conservação do determinismo.

Esta atualização acrescenta um observador sem afetar o ritmo de corrida, regras,
consumo de RNG, classificação ou apresentação. Consulta via
`session.racecraft_report()`, com agrupamento por piloto, perfil e pista seca/molhada.

**Validação:** Godot 4.7.2, teste de 1.027 verificações, hashes idênticos à v0.6.6.1
em Silverstone, Spa, Monza e Singapura (três voltas), replay anterior da v0.6.6.1
reproduzido na v0.6.6.2, teste legado da oficina e capturas de corrida reais.

**Estado:** *release candidate*. Corrida Monza 53 voltas e replay integral NÃO
concluídos após 13m16s de execução, interrompida com registro de RAM >1 GB.
Primeira tentativa de importação limpa Godot terminou em 139; segunda PASSOU.
Não reivindicar estabilidade global ou performance calibrada sem mais testes.

Veja `docs/RELATORIO_TECNICO_0662.md`, `docs/RACECRAFT_TELEMETRY_0662.md`
e `qa/racecraft_0662/`.

Rollback: mantenha o ZIP original v0.6.6.1; não o substitua.
