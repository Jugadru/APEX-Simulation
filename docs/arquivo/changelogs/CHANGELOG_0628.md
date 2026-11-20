# APEX v0.6.2.8 — Cenários 3D procedurais

Base: v0.6.2.7, aprovada pelo usuário em teste real do Diretor TV. Esta entrega **não** é uma reconstrução fotorrealista nem inclui circuitos licenciados em 3D.

## Alterações

- Novo módulo `scripts/apex_circuit_scenery_0628.gd`: define uma paleta visual por ambiente (deserto, tropical, urbano, temperado) e constrói placas originais APEX, postes de proteção em `MultiMesh` e estruturas distantes simples em alguns cenários.
- Bahrain, Yas Marina e Buddh: terreno arenoso, sem árvores tropicais, edifícios baixos e discretos.
- Monaco, Valencia e Marina Bay: terreno acinzentado, volumes de edificações urbanas, sem árvores distribuídas aleatoriamente.
- Sepang e Interlagos: terreno verde tropical e árvores já existentes.
- Outros circuitos: terreno temperado e árvores já existentes.
- Cor do horizonte e da arquibancada adaptadas à paleta, preservando geometria e coordenadas dos traçados.
- Modelos 3D procedurais dos carros receberam retrovisores, entradas de radiador, aletas externas da asa dianteira e luz traseira visual; dinâmica, movimento, pneus e tamanho do carro não mudaram.
- Nenhuma colisão ou física nos novos elementos; placas e edifícios posicionados fora do asfalto com checagem de distância às seções da pista.

## Arquivos existentes alterados

- `scripts/track_3d.gd` — chama o módulo visual e aplica cores do ambiente.
- `scripts/car_model_3d.gd` — apenas adições de detalhes geométricos estáticos no construtor do modelo.
- `scripts/main.gd` e `project.godot` — identificação da versão.

## Integridade

`tests/0628_preserved_sha256.json` fixa SHA-256 dos arquivos imutáveis (motor de corrida, estrategista, regras de pneus, clima, TV, câmera Livre e HUD); as funções de comportamento do modelo de carro têm SHA-256 próprios. Testes estáticos: `tests/test_0628_scenery_static.py`. Smoke test nativo Godot: `tests/core_0628_scenery_smoke_test.gd`. Script: `bash linux/validar_0628.sh`.

## Limites

Não adiciona modelagem real de Bahrain nem prédios oficiais de cada circuito. Ainda é estética procedural de baixo polígono, com ambiente ilustrativo. O resultado visual deve ser observado na sua instalação do Godot.
