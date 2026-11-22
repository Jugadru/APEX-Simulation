# Pista de laboratório sintética — APEX Test Lab

A fixture `tests/fixtures/apex_lab_track.json` define um oval fechado de 32 segmentos,
4 voltas e 2,8 km/volta, com geometria criada exclusivamente para testes. **Não**
faz parte de `data/season_2012.json`, não aparece no calendário e não utiliza
tempos históricos oficiais. O teste `tests/apex_lab_track_smoke.gd` executa o
motor real Godot com 24 carros, duas condições climáticas, dois runs por
condição com seed fixa, hash esportivo repetível e proteção de ordem BOX manual.

O teste entra no FAST e no FULL do Core 2. Serve para encontrar falhas
óbvias em uma bancada reprodutível sem percorrer 20 circuitos. **Não substitui**
FULL-20, FULL-180, Mônaco, Silverstone, replays longos, comparações A/B e
resistência em GPs completos. O atraso de ~70 minutos observado no Gate
9.13 veio do polling de evidências inválidas e foi tratado no PR #99,
independentemente desta fixture.
