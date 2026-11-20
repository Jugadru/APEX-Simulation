# Como abrir o Apex Motorsport Manager v0.6.3.8.1

1. **Mantenha uma cópia da versão 0.6.3.8** como backup, caso precise comparar.
2. Extraia o ZIP `APEX_0638_1_GODOT.zip` inteiro em uma pasta nova.
3. Abra o **Godot Engine 4.7.2** no Linux Mint, escolha **Importar**, abra a pasta `APEX_GODOT_0.6.3.8.1_HOTFIX_LAPS` e selecione **`project.godot`**.
4. Pressione **F5** para executar o jogo.
5. Teste uma corrida avulsa em Interlagos; acompanhe as melhores voltas e, se desejar, o histórico de eventos em 1×, 2× ou simulação acelerada.

Este projeto usa o mesmo nome de diretório de salvamento do Apex anterior (`ApexMotorsportManager`), para preservar a estrutura. Faça backup de seus saves antes de testar uma versão experimental.

## Alternativa — patch

O arquivo `APEX_0638_1_PATCH.zip` contém os arquivos com alterações ou testes novos. Extraia o patch **na raiz da cópia da v0.6.3.8**, mantendo as mesmas subpastas. Isso não substitui o ZIP completo se os arquivos-base tiverem outra versão.

## O que esse hotfix corrige

Evita que um erro de pilotagem em cima da linha de chegada registre uma segunda passagem como se fosse outra volta. A perda de tempo do piloto continua, mas não há recuo artificial da distância percorrida.
