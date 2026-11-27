# Hyper 2.2.0 — Longitudinal integration candidate 01

Sinal verde do responsável em 26/11/2026. Escopo: apenas contrato de movimento longitudinal, não toda a Hyper 2.2. Base de pesquisa Core 2: 8ca21459d107cef978ed427d643cfb1863e4e6ac. A Alpha 2 está em ZIP separado, não na árvore main. A leitura do relatório e manifesto de 2.1 confirma 200 ms, física longitudinal existente, coordenadas em mm e checkpoint separado; o ambiente local falhou antes da extração do código. **Não há auditoria linha a linha, integração, build ou versão 2.2 jogável.** Este candidato no GitHub não substitui a Alpha 2.

## Reuso e responsabilidades

Core 2 atual já possui race_longitudinal_069.gd, race_powertrain_070.gd, race_fuel_mass_0701.gd e race_tyre_grip_071.gd. O adaptador usa as primitivas públicas rates, braking_cap, integrate e settle do primeiro; não duplica a física, não ativa revisões do Core 2, não modifica arquivos esportivos existentes. O algoritmo de taxa é heurístico e não telemetria oficial.

- Entradas: estágio, launch_active, velocidade e alvo m/s, grip normalizado, dt de condução [0,0.2] s, restrições dianteiras distância m/velocidade m/s.
- Proposta: rampa aceleração/frenagem + cruzeiro, distância não negativa, antecipação de restrições, sem alterar posição. A mesma observação produz o mesmo resultado.
- Solver existente é soberano: a liquidação usa distância realmente autorizada e reduz velocidade terminal quando necessário. Tolerância de 1 mm exclusiva de arredondamento; nenhum incremento de posição, pit ou RNG no adaptador.
- Grid/largada, pits, finalização e transições ficam com a política existente. Não usar proposta de TRACK em movimento de box. Rejeição explícita de entradas inválidas, sem mutação.
- O adaptador não possui estado próprio; velocidade terminal e revisão devem pertencer ao kernel da Hyper, com serialização e hash próprios. Não copiar campos de replay Core 2. Não aceitar checkpoints antigos silenciosamente sob física nova.

## Integração pendente, condicionada ao acesso à Alpha 2

1. Abrir ZIP original 2.1 e conferir SHA256/manifesto; auditar experimental/apex2/vehicle_dynamics.gd, vehicle_kernel_11.gd, experimental/hyper/kernel.gd e experimental/hyper2/kernel.gd, quality.gd e replay.gd. Não presumir onde a física deve ser substituída. Verificar dependências dos preloads do Core 2 no ZIP.
2. Identificar um único ponto de proposta/solver/liquidação. Preservar movimento antigo em revisão anterior, sem mudar grid, pit stages, troca de pneus, autoridade manual ou carreira. Reconciliar mm/velocidades/tempos, evitando aplicação dupla de aero, erro, pneus e energia.
3. Nova revisão Hyper e testes de checkpoint/replay em 200 ms. Regra BOX V21 sob chuva 83%, Monza seco, Silverstone molhado, Mônaco tráfego, comparação A/B com mesmas seeds/comandos; validar ritmo e pit real.
4. Testar importação do ZIP extraído e produzir pacote integral somente após evidência. Não alterar Core 2, Alpha 1 ou Alpha 2. Rollback: usar a Alpha 2 original.

## QA

Fixture isolada native Godot roteada no FAST: oráculos de aceleração, distância, frenagem, preview, solver, entradas inválidas, bypass de fases, imutabilidade e determinismo de 24 atores independentes. Não simula corrida, boxes ou replay real. FAST no SHA exato obrigatório; não acionar FULL automático. Inicial: Godot/integração/GP/checkpoints da Hyper 2.2 = NOT_RUN/BLOCKED (ambiente local indisponível). Sem release, sem merge, sem ganho de desempenho declarado.

Roadmap aprovado continua 2.2.1 torque, 2.2.2 câmbio, 2.2.3 antecipação de frenagem refinada, 2.2.4 massa/combustível, 2.2.5 aero, 2.2.6 telemetria, 2.2.7 calibração. Este candidato não antecipa implementação desses sistemas.
