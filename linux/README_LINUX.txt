APEX Motorsport Manager — Core 2
Engine recomendada: Godot 4.7.2. A versão do jogo está em project.godot.

Código-fonte: abra o Godot 4.7.2, importe project.godot, aguarde a importação e pressione F5.
Alternativa no terminal, dentro da pasta do projeto:
  ./linux/run_apex.sh

Se Godot não estiver no PATH, indique o binário instalado:
  GODOT_BIN="/caminho/para/Godot" ./linux/run_apex.sh

O launcher procura Godot 4 localmente; use 4.7.2 para reproduzir a configuração validada.
Em dispositivos sem Vulkan, tente ./linux/run_apex_compatibility.sh.
O script não baixa a engine. Faça backup dos saves antes de trocar de versão.
Para pacotes executáveis e seus números de versão, consulte README.md e GitHub Releases.
