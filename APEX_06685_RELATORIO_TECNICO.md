# APEX Motorsport Manager v0.6.6.8.5 — Core 2 / 3D Performance 2.0

## Escopo
Atualização incremental da APRESENTAÇÃO 3D. Core 2, física, Racecraft esportivo, Pit Wall, HUD ReBroadcast, replays e salvamentos mantidos como na 0.6.6.8.4. Next Engine permanece SUSPENSA.

## Alterações reais
1. `scripts/track_3d.gd` armazena as referências a QueueTag, FocusDisc, PlayerRing e NumberTag por ID enquanto o modelo existe. Remove o cache ao excluir o carro e ao reiniciar o circuito.
2. `scripts/car_model_3d.gd` troca a visibilidade dos quatro conjuntos de rodas somente quando a fase de serviço provoca mudança no estado visível, conservando o comportamento original de pit stop.
3. `scripts/pit_complex_3d.gd` deixa de iterar os mecânicos invisíveis a cada quadro quando não há nenhum serviço ativo. A primeira atualização após um serviço ainda oculta os mecânicos corretamente.
4. `scripts/main.gd` e `project.godot`: somente identificação de versão. O diretório de saves continua o mesmo.

## Desempenho observado (fixture, não FPS)
Godot 4.7.2 headless, 24 carros e 12 garagens, 120 atualizações por processo, cinco pares de processos.
Baseline médias por atualização (µs): [10757.367, 2851.375, 3471.358, 2898.867, 3517.725].
Nova versão médias (µs): [2768.383, 2911.067, 2797.525, 2771.758, 3188.492].
Medianas: 3471.358 µs versus 2797.525 µs (**19.41%** de redução no ensaio). Uma medição da base foi anormalmente lenta. São números de CPU de apresentação; **não comprovam FPS, consumo de GPU ou melhor desempenho em toda corrida**.

## Testes executados
- PASS: 26 verificações visuais dos 24 carros, cache, seleção e pit service.
- PASS: quatro pistas (GBR seco, BEL chuva intensa, ITA seco, SIN chuva intensa), 80 ticks cada com hashes idênticos à v0.6.6.8.4 nos ticks 1, 20, 40 e 80.
- PASS: fila V21, double stack, câmera automática/manual 18 combinações, Racecraft 1027, Driver Dynamics 17, replay 200 ticks e isolamento de replay 400 ticks.
- PASS: importação Godot headless com `--single-threaded-scene`.
- INCONCLUSIVE: uma captura gráfica real 1600×900 foi produzida, mas o processo virtual não encerrou dentro do limite; não é homologação gráfica completa.
- FAIL **preexistente**: `tests/car_model_smoke_test.gd` procura a antiga peça `ChassisVisual/TaperedChassis`, inexistente tanto na v0.6.6.8.4 quanto nesta. Esse teste antigo não foi corrigido porque o escopo não é remodelar os carros.
- NOT_RUN: GP inteiro 53 voltas nesta release, FPS no PC real, captura em 1366×768.
- BLOCKED: suíte anterior de 750 ticks nas quatro pistas excedeu o tempo do ambiente; substituímos por A/B de 80 ticks, sem fingir equivalência de cobertura.

## Instruções
1. Preserve a v0.6.6.8.4 e faça backup dos saves.
2. Extraia o ZIP em uma **pasta nova** e abra `project.godot` no Godot 4.7.2 (Linux).
3. Inicie uma corrida no 3D e compare o FPS na mesma cena, resolução e câmera da versão anterior.
4. Para rollback, feche o Godot e volte a abrir a pasta da v0.6.6.8.4, sem sobrescrever os salvamentos.

## Como repetir testes
```bash
Godot_v4.7.2-stable_linux.x86_64 --headless --single-threaded-scene --editor --path . --import --quit
Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://qa/core2_06685/visual_regression.gd
Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://qa/core2_06685/short_four_circuits.gd
```
**Atenção:** o teste de quatro circuitos no pacote executa a versão nova. A comparação com a versão anterior consta em `sporting_ab_4_circuits.json`.
