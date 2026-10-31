# Biblioteca PBR

Os dez materiais originais de concreto, piso, reboco, ferrugem, madeira, lama, tecido, resíduo e pele continuam disponíveis. Dez materiais novos para objetos pequenos: brushed_metal, wet_steel, dirty_glass, cracked_glass, aged_plastic, worn_rubber, damp_wood, industrial_sheet, moss e old_upholstery.

`tools/art/generate_physics_materials.py` gera albedo, normal e ORM (R: AO, G: rugosidade, B: metálico) em 256 e 128 pixels, com seed fixa e imagens originais sintetizadas. Resources em `assets/materials`, mapas em `assets/textures/pbr`, manifesto `physics_materials_manifest.json`. São texturas funcionais procedurais, sem fotografias de terceiros. Não foram usadas imagens geradas por IA nesta etapa.

`HorrorArt.surface` compartilha materiais, usa projeção triplanar no mundo com escala uniforme e preserva UVs do rig onde solicitado. No perfil baixo, objetos novos usam 128; arquitetônicos antigos 256. No médio/alto, novos objetos usam 256 e arquitetura 512. Normal/AO são reduzidos no baixo. A iluminação original continua escura e industrial.

Aplicações: chapa industrial nas portas e balde, aço no gerador/cadeira, metal escovado em ferramentas/carrinho, madeira úmida em gaveta e caixas, vidro nas garrafas/janela/telas, plástico no rádio/alarme/carcaças, borracha na esfera e cabos, tecido no estofado, musgo no subsolo. Assim, peso e função também recebem pistas visuais distintas.

Vidro é opaco e sujo para evitar transparência ordenada/refração caras em mobile; vidro trincado não é shader de destruição. Correntes oxidam com o material metálico existente. Variações antigas de madeira, concreto e tecido continuam compondo famílias maiores sem duplicar texturas desnecessárias.

Perfis físicos separados em `PhysicsSurfaces`: metal (atrito 0,45/restituição 0,12), madeira (0,72/0,08), concreto (0,8/0,04), vidro (0,35/0,16), borracha (0,95/0,65), terra (0,9/0) e tecido (0,95/0,02). A combinação de dois materiais segue o solver Godot. Experimento com caixas idênticas confirmou maior deslocamento no material de menor atrito.
