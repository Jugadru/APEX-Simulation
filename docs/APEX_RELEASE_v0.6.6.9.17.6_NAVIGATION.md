# v0.6.6.9.17.6 — Navigation Hotfix (candidata)

Base: `d431bab77d5c12e70a5df28bf69f1dba3e90c25a` / PR #118. Issue #120.

## Changelog
- Histórico limitado das telas de menu, central e Staff; VOLTAR retorna à origem, MENU continua explícito.
- Reutiliza raízes existentes, restaura rolagem e seleções da oficina por equipe/ID. Não altera os dados persistidos.
- Retomar GP restaura apenas as ligações do host à sessão pausada, sem reiniciar o motor nem executar ordens. Impede retomada de GP de uma temporada substituída.
- START repetido de botão oculto não substitui o GP já iniciado. Chamadas internas continuam disponíveis para testes e ferramentas.
- Botão do profiler criado uma única vez na Central. Nenhuma alteração de layout da HUD ou retratos.

## QA
`tests/navigation_09176_test.gd`: 100 ciclos, unicidade de raízes e conexões, contagem de nós/órfãos, rolagem, oficina, três resoluções, sessão retomada e hash esportivo. FAST seleciona também menu, gestão, oficina, campeonato e retratos.

Executar em Godot 4.7.2, dados de teste isolados, headless e renderizador Compatibility. O teste nativo pode gravar PNGs em `qa/navigation_09176/`. Não publicar capturas contendo retratos privados. Resultados devem ser registrados separadamente para o SHA exato; este changelog não substitui evidência.

Rollback: voltar à base acima; manter o diretório de saves existente, sem migração de schema. PR Draft, sem merge até homologação.
