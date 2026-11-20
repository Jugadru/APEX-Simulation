# APEX Motorsport Manager v0.6.5.3 — Realistic Racing

Abra `project.godot` no Godot 4.7.2 e pressione F5. No Linux, `linux/run_apex.sh` encontra o Godot no PATH; também aceita `GODOT_BIN=/caminho/para/Godot`.

Esta versão usa Forward+ / Vulkan, com sombras, iluminação de céu, SSAO e suavização temporal na cena 3D. Alternativa para GPUs sem Vulkan: `linux/run_apex_compatibility.sh`, ou selecione Compatibility no editor. Nessa alternativa, SSAO e suavização temporal não estão disponíveis; as malhas, materiais, HUD e animações continuam presentes.

## Melhorias

- Carroceria com superfícies curvas, nariz afilado, sidepods arredondados e cobertura do motor esculpida.
- Cockpit aberto, aro de proteção, banco recuado, visor arredondado e estrutura de proteção do piloto.
- Pneus com ombros arredondados, interior vazado, rodas com raios e faixas de composto mais discretas.
- Aerofólios com perfis suaves e múltiplos elementos; movimento de DRS preservado.
- Materiais com metalicidade, rugosidade e verniz diferenciados.
- Asfalto mais escuro com granulação e marcas de borracha; zebras com padrão métrico contínuo e pintura desgastada.
- Barreiras metálicas corrugadas, postes e telas de proteção; árvores com copas assimétricas e variação de superfície do terreno.

A HUD atual, o motor de corrida, as regras de ultrapassagem, os boxes e o inventário foram preservados. Os recursos são procedurais e originais, inspirados na apresentação de jogos de gestão de automobilismo. A apresentação ainda é estilizada; não equivale ao nível de produção fotorrealista de F1 Manager.

## Evidências

`qa/realistic_racing` contém os resultados desta versão, capturas da HUD em corrida real e uma demonstração controlada da animação. O vídeo é uma sequência visual de cópias de carros, não um replay real nem uma medição de FPS. Pastas de QA e relatórios de versões anteriores são históricos.

O projeto completo e o manifesto de integridade acompanham o ZIP. Não inclui o executável do Godot nem um binário exportado do jogo.
