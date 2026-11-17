# APEX 0.6.3.5 — como abrir no Linux Mint

1. Extraia o ZIP para uma pasta nova, sem substituir sua versão 0.6.3.4.
2. Abra o Godot 4.7.2 e importe o arquivo `project.godot`.
3. Execute o jogo com **F5** e comece uma corrida.
4. Abra **RÁDIO**, selecione um dos pilotos e clique em **DISCUTIR STINT**.
5. Compare as mensagens do PILOTO com a avaliação do ENGENHEIRO. Use os filtros Equipe/Pilotos para organizar o histórico.

A discussão é informativa: não chama o box, não agenda parada e não muda o ritmo. As demais operações funcionam como antes.

Teste nativo automatizado: execute no terminal dentro da pasta do projeto:

```bash
/path/para/godot --headless --path . --script res://tests/core_0635_soul_stint_smoke_test.gd
```

Consulte `RELATORIO_NATIVO_0635.md` para resultados e pendências.
