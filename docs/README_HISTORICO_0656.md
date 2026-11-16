# Versão atual: 0.6.5.5 — Simulation Racecraft

Leia [README_v0.6.5.5.md](README_v0.6.5.5.md).

# Versão atual: 0.6.5.4 — Racecraft

Leia [README_v0.6.5.4.md](README_v0.6.5.4.md) para iniciar e consultar as mudanças e limitações.

# Versão atual: 0.6.5.3 — Realistic Racing

Leia [README_v0.6.5.3.md](README_v0.6.5.3.md) para iniciar e consultar as mudanças e a alternativa Compatibility.

---

# APEX Motorsport Manager v0.6.5.2 — 3D Racing

Abra `project.godot` no Godot **4.7.2** e pressione F5.

Esta versão parte da v0.6.5.1 Living Factory e melhora a apresentação 3D:
- movimentos laterais ligados aos estados reais de preparação, ataque e duelo;
- retorno suave à trajetória, mantendo corredores enquanto os carros ainda estão próximos;
- rodas com raios, esterçamento, movimento da carroceria e asa móvel ligada ao DRS;
- sombras direcionais, antialiasing MSAA 4×, materiais revisados, asfalto e terreno procedurais;
- câmera 3D de transmissão selecionada ao iniciar a corrida.

O modo aéreo e o mapa continuam disponíveis no seletor de visualização. Para observar uma disputa de perto, selecione um piloto e a câmera de batalha. Pausar também congela as animações.

## Arquivos de entrega

- `RELATORIO_0652_3D.md`: implementação, testes e limites.
- `qa/3d_racing/ultrapassagem_demo.mp4`: demonstração visual controlada, renderizada pelo Godot; não é replay de uma corrida real.
- `qa/3d_racing/race_1600x900.png` e `race_1920x1080.png`: capturas de um ataque calculado pela simulação, com HUD.
- `BUILD_MANIFEST_0652.json`: hashes dos arquivos desta entrega.

Recursos visuais próprios. Não foram extraídos modelos, texturas ou código dos jogos de referência. Documentação e evidências numeradas com versões anteriores são históricas.

A oficina e a compatibilidade dos saves da v0.6.5.1 permanecem. O ZIP contém o projeto-fonte completo; não inclui o executável Godot, caches ou os 240 PNGs intermediários do vídeo.

Linux: `GODOT_BIN=/caminho/para/Godot sh linux/run_apex.sh`.
