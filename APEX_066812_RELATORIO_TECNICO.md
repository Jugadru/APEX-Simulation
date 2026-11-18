# Relatório técnico — APEX v0.6.6.8.12 — Guia da Temporada 2012

Base: v0.6.6.8.11, commit b75b96bcc3091f1c547bd6cfeac6a36a0481de46. Godot 4.7.2.

## Arquitetura
O único sistema novo é um guia de referência histórica 2012. O script scripts/apex_season_guide_066812.gd constrói snapshots somente para apresentação, consumindo as estruturas existentes de data/season_2012.json e data/tyres_2012.json. Apenas data/season_reference_2012.json é novo e contém 12 nomes de chassis com motores e as 20 datas de corrida. Não contém desempenho, características aerodinâmicas, telemetria, qualquer parâmetro esportivo ou imagens externas.

O guia exibe cores reais dos pneus Pirelli 2012, equipes e seus chassis e calendário FIA; oferece seleções reais de equipe/GP ligadas aos callbacks antigos do menu, desativadas durante campeonato. A HUD ReBroadcast recebeu apenas novos valores de cor correspondentes aos nomes e códigos de data/tyres_2012.json; a classificação esportiva e regras de pneus não foram alteradas.

## Testes
O workflow da branch foi ampliado de 19 para 20 scripts Godot. O novo teste cobre catálogo 6×12×20, correspondência dos seis códigos e cores com o catálogo, modelos exclusivos, datas únicas e FIA, dois slicks por etapa, janela do menu e as três abas, seleção de equipe/Monza e invariância do snapshot esportivo/replay após consulta. Os testes originais de HUD ReBroadcast e Core 2 permanecem na bateria.

CI real (run 44405628481, commit de código e testes e137e2f995ca787a3f6aa07aafd1d41eca455f86): importação Godot 4.7.2 PASS, 20/20 scripts Godot PASS, novo teste SEASON_GUIDE_066812_PASS checks=152 teams=12 rounds=20 tyres=6 no_sporting_mutation=true. Regressão ReBroadcast PASS 34 verificações, V21 PASS 30, Driver Identity PASS 259, UI de identidade PASS 46, replay PASS 200 ticks. Teste de rede do pack de pilotos anterior: 24/24 downloads com metadados autor/licença. ZIP gerado e CRC verificado: 2.310 arquivos de código-fonte; no run 44405628481, 14.143.134 bytes e SHA-256 7dcc3d0ac14bb6a98209eed82c4a4c6733bfa24b28ab2f2e7cc991d03a530715. Este hash pertence EXCLUSIVAMENTE ao ZIP daquele run (antes da atualização dos documentos de auditoria); conferir SHA256.txt do artefato escolhido. CI não equivale a inspeção visual das fotos em GPU real.

## Limitações de homologação
Não há novas malhas 3D nem texturas de chassis. A apresentação no PC Linux Mint/GPU permanece NOT_RUN até execução local. A revisão visual dos recortes das fotografias da v0.6.6.8.11 continua pendente. Ensaios de GP integral nas quatro pistas prioritárias, memória e FPS reais não são substituídos por smoke tests. Não classificar como estável antes dessas verificações.

## Fontes
- https://press.pirelli.com/pirelli-announces-compound-choice-for-the-first-three-races/
- https://www.f1technical.net/f1db/cars/years/2012
- https://www.fia.com/events/fia-formula-one-world-championship/season-2012/calendar

## Rollback
Preservar o pacote 8.11 e cópia de saves. Abrir os projetos em diretórios separados; o diretório de perfil APEX_0650_SOUL_STAFF e os schemas de save/replay não foram alterados.
