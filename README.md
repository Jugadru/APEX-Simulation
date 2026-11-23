# APEX Motorsport Manager — Core 2 (código v0.6.6.9.16)

**Código-fonte atual na `main`: v0.6.6.9.16 — Race Gaps & Overtaking 2.0 (radar de proximidade).** Nova métrica de distância física de pista na HUD, sem alterar as lacunas cronométricas da classificação ou a simulação esportiva. A última versão binária disponível para teste continua sendo a **9.15**.


### ✅ Política oficial permanente: FAST + APEX Test Lab

**Decisão do projeto (23/11/2026): para atualizações comuns, a homologação obrigatória é somente FAST + APEX Test Lab + regressões direcionadas, no commit exato do PR.** Esta regra se aplica às próximas versões (9.16 em diante) e prevalece sobre relatórios históricos que exigiam FULL como condição de merge.

- **FAST obrigatório:** importar no **Godot 4.7.2**, executar o workflow único `APEX Core 2 - Godot 4.7.2 CI`, o **APEX Test Lab** (24 carros, seco/chuva, determinismo/hash, CPU e memória) e os testes selecionados conforme o código alterado. Regressões relevantes de pit manual, IA, saves e replays devem continuar passando.
- **Aprovação para merge:** FAST concluído com **PASS no SHA da versão**, sem erros ou testes obrigatórios ausentes; corrigir falhas reais antes da integração. Um teste `skipped`, `NOT_RUN` ou `INCONCLUSIVE` não pode ser contado como PASS.
- **FULL NÃO é obrigatório por padrão:** **não** acionar automaticamente `ci:full`, matriz completa 20/180, endurance longo, comparador visual completo, benchmark abrangente, exportação ou Quality Gate histórico para cada PR. Eles são **opcionais e manuais**, quando o responsável solicitar expressamente.
- **Exceções de risco:** se houver mudança de física, replay, save, clima ou um defeito específico de circuito, acrescentar **regressões direcionadas proporcionais ao risco**, inclusive em pista real, sem transformar a alteração em homologação FULL automática. Se não houver evidência suficiente, manter o PR aberto.
- **Uma funcionalidade principal por versão.** Publicar um ZIP jogável ou uma GitHub Release é uma etapa distinta do merge do código e requer validação do pacote.

**Para colaboradores e assistentes de código:** consultar também [AGENTS.md](AGENTS.md) e o [guia do FAST permanente](docs/APEX_CI_INTELIGENTE_TRES_NIVEIS.md). **Não restaurar a política antiga de FULL obrigatório sem nova decisão explícita do projeto.**


**Última compilação jogável para TESTES: v0.6.6.9.15 — Linux e Windows x86_64.** Gerada em 23/11/2026 no Godot 4.7.2, com validação de identificação dos PCKs e smoke Linux. **[⬇ Baixar APEX 9.15 para testar](https://github.com/Jugadru/APEX-Simulation/actions/runs/45263299614/artifacts/14860803687)** (ZIP externo com pacotes de Linux e Windows; pode exigir login GitHub; artefato expira em **07/12/2026**).

**Última release oficial permanente: v0.6.6.9.9 — Race Quality Release.** Publicada em 22/11/2026 para Windows e Linux x86_64. Os ZIPs e a tag dessa release continuam disponíveis, sem alterações.

> **Importante:** a `main` contém código até a **9.16**, mas a build jogável disponível para teste ainda é a **9.15**, distribuída como artefato temporário do GitHub Actions. Isso **não é uma GitHub Release permanente**. Para baixar sem prazo de expiração, a release oficial mais recente ainda é a 9.9. Para desenvolver, abra `project.godot` da `main`.

### Evolução do código após a release 9.9

| Código | Funcionalidade integrada |
| --- | --- |
| 9.10 | Strategy Staff Intelligence — estratégia e coordenação da equipe |
| 9.11 | Race Start Intelligence — decisões na largada |
| 9.12 | Overtaking Intelligence — ultrapassagem e replay |
| 9.13 | Race Engineer Intelligence — relatórios consultivos do engenheiro |
| 9.14 | Setup & Track Knowledge — 20 perfis de pista de 2012, recomendações qualitativas e consulta `SETUP/PISTA` no HUD |
| **9.15** | **Performance & Race Polish** — cache dos perfis estáticos de pista na HUD, preservando clima, pneus e BOX manuais |
| **9.16** | **Race Gaps & Overtaking 2.0 (1ª etapa)** — métrica `DIST. PISTA` com proximidade física no HUD: F=frente, T=trás, unidades esquemáticas (não tempo cronometrado); carro retardatário também conta, sem mudar a física/replay. [Detalhes](docs/APEX_RELEASE_v0.6.6.9.16_RACE_GAPS_OVERTAKING.md) |

Na 9.14, o setup é **consultivo**: não aplica ajustes de asa/suspensão nem muda ordens de box. A revisão esportiva continua `023_overtaking_intelligence_v1`; BOX manual V21 e saves/replays são preservados.

**Desenvolvimento atual:** somente **FAST + APEX Test Lab + regressões direcionadas** automaticamente. Matriz 20/180, endurance, comparações, exportações e Quality Gate histórico são executados manualmente quando solicitados. Consulte o [guia FAST](docs/APEX_CI_INTELIGENTE_TRES_NIVEIS.md).

## 📥 Baixar o jogo — v0.6.6.9.15 (prévia para teste)

### [⬇ Baixar APEX 9.15 — Linux e Windows x86_64](https://github.com/Jugadru/APEX-Simulation/actions/runs/45263299614/artifacts/14860803687)

**Versão atual do código jogável**, compilada com Godot 4.7.2. Abra o link, entre no GitHub se necessário e baixe o artefato `apex-pc-linux-windows-godot-4-7-2`. Extraia primeiro o ZIP externo e depois **o ZIP de seu sistema operacional**. Em cada pasta, mantenha o executável e o arquivo `APEX_Motorsport_Manager.pck` juntos:

- **Linux:** execute `chmod +x APEX_Motorsport_Manager.x86_64` se necessário e abra o executável.
- **Windows:** execute `APEX_Motorsport_Manager.exe`. O pacote foi validado, mas ainda não passou por teste gráfico nativo em Windows.

**Validações:** build Linux e Windows aprovadas, identificação `v0.6.6.9.15` dentro de ambos os PCKs, integridade dos ZIPs e teste de inicialização Linux sem tela. O artefato inclui `SHA256SUMS.txt`, `manifest.json` e `SOURCE_COMMIT.txt`. Não representa homologação gráfica em PC real. **Link temporário, expira em 07/12/2026.**

**Origem:** [build aprovada no GitHub Actions](https://github.com/Jugadru/APEX-Simulation/actions/runs/45263299614) · Código do jogo baseado na `main` v9.15 (`3187e889`); o commit do artefato (`913293d3`) inclui apenas a configuração de exportação opt-in.

## 📦 Release oficial anterior — v0.6.6.9.9

- **[Windows x86_64 — ZIP oficial](https://github.com/Jugadru/APEX-Simulation/releases/download/v0.6.6.9.9/APEX_Motorsport_Manager_4.7.2-stable_windows_x86_64.zip)**
- **[Linux x86_64 — ZIP oficial](https://github.com/Jugadru/APEX-Simulation/releases/download/v0.6.6.9.9/APEX_Motorsport_Manager_4.7.2-stable_linux_x86_64.zip)**
- **[Código-fonte Godot 4.7.2 — ZIP oficial](https://github.com/Jugadru/APEX-Simulation/releases/download/v0.6.6.9.9/APEX_Motorsport_Manager_v0.6.6.9.9_Godot_source.zip)**

[**Release oficial e notas completas**](https://github.com/Jugadru/APEX-Simulation/releases/tag/v0.6.6.9.9) · [SHA-256](https://github.com/Jugadru/APEX-Simulation/releases/download/v0.6.6.9.9/SHA256SUMS.txt) · [Manifesto](https://github.com/Jugadru/APEX-Simulation/releases/download/v0.6.6.9.9/manifest.json)

**Instalação:** extraia o ZIP do seu sistema, mantendo o executável e o arquivo `.pck` juntos. No Linux, se necessário, execute `chmod +x APEX_Motorsport_Manager.x86_64`. Para desenvolver, abra `project.godot` no Godot 4.7.2.

### O que inclui a versão 9.9

- **Race Quality:** correção determinística do travamento por empate de espaço em Mônaco, auditoria das corridas e regressões de estratégia, box, chuva e replay.
- **HUD Manager (PR #90):** BOX em destaque e com estados claros, contexto dos pilotos, composto e vida do pneu, intervalos de classificação e previsão observacional de água na pista para agora, +5, +10 e +15 minutos.
- **Homologação:** [Gate estrito READY 19/19](https://github.com/Jugadru/APEX-Simulation/actions/runs/45036719496) no SHA `8eb8c7bd36a2fda7e4310de6d4f0e27192fe337f`; [matriz completa dos 20 circuitos, 4/4 grupos PASS](https://github.com/Jugadru/APEX-Simulation/actions/runs/45036719568), 180 cenários executados duas vezes e [12 GPs integrais em Silverstone e Monza](https://github.com/Jugadru/APEX-Simulation/actions/runs/45036719465).
- **Distribuição:** [publicação e exportações Linux/Windows aprovadas](https://github.com/Jugadru/APEX-Simulation/actions/runs/45047254584), verificação dos `.pck`, hashes SHA-256, importação Godot e teste de inicialização Linux.
- **Compatibilidade:** motor esportivo Core 2, BOX manual V21, revisão de replay 020, diretório de usuário e saves legados preservados.

A exportação Windows foi validada, mas **não** executada em um PC Windows nativo. O teste Linux é de inicialização headless; os workflows não comprovam FPS/GPU no computador do jogador. O caso de fila de pit de 5,8772 s continua como **REVIEW**, sem conclusão causal de defeito.

A PR [#90 — HUD](https://github.com/Jugadru/APEX-Simulation/pull/90) foi integrada antes da release, e as PRs [#87 — QA](https://github.com/Jugadru/APEX-Simulation/pull/87) e [#88 — Publicação](https://github.com/Jugadru/APEX-Simulation/pull/88) também foram integradas. A tag `v0.6.6.9.9` e seus ZIPs permanecem imutáveis; atualizações de documentação e descrição no ramo `main` feitas depois da publicação não alteram os pacotes já lançados.

**Próxima funcionalidade planejada:** v9.17 — Largada 2.0, respeitando uma melhoria principal por versão. Uma atualização do código não publica automaticamente nova release binária.

---

Simulador de gestão de automobilismo com equipes, estratégias, desenvolvimento de carros e corridas em 3D. O **Core 2** é o motor esportivo oficial deste repositório.

## 📦 Histórico — v0.6.6.9.8 (versão anterior)

### [⬇ Baixar APEX v0.6.6.9.8 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972921/artifacts/14738384976)

Pacote x86_64 exportado em **Godot 4.7.2**; os dois arquivos `.pck` foram verificados com a identificação correta `v0.6.6.9.8`. A inicialização headless no Linux passou. Extraia o ZIP do GitHub Actions e, depois, o ZIP do seu sistema, mantendo executável e `.pck` juntos. No Linux pode ser necessário `chmod +x APEX_Motorsport_Manager.x86_64`.

**Artefato temporário até 06/12/2026**, possivelmente exige login no GitHub. Não é uma GitHub Release permanente nem comprova FPS 3D nativo no PC do jogador.

### [⬇ Baixar o código-fonte oficial v0.6.6.9.8 — Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/archive/c62dc42d0745d6796db1403622f046e515fec7b8.zip)

A candidata `40fa39ab75ebd2c25258f72638d92cbdda387071` foi integrada à `main` pela [PR #86](https://github.com/Jugadru/APEX-Simulation/pull/86), merge `c62dc42d0745d6796db1403622f046e515fec7b8`. As árvores Git são idênticas. O código-fonte não é um executável.

### 🌧️ Novidade — Wet Strategy Intelligence

- **Previsão imperfeita observacional:** a IA analisa água na linha e fora dela, umidade, chuva observada e drenagem sem consultar tempestades futuras ocultas no motor.
- **Estratégia com incerteza:** recomendações conservadoras em transições molhado/seco; o modelo não inventa probabilidade estatística calibrada.
- **Proteção esportiva:** paradas críticas não são bloqueadas, comandos manuais e V21 continuam protegidos, fila FIFO e mecânica de 2012 preservadas.
- **Replay compatível:** novas corridas usam revisão `020_wet_strategy_intelligence_v1`, com manutenção das regras meteorológicas antigas para arquivos `019` e anteriores; schema de save inalterado.
- **Build identificada corretamente:** versão 9.8 validada dentro dos PCKs Linux/Windows; sem alterar a pasta de usuário/saves.

**Homologação:** [21/21 workflows PASS](https://github.com/Jugadru/APEX-Simulation/commit/40fa39ab75ebd2c25258f72638d92cbdda387071/checks), [Quality Gate READY 10/10](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972797), teste Wet Strategy **83 verificações**, [20 circuitos 4/4](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972857), [Monza 53 voltas com 24.229 ticks e replay integral verificado](https://github.com/Jugadru/APEX-Simulation/actions/runs/44984972885), SaveGuard e exportações PASS. A primeira auditoria do gate registrou BLOCKED enquanto faltavam verificações; a nova auditoria pós-CI confirmou READY.

**Caso em acompanhamento:** Pit Wall Analyzer aprovou 8 execuções, mas manteve uma observação `REVIEW/PIT_QUEUE` de 5,8772 s em Monza. Não equivale a teste falhado; a v9.8 não promete eliminar todas as filas. Benchmarks headless não substituem testes reais de GPU/FPS.

**Documentação técnica:** [Relatório Wet Strategy 9.8](docs/APEX_RELEASE_v0.6.6.9.8_WET_STRATEGY.md).

## 📦 Versão anterior — v0.6.6.9.7

### 📥 Baixar o jogo — v0.6.6.9.7

### [⬇ Baixar APEX v0.6.6.9.7 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100017/artifacts/14734451599)

Pacote exportado no **Godot 4.7.2**, com ZIPs para Windows x86_64 e Linux x86_64. Extraia o ZIP externo do GitHub Actions e depois o ZIP do seu sistema, mantendo o executável junto do arquivo `.pck`. No Linux, pode ser necessário `chmod +x APEX_Motorsport_Manager.x86_64`.

**Artefato temporário até 06/12/2026**, sujeito a login/retention do GitHub Actions; não é uma GitHub Release permanente. O smoke de inicialização Linux passou; ainda não equivale a teste gráfico nativo na máquina do jogador.

### [⬇ Baixar o código-fonte v0.6.6.9.7 — Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/archive/6c6560bd36f2eecda82cf7959b884464054bc03c.zip)

A candidata aprovada no commit `689aaf7522002a3d8c385dd70a1ac5eb8b07f851` foi integrada à `main` via [PR #81](https://github.com/Jugadru/APEX-Simulation/pull/81), merge `6c6560bd36f2eecda82cf7959b884464054bc03c`. O ZIP do código-fonte é para desenvolvimento, não contém o executável.

### 🛠️ Novidade — Pit Coordination 2.0

- **FIFO física real:** quando dois pilotos disputam a mesma garagem, o acesso é decidido pelo instante calculado de chegada à equipe de mecânicos e, no empate, pelo ID estável do piloto — nunca pela ordem de processamento do array.
- **Double stack verificável:** o segundo carro aguarda sua vez e acumula tempo real de fila. Serviço, reparo e retenção de segurança continuam exclusivos da única equipe de mecânicos por garagem.
- **Pit Wall integrado:** mostra proprietário atual, etapa de atendimento, retenção factual, posição na fila, espera acumulada e estimativa de liberação. Não inventa tráfego nem acidentes.
- **Autoridade preservada:** nenhuma antecipação indevida de ordem Manual V21, nem alteração da estratégia preventiva/IA, física de pneus ou probabilidade de incidentes.
- **Compatibilidade de replay:** nova revisão esportiva `018_pit_coordination_v1`, com modo legado para reproduzir a regra antiga nos arquivos `017_driver_soul_v1`. Saves usam o mesmo schema.

**Validação:** [20/20 workflows GitHub Actions PASS](https://github.com/Jugadru/APEX-Simulation/commit/689aaf7522002a3d8c385dd70a1ac5eb8b07f851/checks) e [Quality Gate READY 10/10](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100063) no commit aprovado. O módulo v9.7 passou **41 verificações**, SaveGuard **53**, além dos **20 circuitos**, testes visuais, versões legadas, Linux/Windows e [Monza 53 voltas, 24.229 ticks, replay integral com hash confirmado](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100029). Os benchmarks headless não substituem FPS 3D real do PC do usuário.

**Limitação conhecida:** o [Pit Wall Intelligence Analyzer](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100061) encerrou com PASS, mas sinalizou **7 esperas de fila para revisão**, registradas na [issue #82](https://github.com/Jugadru/APEX-Simulation/issues/82). FIFO justo não significa que a IA eliminou todo double stack; eventuais refinamentos preventivos ficam para uma correção pequena e validada separadamente.

**Documentação técnica:** [Pit Coordination 2.0](docs/APEX_RELEASE_v0.6.6.9.7_PIT_COORDINATION_2.md) · [PR #81](https://github.com/Jugadru/APEX-Simulation/pull/81).

## 📦 Versão anterior — v0.6.6.9.6

### 📥 Baixar o jogo — v0.6.6.9.6 (versão anterior)

### [⬇ Baixar APEX v0.6.6.9.6 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44970898039/artifacts/14733518226)

Pacote para **Windows x86_64** e **Linux x86_64**, exportado no **Godot 4.7.2**. Extraia primeiro o arquivo externo do GitHub Actions, depois o ZIP do sistema operacional escolhido. Mantenha o executável e o arquivo `.pck` juntos. No Linux, pode ser necessário `chmod +x APEX_Motorsport_Manager.x86_64`.

**Download temporário até 06/12/2026**, sujeito à disponibilidade do GitHub e possivelmente a login. O artefato não é uma GitHub Release pública permanente. A exportação e o smoke test Linux foram validados; não foi realizado teste gráfico nativo em um PC Windows do jogador.

### [⬇ Baixar o código-fonte oficial v0.6.6.9.6 — Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/archive/3c0d99a6dca921ee0abea86f7d9d1f522f9e052a.zip)

A candidata aprovada `72d2bcedcafe9c993330738658fce856bc65f861` foi integrada à branch `main` na [PR #80](https://github.com/Jugadru/APEX-Simulation/pull/80), commit `3c0d99a6dca921ee0abea86f7d9d1f522f9e052a`. O arquivo de código-fonte serve para editar o jogo, **não** é um executável.

### 🧠 Novidade — Pit Wall Prediction Ledger 1.0

- **Previsões auditáveis:** registra recomendações emitidas, ordens manuais, decisões da IA e cancelamentos. Uma recomendação não executada nunca vira acerto fictício.
- **Resultado real:** relaciona cada previsão de entrada com o histórico confirmado de pit, posição de retorno e perda líquida de tempo, mostrando erros e motivos comprováveis (fila, incidente, treinamento).
- **Pneus, chuva e cinco voltas:** compara desgaste, ritmo e água observados com as projeções. Quando possível, mede ganho/perda relativa de cinco voltas contra um mesmo rival sem nova parada; não inventa um cenário alternativo não observado.
- **Aprendizado e STAFF:** calibração limitada após pelo menos três paradas verificadas da mesma equipe e nível de estrategista; relatórios de erro absoluto médio por categoria. Não presume precisão perfeita nem identidades individuais indisponíveis.
- **Segurança esportiva:** nenhum comando implícito de pit, nenhuma alteração em RNG, física, ritmo ou replay. Uma parada manual agendada V21 continua protegida; arquivos antigos de saves são preservados.

**Validação:** **[18/18 workflows PASS](https://github.com/Jugadru/APEX-Simulation/commit/72d2bcedcafe9c993330738658fce856bc65f861/checks)** e [Quality Gate READY 10/10](https://github.com/Jugadru/APEX-Simulation/actions/runs/44970898010) no mesmo commit. O teste específico passou **28 verificações**; Race Radio 3.0, 69; SaveGuard, Core 2, benchmarks, replay integral Monza 53 voltas, matriz de 20 circuitos, regressões visuais e exportação para PC também foram aprovados. Os benchmarks headless não demonstram FPS 3D real na máquina do jogador.

**Limite da v1:** histórico e calibração da sessão de corrida não são persistidos automaticamente na carreira. Resultados de decisões emitidas muito antes da parada não são tratados como previsões meteorológicas verificáveis para a data futura.

**Documentação técnica:** [Prediction Ledger 1.0](docs/APEX_RELEASE_v0.6.6.9.6_PITWALL_PREDICTION_LEDGER.md) · [PR #80](https://github.com/Jugadru/APEX-Simulation/pull/80).

## 📦 Versão anterior — v0.6.6.9.5

### 📥 Baixar o jogo — v0.6.6.9.5 (versão anterior)

### [⬇ Baixar APEX v0.6.6.9.5 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44966435731/artifacts/14731945591)

Pacote de desktop exportado no **Godot 4.7.2**, com ZIPs para **Windows x86_64** e **Linux x86_64**. Extraia o arquivo externo do GitHub Actions e depois o ZIP do seu sistema; **mantenha o executável e o arquivo `.pck` juntos**. No Linux, pode ser necessário executar `chmod +x APEX_Motorsport_Manager.x86_64`.

**Download temporário até 06/12/2026**, sujeito à disponibilidade do GitHub Actions e possivelmente a login no GitHub. O pacote não é uma GitHub Release pública permanente. As exportações Linux/Windows e o smoke test Linux passaram na CI; isso não equivale a teste gráfico nativo no Windows nem a medição de FPS na máquina do jogador.

### [⬇ Baixar o código-fonte v0.6.6.9.5 — Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/archive/7ffa370708c2b4e096f58ec52531f217ff1664a1.zip)

Código **integrado à `main` na [PR #79](https://github.com/Jugadru/APEX-Simulation/pull/79)**. O merge commit `7ffa370708c2b4e096f58ec52531f217ff1664a1` tem a **mesma árvore Git** da candidata aprovada `edcb579365ef1c68b7c75267eb48d5daf2aba8dc`; nenhum conteúdo foi modificado durante o merge. O ZIP de código-fonte é para editar o projeto, **não** é um executável.

### 📻 Novidade — Race Radio 3.0 (texto primeiro)

- **Cinco perfis de linguagem por piloto:** comunicação concisa, com diferenças consistentes entre estilos direto, explosivo, técnico, cauteloso e competitivo.
- **Driver Soul 3.0 integrado:** a pressão emocional pode influenciar a maneira de falar, sem conceder velocidade ou aderência artificial.
- **Mensagens ancoradas em acontecimentos reais da simulação:** desgaste, temperatura, tráfego, chuva, pedidos de estratégia e dúvidas sobre parada agendada. Mensagens legadas desconhecidas permanecem sem transformação.
- **Diálogo contextual:** respostas escritas do engenheiro, memória de até oito entradas por piloto e supressão de reclamações triviais repetidas.
- **Sem comandos ocultos:** comunicação e previsões textuais não alteram BOX agendado, ordens manuais, pneus, ritmo, física, RNG, saves ou regras de replay.
- **Preparado para vozes futuras:** pacotes de mensagem incluem `text_key`, `locale`, `voice_profile_id`, `simulation_tick` e `conversation_id`. **A versão 9.5 ainda não possui vozes nem síntese de áudio.** As novas falas do cockpit estão inicialmente em inglês.

**Testes:** [17/17 workflows GitHub Actions PASS na candidata](https://github.com/Jugadru/APEX-Simulation/commit/edcb579365ef1c68b7c75267eb48d5daf2aba8dc/checks). O teste dedicado Race Radio 3.0 aprovou **69 verificações**, incluindo imutabilidade esportiva, cinco perfis, continuidade e proteção do BOX V21. Passaram também Soul 2.0/3.0, SaveGuard, Pit Wall, Core 2, GdUnit4, exportações Windows/Linux, regressão visual, comparação A/B e matriz dos **20 circuitos**. O endurance confirmou **Monza 53 voltas, 24.229 ticks e replay integral determinístico**, com hash esportivo igual; os benchmarks headless **não demonstram FPS 3D real nem 32× sustentado**.

**Documentação técnica:** [Race Radio 3.0 — v9.5](docs/APEX_RELEASE_v0.6.6.9.5_RACE_RADIO.md) · [PR #79 e relatório final](https://github.com/Jugadru/APEX-Simulation/pull/79).

## 🗺️ Situação do desenvolvimento após a 9.9

As versões **9.10 (Strategy Staff), 9.11 (Race Start), 9.12 (Overtaking), 9.13 (Race Engineer), 9.14 (Setup & Track Knowledge) e 9.15 (Performance & Race Polish)** já foram integradas à `main`. Isso não significa que foram publicadas novas GitHub Releases para Windows/Linux. Para baixar o jogo pronto, a última release continua sendo **9.9**.

Próximas mudanças: uma funcionalidade principal, FAST + APEX Test Lab e testes específicos. Homologação extensa apenas quando solicitada. Pendências conhecidas: [32× sustentado — #74](https://github.com/Jugadru/APEX-Simulation/issues/74) e [ressincronização visual — #77](https://github.com/Jugadru/APEX-Simulation/issues/77).

## 📦 Versão anterior — v0.6.6.9.4

### Baixar o jogo — v0.6.6.9.4

#### [⬇ Baixar APEX v0.6.6.9.4 — Windows e Linux](https://github.com/Jugadru/APEX-Simulation/actions/runs/44950950040/artifacts/14725252948)

**Pacote para PC**, compilado no **Godot 4.7.2** a partir do commit candidato testado `63d7953cc21184d6902ebc8cc34b7e696ec927ba` e integrado à `main` na [PR #76](https://github.com/Jugadru/APEX-Simulation/pull/76). O artefato contém ZIPs separados para **Windows x86_64** e **Linux x86_64**. Extraia o pacote externo do GitHub Actions e o ZIP do seu sistema; mantenha o executável e o arquivo `.pck` na mesma pasta.

**Download temporário até 05/12/2026**, possivelmente exigindo login no GitHub. A exportação verificou a identificação `APEX Motorsport Manager v0.6.6.9.4` nos dois pacotes. Houve teste básico de inicialização no Linux. Não foi feito teste gráfico nativo no Windows do usuário; **nenhuma Release pública permanente v9.4 foi publicada**.

#### [⬇ Baixar código-fonte oficial da v0.6.6.9.4 — Godot 4.7.2](https://github.com/Jugadru/APEX-Simulation/archive/17ad31b1402d67b239d148e7fb2f5e9c5013b8d0.zip)

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

**Cópia experimental HUD Manager — 21/11/2026.** Interface de corrida baseada na composição do F1 Manager 2024, com dados e comandos do APEX. Abra este `project.godot` para experimentar. [Comparação das referências](docs/HUD_COMPARATIVO_20261121.md) · [Imagens e validação](docs/HUD_MANAGER_20261121_VALIDACAO.md) · [Changelog](docs/arquivo/changelogs/HUD_MANAGER_20261121_CHANGELOG.md). Os downloads históricos abaixo não incluem esta alteração local.

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

- [Release-base Core 2 v0.6.6.8.6 (ZIP original)](https://github.com/Jugadru/APEX-Simulation/releases/tag/Versions)
- [Relatório técnico v0.6.6.8.7](docs/arquivo/relatorios/APEX_06687_RELATORIO_TECNICO.md)
- [Matriz histórica de testes](docs/arquivo/qualidade/APEX_06687_MATRIZ_TESTES.json)
- [Changelog da versão](docs/arquivo/changelogs/APEX_06687_CHANGELOG.md)
- [Referência histórica: replay v0.6.6.0](docs/REPLAY_0660_USO.md)

As capturas, replays e outros arquivos grandes estão no pacote completo da Release; a árvore Git contém o código-fonte e testes leves.

## Validação automatizada (GitHub Actions)

O único workflow automático em PRs e pushes para `main` é [**APEX Core 2 — Godot 4.7.2 CI**](.github/workflows/godot-setup.yml), no modo **FAST**:

1. Instala o Godot 4.7.2 e importa o projeto real, bloqueando erros de sintaxe.
2. Executa **APEX Test Lab** com 24 carros: seco/chuva, hashes determinísticos, CPU média e p95 por tick, memória e relatório.
3. Verifica replay e double stack no laboratório; demais regressões são selecionadas pelo diff (`tools/apex_ci_tiers.py`).
4. Exige retorno e marcador de sucesso de cada teste selecionado, publicando logs.

A matriz 20/180, endurance, capturas, exportação, benchmarks A/B e Quality Gate histórico são **opcionais, não automáticos**. O Lab mede CPU headless — **não mede FPS da GPU do jogador**.

**Execução local básica no Linux** (substitua `godot` pelo caminho instalado):

```bash
godot --headless --single-threaded-scene --path . --import
godot --headless --single-threaded-scene --path . --script res://tests/apex_lab_track_smoke.gd
godot --headless --single-threaded-scene --path . --script res://tests/apex_lab_performance_probe.gd
```

Guia de uso e critérios: [FAST permanente](docs/APEX_CI_INTELIGENTE_TRES_NIVEIS.md).

## Documentação histórica

Os relatórios e planos das versões anteriores continuam disponíveis na pasta `docs/`. O APEX 2 experimental não deve substituir o Core 2 sem aprovação e regressões específicas.


## Documentação histórica organizada

Os **325 documentos e manifestos históricos** que estavam na raiz foram agrupados em [`docs/arquivo/`](docs/arquivo/README.md), com inventário dos caminhos originais e hashes preservados.

O código, `project.godot`, saves e arquivos de importação permanecem nos caminhos necessários ao jogo. Use o histórico apenas como referência de versões anteriores; a documentação de cada versão pode descrever caminhos antigos.
