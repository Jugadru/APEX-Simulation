# Pesquisa técnica 0660
Fontes primárias consultadas em 14/11/2026:
- https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html — seed inicia a sequência, state restaura o ponto exato; algoritmo/runtime precisa ser compatível.
- https://docs.godotengine.org/en/latest/tutorials/io/binary_serialization_api.html — Variant preserva tipos numéricos; arquivos são lidos sem objetos.
- https://github.com/godotengine/godot/blob/master/doc/classes/FileAccess.xml — store_var/get_var e allow_objects=false.
- https://github.com/godotengine/godot/blob/master/doc/classes/RandomNumberGenerator.xml — contrato seed/state.
Godot e documentação: MIT/CC-BY conforme repositório. Consulta conceitual; nenhum código externo ou asset incorporado. Seed sozinha não remove dependência do dt; a sessão define ticks e ordem de decisões.
