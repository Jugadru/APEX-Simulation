# APEX Motorsport Manager — v0.6.6.8.12 (Core 2)

## Guia histórico da temporada 2012

No menu de preparação, clique em GUIA DA TEMPORADA 2012 — PNEUS / CARROS / CALENDÁRIO. O guia reúne três abas: os seis compostos Pirelli e suas cores originais; as 12 equipes e seus nomes históricos de chassis e motores V8; e as 20 corridas do calendário FIA 2012 com data, volta e pneus de seco nominados no catálogo do próprio APEX.

Os botões ESCOLHER EQUIPE e PREPARAR GP operam os seletores existentes do menu, sem iniciar a corrida. Enquanto uma carreira está ativa, as escolhas são apenas consultivas.

A classificação da HUD ReBroadcast também recebeu as cores reais de 2012: SS vermelho, S amarelo, M branco, H prata, I verde, W azul. Nenhum coeficiente de grip, desgaste, pit, lógica de piloto ou RNG foi alterado.

Nesta versão NÃO foram criados modelos 3D adicionais, pinturas históricas externas nem cópias de imagens de carros; a referência de chassi é textual e colore as equipes a partir dos dados já presentes. O pacote de retratos opcionais da 8.11 continua intacto.

Documentação: APEX_066812_CHANGELOG.md, APEX_066812_RELATORIO_TECNICO.md e APEX_066812_MATRIZ_TESTES.json. Fontes: Pirelli 2012 (https://press.pirelli.com/pirelli-announces-compound-choice-for-the-first-three-races/), chassis (https://www.f1technical.net/f1db/cars/years/2012) e calendário arquivado da FIA (https://www.fia.com/events/fia-formula-one-world-championship/season-2012/calendar).

---

# APEX Motorsport Manager — Core 2 v0.6.6.8.11

## Driver Identity Pack 2012 — fotografias de pilotos reais (v0.6.6.8.11)

Identidade histórica dos **24 titulares da temporada 2012**: número, sigla, país, equipe e foto individual. O novo catálogo fica em `data/driver_identity_2012.json`.

No menu, selecione **BAIXAR RETRATOS DA EQUIPE** ou **BAIXAR RETRATOS DE TODA A GRID**. O jogo obtém fotos individuais do Wikimedia Commons e verifica a licença CC BY-SA 3.0 e o fotógrafo Gussisaurio **para cada arquivo** antes de salvar no cache local. Precisa de internet apenas no primeiro download.

**Nunca aparece um carro no lugar do rosto do piloto:** se a foto estiver indisponível, o jogo mostra apenas as iniciais. Os retratos, quando baixados, aparecem nos cards e na janela de rádio com créditos e fonte. A escolha é reversível: remova o cache local `user://apex_driver_portraits_2012` para reverter às iniciais. As fotografias não são embutidas automaticamente no ZIP de fontes.

O material YankeeF1 foi utilizado só como referência; nenhuma foto da montagem foi redistribuída. Consulte os [créditos individuais e licenças](docs/DRIVER_PORTRAITS_2012_CREDITS.md).

**Sem alterações esportivas**: Core 2, Pit Wall, ordens V21, replays e saves permanecem compatíveis com a v0.6.6.8.10. A revisão esportiva do replay não muda.

[Relatório 8.11](APEX_066811_RELATORIO_TECNICO.md) · [Matriz de testes 8.11](APEX_066811_MATRIZ_TESTES.json) · [Changelog 8.11](APEX_066811_CHANGELOG.md)

---

## Ordens de Equipe 1.0 — autorização real (v0.6.6.8.10)

Na janela **RÁDIO**, primeiro escolha o piloto que está atrás e use **COMPARAR COMPANHEIRO**. Quando há duas voltas de vantagem sustentada, menos de 1,5 segundo de distância, posições adjacentes, pneus adequados e segurança, o botão **AUTORIZAR NÃO DEFENDER** envia uma ordem explícita ao companheiro da frente. O pedido é aplicado **no tick seguinte** pelo replay e permite que o líder evite uma defesa antecipada agressiva por até **15 segundos de tempo de simulação**, sem garantir passagem nem dar velocidade artificial. A pista continua respeitando ocupação lateral, segurança e espaço físico no Core 2. O jogador pode usar **CANCELAR AUTORIZAÇÃO**.

Não há ultrapassagem automática, cancelamento de BOX V21, alteração de pneus, ritmo ou prioridade de pit. Quando a manobra não é segura, o sistema recusa a ordem. Como comandos e estado esportivo foram atualizados, replays gravados nas regras anteriores **não carregam na 8.10**; mantenha a 8.9 para reproduzi-los. O formato dos saves de carreira não foi migrado.

[Relatório 8.10](APEX_066810_RELATORIO_TECNICO.md) · [Matriz de testes 8.10](APEX_066810_MATRIZ_TESTES.json) · [Changelog 8.10](APEX_066810_CHANGELOG.md)

---

## Cooperação de Equipe 2.0 — rádio consultivo (v0.6.6.8.9)

O sistema Soul 2.0 já permite ao piloto pedir uma revisão da ordem de equipe quando seu ritmo é consistentemente superior ao do companheiro. Agora, em **RÁDIO > COMPARAR COMPANHEIRO**, o engenheiro confronta o pedido com dados atuais: tempo da última volta de cada carro, diferença de ritmo, distância entre companheiros adjacentes, duas voltas consecutivas de vantagem, chuva, desgaste e operações de box. Se as informações não forem suficientes, informa a incerteza em vez de inventar uma conclusão.

**A ação é somente consultiva:** não ordena ultrapassagem, não altera velocidade, pneus, Pit Wall, regras esportivas, RNG, saves ou replay. Um BOX V21 previamente marcado continua agendado. Replays da 8.8 permanecem sob o mesmo motor esportivo.

[Relatório v8.9](APEX_06689_RELATORIO_TECNICO.md) · [Matriz de testes v8.9](APEX_06689_MATRIZ_TESTES.json) · [Changelog v8.9](APEX_06689_CHANGELOG.md)

---

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
2. Executa uma bateria de **19 testes reais** em `tests/`, incluindo Core 2, Driver Dynamics, Racecraft, team orders, retratos/identidade, três testes de HUD ReBroadcast, Pit Wall, replay e modelo 3D;
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
