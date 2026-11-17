# APEX Motorsport Manager — v0.6.5.0

**Living Factory & Soul Staff — etapa 1 (Soul Staff 1.0)**

## Como iniciar

1. Extraia **todo** o ZIP numa pasta; não execute o jogo diretamente dentro do arquivo compactado.
2. No **Godot 4.7.2**, use **Importar** e selecione `project.godot`.
3. Pressione **F5**. No menu principal, escolha **★ SOUL STAFF 1.0 / GESTÃO DE EQUIPE**.
4. Contrate titulares dos quatro departamentos: Estrategista, Engenheiro, Chefe de Mecânica e Chefe de Aerodinâmica. O mercado e os salários da v0.6.4.9.9 permanecem ativos.
5. Em **NOVA TEMPORADA** ou **CONTINUAR**, antes de cada GP você pode investir em **uma** intervenção: briefing técnico, descanso/suporte ou integração de áreas. Valores são debitados do orçamento de jogo. Não há pagamento de intervenções em GP avulso.
6. Ao fim do GP de campeonato, a moral, a energia, a confiança e os vínculos mudam conforme o melhor resultado da equipe e os temperamentos dos funcionários. O relatório pode ser consultado na tela Soul Staff.
7. Para consultar a 9.9 durante uma corrida, abra **ESTRAT. → SIMULADOR 9.9**. As versões anteriores da HUD, pneus, rádio e pit stops continuam lá.

## O que mudou

- Os 12 candidatos existentes receberam perfis ficcionais próprios de personalidade, estilo de trabalho e reação aos resultados.
- A tela apresenta 3 indicadores por pessoa, relações de trabalho e diálogos contextuais da equipe.
- Há 3 decisões de gerenciamento, com custos e limite por etapa, e acompanhamento entre GPs.
- Os registros são persistidos no mesmo formato da oficina, ampliado para `staff_soul`. Os contratos da v0.6.4.9.9 são migrados sem perda dos campos originais.
- A campanha e a garagem salvas na 9.9 são copiadas **uma única vez**, sem sobrescrever os dados da versão anterior, quando ainda não existir save local da 6.5.0.
- O painel **OFICINA VIVA** lê os níveis e o projeto de P&D existentes, mas **a produção de componentes individuais, novas instalações e uma fábrica 3D ainda não foram implementadas**.

## O que não mudou

Esta é apenas a **primeira parte** da fase Living Factory & Soul Staff. A física, pneus, a IA de pista e estratégia, os cálculos de pit stop, Pit Wall 3.0, Race Engineer 3.0, Soul Driver e Strategy Simulator 1.0 não foram alterados. As novas emoções são um sistema de gerenciamento que não recalcula desempenho dos carros nesta versão. O orçamento passa a considerar as decisões de gestão escolhidas pelo jogador.

**Atenção:** os nomes dos funcionários, perfis psicológicos, custos e relações são atributos **ficcionais de gameplay**. Não representam pessoas reais da Fórmula 1. A temporada é ambientada em 2012; a nova mecânica usa o resultado observado no simulador, não dados históricos de F1.

## Capturas e testes

- `docs/APEX_0650_SOUL_STAFF_1600.png`: captura nativa a 1600×900;
- `docs/APEX_0650_SOUL_STAFF_1920.png`: captura nativa a 1920×1080;
- `docs/APEX_0650_TEMPORADA_ACOES_1600.png`: decisões habilitadas em campeonato;
- `docs/APEX_0650_POS_BRIEFING_1600.png`: decisão real com custo e efeitos aplicados;
- `tests/soul_staff_0650_model_test.gd`: regras econômicas e condições de contorno;
- `tests/soul_staff_0650_migration_test.gd`: importação de saves da 9.9;
- `tests/soul_staff_0650_ui_test.gd`: interface, rotas, interação e screenshots;
- `tests/soul_staff_0650_season_test.gd`: integração com campeonato de GP completo;
- `RELATORIO_TECNICO_0650.md`: integridade da base e resultados verificáveis.

A atualização **não cria** uma v0.6.5.1 nem inicia a próxima fase da fábrica.
