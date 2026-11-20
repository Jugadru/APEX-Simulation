# APEX v0.6.2.8.1 — Hotfix visual validado no Godot 4.7.2

Fonte: v0.6.2.8. Mudanças limitadas ao `scripts/track_3d.gd`, etiquetas de versão e teste novo.

- `Camera3D.near`: 0,10 → 2,0, para reduzir artefatos de z-fighting e triângulos perdidos ao observar asfalto de longe.
- Terreno procedural: 950 × 950 → 2200 × 2200, para cobrir panorâmicas da câmera Livre sem mostrar a cor do céu nas bordas.
- Linha de chegada: adicionar o MeshInstance3D à cena antes de usar `look_at()`, eliminando o erro nativo **Node not inside tree**.
- Nenhuma mudança nas regras esportivas, pneus, pit stops, geometria da pista, câmeras TV/Seguir/Livre ou HUD.

## Testes

Godot Linux 4.7.2 oficial recebido do usuário, executado no Linux com renderizador OpenGL por software (Mesa llvmpipe).

- Importação do editor / parse dos scripts.
- Smoke nativo do cenário e teste específico v0.6.2.8.1.
- Smoke TV Director, free camera, estratégia de pneus.
- Captura de viewport da corrida (ver relatório).

A simulação longa da China ultrapassou o limite de execução neste ambiente; não é classificada como aprovada. Avisos legados de UI/viewport persistem.
