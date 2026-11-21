# APEX v0.6.6.9.3 — Driver Traffic Intelligence (candidata)

Base: `main` em `8e0490be3d4d20459354971c766c1179acd2d7bc`, release v0.6.6.9.2.

## Escopo entregue no código

- `race_driver_traffic_06693.gd`: leitura pura do encontro com retardatário, faixa disponível, clima e proximidade; determina se a cessão antecipada é segura.
- `race_space_0655.gd`: integra a indicação à máquina de corredores existente. O retardatário deixa de propor bloqueio e, quando seguro, sinaliza deslocamento lateral moderado. Não teleporta carros, não altera velocidade-base e não sorteia resultados.
- `driver_traffic_06693_test.gd`: verificações de reconhecimento, inversão de bandeira, chuva, estreitamento, pits, determinismo e ausência de mutação da entrada.
- Revisão esportiva do replay: `016_driver_traffic_v1` para impedir falsa equivalência com a revisão 015.
- `project.godot`: identificação v0.6.6.9.3.

## Limitações

Este incremento NÃO implementa stewarding completo de bandeiras azuis, punições, comunicação por rádio, nem retifica o gargalo de CPU em 32x. Essas questões exigem escopos próprios.

## Critérios de aprovação

| Verificação | Estado inicial |
|---|---|
| Godot 4.7.2 import e parser | NOT_RUN |
| Driver Traffic teste dedicado | NOT_RUN |
| Driver Dynamics regressão | NOT_RUN |
| Core 2, save e replay | NOT_RUN |
| Monza 53 voltas, hash e desempenho | NOT_RUN |
| Silverstone, Spa, Singapura, chuva | NOT_RUN |
| Windows/Linux export e versão interna | NOT_RUN |

Não integrar sem testes relevantes concluídos. Os 15/15 PASS e o benchmark 206,80 s pertencem à **versão-base 9.2**, não à candidata 9.3.

## Rollback

A branch é independente. Até o merge, a `main` v0.6.6.9.2 permanece inalterada.
