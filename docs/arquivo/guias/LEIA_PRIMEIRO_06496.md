# APEX v0.6.4.9.6 — Estratégia viva a cada volta

## Abrir no Linux Mint
1. Extraia todo o ZIP para uma nova pasta, sem misturar arquivos com versões antigas.
2. Abra `project.godot` no **Godot 4.7.2**, aguarde a importação e pressione **F5**.
3. Na preparação, mantenha disponível o **PLANEJADOR DE STINTS** da 0.6.4.9.5.
4. Durante a corrida, abra **ENG.** ou **ESTRAT. → Pit Wall 3.0** para ler **REVISÃO V... / REAVALIAÇÃO V...**.
5. Em Manual, os comentários não substituem ordens; em Automático, mudanças limitadas à janela segura podem alterar uma chamada. Pit agendado V21 não é antecipado.

## O que mudou
Depois de cada passagem na linha de chegada, o Race Engine examina dados já observados do piloto e dos outros 23 carros, analisa ritmo, desgaste, previsão de clima e viabilidade do pit. Uma estratégia poderá ser mantida, antecipada por uma volta (undercut), estendida por uma volta (oportunidade de ultrapassagem) ou protegida conforme as condições.

**Não promete antecipar/estender em toda corrida.** Exigimos condições de segurança. A revisão é registrada até 16 voltas por piloto e consultável sem consumos extras do RNG e sem efeitos de UI.

## Segurança de saves
A versão usa a pasta de usuário `ApexMotorsportManager_PitWall_06496`, separada da 06495; não copie saves sem backup.

## Testes
`GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_06496.sh`
O script executa testes curtos. Para o teste completo de Silverstone: 
`GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_silverstone_06496.sh`

Leia `RELATORIO_TESTES_06496.md` para os resultados verificados e as limitações da entrega.
