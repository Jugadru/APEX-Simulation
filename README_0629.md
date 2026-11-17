# Apex Motorsport Manager — v0.6.2.9 (Circuitos 3D / Etapa II)

Projeto completo para **Godot 4.7.2**, baseado na v0.6.2.8.1.

## Novidades

- Camada independente `scripts/apex_circuit_detail_0629.gd` com arquibancadas em degraus, coberturas e torcida estilizada; barreiras Armco e trechos de áreas de escape; elementos próprios para deserto, trópicos, cidades e regiões temperadas.
- Linhas brancas nas bordas internas das zebras. O traçado e a largura da via não foram modificados.
- Bahrain/Abu Dhabi/Índia recebem pequenas estruturas com cobertura azul-esverdeada, Sepang/Interlagos palmeiras, Monaco/Valencia/Singapura blocos de prédios, outros circuitos estruturas de apoio.
- Todos os objetos novos são **visuais, sem colisões ou impacto na corrida**. Os layouts são estilizados, e NÃO reconstituições exatas de cada autódromo.

## Execução

1. Extraia numa **pasta nova**.
2. Abra `project.godot` no Godot 4.7.2.
3. Pressione F5. Teste Bahrain, Sepang e Monaco em câmera Livre e Diretor TV.
4. Opcionalmente, rode `bash linux/validar_0629.sh` para executar testes nativos.

## Preservação

Sem mudanças na HUD, motor de corrida, regras de pneus, estratégia, câmera Livre e Diretor TV. A lógica de pit stops permanece a da v0.6.2.5.

## Limites

Cenários ainda são low-poly e simplificados. Testes gráficos feitos com renderização OpenGL por software, que pode diferir da GPU do usuário. Testes completos de temporada/corrida da China não foram repetidos nesta atualização.
