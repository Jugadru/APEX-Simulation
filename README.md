# APEX Motorsport Manager — Core 2 v0.6.6.8.10

Simulador de gestão de automobilismo com equipes, estratégias, desenvolvimento de carros e corridas em 3D. O **Core 2** é o motor esportivo oficial deste repositório.

## 📥 Baixar o jogo

### [⬇ Baixar APEX Core 2 v0.6.6.8.6 — ZIP completo (121 MB)](https://github.com/Quereni/APEX-Simulation/releases/download/Versions/APEX_MOTORSPORT_MANAGER_v0.6.6.8.6_CORE2_RACE_STABILITY_COMPLETO.zip)

[Ver a página do download](https://github.com/Quereni/APEX-Simulation/releases/tag/Versions) · [Como abrir](#abrir-o-jogo) · [Guia das pastas](#guia-das-pastas)

**Versão do download:** v0.6.6.8.6. O código da branch `main` contém alterações posteriores; este ZIP não inclui automaticamente essas mudanças. Para abrir o projeto, extraia o pacote e importe o `project.godot` no **Godot 4.7.2**, seguindo as instruções abaixo. O download é um pacote do projeto, não um instalador Windows/Linux.

O repositório é privado: é necessário estar conectado ao GitHub com uma conta que tenha acesso para baixar o arquivo.

## Guia das pastas

| Onde encontrar | Conteúdo |
| --- | --- |
| [`project.godot`](project.godot) | Arquivo para abrir o projeto no Godot |
| [`scripts/`](scripts/) | Código do jogo |
| [`scenes/`](scenes/) | Cenas e interfaces |
| [`assets/`](assets/) e [`data/`](data/) | Recursos visuais e dados |
| [`docs/`](docs/) | Guias e documentação |
| [`docs/arquivo/`](docs/arquivo/README.md) | Relatórios e histórico de versões |
| [`tests/`](tests/) e [`tools/`](tools/) | Testes e ferramentas de desenvolvimento |

Para começar, use o download acima e a seção **Abrir o jogo**. As seções seguintes detalham as mudanças de cada versão.

---

## Ordens de Equipe 1.0 — autorização real (v0.6.6.8.10)

Na janela **RÁDIO**, primeiro escolha o piloto que está atrás e use **COMPARAR COMPANHEIRO**. Quando há duas voltas de vantagem sustentada, menos de 1,5 segundo de distância, posições adjacentes, pneus adequados e segurança, o botão **AUTORIZAR NÃO DEFENDER** envia uma ordem explícita ao companheiro da frente. O pedido é aplicado **no tick seguinte** pelo replay e permite que o líder evite uma defesa antecipada agressiva por até **15 segundos de tempo de simulação**, sem garantir passagem nem dar velocidade artificial. A pista continua respeitando ocupação lateral, segurança e espaço físico no Core 2. O jogador pode usar **CANCELAR AUTORIZAÇÃO**.

Não há ultrapassagem automática, cancelamento de BOX V21, alteração de pneus, ritmo ou prioridade de pit. Quando a manobra não é segura, o sistema recusa a ordem. Como comandos e estado esportivo foram atualizados, replays gravados nas regras anteriores **não carregam na 8.10**; mantenha a 8.9 para reproduzi-los. O formato dos saves de carreira não foi migrado.

[Relatório 8.10](docs/arquivo/relatorios/APEX_066810_RELATORIO_TECNICO.md) · [Matriz de testes 8.10](docs/arquivo/qualidade/APEX_066810_MATRIZ_TESTES.json) · [Changelog 8.10](docs/arquivo/changelogs/APEX_066810_CHANGELOG.md)

---

## Cooperação de Equipe 2.0 — rádio consultivo (v0.6.6.8.9)

O sistema Soul 2.0 já permite ao piloto pedir uma revisão da ordem de equipe quando seu ritmo é consistentemente superior ao do companheiro. Agora, em **RÁDIO > COMPARAR COMPANHEIRO**, o engenheiro confronta o pedido com dados atuais: tempo da última volta de cada carro, diferença de ritmo, distância entre companheiros adjacentes, duas voltas consecutivas de vantagem, chuva, desgaste e operações de box. Se as informações não forem suficientes, informa a incerteza em vez de inventar uma conclusão.

**A ação é somente consultiva:** não ordena ultrapassagem, não altera velocidade, pneus, Pit Wall, regras esportivas, RNG, saves ou replay. Um BOX V21 previamente marcado continua agendado. Replays da 8.8 permanecem sob o mesmo motor esportivo.

[Relatório v8.9](docs/arquivo/relatorios/APEX_06689_RELATORIO_TECNICO.md) · [Matriz de testes v8.9](docs/arquivo/qualidade/APEX_06689_MATRIZ_TESTES.json) · [Changelog v8.9](docs/arquivo/changelogs/APEX_06689_CHANGELOG.md)

---

## Racecraft 2.0 — defesa consciente da aderência

A novidade é uma decisão de **defesa antecipada** mais prudente quando a pista está molhada e o defensor tem pneus gastos e percepção espacial limitada. Pilotos com melhor consciência espacial e pneus em bom estado ainda podem defender. O piloto **não recebe velocidade artificial**; depois de iniciar a disputa, a linha defensiva permanece travada (sem segunda mudança de direção). **O comportamento na pista seca permanece igual ao da v0.6.6.8.7.**

**Replay:** como uma decisão real da simulação mudou na chuva, novos registros usam `simulation_revision = 06688_grip_aware_defense`. Replays sob regras anteriores são **recusados explicitamente**, não reproduzidos com hashes incompatíveis. Faça backup de saves e replays antes de trocar de versão. O Core 2 continua único motor esportivo oficial; Next Engine suspensa.

[Relatório v8.8](docs/arquivo/relatorios/APEX_06688_RELATORIO_TECNICO.md) · [Matriz de testes](docs/arquivo/qualidade/APEX_06688_MATRIZ_TESTES.json) · [Changelog](docs/arquivo/changelogs/APEX_06688_CHANGELOG.md)

---


Simulador de gestão de automobilismo criado em **Godot 4.7.2**. A branch `main` usa o **Core 2** como motor esportivo oficial. A **APEX 2 Next Engine** é uma experiência separada e **não está ativada**.

## Novidade Driver Dynamics 2.0

Em **RÁDIO > DISCUTIR STINT**, o piloto compara a última volta com a melhor volta e avalia desgaste, temperatura e tolerância fictícia ao risco. Pode pedir revisão da janela por perda de ritmo ou sugerir ficar mais uma volta quando o rendimento está estável. O engenheiro pondera a telemetria e preserva o BOX manual V21. **Este diálogo não altera ordens, física ou replay.** Relatório: [v0.6.6.8.7](docs/arquivo/relatorios/APEX_06687_RELATORIO_TECNICO.md).

## Abrir o jogo

1. Instale o Godot **4.7.2**.
2. Abra `project.godot` no editor Godot e aguarde a importação dos recursos.
3. Execute a cena principal (F5). No Linux, `linux/run_apex.sh` aceita a variável `GODOT_BIN`.
4. Faça backup dos saves antes de mudar de versão. O diretório estável de usuário continua em `APEX_0650_SOUL_STAFF`.

O projeto inclui corrida com 24 carros, 3D, HUD ReBroadcast, Pit Wall, replay determinístico e gerenciamento de equipe. As verificações esportivas possuem limitações descritas nos relatórios, e desempenho de FPS deve ser testado no hardware do jogador.

## Versão completa e histórico

- [Release-base Core 2 v0.6.6.8.6 (ZIP original)](https://github.com/Quereni/APEX-Simulation/releases/tag/Versions)
- [Relatório técnico v0.6.6.8.7](docs/arquivo/relatorios/APEX_06687_RELATORIO_TECNICO.md)
- [Matriz histórica de testes](docs/arquivo/qualidade/APEX_06687_MATRIZ_TESTES.json)
- [Changelog da versão](docs/arquivo/changelogs/APEX_06687_CHANGELOG.md)
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


## Documentação histórica organizada

Os **325 documentos e manifestos históricos** que estavam na raiz foram agrupados em [`docs/arquivo/`](docs/arquivo/README.md), com inventário dos caminhos originais e hashes preservados.

O código, `project.godot`, saves e arquivos de importação permanecem nos caminhos necessários ao jogo. Use o histórico apenas como referência de versões anteriores; a documentação de cada versão pode descrever caminhos antigos.
