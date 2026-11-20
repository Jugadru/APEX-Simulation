# Relatório de validação — Apex v0.6.1

- Base de entrada: `Apex_0600_Temporada2012_EXPERIMENTAL.zip` íntegro (CRC).
- Comandos: `python3 tests/run_all_static.py` → **30/30 scripts PASS**; `python3 tests/test_0610_static.py` → **PASS**.
- Confirmada presença dos 20 códigos de circuito únicos e clima independente por código/seed.
- `scripts/race_engine.gd` e `scripts/championship_2012.gd` não foram alterados, protegendo o motor, pontuação e persistência anterior.
- Verificados em código os modos 32×, Aérea, minimapa dinâmico, painel contextual e o enquadramento responsivo.
- Godot não foi encontrado no PATH, nem em `/opt`/`/usr/local`; tentativa de consulta externa falhou por DNS. **Não executado nenhum teste runtime do Godot.**
- Teste GDScript incluído para usuário: `godot --headless --path . --script res://tests/core_0610_weather_and_speed_test.gd`.

**Conclusão:** pronto como *release experimental para teste*, não como versão homologada.
