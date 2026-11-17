# v0.5.5.0 — Core 2 / Clima Dinâmico

- Novo módulo `race_weather.gd` como fonte única para física e HUD.
- Novo módulo `race_wet_physics.gd` com penalidades de tempo e desgaste por água/composto.
- Corrida e IA adaptadas a chuva e pista secando.
- Pneus intermediário e chuva no Pit Wall e cartões inferiores.
- Perfil de clima selecionável no menu antes do grid.
- DRS desabilitado pelo estado climático simplificado.
- Eventos de alteração de pista no rádio.
- Quinta tabela exportável de telemetria: `clima.csv`.
- Física de boxes/duelos, geometria e câmeras preservadas.
- Teste estático e teste de integração GDScript incluídos.

Importante: a física da chuva é um primeiro modelo experimental, não fidelidade FIA nem
simulação do circuito inteiro em 3D. Sem execução do Godot na máquina de desenvolvimento.
