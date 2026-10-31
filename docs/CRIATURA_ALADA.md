# A Sombra Alada

Entidade ambiental original, separada do Escutador terrestre. Fontes: `tools/art/build_flying_shadow.py` e `assets/source/sombra_alada.blend`. Exports: `assets/models/sombra_alada.glb` e `_low.glb`; manifesto junto dos modelos.

Modelo humanoide alongado, crânio bifurcado, braços, pernas, garras e asas membranosas recortadas com nervuras. Envergadura 14 m; rig de 11 ossos, 1.192 triângulos no normal e 654 no baixo. Seis clipes exportados: `glide`, `flap`, `bank_left`, `bank_right`, `fast_pass`, `vanish`. O evento usa planado, batidas, passagem rápida e desaparecimento; curvas aplicam inclinação procedural adicional. Os clipes de curva também estão disponíveis no AnimationPlayer para evolução futura.

Materiais pretos, dupla face nas membranas e fade nas extremidades da trajetória. Há uma instância reutilizada; troca de LOD ocorre somente ociosa. A silhueta foi conferida contra a lua na captura `review/night/03_shadow_moon.png`; carregamento, animações usadas e dois LODs passaram nos testes.

É um modelo otimizado para distância, com acabamento procedural simplificado. Não foram implementados pouso, investigação, combate ou perseguição aérea; a criatura não substitui nem altera a IA terrestre.
