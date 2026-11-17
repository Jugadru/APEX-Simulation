# Relatório de validação — Apex v0.6.3.2

**Engine:** Godot 4.7.2.stable.official.ed1daf0bf, Linux x86_64 (executável fornecido). A instalação no Linux Mint do usuário não foi testada neste ambiente.

| Teste | Resultado |
|---|---|
| Importação nativa do projeto (`--headless --editor --quit`) | PASS, exit 0, sem erro de parser |
| Teste novo de perguntas/GUI/radio/filtro/ordens (`core_0632_engineer_interactive_smoke_test.gd`) | PASS |
| v0.6.3.1 diálogo piloto/engenheiro | PASS |
| v0.6.3.0 rádio dos pilotos | PASS |
| Estratégia seca e agendamento manual V21 | PASS |
| Diretor TV | PASS |
| Ambiente/circuitos 2012 | PASS |
| Calendário de 2012 | PASS |
| Comparação com v0.6.3.1, após 240 etapas de 4 s (9 voltas) | IGUAL nos 24 carros, mesma seed 141: tempo, posição, pneus, desgaste, paradas e solicitações |
| Renderização nativa OpenGL/software com Xvfb a 1600x900 e captura | PASS, imagem gerada sem erro de script |
| Legado `core_0622_corner_hud_smoke_test.gd` em ambiente headless | FAIL no detalhe de expansão vertical; **mesma falha reproduzida na v0.6.3.1**, preexistente |

## Observações

- O módulo de perguntas não executa box, não muda ritmo, pneus, IA nem física. O snapshot da corrida permanece idêntico antes e depois das perguntas e dos cliques de interface testados.
- O rádio é textual, fictício e baseado nos valores da corrida. As falas não são gravações reais da F1.
- A conversação não interpreta texto livre; fornece quatro perguntas pré-configuradas.
- A captura teve aviso de áudio ALSA indisponível no servidor, com fallback automático para o driver dummy. Isso não afetou a interface.
- Também surgiram os avisos preexistentes de âncoras e SubViewport com stretch.
- Não houve teste de corrida completa até a bandeirada; a paridade cobre nove voltas e os testes separados da lógica.
- A interface foi vista a 1600x900 neste ambiente; testes em outras resoluções no Linux Mint ainda são recomendados.

Para reproduzir: `tests/core_0632_engineer_interactive_smoke_test.gd` e `tests/native_capture_0632.gd`.
