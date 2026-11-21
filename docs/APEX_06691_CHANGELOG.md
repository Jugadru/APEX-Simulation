# Changelog — APEX 0.6.6.9.1 (proposta)

Status: DRAFT / aguardando benchmarks.

- Filtro conservador de amplo alcance (broadphase) antes do SAT contínuo de ocupação visual 3D.
- Equivalência lógica com o algoritmo anterior: 16.005 casos fixos e pseudoaleatórios reproduzíveis.
- Regressão automática de 24 carros em Silverstone, Mônaco, Spa e Singapura.
- Comparação A/B dos mesmos frames de ocupação entre `main` e candidata, com hashes esportivos cobertos pelos testes existentes.

**Não altera:** Core 2, resultados esportivos, regras de 2012, IA, pneus, boxes, clima, velocidade nominal, HUD, save/replay e fábrica.

**Não comprova ainda:** FPS em GPU física, ganho real em 32×, melhoria estatisticamente robusta. O resultado medido, favorável ou não, deve ser anotado antes de liberar o merge.

Base de desenvolvimento: `60537e348a5dd1eb6c55d60f6c144bb689221529`. Não é uma Release.
