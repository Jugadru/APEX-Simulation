# APEX Motorsport Manager — Core 2 v0.6.6.8.8

## Racecraft 2.0 — defesa consciente da aderência

A novidade é uma decisão de **defesa antecipada** mais prudente quando a pista está molhada e o defensor tem pneus gastos e percepção espacial limitada. Pilotos com melhor consciência espacial e pneus em bom estado ainda podem defender. O piloto **não recebe velocidade artificial**; depois de iniciar a disputa, a linha defensiva permanece travada (sem segunda mudança de direção). **O comportamento na pista seca permanece igual ao da v0.6.6.8.7.**

**Replay:** como uma decisão real da simulação mudou na chuva, novos registros usam `simulation_revision = 06688_grip_aware_defense`. Replays sob regras anteriores são **recusados explicitamente**, não reproduzidos com hashes incompatíveis. Faça backup de saves e replays antes de trocar de versão. O Core 2 continua único motor esportivo oficial; Next Engine suspensa.

[Relatório v8.8](APEX_06688_RELATORIO_TECNICO.md) · [Matriz de testes](APEX_06688_MATRIZ_TESTES.json) · [Changelog](APEX_06688_CHANGELOG.md)

---


Simulador de gestão de automobilismo criado em **Godot 4.7.2**. A branch `main` usa o **Core 2** como motor esportivo oficial. A **APEX 2 Next Engine** é uma experiência separada e **não está ativada**.

## Novidade Driver Dynamics 2.0

Em **RÁDIO > DISCUTIR STINT**, o piloto compara a última volta com a melhor volta e avalia desgaste, temperatura e tolerância fictícia ao risco. Pode pedir revisão da janela por perda de ritmo ou sugerir ficar mais uma volta quando o rendimento está estável. O engenheiro pondera a telemetria e preserva o BOX manual V21. **Este diálogo não altera ordens, física ou replay.** Relatório: [v0.6.6.8.7](APEX_06687_RELATORIO_TECNICO.md).

## Abrir o jogo

1. Instale o Godot **4.7.2**.
2. Abra `project.godot` no editor Godot e aguarde a importação dos recursos.
3. Execute a cena principal (F5). No Linux, `linux/run_apex.sh` aceita a variável `GODOT_BIN`.
4. Faça backup dos saves antes de mudar de versão. O diretório estável de usuário continua em `APEX_0650_SOUL_STAFF`.

O projeto inclui corrida com 24 carros, 3D, HUD ReBroadcast, Pit Wall, replay determinístico e gerenciamento de equipe. As verificações esportivas possuem limitações descritas nos relatórios, e desempenho de FPS deve ser testado no hardware do jogador.

## Versão completa e histórico

- [Release-base Core 2 v0.6.6.8.6 (ZIP original)](https://github.com/Quereni/APEX-Simulation/releases/tag/Versions)
- [Relatório técnico v0.6.6.8.7](APEX_06687_RELATORIO_TECNICO.md)
- [Matriz histórica de testes](APEX_06687_MATRIZ_TESTES.json)
- [Changelog da versão](APEX_06687_CHANGELOG.md)
- [Referência histórica: replay v0.6.6.0](docs/REPLAY_0660_USO.md)

As capturas, replays e outros arquivos grandes estão no pacote completo da Release; a árvore Git contém o código-fonte e testes leves.

## Validação automatizada (GitHub Actions)

O workflow [APEX Core 2 - Godot 4.7.2 CI](.github/workflows/godot-setup.yml) roda em push para `main` e em Pull Requests para `main`. Ele:

1. Instala o Godot 4.7.2 e **importa realmente o projeto**, em modo headless;
2. Executa seis testes de regressão reais em `tests/` (ordenação Core 2, Driver Dynamics, Racecraft, double stack, replay e modelo 3D);
3. Verifica o código de saída, o marcador de sucesso e erros reportados; publica logs de diagnóstico.

Para executar localmente no Linux, substitua `godot` pelo caminho do seu executável caso necessário:

```bash
godot --headless --single-threaded-scene --path . --import
godot --headless --single-threaded-scene --path . --script res://tests/core2_06686_sort_contract.gd
godot --headless --single-threaded-scene --path . --script res://tests/driver_dynamics_0661_test.gd
godot --headless --single-threaded-scene --path . --script res://tests/racecraft_0662_test.gd
godot --headless --single-threaded-scene --path . --script res://tests/pit_incidents_double_stack_test.gd
godot --headless --single-threaded-scene --path . --script res://tests/replay_0660_test.gd
godot --headless --single-threaded-scene --path . --script res://tests/car_model_smoke_test.gd
```

**Limite:** a bateria automática é um smoke test de engenharia, não substitui corridas completas de quatro pistas, testes de FPS 3D real ou saves de múltiplas temporadas. Mais testes direcionados devem ser adicionados gradualmente.

## Documentação histórica

Os relatórios e planos das versões anteriores continuam disponíveis na pasta `docs/`. O APEX 2 experimental não deve substituir o Core 2 sem aprovação e regressões específicas.
