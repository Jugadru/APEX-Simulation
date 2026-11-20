# APEX v0.6.5.2 — gráficos e animações de corrida

Entrega preparada em 11/11/2026. Base: projeto completo v0.6.5.1 Living Factory. A base anterior foi preservada em sua própria pasta.

## Implementação

### Disputas

`apex_battle_motion_0652.gd` observa `combat_state`, `combat_target_id`, progresso, direção e posição projetada na pista. Preparação desloca os carros parcialmente; ataque e duelo reservam corredores laterais opostos. O retorno usa interpolação exponencial independente da taxa de quadros. Se dois carros ainda estão próximos longitudinalmente, mantém os corredores antes de retornar, reduzindo o cruzamento visual dos modelos.

Alvos distantes, em outra volta, em trechos de direção oposta, finalizados ou nos boxes são excluídos. Cada carro participa de um par por atualização. Os deslocamentos ficam limitados a ±1,55 unidades da cena. O progresso longitudinal, os tempos e o resultado da ultrapassagem vêm integralmente do motor existente.

`track_3d.gd` aplica o deslocamento aos modelos, acrescenta uma pequena orientação durante a mudança lateral e preserva o trajeto dos boxes. `main.gd` envia delta zero ao renderizador quando a corrida está pausada.

### Carros

`car_model_3d.gd` recebeu sidepods afilados, assoalho e aletas de difusor, rodas mais redondas com raios e faixas de composto em anel. Materiais têm rugosidade, metalicidade e verniz revisados. A carroceria apresenta rolagem, oscilação vertical discreta e inclinação conforme a variação de movimento visual. A asa traseira abre e fecha com `drs_active`; não libera DRS por conta própria.

### Cena

Sombras direcionais com cascatas, céu procedural, luz ambiente ajustada e MSAA 4× no SubViewport. Asfalto e terreno possuem shaders próprios com variações de superfície; o terreno substitui os antigos remendos quadrados. Todos os recursos novos são procedurais e originais. Nenhum asset, textura, marca gráfica ou código dos jogos de referência foi copiado.

A câmera de transmissão 3D passa a ser a opção inicial. Mapa, vista aérea, câmera livre e demais controles continuam disponíveis.

## Arquivos de produção

Criados:
- `scripts/apex_battle_motion_0652.gd`
- `assets/shaders/asphalt_0652.gdshader`
- `assets/shaders/terrain_0652.gdshader`

Modificados:
- `scripts/track_3d.gd`
- `scripts/car_model_3d.gd`
- `scripts/main.gd`
- `scripts/apex_race_ui_legacy_builder.gd`
- `scripts/apex_race_session_controller.gd`
- `scripts/apex_front_menu.gd`
- `project.godot` e documentação principal.

O arquivo `qa/3d_racing/source_audit.json` registra a comparação com a v0.6.5.1. `race_engine.gd`, todos os módulos de `scripts/core` e `garage.gd` permanecem idênticos. Nenhuma alteração de física, IA estratégica, pit stops, economia, staff ou inventário.

## Validação executada

Ambiente: Godot 4.7.2, renderer Compatibility / OpenGL, NVIDIA GTX 1650.

- `battle_motion_0652_test.gd`: separação de pares, recuperação, proteção de proximidade, pausa, equivalência a 30/60 FPS, exclusão de pit/volta/trecho oposto/alvo distante e imutabilidade da entrada. Inclui abertura/fechamento de DRS, rotação das rodas e congelamento da carroceria/rodas/asa em pausa.
- `graphics_0652_native_test.gd`: 720 segundos de simulação em Silverstone, semente 6520, dois motores iguais. Compara todos os carros e eventos a cada passo de 4 segundos. O observador gráfico não gerou divergências; 1947 amostras laterais não nulas foram obtidas de dados reais.
- Regressões de inventário, UI da oficina, HUD Unificada e regras de coordenação de boxes: código 0 em todos os cinco grupos registrados em `regressions.json`.
- `graphics_0652_hud_capture.gd`: encontrou ataque real do carro ID 12 aos 12 segundos; capturou HUD e cena 3D em 1600×900 e 1920×1080, com dimensões verificadas.
- `graphics_0652_capture.gd`: 240 quadros nativos da cena para vídeo de 8 segundos a 30 FPS. Este é um cenário visual controlado com cópias dos carros; testa a apresentação sem alterar a corrida original. O vídeo está identificado como demonstração e não como replay real.
- Inspeção visual das capturas: sombras, carroceria, faixas das rodas, terreno, deslocamento lateral e legibilidade da HUD.

Logs atuais em `qa/3d_racing`. As evidências de versões anteriores não representam novas execuções nesta versão. Não foram repetidos GPs completos ou testes de todas as pistas nesta atualização gráfica.

## Correções na validação

Uma constante de ambiente incompatível foi removida após erro de importação. FXAA não é suportado no renderer Compatibility e foi retirado; MSAA 4× permanece. A contribuição do céu e os materiais do terreno foram ajustados após inspeção das primeiras capturas. O título do vídeo foi colocado acima da camada da HUD. A recuperação da disputa passou a aguardar espaço antes de unir as trajetórias visuais.

## Limites

A apresentação continua procedural e estilizada, não fotorrealista. O motor ainda usa progresso longitudinal; esta atualização não implementa física de contato, trajetória física independente ou garantias de ausência de sobreposição para todo um pelotão. O lado de ataque é escolhido deterministicamente pela apresentação; não representa uma nova decisão estratégica de linha interna/externa. Os corredores representam a disputa calculada pelo motor e não determinam seu vencedor.

A oscilação da carroceria é um efeito visual limitado, não telemetria nova de suspensão. Não foram adicionados danos visuais, spray de chuva, multidões animadas ou modelos externos. Sombras e MSAA aumentam o custo de GPU; não foi medido um benchmark representativo nem garantida uma taxa de FPS específica. A pausa congela as animações; velocidades aceleradas podem pular detalhes intermediários das disputas.

Saves pessoais não foram usados nos testes: todas as execuções usaram `XDG_DATA_HOME` temporário. O formato de salvamento permanece o da v0.6.5.1.
