# APEX MOTORSPORT MANAGER v0.6.6.1 — DRIVER DYNAMICS

Pacote completo para Godot 4.7.2 / Linux Mint. Atualização incremental da v0.6.6.0.

## Abrir
Extraia este ZIP, abra `project.godot` no Godot 4.7.2, aguarde importação
e execute a cena principal. Não é necessário instalar binários extras,
e não há dependência do diretório onde o ZIP foi criado.

## Alteração principal
IA de ultrapassagem/defesa com decisões baseadas em ritmo, espaço físico
esquemático, pneus, confiança, estilo de piloto e chuva. Sem acelerar
artificialmente carros para forçar posição ou alterar ranking pela animação.

## Replay
Gravações criadas neste build têm `simulation_revision=0661_driver_dynamics`.
A física evoluiu e os arquivos de replay da v0.6.6.0 devem ser assistidos
na v0.6.6.0 original; a v0.6.6.1 os recusará com explicação.
A simulação da v0.6.6.1 continua determinística dentro do mesmo runtime.

## Evidências
Leia `RELATORIO_TECNICO_APEX_v0.6.6.1.md` e a pasta
`qa/driver_dynamics_0661/`. A validação inclui quatro GPs de 3 voltas,
corrida curta de 24 carros e capturas reais em duas resoluções.
**Não houve reexecução de uma corrida oficial integral de 52 voltas.**
