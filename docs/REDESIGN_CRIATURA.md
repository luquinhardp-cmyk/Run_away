# O Escutador — segunda versão

Conceito original: um predador de audição hipertrofiada, ombros e braços assimétricos, pescoço torto, dorso elevado, cabeça bipartida e mandíbula articulada. Conchas auditivas desiguais e costelas externas preservam leitura da silhueta; dedos compridos e dentes irregulares completam a ameaça.

Fonte reproduzível: `tools/art/build_escutador_v2.py`, executada no Blender 4.5.15. Arquivo editável: `assets/source/escutador_v2.blend`. GLBs: `assets/models/escutador_v2.glb` e `escutador_v2_low.glb`. Manifesto ao lado dos modelos registra estatísticas e origem. São modelos 3D reais, com UVs, quatro materiais PBR e 29 ossos. A derme é contínua, remalhada por voxels, suavizada e decimada; mandíbula, conchas e queratina preservam articulação própria.

LOD principal: 11.144 triângulos. LOD baixo: 5.126. Há 23 clipes: idle, breathe, walk, patrol, listen, investigate, search, run, chase, attack, capture, return, head_tilt, hide_search, lost e oito capture_* (consultar manifesto para a lista exata). O adaptador em `escutador_visual.gd` conecta estados, busca em esconderijo e captura. Ausência de um clipe específico usa captura/ataque disponível como fallback.

O material da pele usa texturas existentes e ajuste de cor local. Perfil baixo usa o GLB reduzido e mapas 256; médio usa 512. GLBs antigos permanecem no repositório, excluídos das novas exportações.

Limite artístico: é uma escultura e animação procedurais funcionais. Ainda precisa de acabamento manual de anatomia, retopologia, pintura e contatos das mãos para qualidade cinematográfica. As variantes de captura são poses distintas do mesmo rig, não oito cenas cinematográficas produzidas à mão. Não há modelo externo copiado.
