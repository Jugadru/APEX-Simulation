# v0.6.6.9.17.11 — Slipstream & Dirty Air 1.0 (candidata)

Base: `6293a5b1d26a0aea6da747c343686268cb4d7391` / PR #125. Revisão esportiva 032. Plano Mestre Unificado 2.0: resistência, carga aerodinâmica e ar sujo/vácuo, respeitando o nível de abstração.

- Novo módulo puro `race_aero_wake_091711.gd`. Estima distância longitudinal usando progresso circular e lap_km; distância lateral continua em unidades esquemáticas. Janela máxima 150 m estimados, transições suaves por distância, alinhamento e carga de curva atual/prevista. Exposição mais larga para ar sujo; fonte de maior exposição, sem somar ganhos de um pelotão; ID estável em empate. Exclui carros finalizados, em box e atrás, inclusive passagem pela linha e retardatários. O modelo não interpreta a intenção do adversário.
- Substitui apenas o modificador longitudinal 031 após 24 s, inclusive em ataques, sem alterar decisão tática, objetivo lateral, ocupação, pneus, DRS, KERS, pit ou apresentação. Preserva penalidade genérica de tráfego existente, que também representa efeitos não aerodinâmicos; não reaplica o modificador aero 031. Limites teóricos sobre tempo equivalente local: vácuo -1,4%, ar sujo +2%, cautela molhada +0,5%. Não são perdas medidas de downforce ou arrasto nem ganhos de volta inteira; sem CFD, calibração 2012 ou modelo térmico novo. Curvas reduzem vácuo, água reduz a vantagem e aumenta cautela. Coeficientes sujeitos à homologação e balanceamento.
- Diagnóstico por carro `aero_wake_032` no snapshot esportivo (fonte, distância estimada, exposição, modificadores), não muda schema de save; flag excluída dos checkpoints. Preserva revisões 031 e anteriores. Não altera direção para buscar vácuo nem força ultrapassagem. As regras antigas de espaçamento permanecem autoritativas.
- Referências conceituais: https://www.racecar-engineering.com/tech-explained/slipstream-and-dirty-air-explained/ e https://www.mclaren.com/racing/latest-news/mclarenracing/article/rookies-guide-f1/. Sem código externo.
- QA: fixture física e integração com solver, A/B de Monza, Silverstone, Mônaco e Monza molhado, contagem de exposição, inversões, sobreposição, paradas e ultrapassagens; hash 031 independente, replay 031/032 e seek; FAST + Test Lab, pit agendado. CI dedicada 1800 ticks por cenário. Não equivale a GP completo ou prova de naturalidade visual universal. Resultados no PR do SHA exato.

Rollback: main base acima. Não publicar retratos privados ou release, nem fazer merge sem homologação.


## REV2 — revisão esportiva 033 (candidata)

A revisão 032 selecionava a maior exposição de ar sujo mesmo em reta. A 033 escolhe a maior magnitude efetiva entre vácuo e ar sujo + cautela, com desempate estável por ID e fonte única. Coeficientes e direção permanecem inalterados. Replays 031 e 032 mantêm seus caminhos históricos; flag de revisão excluída do codec. O campo de diagnóstico aero_wake_032 mantém o nome para compatibilidade.

QA acrescentado: fixture de três carros, ordem estável, empate, chuva, frenagem e retardatários; tolerância agregada de 10% (piso 2) e por piloto (piso 3), 30 comparativos de seis minutos, GPs completos direcionados e câmera P15 030/031/032/033 com renderer Compatibility em ambiente virtual. Tempo de motor e memória estática amostrada registrados; não representam GPU física ou benchmark de velocidade de apresentação. Resultados dependem dos jobs no SHA exato; nenhum PASS antecipado. Rollback: commit a6a272a4 ou main 6293a5b1. Não publicar retratos privados.
