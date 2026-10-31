# Renderização Web

Compatibility/WebGL 2 continua separado de Mobile nativo. Preservados lua de sangue, floresta em MultiMesh, neblina leve, LOD, sombras por qualidade e controles de resolução. Não houve corte de vegetação para obter números melhores.

Os três perfis e resolução adaptativa existentes continuam disponíveis. Ainda não foi criado um perfil Web independente com limites derivados de múltiplos dispositivos; não apresentar os perfis genéricos como calibração Web concluída.

Exceção específica Web implementada: a criatura alada distante usa material sem iluminação e sem projetar sombras, mantendo a silhueta preta, transparência e animação. A criatura terrestre e seus materiais permanecem preservados. `Performance.MEMORY_STATIC=0` no export não comprova consumo zero: essa métrica não oferece uma medição útil de RAM neste ensaio.

O bloqueio inicial próximo de 20 s requer separar compilação de shaders/driver e primeiro desenho. A instrumentação de construção do mundo mede apenas CPU das etapas, não custo posterior de shader/GPU. No ensaio registrado a navegação ocupou cerca de 70 ms. Evidência em `review/web-audit/startup.json`.

Referência: [exportação Web Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html).
