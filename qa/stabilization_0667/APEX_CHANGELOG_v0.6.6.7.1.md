# APEX v0.6.6.7.1 — Pit Wall Stabilization

- Corrigido agendamento manual simultâneo de dois pilotos na mesma volta durante o tick pendente, com rejeição na fila de gravação.
- Adicionada regressão automatizada que reproduz falha anterior e confirma proteção posterior.
- Atualizados os testes legados de UI e inteligência para a semântica de comandos aplicados no tick seguinte.
- Atualizada a verificação da autonomia para `ReplaySession.policy.fingerprints`.
- 12 regressões executadas e aprovadas, incluindo 4 corridas curtas + replays.
- Monza 53 voltas completa e reprodução integral: **aprovadas**; 24 carros e 24.431 ticks; hash inalterado.
- Replay curto gravado em v0.6.6.7 e hotfix: 161.096 bytes, **SHA-256 binário idêntico**.
- Replay histórico Monza 53 voltas: nove buscas aprovadas.
- Teste administrativo 20 campeonatos / 400 resultados: aprovado; **não** prova simulação de 400 corridas ou 20 anos de carreira.
- Não modificados os módulos de física, IA, pneus, telemetria e Diretor TV.
