# HUD Manager primeira versão visual

21/11/2026 — versão experimental sobre Core 2 v0.6.6.8.10.

- Cards dos dois pilotos reorganizados em pneus, ritmo e KERS, com faixa clara, temperatura, última volta e DRS.
- Torre compacta para 24 pilotos, clima e pista separados, minimapa translúcido e abas com nomes explícitos.
- Estado textual de box, encerramento e desclassificação; prevenção de sobreposição de contextos.
- Comandos existentes e distinção entre ordem pendente e confirmada preservados.
- Importação, 24 verificações existentes, 6 rechecks e capturas/interações gráficas aprovados. GdUnit4 executou 2 casos.
- Sem alterações do motor esportivo, física, revisão de replay ou formato de saves.

[Resultados, capturas e limites](../../HUD_MANAGER_20261121_VALIDACAO.md).

## Integração de 22/11/2026

- Incorporada main 8e5f176, incluindo prevenção de filas de pit v0.6.6.9.7.1.
- Estilos portados para os builders modulares de ranking, clima e minimapa; novos sistemas de rádio e Pit Wall preservados.
- Testes de aparência atualizados para os novos títulos e dimensões; contratos de callbacks e hierarquia mantidos.
- Evidências da integração em qa/hud_merge_20261122.

Validação da integração: 32 scripts PASS após repetir os três contratos visuais atualizados; GdUnit4 2/2 PASS; prevenção de filas 28 checks PASS; importação e 8 capturas/interações PASS. Sem benchmark de FPS ou GP completo.
