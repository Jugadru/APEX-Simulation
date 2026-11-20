# APEX 0.6.1 — Importar no Godot

1. Extraia todo o ZIP em pasta nova. **Não substitua sua v0.6.0 ainda.**
2. Godot 4 → Importar → selecione `project.godot` → F5.
3. Em **GP avulso**, escolha Bahrain e marque **Automático**: a chuva não é forçada. Depois teste Sepang, Spa e Singapura.
4. Em **Continuar temporada**, verifique se o GP da etapa corresponde ao calendário; as pontuações anteriores devem permanecer.
5. Inicie a corrida, abra **32×**, e verifique que o visual Auto mostra o mapa 2D. Em 1×/2×, veja a câmera 3D.
6. Na parte superior, alterne **PILOTO**, **MAPA 2D** e **VISÃO → Aérea estratégica**.
7. Clique num piloto da classificação e observe painel contextual. Para rodar verificações: `bash linux/validar_0610.sh` (com comando godot ou godot4 instalado no PATH).

## Diagnóstico
O arquivo `scripts/core/race_weather.gd` contém os riscos-base da versão; não são dados oficiais dos jogos F1 2020 ou F1 Manager.
Se houver erro vermelho, envie a mensagem exata e o arquivo/linha. Guarde backup do diretório de dados do usuário caso queira preservar salvamentos da temporada.
