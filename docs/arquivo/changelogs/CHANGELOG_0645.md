# v0.6.4.5 — Race Intelligence & Driver Soul

Base: ZIP completo v0.6.4.4 fornecido pelo usuário, com HUD UI02.

- **IA Estratégica 2.0:** camada determinística sobre o otimizador existente. Projeta posição e distância ao tráfego na saída usando progresso real, tempo-base de volta e custo de pit. Diferencia manter plano, undercut dentro da janela e extensão de uma volta para evitar tráfego. Extensão exige pista seca estável, desgaste abaixo de 65%, mais de duas voltas de vida estimada e margem até o final. Não permite adiamentos consecutivos, não contorna histerese da chuva nem substitui ordens confirmadas. Alternativas e confiança ficam disponíveis ao engenheiro.
- **Apex Soul Driver:** pressão, autoconfiança, foco, motivo e oito registros de memória por piloto. Atualização por volta no motor, mesmo sem HUD. Disputa, posição, água e desgaste alimentam o estado. O rádio existente recebe um ajuste limitado de percepção, sem acumulação por quadro. Perfil é ficcional; não descreve psicologia de pessoas reais. Não altera física, desempenho, desgaste nem RNG.
- **Race Engineer 2.0:** une os dados anteriores à avaliação de tráfego, alternativas de manter/parar, confiança e estado do piloto. Bloqueia aceitação de box em carro finalizado, ordem agendada ou pit em execução. Modos Manual, Assistido e Automático preservados.
- **HUD UI03 incremental:** painel do engenheiro com tática, Soul, alternativas e projeção de retorno; rádio com estado emocional; menu e título de janela atualizados. Layout-base, controles, câmeras e painéis térmicos mantidos.

## Preservação

Física de pista/pneus, clima, histerese, oficina, campeonato, evolução das rivais, regras de pneus, cronometragem e comandos conservam sua implementação. `race_engine.gd` recebe apenas integração dos novos módulos e invalidação temporal do cache consultivo; o trecho de cronometragem não foi reescrito. O manifesto da versão registra os hashes dos arquivos preservados.

## Limites

Projeção de retorno é uma estimativa instantânea: não prevê futuras paradas alheias ou incidentes. Confiança é qualitativa, não probabilidade calibrada. Soul vale para o GP atual, sem persistência de carreira e sem bônus de desempenho. Não houve nova produção de modelos 3D; Blender não é necessário nesta atualização. A bateria principal de oito GPs foi atualizada para `step(0.20)`, sem chamadas diretas ao integrador. São corridas completas headless pelo motor de produção, não sessões gráficas renderizadas. A execução de 8s foi preservada apenas como histórico.


## Revalidação integral no passo nativo — 09/11/2026

O teste `race_0645_eight_gp_test.gd` agora usa exclusivamente `sim.step(0.20)`. Verifica o incremento do relógio a cada tick; amostra física e pneus a cada 20 segundos simulados; salva classificação, voltas e histórico de boxes por GP. Seeds, circuitos, clima, upgrades e controle automático são os mesmos da bateria anterior. `race_0645_eight_gp_coarse_test.gd` preserva o ensaio histórico de 8s, sem fazer parte da revalidação principal.

O executor Linux mantém saves isolados e amplia o limite de duração para comportar a bateria nativa em máquinas mais lentas. Nenhum arquivo de implementação do jogo foi alterado nesta revalidação.


## Validação de carreira consecutiva — 09/11/2026

- Oito etapas sequenciais completas em Godot 4.7.2 por `step(0.20)`, com saves isolados compartilhados entre oito processos: PASS.
- Teste da cena real, pontuação e prêmios idempotentes, compras, treinamento, contratação, quatro entregas de P&D, cancelamento e evolução paga das 11 rivais.
- Novo `tests/career_0645_native_worker.gd` e `linux/validar_carreira_0645.sh`; integração ao executor completo.
- Comparação de saves normaliza a representação numérica JSON para evitar falso erro entre inteiros e floats. A tentativa inicial foi arquivada e a carreira inteira reexecutada.
- Relatório detalhado `RELATORIO_CARREIRA_0645.md`, CSV e snapshots por etapa. Código de produção preservado.
