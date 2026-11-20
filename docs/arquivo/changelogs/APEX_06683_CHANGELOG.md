# Changelog — APEX Motorsport Manager 0.6.6.8.3

**CORE 2 — Frozen Tick Snapshot CPU**

- Otimização restrita a `RaceEngine._advance`: substituída a cópia profunda do snapshot esportivo por cópia superficial das chaves de cada carro, pois os consumidores atuais consultam apenas escalares.
- Preservadas cópias profundas no estado público, salvar e replay.
- Acrescentado teste A/B de hashes e posições para 4 pistas/2 condições de clima e ordem de box V21.
- Atualizado o título da janela e a identificação do projeto.
- Sem mudança de física, clima, IA, Pit Wall, HUD ou câmera. A Next Engine permanece fora do pacote.
