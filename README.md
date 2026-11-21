# APEX Motorsport Manager — Core 2 (v0.6.6.9.4)

Simulador de gestão de automobilismo com equipes, estratégias, desenvolvimento de carros e corridas em 3D. O **Core 2** é o motor esportivo oficial deste repositório.

## 📥 Baixar o jogo — v0.6.6.9.4

### [⬇ Baixar APEX v0.6.6.9.4 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950040/artifacts/14725252948)

**Pacote para PC**, compilado no **Godot 4.7.2** a partir do commit candidato testado `63d7953cc21184d6902ebc8cc34b7e696ec927ba` e integrado à `main` na [PR #76](https://github.com/Jugadru/APEX-Simulation/pull/76). O artefato contém ZIPs separados para **Windows x86_64** e **Linux x86_64**. Extraia o pacote externo do GitHub Actions e o ZIP do seu sistema; mantenha o executável e o arquivo `.pck` na mesma pasta.

**Download temporário até 05/12/2026**, possivelmente exigindo login no GitHub. A exportação verificou a identificação `APEX Motorsport Manager v0.6.6.9.4` nos dois pacotes. Houve teste básico de inicialização no Linux. Não foi feito teste gráfico nativo no Windows do usuário; **nenhuma Release pública permanente v9.4 foi publicada**.

### [⬇ Baixar código-fonte oficial da v0.6.6.9.4 — Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/archive/17ad31b1402d67b239d148e7fb2f5e9c5013b8d0.zip)

O código integrado no commit `17ad31b1402d67b239d148e7fb2f5e9c5013b8d0` tem a **mesma árvore de arquivos** do commit testado e exportado `63d7953cc21184d6902ebc8cc34b7e696ec927ba`. O ZIP do código-fonte serve para edição no Godot, não contém executáveis prontos.

**Novidade Driver Soul 3.0:** pilotos têm intenção por volta, refletindo confiança, foco, pressão, iniciativa e desgaste percebido. Esses valores influenciam **o limiar para assumir uma ultrapassagem**, não a velocidade ou aderência do carro. O rádio transmite pedidos fictícios baseados nos fatos da corrida e preserva controles IA/manual e agendamentos de box. Replays da v9.3 usam as próprias regras históricas para evitar divergências silenciosas.

**Validação:** **17/17 workflows PASS** e [Quality Gate READY 10/10](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950949960) no commit candidato. [Monza 53 voltas PASS](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950061) com 24 carros classificados, 24.229 ticks e replay integral com hash igual. SaveGuard e 20 circuitos PASS. O comparador visual A/B verificou zero colisões, nenhuma piora em ressincronização/lag e repetibilidade dentro de cada revisão. O agregado headless mediano foi ~0,30% menor que na v9.3, mas **não prova ganho de FPS**. Problema de 32× sustentados segue na [issue #74](https://github.com/Jugadru/APEX-Simulation/issues/74), e ressincronizações visuais antigas em Mônaco/Spa na [issue #77](https://github.com/Jugadru/APEX-Simulation/issues/77).

## 📦 Versão anterior — v0.6.6.9.3

### [⬇ Baixar APEX v0.6.6.9.3 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44944744266/artifacts/14722189740)

Pacote de rollback para a última revisão antes do Soul 3.0. [Código-fonte v9.3](https://github.com/Jugadru/APEX-Simulation/archive/53c0adf0da87a93e4b79c8a2c240c063b7c201f2.zip). Também é um download temporário do GitHub Actions.

## 📦 Versão anterior — v0.6.6.9.2

### [⬇ Baixar APEX v0.6.6.9.2 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44938862417/artifacts/14720252805)

Pacote de rollback e comparação, também para Godot 4.7.2. [Código-fonte da v9.2](https://github.com/Jugadru/APEX-Simulation/archive/8e0490be3d4d20459354971c766c1179acd2d7bc.zip). A v9.2 introduziu otimização de cache no hash esportivo e preservou o determinismo; veja a [PR #70](https://github.com/Jugadru/APEX-Simulation/pull/70). O download binário é temporário e requer conferência de disponibilidade no GitHub.

## 📦 Versão anterior — v0.6.6.9.1

### [⬇ Baixar ZIPs CORRIGIDOS para Windows e Linux — v0.6.6.9.1](https://github.com/Jugadru/APEX-Simulation/actions/runs/44934421047/artifacts/14718572939)

Esse link abre o **artefato de build corrigido da versão v0.6.6.9.1**: dentro dele estão os ZIPs de **Windows x86_64** e **Linux x86_64**, ambos com o executável e o arquivo `.pck`, gerados no Godot 4.7.2. **Verificação realizada nos dois `.pck`: ambos contêm a identificação v0.6.6.9.1 e não contêm mais a identificação v0.6.6.8.10.** Extraia o arquivo externo do GitHub Actions e, em seguida, o ZIP do seu sistema operacional. Pode ser necessário entrar na sua conta GitHub para baixar o artefato.

**Atenção: download temporário.** O GitHub Actions mantém esse artefato até **05/12/2026**. O ZIP corrigido foi gerado a partir do commit `61101ee3f53494340111715a6a782e297934fd53` ([PR #67](https://github.com/Jugadru/APEX-Simulation/pull/67)), com exportação Linux/Windows e checagem da identificação interna aprovadas. A otimização v0.6.6.9.1 anterior passou 16/16 workflows no [PR #65](https://github.com/Jugadru/APEX-Simulation/pull/65). A correção da identificação foi **integrada à `main` na [PR #67](https://github.com/Jugadru/APEX-Simulation/pull/67)**, após **15/15 workflows aprovados e Quality Gate READY 10/10**. O pacote corrigido **ainda não é uma Release pública permanente**.

### [⬇ Baixar ZIP do código-fonte corrigido v0.6.6.9.1 — Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/archive/def8fdfcd638dc0f5b539ef816a014e9673bc1ff.zip)

Esse segundo link aponta para o **commit definitivo da `main` que integrou a correção da versão**, preservando o mesmo código executável do pacote validado; o artefato binário foi construído no commit candidato descrito acima. Use-o para **editar o jogo no Godot**; não substitui os executáveis de Windows/Linux.

### [⬇ Última Release pública permanente — v0.6.6.8.10](https://github.com/Jugadru/APEX-Simulation/releases/tag/v0.6.6.8.10-core2-current)

A Release pública acima é da **v0.6.6.8.10**, **não** contém a otimização 3D da v0.6.6.9.1. Serve como alternativa estável de download quando o artefato temporário expirar, até que a versão 9.1 seja publicada oficialmente.

**Para jogar:** descompacte o ZIP específico de Windows ou Linux e execute o programa; no Linux, talvez seja preciso `chmod +x APEX_Motorsport_Manager.x86_64`. Os pacotes de desktop são exportações para PC, sem teste nativo de execução no Windows ou medição de FPS na GPU do usuário.

**Versão histórica preservada:** [v0.6.6.8.6 — ZIP completo do projeto](https://github.com/Jugadru/APEX-Simulation/releases/download/Versions/APEX_MOTORSPORT_MANAGER_v0.6.6.8.6_CORE2_RACE_STABILITY_COMPLETO.zip). Esse pacote não contém as atualizações recentes da `main`.

[Como abrir no Godot](#abrir-o-jogo) · [Histórico de Releases](https://github.com/Jugadru/APEX-Simulation/releases) · [Guia das pastas](#guia-das-pastas)

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

- [Release-base Core 2 v0.6.6.8.6 (ZIP original)](https://github.com/Jugadru/APEX-Simulation/releases/tag/Versions)
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
